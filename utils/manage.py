# utils/manage.py

import click
import sys

from github_helper.branches import Branch_Handler


@click.group()
def cli():
    pass


@cli.command()
@click.option('-b', '--branch', required=True, type=str)
@click.option('-sha', '--commit', required=True, type=str)
def update_repo_branch(branch: str, commit: str):
    """
        Manages Github repo branch
    """
    github_handler = Branch_Handler()
    resp = github_handler.task_handler(branch, commit)
    message = resp['message']
    if resp['exit_code'] != 0:
        message = resp['error']
        click.echo(message=message)
        return sys.exit(resp['exit_code'])
    click.echo(message=message)
    return sys.exit(0)


if __name__ == '__main__':
    cli()
    # branch = Branch_Handler()
    # resp = branch.task_handler(
    #     "alfresco-dev", "126498d708e794993f5121e9a962c3fb8fe3d33c")
    # print(resp)
