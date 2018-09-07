terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../../vpc", "../ecr"]
  }
}

internal = true

listener = [
  {
    instance_port     = "8080"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  },
]

health_check = [
  {
    target              = "HTTP:8080/alfresco/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  },
]

# ASG
service_desired_count = "3"

user_data = "user_data/user_data.sh"

volume_size = "20"

ebs_device_name = "/dev/xvdb"

ebs_volume_type = "standard"

ebs_volume_size = "512"

ebs_encrypted = "true"

instance_type = "t2.large"

associate_public_ip_address = false

cache_home = "/srv/cache"
