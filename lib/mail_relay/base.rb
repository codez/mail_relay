module MailRelay
  # A generic email relay object. Retrieves messages from a mail server and resends them to a list of recievers.
  # In subclasses, override the methods #relay_address?, #sender_allowed? and #receivers
  # to constrain which mails are sent to whom.
  class Base

    class << self
      # Define a header that contains the original receiver address.
      # This header could be set by the mail server.
      attr_accessor :receiver_header

      # Number of emails to retrieve in one batch.
      attr_accessor :retrieve_count

      # The local domain where mails are received and sent from.
      attr_accessor :mail_domain

      # Retrieve, process and delete all mails from the mail server.
      def relay_current
        begin
          last_exception = nil

          mails = Mail.find_and_delete(:count => retrieve_count) do |message|
            begin
              new(message).relay
            rescue Exception => e
              message.mark_for_delete = false
              last_exception = MailRelay::Error.new(message, e)
            end
          end

          raise(last_exception) if last_exception

        end while mails.size >= retrieve_count
      end

    end

    self.retrieve_count = 5
    self.receiver_header = 'X-Envelope-To'
    self.mail_domain = 'localhost'


    attr_reader :message

    def initialize(message)
      @message = message
    end

    # Process the given email.
    def relay
      if relay_address?
        if sender_allowed?
          resend_to(receivers)
        else
          reject_not_allowed
        end
      else
        reject_not_existing
      end
    end

    # Send the same mail as is to all receivers, if any.
    def resend_to(destinations)
      if destinations.size > 0
        message.smtp_envelope_to = destinations

        # Set envelope from and sender to local server to satisfy SPF:
        # http://www.openspf.org/Best_Practices/Webgenerated
        message.sender = envelope_sender
        message.smtp_envelope_from = envelope_sender

        # set list headers
        message.header['Precedence'] = 'list'
        message.header['List-Id'] = list_id

        deliver(message)
      end
    end

    # If the email sender was not allowed to post messages, this method is called.
    # Silently ignores the message by default.
    def reject_not_allowed
      # do nothing
    end

    # If the email is sent to an address that is not a valid relay, this method is called.
    # Silently ignores the message by default.
    def reject_not_existing
      # do nothing
    end

    # The receiver account that originally got this email.
    # You probably have to re-implement this method depending on your mail server setup.
    # Returns only the part before the @ sign.
    def envelope_receiver_name
      receiver_from_x_header ||
      receiver_from_received_header ||
      raise("Could not determine original receiver for email:\n#{message.header}")
    end

    # The email address of the sender. As found in the from header.
    def sender_email
      @sender_email ||= message.from && message.from.first
    end


    # Heuristic method to find actual receiver of the message.
    # May return nil if could not determine.
    def receiver_from_received_header
      if received = message.received
        received = received.first if received.respond_to?(:first)
        received.info[/ for .*?([^\s<>]+)@[^\s<>]+/, 1]
      end
    end

    # Try to read the envelope receiver from the given x header
    def receiver_from_x_header
      if field = message.header[self.class.receiver_header]
        field.to_s.split('@', 2).first
      end
    end

    # Is the mail sent to a valid relay address?
    def relay_address?
      true
    end

    # Is the mail sender allowed to post to this address
    def sender_allowed?
      true
    end

    # List of receiver email addresses for the resent email.
    def receivers
      []
    end

    def envelope_sender
      "#{envelope_receiver_name}@#{mail_domain}"
    end

    def list_id
      "#{envelope_receiver_name}.#{mail_domain}"
    end

    def mail_domain
      self.class.mail_domain
    end

    private

    def deliver(message)
      if defined?(ActionMailer::Base)
        ActionMailer::Base.wrap_delivery_behavior(message)
      end
      message.deliver
    end

  end
end