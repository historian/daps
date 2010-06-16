class Daps::Server

  def initialize(dir, token, port)
    @dir, @token, @port = File.expand_path(dir), token, port.to_i
  end

  def start!
    Dir.chdir(@dir)

    @port    = rand(5000) + 5000 if @port == 0
    @token ||= Digest::SHA1.hexdigest([Time.now, rand(1<<100)].join('--'))

    puts "URI: daps://#{`hostname`.strip}:#{@port}/#{@token}"

    Rack::Handler::Thin.run(self, :Port => @port) { |s| s.silent = true }
  end

  def call(env)
    env['daps.token'] = @token
    env['daps.dir']   = @dir
    ArchiveStreamer.call(env)
  end

  class ArchiveStreamer < Cramp::Controller::Action
    before_start :verify_token
    on_start  :open_stream
    on_finish :terminate

    def verify_token
      @token = File.basename(@env['PATH_INFO'])
      if @env['daps.token'] != @token
        halt 403, {'Content-Type' => 'text/html'}, 'back off!!'
      else
        yield
      end
    end

    def respond_with
      [200, {'Content-Type' => 'application/x-gzip', 'Transfer-Encoding' => 'chunked'}]
    end

    def open_stream
      puts "Transferring archive..."
      @pipe = EM.popen('tar -czf - .', Daps::Server::Pipe, self)
    end

    def terminate
      @pipe.terminate if @pipe
      EM.next_tick {
        if @env['daps.token'] == @token
          EM.stop_event_loop
        end
      }
    end

    def render(data)
      term = "\r\n"
      size = Rack::Utils.bytesize(data)
      super([size.to_s(16), term, data, term].join)
    end

  end

  module Pipe

    def initialize(connection)
      @connection = connection
      # super
    end

    def receive_data(data)
      @connection.render data
    end

    def unbind
      @connection.render('')
      EM.next_tick{ @connection.finish }
    end

    def terminate
      Process.kill('INT', get_pid) rescue nil
    end

  end

end