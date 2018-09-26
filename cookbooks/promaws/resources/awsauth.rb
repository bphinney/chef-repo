actions :connect
default_action :connect  #Declare a default action
attribute :elbname, :name_attribute => true, :kind_of => String, :required => true
attr_accessor :exists
