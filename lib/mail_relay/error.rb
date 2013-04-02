module MailRelay
  class Error < StandardError
    attr_reader :original
    attr_reader :mail

    def initialize(mail, original = nil)
      @mail = mail
      @original = original
    end
  end
end