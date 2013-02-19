#!/usr/bin/env rake
require "rubygems"
require "bundler/setup"


Bundler::GemHelper.install_tasks


require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)


require 'rdoc/task'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'mail_relay'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec