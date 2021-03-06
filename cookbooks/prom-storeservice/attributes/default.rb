##########################
# global-service defaults #
###########################

# Application Version
default['applications']['backend']['storeservice_version'] = "0.0.0-1"

#### store-service defaults ####
# db endpoint
default['store-service']['database'] = "storesvc#{node.chef_environment}"
default['store-service']['username'] = 'storesvcuser'
default['store-service']['password'] = 'storesvcpass'

## SMTP ##
default['smtp']['smtp_from_address'] = "classflow@prometheanjira.com"
default['smtp']['validation_timeout'] = "10"

# Java Log Levels
default["foundationlog"]["defaultloglevel"] = "INFO"
default['foundationlog']['logger_storeloglevel'] = [ ]

# RabbitMQ Stuff
default['rabbitmq']['storeservice']['consumers'] = "1"
default['rabbitmq']['paypal']['delayedpayment']['consumers'] = "2"

# Paypal info
default['paypal']['api'] = "https://svcs.sandbox.paypal.com"
default['paypal']['transurl'] = "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_ap-payment&paykey="
default['paypal']['serviceuser'] = "john.molnar-facilitator_api1.prometheanworld.com"
default['paypal']['servicepass'] = "4SXWRVP7Y6KMXPM7"
default['paypal']['serviceusersig'] = "AFcWxV21C7fd0v3bYYYRCpSSRl31AIh5U03ANk0Eu3Ax2gVGqlTwdrpU"
default['paypal']['serviceappid'] = "APP-80W284485P519543T"
default['paypal']['currency'] = "USD"
default['paypal']['curracct'] = "USD@prometheanworld.com"
default['paypal']['currency_account'] = '"USD":"USD@prometheanworld.com"'

# IN-1642 Basic Auth credentials
default['af']['intapiuser'] = "#{node.chef_environment}apiuser"
default['af']['intapipass'] = "#{node.chef_environment}apipass"
