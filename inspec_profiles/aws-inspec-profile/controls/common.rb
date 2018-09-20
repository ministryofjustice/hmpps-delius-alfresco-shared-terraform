# load data from Terraform output
json_file="output-common.json"
content = inspec.profile.file(json_file)
params = JSON.parse(content)

# #variables

# #region
# aws_region = params['region']['value']

#tags
control 'check_environment_tags' do
  describe params['common_tags']['value'] do
    its(['application']) { should_not eq nil }
    its(['business-unit']) { should_not eq nil }
    its(['environment']) { should_not eq nil }
    its(['environment-name']) { should_not eq nil }
    its(['infrastructure-support']) { should_not eq nil }
    its(['is-production']) { should_not eq nil }
    its(['owner']) { should_not eq nil }
    its(['provisioned-with']) { should_not eq nil }
    its(['region']) { should_not eq nil }
    its(['sub-project']) { should_not eq nil }
  end
end