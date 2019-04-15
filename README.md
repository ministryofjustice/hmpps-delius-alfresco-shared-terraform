## hmpps-delius-alfresco-shared-terraform
Terraform Repo for the Alfresco in the shared VPC


## URLS


### Alfresco Dev

Alfresco external - [alfresco.dev.alfresco.probation.hmpps.dsd.io](alfresco.dev.alfresco.probation.hmpps.dsd.io)


### Alfresco Int

Alfresco external - [https://alfresco.dev.delius-core.probation.hmpps.dsd.io](https://alfresco.dev.delius-core.probation.hmpps.dsd.io)

### Alfresco Training Test

Alfresco external - [https://alfresco.training-test.delius.probation.hmpps.dsd.io](https://alfresco.training-test.delius.probation.hmpps.dsd.io)


## USING TERRAFORM


A shell script has been created to automate the running of terraform.
Script takes the following arguments

* environment_type: Target environment eg dev - prod - int
* action_type: Operation to be completed eg plan - apply - test - output
* AWS_TOKEN: token to use when running locally eg hmpps-token

Example

```
sh run.sh plan hmpps-token
```


## REMOTE STATE


Bucket name: [tf-eu-west-2-hmpps-delius-core-dev-remote-state](https://s3.console.aws.amazon.com/s3/object/tf-eu-west-2-hmpps-delius-core-dev-remote-state/vpc/terraform.tfstate?region=eu-west-2&tab=overview)

## DEPLOYER KEY


The deployer key is stored in AWS [Parameter store](https://eu-west-2.console.aws.amazon.com/systems-manager/parameters/tf-eu-west-2-hmpps-delius-core-dev-alfresco-ssh-private-key/description?region=eu-west-2)



```
terragrunt output ssh_private_key_pem
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

## TERRAGRUNT


### DOCKER CONTAINER IMAGE

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

```
terragrunt plan -detailed-exitcode --out ${TG_ENVIRONMENT_TYPE}.plan
terragrunt apply ${TG_ENVIRONMENT_TYPE}.plan
```

## Terraform - automated run


A python script has been written up: docker-run.py.

The script takes arguments shown below:

```
python docker-run.py -h
usage: docker-run.py [-h] --env ENV --action {apply,plan,test,output}
                     [--component COMPONENT] [--token TOKEN] [--repo REPO]
                     [--branch BRANCH]

terraform docker runner

optional arguments:
  -h, --help            show this help message and exit
  --env ENV             target environment
  --action {apply,plan,test,output}
                        action to perform
  --component COMPONENT
                        component to run task on
  --token TOKEN         aws token for credentials
  --repo REPO           git repo for env configs, defaults to hmpps-env-
                        configs.git
  --branch BRANCH       git repo branch for env configs, defaults to master
                        branch
````

## Usage

When running locally provide the token argument:

```
python docker-run.py --env dev --action test --token hmpps-token
```

When running in CI environment:

```
python docker-run.py --env dev --action test
```


## INSPEC

[Reference material](https://www.inspec.io/docs/reference/resources/#aws-resources)

### TERRAFORM TESTING

#### Temporary AWS creds 

Script __scripts/aws-get-temp-creds.sh__ has been written up to automate the process of generating the creds into a file __env_configs/inspec-creds.properties__

#### Usage

```
sh scripts/generate-terraform-outputs.sh
sh scripts/aws-get-temp-creds.sh
source env_configs/inspec-creds.properties
inspec exec ${inspec_profile} -t aws://${TG_REGION}
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

# Alfresco DB Restore

#### PSQL binary

Reduce Alfresco ASG to a single instance. SSH on the reamining Alfresco instance execute the commands below 

```
systemctl stop alfresco
yum install postgresql -y
```

All commands should be run on the Alfresco instance unless otherwise indicated.

#### AWS S3bucket

Jenkins job [Alfresco-s3-buckets-content-pipeline](https://jenkins.engineering-dev.probation.hmpps.dsd.io/job/Alfresco/job/Alfresco-s3-buckets-content-pipeline/)

Run the jenkins job above giving the environment name as a parameter

#### Prepare database

Please run the following steps in psql. Replace the following with appropriate details.

- alfresco-db-host
- alfresco-user


```
psql -h alfresco-db-host -U alfresco-user -d postgres
drop database alfresco-database;
create database alfresco-database;
create role postgres;
grant postgres to alfresco-user;
create role alfresco;
grant alfresco to alfresco-user;
```

#### Restore database

Replace the following

- alfresco-storage-s3bucket
- alfresco-db-host
- alfresco-user


```
aws s3 cp s3://alfresco-storage-s3bucket/restore_data/alfresco.sql ~/
psql -h alfresco-db-host -U alfresco-user -d alfresco-database -f ~/alfresco.sql
rm -rf ~/alfresco.sql
```

#### Startup Alfresco

Empty the Alfresco log file:  /usr/share/tomcat/alfresco.log

```
> /usr/share/tomcat/alfresco.log
```

Rename the license file: /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic.installed

```
mv /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic.installed /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic
```

Start up the tomcat service

```
systemctl start tomcat
```

Watch the log file /usr/share/tomcat/alfresco.log for any errors.

