actions :delete_queue, :noop_delete_queue
default_action :noop_delete_queue #Declare a default action
attribute :vhost, :name_attribute => true, :kind_of => String, :required => true
attribute :queue, :kind_of => String
attr_accessor :exists

