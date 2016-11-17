#!/usr/bin/env python
#
# Copyright 2016 Mario Ynocente Castro, Mathieu Bernard
#
# You can redistribute this file and/or modify it under the terms of
# the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
"""High-level wrapper for NaivePhysics data generation

This programm wraps the NaivePhysics binary (as packaged by Unreal
Engine) into a simple to use command-line interface. It defines few
environment variables (namely input JSon configuration file, output
directory and random seed), launch the binary and filter its log
messages at runtime, keeping only relevant messages.

The NAIVEPHYSICS_BINARY variable must be defined in your environment
(this is done for you by the activate-naivephysics script).

To see command-line arguments, have a::

    ./naivedata.py --help

"""

import argparse
import logging
import os
import re
import shlex
import shutil
import subprocess
import sys
import threading


# an exemple of a config file to feed the NaivePhysics data generator
JSON_EXEMPLE = '''
{
    "blockC1_static" :
    {
        "train": 100,
        "test": 20
    },
    "blockC1_dynamic_1" :
    {
        "train": 0,
        "test": 0
    },
    "blockC1_dynamic_2" :
    {
        "train": 0,
        "test": 0
    }
}
'''

# blocks actually implemented in the lua scripts
BLOCKS_AVAILABLE = ['blockC1_static', 'blockC1_dynamic_1', 'blockC1_dynamic_2']


# path to packaged the NaivePhysics binary (environment variable has
# been setup in activate-naivephysics)
NAIVEPHYSICS_BINARY = os.environ['NAIVEPHYSICS_BINARY']

# path to the UnrealEngine directory
UNREALENGINE_ROOT = os.environ['UNREALENGINE_ROOT']

# path to the NaivePhysics directory
NAIVEPHYSICS_ROOT = os.environ['NAIVEPHYSICS_ROOT']


class LogStripFormatter(logging.Formatter):
    """Strips trailing \n in log messages"""
    def format(self, record):
        record.msg = record.msg.strip()
        return super(LogStripFormatter, self).format(record)


class LogUnrealFormatter(LogStripFormatter):
    """Removes begining date, module name and trailing '\n'"""
    def format(self, record):
        # remove all content before and including the second ':' (this
        # strip off the date and id from Unreal log messages)
        try:
            record.msg = record.msg[
                [m.start() for m in re.finditer(':', record.msg)][1]+1:]
        except IndexError:
            pass

        return super(LogUnrealFormatter, self).format(record)


class LogNoEmptyMessageFilter(logging.Filter):
    """Inhibits empty log messages (spaces only or \n)"""
    def filter(self, record):
        return len(record.getMessage().strip())


class LogNoStartupMessagesFilter(logging.Filter):
    """Removes luatorch import messages and unreal startup messages"""
    def filter(self, record):
        msg = record.getMessage()
        return not (
            'Importing uetorch.lua ...' in msg or
            'Using binned.' in msg or
            'per-process limit of core file size to infinity.' in msg)


class LogInhibitUnrealFilter(logging.Filter):
    """Inhibits some unrelevant Unreal log messages

    Messages containing 'Error:' or 'LogScriptPlugin' are kept, other
    are removed from the Unreal Engine log (messages like
    "[data][id]message")

    """
    def filter(self, record):
        msg = record.getMessage()
        return (not re.search('\[.*\]\[.*\]', msg) or
                'Error:' in msg or
                'LogScriptPlugin' in msg)


def GetLogger(verbose=False):
    """Returns a logger configured to filter Unreal log messages

    If `verbose` is True, do not filter any message, if `verbose` is
    False (default), keep only relevant messages)

    """
    log = logging.getLogger('NaivePhysics')
    log.setLevel(logging.DEBUG)
    log.addFilter(LogNoEmptyMessageFilter())

    if not verbose:
        log.addFilter(LogInhibitUnrealFilter())
        log.addFilter(LogNoStartupMessagesFilter())
        formatter = LogUnrealFormatter('%(message)s')
    else:
        formatter = LogStripFormatter('%(message)s')

    # log to standard output
    std_handler = logging.StreamHandler(sys.stdout)
    std_handler.setFormatter(formatter)
    std_handler.setLevel(logging.DEBUG)
    log.addHandler(std_handler)

    return log


def ParseArgs():
    """Defines a commndline argument parser and returns the parsed arguments"""
    # better display of the help message, do not format epilog but
    # arguments only (see
    # https://stackoverflow.com/questions/18462610)
    class CustomFormatter(
            argparse.ArgumentDefaultsHelpFormatter,
            argparse.RawDescriptionHelpFormatter):
        pass

    parser = argparse.ArgumentParser(
        description='Data generator for the NaivePhysics project',
        epilog='An exemple of a JSon configuration file is:\n{}'
        .format(JSON_EXEMPLE),
        formatter_class=CustomFormatter)

    parser.add_argument(
        'config_file', metavar='<json-file>', help=(
            'JSon configuration file defining the number of test and train '
            'iterations to run for each block. Supported blocks are: {}.'
            .format(', '.join(BLOCKS_AVAILABLE))))

    parser.add_argument(
        'output_dir', metavar='<output-dir>', help='''
        Directory where to write generated data, must be non-existing
        or used along with the --force option.''')

    parser.add_argument(
        '-s', '--seed', default=None, metavar='<int>',
        help='Optional random seed for data generator, '
        'by default use the current system time')

    parser.add_argument(
        '-f', '--force', action='store_true',
        help='Overwrite <output-dir>, any existing content is erased')

    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help='Display all the UnrealEngine log messages')

    parser.add_argument(
        '--editor', action='store_true',
        help='Launch the NaivePhysics project in the UnrealEngine editor')

    return parser.parse_args()


def _Run(command, log):
    print(command)
    job = subprocess.Popen(
        shlex.split(command),
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT)

    # join the command output to log (from
    # https://stackoverflow.com/questions/35488927)
    def ConsumeLines(pipe, consume):
        with pipe:
            # NOTE: workaround read-ahead bug
            for line in iter(pipe.readline, b''):
                consume(line)
            consume('\n')

    threading.Thread(
        target=ConsumeLines,
        args=[job.stdout, lambda line: log.info(line)]).start()

    job.wait()

    if job.returncode:
        log.error('%s returned with %s',
                  os.path.basename(NAIVEPHYSICS_BINARY),
                  job.returncode)
        sys.exit(job.returncode)


def RunBinary(log):
    """Run the NaivePhysics packaged binary as a subprocess"""
    if not os.path.isfile(NAIVEPHYSICS_BINARY):
        raise IOError('No such file: {}'.format(NAIVEPHYSICS_BINARY))

    log.debug('running {}'.format(os.path.basename(NAIVEPHYSICS_BINARY)))

    _Run(NAIVEPHYSICS_BINARY, log)


def RunEditor(log):
    """Run the NaivePhysics project within the UnrealEngine editor"""

    editor = os.path.join(
        UNREALENGINE_ROOT, 'Engine', 'Binaries', 'Linux', 'UE4Editor')
    if not os.path.isfile(editor):
        raise IOError('No such file: {}'.format(editor))

    project = os.path.join(
        NAIVEPHYSICS_ROOT, 'UnrealProject', 'NaivePhysics.uproject')
    if not os.path.isfile(project):
        raise IOError('No such file: {}'.format(project))

    log.debug('running NaivePhysics in the Unreal Engine editor')

    _Run(editor + ' ' + project, log)


def Main():
    args = ParseArgs()

    # get the output directory as absolute path with a trailing /
    output_dir = os.path.abspath(args.output_dir)
    if output_dir[-1] != '/':
        output_dir += '/'

    # setup an empty output directory
    if os.path.exists(output_dir):
        if args.force:
            shutil.rmtree(output_dir)
        else:
            raise IOError(
                'Existing output directory: {}'.format(output_dir))

    os.makedirs(output_dir)

    # setup the environment variables used in lua scripts
    os.environ['NAIVEPHYSICS_DATA'] = output_dir
    os.environ['NAIVEPHYSICS_JSON'] = os.path.abspath(args.config_file)
    if args.seed is not None:
        os.environ['NAIVEPHYSICS_SEED'] = args.seed

    # finally setup the log and run the simulation
    log = GetLogger(verbose=args.verbose)

    if args.editor:
        RunEditor(log)
    else:
        RunBinary(log)


if __name__ == '__main__':
    try:
        Main()
    except KeyboardInterrupt:
        print('Keyboard interruption, exiting')
        sys.exit(0)
