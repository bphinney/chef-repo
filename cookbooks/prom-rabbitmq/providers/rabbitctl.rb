def whyrun_supported?
  true
end

action :delete_queue do 
  if @current_resource.exists
    Chef::Log.info "#{@new_resource} already deleted queues."
  else
    converge_by("Delete #{@new_resource}->#{@current_resource.queue}") do
      remove_queue 
    end
  end
end

action :noop_delete_queue do
  noop_remove_queue
end

def load_current_resource
  @current_resource = Chef::Resource::PromRabbitmqRabbitctl.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.vhost(@new_resource.vhost)
  @current_resource.queue(@new_resource.queue)
end

def remove_queue
  vhost = new_resource.vhost
  queue = new_resource.queue 
  %x(/usr/local/bin/rabbitmqadmin -u bugsbunny -p wascallywabbit -V #{vhost} delete queue name=#{queue} >/dev/null 2>&1 &)
end

def noop_remove_queue
  vhost = new_resource.vhost
  queue = new_resource.queue
  puts "/usr/local/bin/rabbitmqadmin -u bugsbunny -p wascallywabbit -V #{vhost} delete queue name=#{queue}"
end

