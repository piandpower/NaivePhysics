#!/usr/bin/env python

import argparse
import logging
import os
import re
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


class StripFormatter(logging.Formatter):
    """Strip trailing \n in log messages"""
    def format(self, record):
        record.msg = record.msg.strip()
        return super(StripFormatter, self).format(record)


class UnrealLogFormatter(StripFormatter):
    """Remove begining date and module name, remove ending '\n'"""
    def format(self, record):
        # remove all content before and including the second ':' (this
        # strip off the date and id from Unreal log messages)
        try:
            record.msg = record.msg[
                [m.start() for m in re.finditer(':', record.msg)][1]+1:]
        except IndexError:
            pass

        return super(UnrealLogFormatter, self).format(record)


class NoEmptyMessageFilter(logging.Filter):
    """Inhibit empty log messages (spaces only or \n)"""
    def filter(self, record):
        return len(record.getMessage().strip())


class NoStartupMessagesFilter(logging.Filter):
    """Remove luatorch import messages and unreal startup messages"""
    def filter(self, record):
        msg = record.getMessage()
        return not (
            'Importing uetorch.lua ...' in msg or
            'Using binned.' in msg or
            'per-process limit of core file size to infinity.' in msg)


class InhibitUnrealFilter(logging.Filter):
    """Inhibit some Unreal log messages

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
    log = logging.getLogger('NaivePhysics')
    log.setLevel(logging.DEBUG)
    log.addFilter(NoEmptyMessageFilter())

    if not verbose:
        log.addFilter(InhibitUnrealFilter())
        log.addFilter(NoStartupMessagesFilter())
        formatter = UnrealLogFormatter('%(message)s')
    else:
        formatter = StripFormatter('%(message)s')

    # log to standard output
    std_handler = logging.StreamHandler(sys.stdout)
    std_handler.setFormatter(formatter)
    std_handler.setLevel(logging.DEBUG)
    log.addHandler(std_handler)

    return log


def ParseArgs():
    # do not format epilog, arguments only (see
    # https://stackoverflow.com/questions/18462610)
    class CustomFormatter(
            argparse.ArgumentDefaultsHelpFormatter,
            argparse.RawDescriptionHelpFormatter):
        pass

    parser = argparse.ArgumentParser(
        description='Data generation for the NaivePhysics project',
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
        help='Overwrite <output-dir>, any content is erased')

    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help='Do not filter UnrealEngine messages')

    return parser.parse_args()


def RunBinary(log):
    if not os.path.isfile(NAIVEPHYSICS_BINARY):
        raise IOError('No such file: {}'.format(NAIVEPHYSICS_BINARY))

    log.debug('running {}'.format(os.path.basename(NAIVEPHYSICS_BINARY)))

    job = subprocess.Popen(
        NAIVEPHYSICS_BINARY,
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

    for i in range(1, 6):
        os.makedirs(os.path.join(output_dir, str(i)))

    # setup the environment variables used in lua scripts
    os.environ['NAIVEPHYSICS_DATA'] = output_dir
    os.environ['NAIVEPHYSICS_JSON'] = os.path.abspath(args.config_file)
    if args.seed is not None:
        os.environ['NAIVEPHYSICS_SEED'] = args.seed

    # finally setup the log and run the simulation
    RunBinary(GetLogger(verbose=args.verbose))


if __name__ == '__main__':
    try:
        Main()
    except KeyboardInterrupt:
        print('Keyboard interruption, exiting')
        sys.exit(0)
