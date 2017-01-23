#!/usr/bin/env python
#
# Copyright 2016, 2017 Mario Ynocente Castro, Mathieu Bernard
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
import copy
import joblib
import json
import logging
import os
import re
import shlex
import shutil
import subprocess
import sys
import threading
import time


# an exemple of a config file to feed the NaivePhysics data generator
JSON_EXEMPLE = '''
{
    "blockC1" :
    {
        "train" : 100,
        "static" : 5,
        "dynamic_1" : 5,
        "dynamic_2" : 5
    }
}

This generates 100 train videos and 15 test videos (5 for each variant).'''

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


def GetLogger(verbose=False, name=None):
    """Returns a logger configured to filter Unreal log messages

    If `verbose` is True, do not filter any message, if `verbose` is
    False (default), keep only relevant messages).

    If `name` is not None, prefix all messages with it.

    """
    msg = '{}%(message)s'.format('{}: '.format(name) if name else '')

    log = logging.getLogger(name)
    log.setLevel(logging.DEBUG)
    log.addFilter(LogNoEmptyMessageFilter())

    if not verbose:
        log.addFilter(LogInhibitUnrealFilter())
        log.addFilter(LogNoStartupMessagesFilter())
        formatter = LogUnrealFormatter(msg)
    else:
        formatter = LogStripFormatter(msg)

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
        epilog='An exemple of a json configuration file is:\n{}'
        .format(JSON_EXEMPLE),
        formatter_class=CustomFormatter)

    parser.add_argument(
        'config_file', metavar='<json-file>', help=(
            'json configuration file defining the number of test and train '
            'iterations to run for each block, see exemple below.'))

    parser.add_argument(
        'output_dir', metavar='<output-dir>', help='''
        directory where to write generated data, must be non-existing
        or used along with the --force option.''')

    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help='display all the UnrealEngine log messages')

    parser.add_argument(
        '-s', '--seed', default=None, metavar='<int>', type=int,
        help='optional random seed for data generator, '
        'by default use the current system time')

    parser.add_argument(
        '-f', '--force', action='store_true',
        help='overwrite <output-dir>, any existing content is erased')

    parser.add_argument(
        '-j', '--njobs', type=int, default=1, metavar='<int>',
        help='''number of data generation to run in parallel,
        this option is ignored if --editor is specified''')

    parser.add_argument(
        '-e', '--editor', action='store_true',
        help='launch the NaivePhysics project in the UnrealEngine editor')

    parser.add_argument(
        '-d', '--dry', action='store_true',
        help='do not save any image, this runs really faster')

    return parser.parse_args()


def _BalanceList(l, n):
    """Balance the elements of a list of integers into `n` sublists

    This is used for subjobs configuration generation.

    >>> balance_list([5, 1, 2], 2) == [[3, 0, 1], [2, 1, 1]]

    Sublists with only zeros are removed

    >>> balance_list([1, 0], 2) == [[1, 0]]

    """
    balanced = [[(v / n if v >= n else 0) for v in l] for _ in range(n)]

    idx = 0
    for i, v in enumerate(l):
        if v < n:
            for j in range(v):
                balanced[(j + idx) % n][i] = 1
            idx += v

    idx = 0
    for i, v in enumerate(l):
        diff = v - sum(s[i] for s in balanced)
        if diff:
            balanced[idx][i] += diff
            idx = (idx + 1) % n

    balanced = [s for s in balanced if sum(s)]

    for i in range(len(l)):
        assert sum(b[i] for b in balanced) == l[i]

    return balanced


def _BalanceConfig(config, njobs):
    """Split the `config` into `n` parts returned as list of dicts

    Return a tuple (subconfigs, nruns, njobs) where subconfigs is a
    list of JSON dicts, each one being the configuration of a
    subjob. `nruns` is a list of the total number of runs in each
    subjobs. `njobs` can be modified and is returned as the third
    element in the pair.

    """
    # compute the list of balanced subjobs (from nested dict to list)
    values = list(v for vv in config.values() for v in vv.values())
    balanced = _BalanceList(values, njobs)
    nruns = [sum(l) for l in balanced]

    if njobs > len(balanced):
        njobs = len(balanced)
        print('reducing the number of jobs to {}'.format(njobs))

    # create subconfigs for each subjob (from list to nested dict)
    subconfigs = [copy.deepcopy(config) for _ in range(njobs)]
    for name, block in config.items():
        for j, category in enumerate(block.keys()):
            for i in range(njobs):
                subconfigs[i][name][category] = balanced[i][j]

    return subconfigs, nruns, njobs


def _Run(command, log, config_file, output_dir, seed=None, dry=False):
    """Run `command` as a subprocess

    The `command` stdout and stderr are forwarded to `log`. The
    `command` runs with the following environment variables, in top of
    the current environment:

    NAIVEPHYSICS_JSON is the absolute path to `config_file`.

    NAIVEPHYSICS_DATA is the absolute path to `output_dir` with a
       trailing slash added.

    NAIVEPHYSICS_SEED is `seed`.

    NAIVEPHYSICS_DRY is `dry`

    """
    # get the output directory as absolute path with a trailing /,
    # this is required by lua scripts
    output_dir = os.path.abspath(output_dir)
    if output_dir[-1] != '/':
        output_dir += '/'

    # setup the environment variables used in lua scripts
    environ = copy.deepcopy(os.environ)
    environ['NAIVEPHYSICS_DATA'] = output_dir
    environ['NAIVEPHYSICS_JSON'] = os.path.abspath(config_file)

    if dry:
        environ['NAIVEPHYSICS_DRY'] = 'true'
        log.info('running in dry mode: do not capture any image')

    if seed is not None:
        environ['NAIVEPHYSICS_SEED'] = str(seed)

    # run the command as a subprocess
    job = subprocess.Popen(
        shlex.split(command),
        stdin=None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=environ)

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

    # wait the job is finished, forwarding any error
    job.wait()
    if job.returncode:
        log.error('command "%s" returned with %s', command, job.returncode)
        sys.exit(job.returncode)


def RunBinary(output_dir, config_file, njobs=1,
              seed=None, dry=False, verbose=False):
    """Run the NaivePhysics packaged binary as a subprocess

    If `njobs` is greater than 1, split the json configuration file
    into subparts of equivalent workload and run several jobs in
    parallel

    """
    if type(njobs) is not int or njobs < 1:
        raise IOError('njobs argument must be a strictly positive integer')

    if not os.path.isfile(NAIVEPHYSICS_BINARY):
        raise IOError('No such file: {}'.format(NAIVEPHYSICS_BINARY))

    if not os.path.isfile(config_file):
        raise IOError('Json file not found: {}'.format(config_file))

    print('running {}{}'.format(
        os.path.basename(NAIVEPHYSICS_BINARY),
        '' if njobs == 1 else ' in {} jobs'.format(njobs)))

    if njobs == 1:
        _Run(NAIVEPHYSICS_BINARY,
             GetLogger(verbose=verbose),
             config_file, output_dir, seed=seed, dry=dry)
    else:
        # split the json configuration file into balanced subparts
        subconfigs, nruns, njobs = _BalanceConfig(
            json.load(open(config_file, 'r')), njobs)

        # increase artificially the nruns to have margin for retries
        # (this can occur for test runs)
        nruns = [10 * r for r in nruns]

        # write them in subdirectories
        for i, config in enumerate(subconfigs, 1):
            path = os.path.join(output_dir, str(i))
            os.makedirs(path)
            open(os.path.join(path, 'config.json'), 'w').write(
                json.dumps(config, indent=4))

        # parallel must defines a different seed for each job
        seed = int(round(time.time() * 1000)) if seed is None else seed

        # define arguments list for each jobs
        _out = [os.path.join(output_dir, str(i)) for i in range(1, njobs+1)]
        _conf = [os.path.join(output_dir, str(i), 'config.json')
                 for i in range(1, njobs+1)]
        _seed = [str(seed + sum(nruns[:i])) for i in range(njobs)]
        _log = [GetLogger(name='job {}'.format(i))
                for i in range(1, njobs+1)]

        # run the subprocesses
        joblib.Parallel(n_jobs=njobs, backend='threading')(
            joblib.delayed(_Run)(
                NAIVEPHYSICS_BINARY, _log[i], _conf[i], _out[i],
                seed=_seed[i], dry=dry)
            for i in range(njobs))


def RunEditor(output_dir, config_file, seed=None, dry=False, verbose=False):
    """Run the NaivePhysics project within the UnrealEngine editor"""
    log = GetLogger(verbose=verbose)

    editor = os.path.join(
        UNREALENGINE_ROOT, 'Engine', 'Binaries', 'Linux', 'UE4Editor')
    if not os.path.isfile(editor):
        raise IOError('No such file {}'.format(editor))

    project = os.path.join(
        NAIVEPHYSICS_ROOT, 'UnrealProject', 'NaivePhysics.uproject')
    if not os.path.isfile(project):
        raise IOError('No such file {}'.format(project))

    log.debug('running NaivePhysics in the Unreal Engine editor')

    _Run(editor + ' ' + project, log, config_file, output_dir,
         seed=seed, dry=dry)


def FindDuplicates(directory):
    """Find any duplicated scenes in `directory`

    Having two identical scenes is very unlikely but was a problem
    while coding the '--njobs' option...

    Load and compare all 'params.json' files found in
    `directory`. Print duplicate on stdout.

    """
    # load all 'params.json' files in a dict: file -> content
    params = []
    for root, dirs, files in os.walk("./data"):
        for file in files:
            if file.endswith("params.json"):
                params.append(os.path.join(root, file))
    params = {p: json.load(open(p, 'r')) for p in params}

    # ensure each file have a different content (can't use
    # collections.Counter because dicts are unhashable)
    duplicate = []
    for i, (n1, p1) in enumerate(params.items()):
        for n2, p2 in params.items()[i+1:]:
            if p1 == p2:
                duplicate.append((n1, n2))

    if len(duplicate):
        print('WARNING: Found {} duplicated scenes.'.format(len(duplicate)))
        print('The following scenes are the same:')
        for (n1, n2) in sorted(duplicate):
            print('{}  ==  {}'.format(os.path.dirname(n1), os.path.dirname(n2)))



def Main():
    # parse command-line arguments
    args = ParseArgs()

    # setup an empty output directory
    output_dir = os.path.abspath(args.output_dir)
    if os.path.exists(output_dir):
        if args.force:
            shutil.rmtree(output_dir)
        else:
            raise IOError(
                'Existing output directory {}\n'
                'Use the --force option to overwrite it'
                .format(output_dir))
    os.makedirs(output_dir)

    # check the config_file is a correct JSON file
    try:
        json.load(open(args.config_file, 'r'))
    except ValueError:
        raise IOError(
              'The configuration is not a valid JSON file: {}'
              .format(args.config_file))

    # run the simulation either in the editor or as a standalone
    # program
    if args.editor:
        RunEditor(output_dir, args.config_file,
                  seed=args.seed, dry=args.dry, verbose=args.verbose)
    else:
        RunBinary(output_dir, args.config_file, njobs=args.njobs,
                  seed=args.seed, dry=args.dry, verbose=args.verbose)

    # check for duplicated scenes
    #if not args.dry:
    FindDuplicates(output_dir)


if __name__ == '__main__':
    try:
        Main()
    except IOError as err:
        print('Fatal error, exiting: {}'.format(err))
        sys.exit(-1)
    except KeyboardInterrupt:
        print('Keyboard interruption, exiting')
        sys.exit(0)
