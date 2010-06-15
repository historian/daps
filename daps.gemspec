# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'daps/version'

Gem::Specification.new do |s|
  s.name        = "daps"
  s.version     = Daps::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Menke"]
  s.email       = ["simon.menke@gmail.com"]
  s.homepage    = "http://github.com/fd/daps"
  s.summary     = "Ad hoc rsync server"
  s.description = "Ad hoc rsync server."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "daps"

  s.require_path = 'lib'
  s.files        = Dir.glob("{lib}/**/*") +
                   %w(LICENSE README.md )

  s.executables = %w( daps )

  s.add_runtime_dependency 'cramp', '= 0.11'
  s.add_runtime_dependency 'thin',  '= 1.2.7'
  s.add_runtime_dependency 'thor',  '= 0.13.6'
end