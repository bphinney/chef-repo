# Class for Email notifications

# use example
#if opts['email']
#  emailconnect = EmailSender.new(dbconnect, opts['tenant'])
#  emailconnect.notify(opts['email'], 'refresh')
#end

require_relative 'apiconnect'

class EmailSender
  include ApiConnect
  def initialize(t)
    @tenant = t
  end

  require 'net/smtp'

  def notify(email_to, message_type = 'default')
    connector = ApiConnect::chef_api_connect.new
    connector.connect.search.query('email', 'id:promethean', start: 0).rows.each do |item|
      @smtpserver = "#{item['raw_data']['smtpserver']}"
    end

    port       = '587'
    originator = 'chef-server'
    email_from = 'provisioning@prometheanjira.com'

    if message_type == 'refresh'
      subject = 'Tenant Updated'
      message = "The data bag for #{@tenant} has been updated."
    elsif message_type == 'default'
      subject = 'Default Message'
      message = 'No message type was configured for this notification.'
    end

    template = <<-MESSAGE_END
      From: Tenant Provisioning <#{email_from}>
      To: DevOps <#{email_to}>
      MIME-Version: 1.0
      Content-Type: text/plain; charset=us-ascii
      Subject: #{subject}

      #{message}

      MESSAGE_END

    begin
    Net::SMTP.start(@smtpserver, port, originator) do |smtp|
      smtp.send_message template, email_from, email_to
    end
    rescue e
      puts "(chef=>tenant_prov): Email notification failure. Error: #{e}"
    end
  end
end
