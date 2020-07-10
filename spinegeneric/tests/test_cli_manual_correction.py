#!/usr/bin/env python
# -*- coding: utf-8
# Test script for manual_correction

import os


def test_manual_correction():
    """Check if CLI script can execute without error"""
    assert os.system('sg_manual_correction') == 0
