class Daps::Application < Thor

  desc "server DIR [TOKEN]", "Start the daps server"
  method_option :port, :type => :numeric, :default => 0
  def server(dir, token=nil)
    server = Daps::Server.new(dir, token, options.port)
    server.start!
  end

  desc "pull REMOTE DIR", "Pull file from a remote"
  def pull(remote, dir)
    remote = remote.sub(/^http[s]?[:]\/\//, 'daps://')
    remote = "daps://#{remote}" unless remote[0,7] == 'daps://'
    remote = URI.parse(remote)

    port  = remote.port || 5001
    token = File.basename(remote.path)
    remote = remote.host

    client = Daps::Client.new(dir, remote, token, port)
    client.start!
  end

end