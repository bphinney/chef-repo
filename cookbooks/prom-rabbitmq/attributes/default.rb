# Default Rabbitmq
default["rabbitmq_service"] = "internal-rabbitmq-634112559.us-east-1.elb.amazonaws.com"
# Default Environments to not create shared infrastructure for
default["noenvirons"] = ["local", "_default", "tools", "localpoc"]
