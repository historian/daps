class RsyncAdhoc::Client

  require "tempfile"
  require "eventmachine"

  attr_reader :dir, :remote, :username, :password, :port

  def initialize(dir, remote, username, password, port)
    @dir, @remote, @username, @password, @port = File.expand_path(dir), remote, username, password, port
  end

  def start!
    EM.run do
      EM.connect(@remote, @port, SignalClient,
        @dir, @remote, @username, @password)
    end
  end

  class SignalClient < EM::Connection
    include EM::P::ObjectProtocol

    attr_accessor :password

    def initialize(dir, remote, username, password)
      @dir, @remote, @username, @password = dir, remote, username, password
      @sha = Digest::SHA1.hexdigest([@username, @password].join(':'))
      super
    end

    def post_init
      send_object(@sha)
    end

    def receive_object(obj)
      if Hash === obj and obj.key?(:port)
        @port = obj[:port].to_i
        sleep 0.5
        boot_rsync!
      else
        close_connection
      end
    end

    def unbind
      if @pipe
        @pipe.kill!
      end

      if @password_file
        password_file.close
        File.unlink(password_file.path)
      end

      EM.stop_event_loop
    end

    def password_file
      @password_file ||= begin
        f = Tempfile.open(["adhoc-rsync", ".sec"])
        f.puts @password
        f.flush
        f
      end
    end

    def boot_rsync!
      cmd = %{rsync --stats --progress -avz --password-file=#{password_file.path} --port #{@port} #{@username}@#{@remote}::tmp #{@dir}}

      @pipe = EM::popen(cmd, PipeHandler, self)
    end

  end

  module PipeHandler

    attr_accessor :client

    def initialize(client)
      @client = client
      super
    end

    def post_init

    end

    def receive_data(data)
      puts data
    end

    def unbind
      @client.close_connection
    end

    def kill!
      Process.kill("INT", get_pid) rescue nil
    end

  end

end