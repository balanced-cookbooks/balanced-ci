#!/usr/bin/env python

'''
Jenkins' Cobertura plugin doesn't allow marking a build as successful or
failed based on coverage of individual packages -- only the project as a
whole. This script will parse the coverage.xml file and fail if the coverage of
specified packages doesn't meet the thresholds given

'''

import ast
import itertools
import logging
import logging.config
import os
import sys

from argparse import ArgumentParser
from lxml import etree

logger = logging.getLogger(__name__)
logger.setLevel(logging.WARNING)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

PACKAGES_XPATH = etree.XPath('/coverage/packages/package')
FILES_XPATH = etree.XPath('/coverage/packages/package/classes/class')
PACKAGE_SEPARATOR = '.'


def check_package_coverage(root, package_coverage_dict):
    failed = False

    packages = PACKAGES_XPATH(root)
    check_done = set()

    for package in packages:
        name = package.get('name')
        do_check = False
        check_name = name
        if name in package_coverage_dict:
            # We care about this one
            do_check = True
        else:
            # Check subpackages
            name_parts = name.split('.')
            for i in range(len(name_parts) - 1, 1, -1):
                possible_name = '.'.join(name_parts[:i])
                if possible_name in package_coverage_dict:
                    do_check = True
                    check_name = possible_name
                    break

        if do_check:
            check_done.add(check_name)
            logger.info('Checking package {} -- need {}% coverage'.format(
                name, package_coverage_dict[check_name]))
            coverage = float(package.get('line-rate', '100.0')) * 100
            if coverage < package_coverage_dict[check_name]:
                logger.warning('FAILED - Coverage for package {} is {}% -- '
                       'minimum is {}%'.format(
                        name, coverage, package_coverage_dict[check_name]))
                failed = True
            else:
                logger.info("PASS")

    if set(package_coverage_dict.keys()) - check_done:
        failed = True
        not_found = ','.join(set(package_coverage_dict.keys()) - check_done)
        logger.warning("FAILED - couldn't determine coverage for package(s) {}"
                       .format(not_found))

    return failed


def check_file_coverage(root, coverage_file, default_coverage=90,
    strict=False):

    if not coverage_file:
        raise Exception('Please supply a filename to store per-file '
                        'coverage information')

    coverage_history = {}
    failed = False
    if os.path.exists(coverage_file):
        with open(coverage_file, 'r') as f:
            try:
                coverage_history = ast.literal_eval(f.read())
            except:
                # We can't be strict with no previous data
                strict = False

    files = FILES_XPATH(root)
    for f in files:
        filename = f.get('filename')
        coverage = float(f.get('line-rate', '0.0')) * 100
        previous = coverage_history.get(filename, default_coverage)
        logger.info('{} - previous: {}  current: {}  result: {}'.format(
            filename, previous, coverage,
            ('PASS' if coverage >= previous else 'FAIL')))
        if coverage < previous:
            logger.warning('FAILED - Coverage for file {} is {}% -- '
                   'down from {}%'.format(filename, coverage, previous))
            failed = True
        # Being non-strict will block files with < default_coverage on
        # initial commit, but allow them on subsequent commits, even if
        # coverage remains less than the default.
        if coverage > previous or not strict:
            coverage_history[filename] = coverage

    with open(coverage_file, 'w') as f:
        f.write('%r' % coverage_history)

    return failed


def main():
    arg_parser = ArgumentParser(description='Enforce test coverage of '
        'packages and/or individual files')
    arg_parser.add_argument('filename', help='coverage.xml file to parse')
    arg_parser.add_argument('packages', nargs='*',
        help='packages to enforce coverage on. Format: package.name:coverage '
        '(balanced.controllers:90)')
    arg_parser.add_argument('--per-file',
        help="Track per-file coverage, and don't let coverage drop "
        "below the previous saved value (default: False)",
        action='store_true')
    arg_parser.add_argument('--coverage-file',
        help='Where to keep track of per-file coverage')
    arg_parser.add_argument('--strict',
        help="When not strict, previous coverage values will be updated with "
        "newer values, even if lower than before. This will let the file pass "
        "on the next test.",
        action='store_true')
    arg_parser.add_argument('--verbose', '-v',
        help='Be verbose', action='store_true')
    args = arg_parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    if args.strict:
        logger.debug('Being strict')

    filename = args.filename

    package_args = args.packages
    # format is package_name:coverage_threshold
    package_coverage_dict = {package: int(coverage) for
        package, coverage in [x.split(':') for x in package_args]}

    xml = open(filename, 'r').read()
    root = etree.fromstring(xml)

    package_failed = False
    if package_coverage_dict:
        package_failed = check_package_coverage(root, package_coverage_dict)

    file_failed = False
    if args.per_file:
        file_failed = check_file_coverage(root, args.coverage_file,
            strict=args.strict)

    if package_failed or file_failed:
        # TODO: should non-strict runs just succeed here?
        logger.warning("Coverage test FAILED")
        sys.exit(1)

    logger.warning("Coverage test SUCCEEDED")

if __name__ == '__main__':
    main()
