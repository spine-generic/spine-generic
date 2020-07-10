#!/usr/bin/env python
# -*- coding: utf-8
# Test script for generate_figure

import os


def test_generate_figure():
    """Check if CLI script can execute without error"""
    assert os.system('sg_generate_figure') == 0
