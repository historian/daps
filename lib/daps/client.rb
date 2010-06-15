class Daps::Client

  def initialize(dir, remote, token, port)
    @dir, @remote, @token, @port = File.expand_path(dir), remote, token, port
  end

  def start!
    system(%{
      wget -T 600 -O /tmp/daps-#{@token}-client.tar.gz http://#{@remote}:#{@port}/#{@token} &&
      tar --directory=#{@dir} -xzf /tmp/daps-#{@token}-client.tar.gz ;
      rm -f /tmp/daps-#{@token}-client.tar.gz
    })
  end

end