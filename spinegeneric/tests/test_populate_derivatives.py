#!/usr/bin/env python
# -*- coding: utf-8
# Test script for copy_to_derivatives

import os


def test_populate_derivatives():
    """Check if CLI script can execute without error"""
    assert os.system('sg_populate_derivatives -h') == 0
