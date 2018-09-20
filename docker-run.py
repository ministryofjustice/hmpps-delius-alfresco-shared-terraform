import os

from utils.args_parser import argsParser

args = argsParser()

env_target = args.env
action_type = args.action
component_target = args.component

# working directory
work_dir = os.getcwd()

# image
image_id = 'hmpps/terraform-builder:latest'

# command prfix
cmd = 'sh run.sh'

# docker run command
docker_cmd = "docker run -it --rm -v {}:/home/tools/data {}".format(
    work_dir,
    '-v ${HOME}/.aws:/home/tools/.aws -e RUNNING_IN_CONTAINER=True')

if args.token:
    aws_token = args.token
    token_args = "-e AWS_PROFILE={}".format(aws_token)
    run_cmd = "{docker_cmd} {token_args} {image_id} {cmd} {environment} {action} {component}".format(
        docker_cmd=docker_cmd,
        image_id=image_id,
        token_args=token_args,
        cmd=cmd,
        environment=env_target,
        action=action_type,
        token='hmpps-token',
        component=component_target)
else:
    run_cmd = "{docker_cmd} {image_id} {cmd} {environment} {action} {component}".format(
        docker_cmd=docker_cmd,
        image_id=image_id,
        cmd=cmd,
        environment=env_target,
        action=action_type,
        component=component_target)

print("Running command: {}".format(run_cmd))
os.system(run_cmd)
