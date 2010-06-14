# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rsync-adhoc/version'

Gem::Specification.new do |s|
  s.name        = "rsync-adhoc"
  s.version     = RsyncAdhoc::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Menke"]
  s.email       = ["simon.menke@gmail.com"]
  s.homepage    = "http://github.com/fd/rsync-adhoc"
  s.summary     = "Ad hoc rsync server"
  s.description = "Ad hoc rsync server."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "rsync-adhoc"

  s.require_path = 'lib'
  s.files        = Dir.glob("{lib}/**/*") +
                   %w(LICENSE README.md )

  s.executables = %w( rsync-adhoc )

  s.add_runtime_dependency 'eventmachine', '= 0.12.10'
  s.add_runtime_dependency 'thor',         '= 0.13.6'
end