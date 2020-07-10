#!/usr/bin/env python
# -*- coding: utf-8
# BIDS utility tools


def get_subject(file):
    """
    Get subject from BIDS file name
    :param file:
    :return: subject
    """
    return file.split('_')[0]


def get_contrast(file):
    """
    Get contrast from BIDS file name
    :param file:
    :return:
    """
    return 'dwi' if file.split('_')[1] == 'dwi' else 'anat'
