class Daps::Server

  def initialize(dir, token, port)
    @dir, @token, @port = File.expand_path(dir), token, port.to_i
    Dir.chdir(@dir)
  end

  def start!
    Rack::Handler::Thin.run self, :Port => @port
  end

  def call(env)
    env['daps.token'] = @token
    env['daps.dir']   = @dir
    Http.call(env)
  end

  class Http < Sinatra::Base

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

class Sinatra::Helpers::StaticFile < ::File
  alias_method :other_each, :each
  def each(&block)
    other_each(&block)
  ensure
    EM.next_tick do
      File.unlink(self.path)
      EM.stop_event_loop
    end
  end
end