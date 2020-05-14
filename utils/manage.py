# utils/manage.py

import click
import sys

from github_helper.branches import Branch_Handler
from github_helper.releases import Release_Handler


@click.group()
def cli():
    pass


@cli.command()
@click.option('-b', '--branch', required=True, type=str)
# @click.option('-sha', '--commit', required=True, type=str)
def update_repo_branch(branch: str):
    """
        Manages Github repo branch
    """
    branch_manager = Branch_Handler()
    resp = branch_manager.task_handler(branch)
    message = resp['message']
    if resp['exit_code'] != 0:
        message = resp['error']
        click.echo(message=message)
        return sys.exit(resp['exit_code'])
    click.echo(message=message)
    return sys.exit(0)


@cli.command()
@click.option('-b', '--branch', required=True, type=str)
@click.option('-sha', '--commit', required=True, type=str)
def create_release(branch: str, commit: str):
    """
        Manages Github repo releases
    """
    manager = Release_Handler()
    resp = manager.task_handler(branch, commit)
    message = resp['message']
    if resp['exit_code'] != 0:
        message = resp['error']
        click.echo(message=message)
        return sys.exit(resp['exit_code'])
    click.echo(message=message)
    return sys.exit(0)


@cli.command()
def get_version():
    """
        Manages Github repo releases
    """
    manager = Release_Handler()
    try:
        message = manager.get_latest_version()
    except Exception as err:
        message = err
        click.echo(message=message)
        return sys.exit(12)
    click.echo(message=message)
    return sys.exit(0)


if __name__ == '__main__':
    cli()
