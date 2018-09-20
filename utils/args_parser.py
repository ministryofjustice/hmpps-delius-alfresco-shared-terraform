import argparse


def argsParser():
    parser = argparse.ArgumentParser(description='terraform docker runner')

    parser.add_argument('--env', type=str,
                        help='target environment', required=True)
    parser.add_argument('--action', type=str, help='action to perform',
                        choices=['apply', 'plan', 'test', 'output'], required=True)
    parser.add_argument('--component', type=str,
                        help='component to run task on', default='common')
    parser.add_argument('--token', type=str,
                        help='aws token for credentials')

    return parser.parse_args()
