# load data from Terraform output
json_file="output-s3buckets.json"
content = inspec.profile.file(json_file)
params = JSON.parse(content)

# #variables
# storage bucket
s3bucket = params['s3bucket']['value']
s3bucket_logs = params['s3bucket-logs']['value']

# #region
aws_region = params['region']['value']

# kms
s3bucket_kms_arn = params['s3bucket_kms_arn']['value']

#cloudtrail
s3bucket_cloudtrail_id = params['s3bucket_cloudtrail_id']['value']

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

# Find a kms key by arn
describe aws_kms_key(s3bucket_kms_arn) do
  it { should exist }
end

# Find a trail by name
describe aws_cloudtrail_trail(s3bucket_cloudtrail_id) do
  it { should exist }
end