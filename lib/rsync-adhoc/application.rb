class RsyncAdhoc::Application < Thor

  desc "server DIR USER PASSWORD", "Start the ad hoc rsync server"
  method_option :port, :type => :numeric, :default => 5001
  def server(dir, user, password)
    server = RsyncAdhoc::Server.new(dir, user, password, options.port)
    server.start!
  end

  desc "pull DIR REMOTE USER PASSWORD", "Pull file from a remote"
  method_option :port, :type => :numeric, :default => 5001
  def pull(dir, remote, user, password)
    client = RsyncAdhoc::Client.new(dir, remote, user, password, options.port)
    client.start!
  end

end