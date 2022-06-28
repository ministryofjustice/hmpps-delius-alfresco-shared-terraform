## hmpps-delius-alfresco-shared-terraform

Terraform Repo for the Alfresco in the shared VPC

## URLS

### Alfresco Dev

Alfresco external - [alfresco.dev.alfresco.probation.hmpps.dsd.io](alfresco.dev.alfresco.probation.hmpps.dsd.io)

### Alfresco Delius Core Dev

Alfresco external - [https://alfresco.dev.delius-core.probation.hmpps.dsd.io](https://alfresco.dev.delius-core.probation.hmpps.dsd.io)

### Alfresco Delius Test

Alfresco external - [https://alfresco.test.delius.probation.hmpps.dsd.io](https://alfresco.test.delius.probation.hmpps.dsd.io)

### Alfresco PreProd

Alfresco external - [alfresco.pre-prod.delius.probation.hmpps.dsd.io](alfresco.pre-prod.delius.probation.hmpps.dsd.io)

### Alfresco Prod

Alfresco external - [https://alfresco.probation.service.justice.gov.uk](https://alfresco.probation.service.justice.gov.uk)

## USING TERRAFORM

A makefile has been created to orchestrate the container locally using docker-compose

Example

```
  start -> make start
  stop -> make stop
  reload env vars -> make restart or make start
  plan -> make local_plan
  apply -> make local_apply
  get configs -> make get_configs
  get utils -> make get_utils
```

## REMOTE STATE

Bucket name: [tf-eu-west-2-hmpps-delius-core-dev-remote-state](https://s3.console.aws.amazon.com/s3/object/tf-eu-west-2-hmpps-delius-core-dev-remote-state/vpc/terraform.tfstate?region=eu-west-2&tab=overview)

## DEPLOYER KEY

The deployer key is stored in AWS [Parameter store](https://eu-west-2.console.aws.amazon.com/systems-manager/parameters/tf-eu-west-2-hmpps-delius-core-dev-alfresco-ssh-private-key/description?region=eu-west-2)

```
terragrunt output ssh_private_key_pem
```

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
```

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

Script **scripts/aws-get-temp-creds.sh** has been written up to automate the process of generating the creds into a file **env_configs/inspec-creds.properties**

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

Below is the procedure to perform the Alfresco Database restore on the RDS Postgres DB. The restore is performed from Jenkins pipeline. The pipeline will standup a docker container: mojdigitalstudio/hmpps-base-psql. The docker container will then run a script which will start the restore process dry run, then will do an actual restore after approval. Script location is hmpps-delius-alfresco-shared-terraform/scripts/alfresco_db_restore.sh. The script will collect the restore file (\*.sql) from S3 buckets to the container, then will perform the restore to RDS from the container. Below are the steps to follow:

#### Alfresco Env Configs

For each env requiring Alfresco data restore, env configs are required. This file will contain the name of the Source S3 bucket where the data to restore will be stored and the name of the sql file to restore. The files are located here: hmpps-delius-alfresco-shared-terraform/alf_env_configs/. If the file for the env you intend to restore is not present, then one should be created before proceeding with the restore.

#### Alfresco EC2 Instances

Destroy the running Alfresco instances or ensure tomcat is not running on the Alfresco instances. There should be no connections to the RDS db during the data restore.

#### Perform DB Restore

Run the Alfresco-db-restore pipeline for the env. This can be found under DAMS > Environments > ${env name} > Alfresco.
The pipeline will ask for confirmation before it proceeds the steps to restore the DB.

#### Stand up EC2 instances

After successful restore, stand up the Alfresco instances. Ensure tomcat is running on the EC2 instance and check /usr/share/tomcat/alfresco.log for any errors.

#### Startup Alfresco

Empty the Alfresco log file: /usr/share/tomcat/alfresco.log

Rename the license file: /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic.installed

```
mv /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic.installed /usr/share/tomcat/shared/classes/alfresco/extension/license/alfresco-ent-5.2-NOMS.lic
```

#### Start up the tomcat service

```
systemctl start tomcat
```

Watch the log file /usr/share/tomcat/alfresco.log for any errors.
