# load data from Terraform output
json_file="terraform.json"
content = inspec.profile.file(json_file)
params = JSON.parse(content)

#variables
# storage bucket
s3bucket = params['s3bucket']['value']
s3bucket_logs = params['s3bucket-logs']['value']

#region
aws_region = params['region']['value']


#S3Buckets
# storage bucket
describe aws_s3_bucket(bucket_name: s3bucket_logs) do
  it { should exist }
  it { should_not be_public }
  # Check if the correct region is set
  its('region') { should eq aws_region }
end

# lb logs bucket
describe aws_s3_bucket(bucket_name: s3bucket) do
  it { should exist }
  it { should_not be_public }
  # Check if the correct region is set
  its('region') { should eq aws_region }
end

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