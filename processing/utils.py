#!/usr/bin/env python
# -*- coding: utf-8
# Collection of useful functions


import io
import os
import re
import tempfile
import datetime
import logging
import argparse
import subprocess
import shutil
import tqdm
from enum import Enum

logger = logging.getLogger(__name__)


class Metavar(Enum):
    """
    This class is used to display intuitive input types via the metavar field of argparse
    """
    file = "<file>"
    str = "<str>"
    folder = "<folder>"
    int = "<int>"
    list = "<list>"
    float = "<float>"

    def __str__(self):
        return self.value


class SmartFormatter(argparse.HelpFormatter):
    """
    Custom formatter that inherits from HelpFormatter, which adjusts the default width to the current Terminal size,
    and that gives the possibility to bypass argparse's default formatting by adding "R|" at the beginning of the text.
    Inspired from: https://pythonhosted.org/skaff/_modules/skaff/cli.html
    """
    def __init__(self, *args, **kw):
        self._add_defaults = None
        super(SmartFormatter, self).__init__(*args, **kw)
        # Update _width to match Terminal width
        try:
            self._width = shutil.get_terminal_size()[0]
        except (KeyError, ValueError):
            logger.warning('Not able to fetch Terminal width. Using default: %s'.format(self._width))

    # this is the RawTextHelpFormatter._fill_text
    def _fill_text(self, text, width, indent):
        # print("splot",text)
        if text.startswith('R|'):
            paragraphs = text[2:].splitlines()
            rebroken = [argparse._textwrap.wrap(tpar, width) for tpar in paragraphs]
            rebrokenstr = []
            for tlinearr in rebroken:
                if (len(tlinearr) == 0):
                    rebrokenstr.append("")
                else:
                    for tlinepiece in tlinearr:
                        rebrokenstr.append(tlinepiece)
            return '\n'.join(rebrokenstr)  # (argparse._textwrap.wrap(text[2:], width))
        return argparse.RawDescriptionHelpFormatter._fill_text(self, text, width, indent)

    # this is the RawTextHelpFormatter._split_lines
    def _split_lines(self, text, width):
        if text.startswith('R|'):
            lines = text[2:].splitlines()
            while lines[0] == '':  # Discard empty start lines
                lines = lines[1:]
            offsets = [re.match("^[ \t]*", l).group(0) for l in lines]
            wrapped = []
            for i in range(len(lines)):
                li = lines[i]
                if len(li) > 0:
                    o = offsets[i]
                    ol = len(o)
                    init_wrap = argparse._textwrap.fill(li, width).splitlines()
                    first = init_wrap[0]
                    rest = "\n".join(init_wrap[1:])
                    rest_wrap = argparse._textwrap.fill(rest, width - ol).splitlines()
                    offset_lines = [o + wl for wl in rest_wrap]
                    wrapped = wrapped + [first] + offset_lines
                else:
                    wrapped = wrapped + [li]
            return wrapped
        return argparse.HelpFormatter._split_lines(self, text, width)


def check_software_installed(list_software=['fsleyes', 'sct']):
    """
    Make sure software are installed
    :param list_software:
    :return:
    """
    install_ok = True
    software_cmd = {
        'fsleyes': 'fsleyes --version',
        'sct': 'sct_version'
        }
    for software in list_software:
        try:
            output = subprocess.check_output(software_cmd[software], shell=True)
            logger.info("'{}' (version: {}) is installed.".format(software, output.decode('utf-8').strip('\n')))
        except FileNotFoundError:
            logger.error("'{}' is not installed. Please install it before using this software.".format(software))
            install_ok = False
    return install_ok