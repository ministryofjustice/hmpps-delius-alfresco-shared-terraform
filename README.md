# hmpps-delius-alfresco-shared-terraform
Terraform Repo for the Alfresco in the shared VPC

REMOTE STATE
============

Bucket name: [tf-eu-west-2-hmpps-delius-core-dev-remote-state](https://s3.console.aws.amazon.com/s3/object/tf-eu-west-2-hmpps-delius-core-dev-remote-state/vpc/terraform.tfstate?region=eu-west-2&tab=overview)

DEPLOYER KEY
============

The deployer created is stored in the remote state bucket in the ssh-key state file as an output.

To retrive the key type command below

```
terragrunt output ssh_private_key_pem
```

```


## ASG setup

```

# ALFRESCO AMI
alfresco_instance_ami = {
  az1 = ""

  az2 = "ami-0d0cfea5db992db12"

  az3 = "ami-02a2337c574b6d5e2"
}
```

The ASG uses a map to control the AMI deployed, if the variable is set to empty the launch configuration will default to the latest AMI found by terrafrom. If specified the launch configuration will use the AMI defined.

```
az_asg_desired = {
  az1 = "1"

  az2 = "0"

  az3 = "0"
}
az_asg_max = {
  az1 = "1"

  az2 = "0"

  az3 = "0"
}
az_asg_min = {
  az1 = "1"

  az2 = "0"

  az3 = "0"
}
```

Above controls ASG sizes

TERRAGRUNT
===========

## DOCKER CONTAINER IMAGE

Container repo [hmpps-engineering-tools](https://github.com/ministryofjustice/hmpps-engineering-tools)

To run the container please run the following steps

#### ARN FOR NON PROD ENGINEERING

```
arn:aws:iam::563502482979:role/terraform
```

#### TERRAFORM REPOS

[hmpps-delius-alfresco-shared-terraform](https://github.com/ministryofjustice/hmpps-delius-alfresco-shared-terraform)

[hmpps-terraform-modules](https://github.com/ministryofjustice/hmpps-terraform-modules)

Ensure hmpps-engineering-platform-terraform is cloned into the current directory

```
ls
hmpps-delius-alfresco-shared-terraform

```

#### START UP

Provide the docker container with the following environment variables

```
AWS_PROFILE
```

#### COMMAND

cd to the directory above this repo, replace 'hmpps-token' in the command below with one of your own, and run
```
docker run -it --rm \
	-v $(pwd)/hmpps-delius-alfresco-shared-terraform:/home/tools/data \
	-v ~/.aws:/home/tools/.aws \
	-e AWS_PROFILE=hmpps-token \
	hmpps/terraform-builder:latest bash
```
Once in the container, run

```
source env_configs/dev.properties
```
Now navigate to the directory for your configuration (e.g. service-jenkins-eng) and run terragrunt commands as normal?

INSPEC
======

[Reference material](https://www.inspec.io/docs/reference/resources/#aws-resources)

## TERRAFORM TESTING

#### Temporary AWS creds 

Script __scripts/aws-get-temp-creds.sh__ has been written up to automate the process of generating the creds into a file __env_configs/inspec-creds.properties__

#### Usage

```
sh scripts/generate-terraform-outputs.sh
sh scripts/aws-get-temp-creds.sh
source env_configs/inspec-creds.properties
inspec exec ${inspec_profile} -t aws://${TG_REGION} --attrs ${attributes_file}
```

#### To remove the creds

```
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
export AWS_PROFILE=hmpps-token
source env_configs/dev.properties
rm -rf env_configs/inspec-creds.properties
```