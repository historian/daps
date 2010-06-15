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
    before_start :verify_token, :build_archive
    on_start  :prepare_stream
    on_finish :terminate

    def verify_token
      @token = File.basename(@env['PATH_INFO'])
      if @env['daps.token'] != @token
        halt 403, {}, 'back off!!'
      else
        yield
      end
    end

    def build_archive
      puts "Compressing files..."
      system(%{
        cd #{@env['daps.dir']} ;
        tar -czf /tmp/daps-#{@token}-server.tar.gz . ;
      })

      @length  = File.size("/tmp/daps-#{@token}-server.tar.gz")
      @archive = File.open("/tmp/daps-#{@token}-server.tar.gz")

      yield
    end

    def respond_with
      [200, {'Content-Type' => 'text/html', 'Content-Length' => @length.to_s}]
    end

    def prepare_stream
      puts "Transferring archive..."
      stream_chunks
    end

    def stream_chunks
      if data = @archive.read(1024 * 156)
        render data
        EM.add_timer(0.01) { stream_chunks }
      else
        finish
      end
    end

    def terminate
      EM.next_tick {
        if @env['daps.token'] == @token
          File.unlink("/tmp/daps-#{@token}-server.tar.gz")
          EM.stop_event_loop
        end
      }
    end

  end

end