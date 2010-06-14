class RsyncAdhoc::Server

  require "tempfile"
  require "eventmachine"

  attr_reader :dir, :username, :password, :port

  def initialize(dir, username, password, port)
    @dir, @username, @password, @port = File.expand_path(dir), username, password, port
  end

  def start!
    EM.run do
      EM.start_server("127.0.0.1", @port, SignalServer,
        @dir, @username, @password, @port)
    end
  end

  class SignalServer < EM::Connection
    include EM::P::ObjectProtocol

    attr_reader :port

    def initialize(dir, username, password, port)
      @dir, @username, @password, @port = dir, username, password, port
      @sha = Digest::SHA1.hexdigest([@username, @password].join(':'))
      super
    end

    def receive_object(obj)
      if String === obj and @sha == obj
        boot_rsyncd!
      else
        close_connection
      end
    end

    def unbind
      if @pipe
        @pipe.kill! rescue nil
      end

      if @password_file
        password_file.close
        File.unlink(password_file.path)
      end

      if @pid_file
        pid_file.close
        File.unlink(pid_file.path)
      end

      if @config_file
        config_file.close
        File.unlink(config_file.path)
      end

      EM.stop_event_loop
    end

    def boot_rsyncd!
      cmd = %Q{bash -c 'set -e ; rsync --daemon --no-detach --port=#{@port + 1} --config=#{config_file.path} </dev/null'}

      @pipe = EM::popen(cmd, PipeHandler, self, @port)
    end

    def password_file
      @password_file ||= begin
        f = Tempfile.open(["adhoc-rsync", ".sec"])
        f.puts "#{@username}:#{@password}"
        f.flush
        f
      end
    end

    def lock_file
      @lock_file ||= begin
        f = Tempfile.new(["adhoc-rsync", ".lck"])
        f
      end
    end

    def pid_file
      @pid_file ||= begin
        f = Tempfile.new(["adhoc-rsync", ".pid"])
        f
      end
    end

    def config_file
      @config_file ||= begin
        f = Tempfile.open(["adhoc-rsync", ".cfg"])
        f.write <<-EOC
max connections = 1
lock file       = #{lock_file.path}
pid file        = #{pid_file.path}

[tmp]
        path = #{@dir}
        comment = Ad hoc Rsync Server
        auth users = #{@username}
        secrets file = #{password_file.path}
        read only = true
        use chroot = false
EOC
        f.flush
        f
      end
    end

  end

  module PipeHandler

    attr_accessor :server, :port

    def initialize(server, port)
      @server, @port = server, port
      super
    end

    def post_init
      @server.send_object({ :port => @port + 1 })
    end

    def receive_data(data)
    end

    def unbind
    end

    def kill!
      pid = File.read(@server.pid_file.path).strip.to_i
      Process.kill("INT", pid)
    end

  end

end