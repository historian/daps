
desc "build the daps"
task :build do
  sh "gem build daps.gemspec"
  system("mkdir -p pkg ; mv ./*.gem pkg/")
end

desc "install the daps"
task :install => [:load_version, :build] do
  sh "gem install -l pkg/daps-#{Daps::VERSION}.gem"
end

desc "release the daps"
task :release => [:load_version, :build] do
  unless %x[ git status 2>&1 ].include?('nothing to commit (working directory clean)')
    puts "Your git stage is not clean!"
    exit(1)
  end

  if %x[ git tag 2>&1 ] =~ /^#{Regexp.escape(Daps::VERSION)}$/
    puts "Please bump your version first!"
    exit(1)
  end

  require File.expand_path('../lib/daps/version', __FILE__)
  sh "gem push pkg/daps-#{Daps::VERSION}.gem"
  sh "git tag -a -m \"#{Daps::VERSION}\" #{Daps::VERSION}"
  sh "git push origin master"
  sh "git push origin master --tags"
end

desc 'Build the manual'
task :man => :load_version do
  require 'ronn'
  ENV['RONN_MANUAL']  = "Daps #{Daps::VERSION}"
  ENV['RONN_ORGANIZATION'] = "Simon Menke"
  sh "ronn -w -s toc man/*.ronn"
end

desc 'Publish to github pages'
task :pages => :man do
  puts '----------------------------------------------'
  puts 'Rebuilding pages ...'
  verbose(false) {
    rm_rf 'pages'
    push_url = `git remote show origin`.grep(/Push.*URL/).first[/git@.*/]
    sh "
      set -e
      git fetch -q origin
      rev=$(git rev-parse origin/gh-pages)
      git clone -q -b gh-pages . pages
      cd pages
      git reset --hard $rev
      rm -f daps*.html index.html
      cp -rp ../man/daps*.html ./
      cp -p daps.1.html index.html
      git add daps*.html index.html
      git add -u daps*.html index.html
      git commit -m 'rebuild manual'
      git push #{push_url} gh-pages
    ", :verbose => false
    rm_rf 'pages'
  }
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
  require File.expand_path('../lib/daps/version', __FILE__)
end