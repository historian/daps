class Daps::Client

  require 'fileutils'

  def initialize(dir, remote, token, port)
    @dir, @remote, @token, @port = File.expand_path(dir), remote, token, port
  end

  def start!
    FileUtils.mkdir_p(@dir)
    system(%{
      curl http://#{@remote}:#{@port}/#{@token} | tar --directory=#{@dir} -xzf -
    })
  end

end