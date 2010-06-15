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
    Http.call(env)
  end

  class Http < Sinatra::Base

    get '/:token/close' do
      token = params[:token]
      if @env['daps.token'] != token
        halt(403, {'Content-type' => 'text/plain'}, 'back off!')
      end

      File.unlink("/tmp/daps-#{token}-server.tar.gz")
      EM.stop_event_loop
    end

    get '/:token' do
      token = params[:token]
      if @env['daps.token'] != token
        halt(403, {'Content-type' => 'text/plain'}, 'back off!')
      end

      puts "Compressing files..."
      system(%{
        cd #{@env['daps.dir']} ;
        tar -czf /tmp/daps-#{token}-server.tar.gz . ;
      })

      puts "Transfering archive..."
      send_file "/tmp/daps-#{token}-server.tar.gz"
    end

  end

end