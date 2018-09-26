actions :enable
 
attribute :tagname, :name_attribute => true, :kind_of => String, :required => true
attribute :retention, :kind_of => Integer, :required => true 
attribute :frequency, :kind_of => String, :required => true

attr_accessor :exists
