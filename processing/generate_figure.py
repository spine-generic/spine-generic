#!/usr/bin/env python
#
# Generate figures for the spine-generic dataset. Figures are output in the sub-folder /results of the path specified
# by -p.
# IMPORTANT: the input path (-p) should include subfolders data/ (has all the processed data) and results/
#
# USAGE:
#   ${SCT_DIR}/python/bin/python generate_figure.py -p PATH_DATA
#
#   Example:
#   ${SCT_DIR}/python/bin/python generate_figure.py -p /home/bob/spine_generic/
#
# DEPENDENCIES:
#   SCT
#
# Author: Julien Cohen-Adad

import os
import argparse
import sys
import glob
import csv
import json
import pandas as pd

import numpy as np
import logging
import matplotlib.pyplot as plt
from collections import OrderedDict


# Initialize logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # default: logging.INFO
hdlr = logging.StreamHandler(sys.stdout)
# fmt = logging.Formatter()
# fmt.format = _format_wrap(fmt.format)
# hdlr.setFormatter(fmt)
logging.root.addHandler(hdlr)

# Create a dictionary of centers: key: folder name, val: dataframe name
centers = {
    'chiba_spine-generic_20180608-750': 'Chiba-750',
    'juntendo-750w_spine-generic_20180529': 'Juntendo-750w',
    'tokyo-univ_spine-generic_20180604-750w': 'TokyoUniv-750w',
    'tokyo-univ_spine-generic_20180604-signa1': 'TokyoUniv-Signa1',
    'tokyo-univ_spine-generic_20180604-signa2': 'TokyoUniv-Signa2',
    'ucl_spine-generic_20171207': 'UCL-Achieva',
    'juntendo-achieva_spine-teneric_20180524': 'Juntendo-Achieva',
    'glen_spine-generic_20171128': 'Glen-Ingenia',
    'tokyo-univ_spine-generic_20180604-ingenia': 'TokyoUniv-Ingenia',
    'chiba_spine-generic_20180608-ingenia': 'Chiba-Ingenia',
    'mgh-bay3_spine-generic_20171201': 'MGH-Trio',
    'douglas_spine-generic_20171127': 'Douglas-Trio',
    'poly_spine-generic_20171221': 'Polytechnique-Skyra',
    'juntendo-skyra_spine-generic_20180509': 'Juntendo-Skyra',
    'tokyo-univ_spine-generic_20180604-skyra': 'TokyoUniv-Skyra',
    'unf_sct_026': 'UNF-Prisma',
    'oxford_spine-generic_20171209': 'Oxford-Prisma',
    'juntendo-prisma_spine-generic_20180523': 'Juntendo-Prisma',
}

# color to assign to each MRI model for the figure
# TODO: choose slightly different color based on MRI model (within vendor)
vendor_to_color = {
    'GE': 'black',
    'Philips': 'dodgerblue',
    'Siemens': 'limegreen',
}

# fetch contrast based on csv file
file_to_metric = {
    'csa-SC_T1w.csv': 'csa_t1',
    'csa-SC_T2w.csv': 'csa_t2',
    'csa-GM_T2s.csv': 'csa_gm',
    'DWI_FA.csv': 'fa',
    'DWI_MD.csv': 'md',
    'DWI_RD.csv': 'md',
    'MTR.csv': 'mtr',
    'MTsat.csv': 'mtsat',
    'T1.csv': 't1',
}

# fetch metric field
metric_to_field = {
    'csa_t1': 'MEAN(area)',
    'csa_t2': 'MEAN(area)',
    'csa_gm': 'MEAN(area)',
    'fa': 'WA()',
    'md': 'WA()',
    'md': 'WA()',
    'mtr': 'WA()',
    'mtsat': 'WA()',
    't1': 'WA()',
}

# fetch metric field
metric_to_label = {
    'csa_t1': 'Cord CSA from T1w [$mm^2$]',
    'csa_t2': 'Cord CSA from T2w [$mm^2$]',
    'csa_gm': 'Gray Matter CSA [$mm^2$]',
    'fa': 'Fractional anisotropy',
    'md': 'Mean diffusivity [$mm^2.s^-1]',
    'md': 'Radial diffusivity [$mm^2.s^-1]',
    'mtr': 'Magnetization transfer ratio [%]',
    'mtsat': 'Magnetization transfer saturation [a.u.]',
    't1': 'T1 [ms]',
}

# scaling factor (for display)
scaling_factor = {
    'csa_t1': 1,
    'csa_t2': 1,
    'csa_gm': 1,
    'fa': 1,
    'md': 1000,
    'md': 1000,
    'mtr': 1,
    'mtsat': 1,
    't1': 1000,
}

# ylim for figure
ylim = {
    't1': [40, 90],
    't2': [40, 90],
    'dmri': [0.4, 0.9],
    'mt': [30, 65],
    't2s': [10, 20],
}


# ystep (in yticks) for figure
ystep = {
    't1': 5,
    't2': 5,
    'dmri': 0.1,
    'mt': 5,
    't2s': 1,
}


def aggregate_per_site(dict_results, metric, path_data):
    """
    Aggregate metrics per site
    :param dict_results:
    :param metric: Metric type
    :param path_data: Path that contains results/ and data/ folders
    :return:
    """
    results_agg = {}
    # Fetch specific field for the selected metric
    metric_field = metric_to_field[metric]
    # Loop across lines and fill dict of aggregated results
    for i in range(len(dict_results)):
        filename = dict_results[i]['Filename']
        logger.debug('Filename: '+filename)
        # Fetch metadata for the site
        dataset_description = read_dataset_description(filename, path_data)
        # cluster values per site
        site, subject = parse_filename(filename)
        if not site in results_agg.keys():
            # if this is a new site, initialize sub-dict
            results_agg[site] = {}
            results_agg[site]['site'] = site  # need to duplicate in order to be able to sort using vendor AND site with Pandas
            results_agg[site]['vendor'] = dataset_description['Manufacturer']
            results_agg[site]['model'] = dataset_description['ManufacturersModelName']
            results_agg[site]['val'] = []
        # add val for site (ignore None)
        val = dict_results[i][metric_field]
        if not val == 'None':
            results_agg[site]['val'].append(float(val))
    return results_agg


def compute_statistics(df):
    """
    Compute statistics such as mean, std, COV, etc.
    :param df Pandas structure
    """
    vendors = ['GE', 'Philips', 'Siemens']
    mean_per_row = []
    std_per_row = []
    stats = {}
    for site in df.index:
        mean_per_row.append(np.mean(df['val'][site]))
        std_per_row.append(np.std(df['val'][site]))
    # Update Dataframe
    df['mean'] = mean_per_row
    df['std'] = std_per_row
    df['cov'] = np.array(std_per_row) / np.array(mean_per_row)
    # Compute intra-vendor COV
    for vendor in vendors:
        # init dict
        if not 'cov' in stats.keys():
            stats['cov'] = {}
        # fetch vals for specific vendor
        val_per_vendor = df['mean'][df['vendor'] == vendor].values
        # compute COV
        stats['cov'][vendor] = np.std(val_per_vendor) / np.mean(val_per_vendor)
    return df, stats


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Generate figures for the spine-generic dataset. Figures are output in the sub-folder "results/" '
                    'of the path specified by the input path (-p). The input path should include subfolders "data/" '
                    '(which has all the processed data) and "results/".')
    parser.add_argument('-p', '--path',
                        required=True,
                        help='Path to spineGeneric parent folder, which contains folders "data/" and "results/" '
                             'sub-folders.')
    args = parser.parse_args()
    return args


def main():
    # TODO: make "results" an input param

    # fetch all .csv result files
    csv_files = glob.glob(os.path.join(path_data, 'results/*.csv'))

    # loop across results and generate figure
    for csv_file in csv_files:

        # Open CSV file and create dict
        logger.info('Processing: '+csv_file)
        dict_results = []
        with open(csv_file, newline='') as f_csv:
            reader = csv.DictReader(f_csv)
            for row in reader:
                dict_results.append(row)

        # Fetch metric name
        _, csv_file_small = os.path.split(csv_file)
        metric = file_to_metric[csv_file_small]

        # Fetch mean, std, etc. per site
        results_dict = aggregate_per_site(dict_results, metric, path_data)

        # Make it a pandas structure (easier for manipulations)
        df = pd.DataFrame.from_dict(results_dict, orient='index')

        # Compute statistics
        df, stats = compute_statistics(df)

        # sites = list(results_agg.keys())
        # val_mean = [np.mean(values_per_site) for values_per_site in list(results_agg.values())]
        # val_std = [np.std(values_per_site) for values_per_site in list(results_agg.values())]

        if logger.level == 10:
            import matplotlib
            matplotlib.use('TkAgg')
            plt.ion()

        # Sort values per vendor
        # TODO: sort per model
        site_sorted = df.sort_values(by=['vendor', 'site']).index.values
        vendor_sorted = df['vendor'][site_sorted].values
        mean_sorted = df['mean'][site_sorted].values
        std_sorted = df['std'][site_sorted].values

        # Scale values (for display)
        mean_sorted = mean_sorted * scaling_factor[metric]
        std_sorted = std_sorted * scaling_factor[metric]

        # Get color based on vendor
        list_colors = [vendor_to_color[i] for i in vendor_sorted]

        # Create figure and plot bar graph
        fig, ax = plt.subplots(figsize=(15, 8))
        # TODO: show only superior part of STD
        plt.grid(axis='y')
        plt.bar(range(len(site_sorted)), height=mean_sorted, width=0.5, tick_label=site_sorted, yerr=std_sorted, color=list_colors)
        # TODO: Display ManufacturersModelName in vertical, embedded in each bar
        plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg, align at end
        plt.xlim([-1, len(site_sorted)])
        # ax.set_xticklabels(site_sorted)
        # ax.get_xaxis().set_visible(True)
        ax.tick_params(labelsize=15)
        plt.ylabel(metric_to_label[metric], fontsize=15)

        # plt.ylim(ylim[contrast])
        # plt.yticks(np.arange(ylim[contrast][0], ylim[contrast][1], step=ystep[contrast]))
        # plt.title(contrast)
        plt.tight_layout()  # make sure everything fits
        plt.savefig(os.path.join(path_data, 'results/fig_'+metric+'.png'))


def parse_filename(filename):
    """
    Get site and subject from filename
    :param filename:
    :return: site, subject
    """
    path, file = os.path.split(filename)
    site = path.split(os.sep)[-3].replace('_spineGeneric', '')
    subject = path.split(os.sep)[-2]
    return site, subject


def read_dataset_description(filename, path_data):
    """Read dataset_description.json file associated with the input filename and output dict"""
    path, file = os.path.split(filename)
    fname_dataset_description = os.path.join(path_data, 'data', path.split(os.sep)[-3], 'dataset_description.json')
    with open(fname_dataset_description, 'r+') as fjson:
        dataset_description = json.load(fjson)
    return dataset_description


if __name__ == "__main__":
    args = get_parameters()
    path_data = args.path
    main()
