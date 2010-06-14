
desc "build the rsync-adhoc"
task :build do
  sh "gem build rsync-adhoc.gemspec"
  system("mkdir -p pkg ; mv ./*.gem pkg/")
end

desc "install the rsync-adhoc"
task :install => [:load_version, :build] do
  sh "gem install -l pkg/rsync-adhoc-#{RsyncAdhoc::VERSION}.gem"
end

desc "release the rsync-adhoc"
task :release => [:load_version, :build] do
  unless %x[ git status 2>&1 ].include?('nothing to commit (working directory clean)')
    puts "Your git stage is not clean!"
    exit(1)
  end

  if %x[ git tag 2>&1 ] =~ /^#{Regexp.escape(RsyncAdhoc::VERSION)}$/
    puts "Please bump your version first!"
    exit(1)
  end

  require File.expand_path('../lib/rsync-adhoc/version', __FILE__)
  sh "gem push pkg/rsync-adhoc-#{RsyncAdhoc::VERSION}.gem"
  sh "git tag -a -m \"#{RsyncAdhoc::VERSION}\" #{RsyncAdhoc::VERSION}"
  sh "git push origin master"
  sh "git push origin master --tags"
end

desc 'Build the manual'
task :man => :load_version do
  require 'ronn'
  ENV['RONN_MANUAL']  = "RsyncAdhoc #{RsyncAdhoc::VERSION}"
  ENV['RONN_ORGANIZATION'] = "Simon Menke"
  sh "ronn -w -s toc man/*.ronn"
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = FileList['lib/**/*.rb'].to_a
    t.options = ['-m', 'markdown', '--files', FileList['documentation/*.markdown'].to_a.join(',')]
  end
rescue LoadError
  puts "YARD not available. Install it with: sudo gem install yard"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :load_version do
  require File.expand_path('../lib/rsync-adhoc/version', __FILE__)
end