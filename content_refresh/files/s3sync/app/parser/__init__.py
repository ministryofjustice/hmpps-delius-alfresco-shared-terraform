# app/parser/__init__.py

import argparse

# Construct the argument parser
ap = argparse.ArgumentParser()

ap.add_argument("-p", "--prefix", default="", help="s3bucket object prefix")

args = vars(ap.parse_args())
