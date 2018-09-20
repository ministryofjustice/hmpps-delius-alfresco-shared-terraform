# load data from Terraform output
json_file="output-iam.json"
content = inspec.profile.file(json_file)
params = JSON.parse(content)

# #variables
iam_policy_ext_app_role_name = params['iam_policy_ext_app_role_name']['value']
iam_policy_int_app_role_name = params['iam_policy_int_app_role_name']['value']
iam_role_ext_ecs_role_name = params['iam_role_ext_ecs_role_name']['value']

# Ensure that a certain role exists
describe aws_iam_role(iam_policy_ext_app_role_name) do
  it { should exist }
end

# Ensure that a certain role exists
describe aws_iam_role(iam_policy_int_app_role_name) do
  it { should exist }
end

# Ensure that a certain role exists
describe aws_iam_role(iam_role_ext_ecs_role_name) do
  it { should exist }
end