#!/usr/bin/env python
# -*- coding: utf-8
# Test script for generate_figure

import os
import subprocess
from pathlib import Path


def test_generate_figure_help():
    """Check if CLI script can execute without error"""
    result = subprocess.run(['sg_generate_figure', '-h'])
    assert result.returncode == 0


def test_generate_figure_dummy():
    """Check if figures are generated using dummy csv results"""
    path_results = Path(__file__).parent / "results_dummy"
    result = subprocess.run(['sg_generate_figure', '-path-results', path_results])
    assert result.returncode == 0
    files = ['fig_csa_t1.png',
             'fig_csa_t2.png',
             'fig_t1_t2_agreement_per_vendor.png',
             'fig_t1_t2_agreement.png']
    is_file_created = [os.path.isfile(path_results.joinpath(file)) for file in files]
    assert all(is_file_created)
