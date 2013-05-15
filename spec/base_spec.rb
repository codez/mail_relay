require 'spec_helper'

describe MailRelay::Base do

  let(:simple)  { Mail.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'simple.eml'))) }
  let(:regular) { Mail.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'regular.eml'))) }
  let(:list)    { Mail.new(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'list.eml'))) }

  let(:relay) { MailRelay::Base.new(message) }

  let(:last_email) { Mail::TestMailer.deliveries.last }

  describe "#receiver_from_received_header" do
    subject { relay }

    context "simple" do
      let(:message) { simple }

      its(:receiver_from_received_header) { should be_nil }
      its(:receiver_from_x_header) { should be_nil }
    end

    context "regular" do
      let(:message) { regular }

      its(:receiver_from_received_header) { should == 'receiver' }
      its(:receiver_from_x_header) { should == 'receiver' }
    end

    context "list" do
      let(:message) { list }

      its(:receiver_from_received_header) { should == 'receiver' }
      its(:receiver_from_x_header) { should == 'receiver' }
    end
  end

  describe "#envelope_receiver_name" do
    context "regular" do
      let(:message) { regular }

      it "returns receiver" do
        relay.envelope_receiver_name.should == 'receiver'
      end
    end
  end

  describe "#relay" do
    let(:message) { regular }

    subject { last_email }

    context "without receivers" do
      before { relay.relay }

      it { should be_nil }
    end

    context "with receivers" do
      let(:receivers) { %w(a@example.com b@example.com) }
      before do
        relay.stub(:receivers).and_return(receivers)
        relay.relay
      end

      it { should_not be_nil }
      its(:smtp_envelope_to) { should == receivers }
      its(:smtp_envelope_from) { should == 'receiver@localhost' }
      its(:to) { should == ['receiver@example.com'] }
      its(:from) { should == ['sender@example.com'] }
    end
  end

  describe ".relay_current" do
    it "processes all mails" do
      MailRelay::Base.retrieve_count = 5

      first = true
      Mail.should_receive(:find_and_delete) do |options, &block|
        msgs = first ? [1,2,3,4,5] : [6,7,8]
        msgs.each {|m| block.call(m) }
        first = false
        msgs
      end.twice

      m = mock
      m.stub(:relay)
      MailRelay::Base.stub(:new).and_return(m)
      MailRelay::Base.should_receive(:new).exactly(8).times

      MailRelay::Base.relay_current
    end

    it "fails after one batch" do
      MailRelay::Base.retrieve_count = 5

      msg = Struct.new(:id, :mark_for_delete)
      msgs1 = (1..5).collect {|i| msg.new(i, true) }
      msgs2 = (6..8).collect {|i| msg.new(i, true) }

      first = true
      Mail.should_receive(:find_and_delete) do |options, &block|
        msgs = first ? msgs1 : msgs2
        msgs.each {|m| block.call(m) }
        first = false
        msgs
      end


      mail = double(:mail)
      mail.should_receive(:relay).exactly(4).times
      MailRelay::Base.stub(:new).and_return(mail)
      mail = double(:mail)
      mail.should_receive(:relay).and_raise('failure!')
      MailRelay::Base.should_receive(:new).with(msgs1[2]).and_return(mail)

      expect { MailRelay::Base.relay_current }.to raise_error(MailRelay::Error)

      msgs1[0].mark_for_delete.should == true
      msgs1[1].mark_for_delete.should == true
      msgs1[2].mark_for_delete.should == false
      msgs1[3].mark_for_delete.should == true
      msgs1[4].mark_for_delete.should == true
    end
  end
end
