# load data from Terraform output
json_file="output-rds.json"
content = inspec.profile.file(json_file)
params = JSON.parse(content)

# #variables
rds_db_instance_id = params['rds_db_instance_id']['value']

# Ensure you have a RDS instance with a certain ID
describe aws_rds_instance(rds_db_instance_id) do
  it { should exist }
end