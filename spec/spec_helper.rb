require "bundler"
Bundler.setup

if RUBY_VERSION =~ /\A1\.9/ && !defined?(JRUBY_VERSION)
  require 'simplecov'
  SimpleCov.start
  SimpleCov.coverage_dir 'spec/coverage'
end

require "rspec"
require "mail_relay"

Mail.defaults do
  delivery_method Mail::TestMailer
end

RSpec.configure do |config|
  #config.include NewGem::Spec::Matchers
end