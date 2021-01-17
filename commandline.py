import argparse
import os


def parser(add_help=True):
    parser = argparse.ArgumentParser(prog="incontext", description="Generate website.", add_help=add_help)
    parser.add_argument('--site', '-s', default=os.getcwd(), help="path to the root of the site")
    parser.add_argument('--verbose', '-v', action='store_true', default=False, help="show verbose output")
    parser.add_argument('--volume', action='append', help="mount an additional volume in the Docker container")
    return parser
