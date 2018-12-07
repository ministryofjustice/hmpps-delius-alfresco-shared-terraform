import argparse


def argsParser():
    parser = argparse.ArgumentParser(description='terraform docker runner')

    parser.add_argument('--env', type=str,
                        help='target environment', required=True)
    parser.add_argument('--action', type=str, help='action to perform',
                        choices=['apply', 'plan', 'test', 'output', 'destroy'], required=True)
    parser.add_argument('--component', type=str,
                        help='component to run task on', default='common')
    parser.add_argument('--token', type=str,
                        help='aws token for credentials')
    parser.add_argument('--repo', type=str,
                        help='git repo for env configs, defaults to hmpps-env-configs.git', default='https://github.com/ministryofjustice/hmpps-env-configs.git')
    parser.add_argument('--branch', type=str,
                        help='git repo branch for env configs, defaults to master branch', default='master')

    return parser.parse_args()
