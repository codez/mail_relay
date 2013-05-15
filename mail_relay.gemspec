$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mail_relay/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mail_relay"
  s.version     = MailRelay::VERSION
  s.authors     = ["Pascal Zumkehr"]
  s.email       = ["spam@codez.ch"]
  s.homepage    = "http://github.com/codez/mail_relay"
  s.summary     = "Relay emails for a catch-all address to user-defined recipients."
  s.description = "Retrieves messages from a mail server and resends them to a list of recievers."

  s.files = Dir["lib/**/{*,.[a-z]*}"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.require_path = 'lib'
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "bundler", ">= 1.1"

  s.add_dependency "mail", ">= 2.5.4"

  s.add_development_dependency "rake"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rspec"

end
