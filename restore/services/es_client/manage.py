import click
import pytest


@click.group()
def main():
    """
    ES_Manager a tool to manage elasticsearch
    """
    pass


@main.command()
def config():
    """
    Store configuration values in a file.
    """
    print("I handle the configuration.")


@main.command()
@click.option(
    '--test-type',
    default='full-coverage',
    help='Options are full, full-coverage and minimal'
)
def test(test_type):
    """
    Store configuration values in a file.
    """
    print("I am running test: {}".format(test_type))
    test_options = []
    test_options.append('-v')
    test_options.append('-x')
    test_options.append('--color=yes')
    test_options.append('--cov=app')
    test_options.append('--cov-report')
    test_options.append('html:/tmp/reports/cov.html')
    test_options.append('--html=/tmp/reports/test-report.html')
    test_options.append('--capture=sys')
    print(test_options)
    pytest.main(test_options)


if __name__ == "__main__":
    main()
