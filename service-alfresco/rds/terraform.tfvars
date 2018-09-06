terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../../vpc", "../ecr"]
  }
}

create_db_subnet_group = true

create_db_parameter_group = true

create_db_option_group = true

create_db_instance = true

parameters = []

family = "postgres9.6"

engine = "postgres"

major_engine_version = "9.6"

engine_version = "9.6.6"

port = "5432"

storage_encrypted = true

maintenance_window = "Mon:00:00-Mon:03:00"

backup_window = "03:00-06:00"

multi_az = true
