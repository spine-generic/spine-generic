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
import tqdm
import sys
import glob
import csv
import json
import pandas as pd

import numpy as np
from scipy import ndimage
from collections import OrderedDict
import logging
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage,AnnotationBbox
import matplotlib.patches as patches

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

# country dictionary: key: site, value: country name
flags = {
    'chiba': 'japan',
    'juntendo-750w': 'japan',
    'ucl': 'uk',
    'juntendo-achieva': 'japan',
    'glen': 'somewhere',
    'douglas': 'somewhere',
    'poly': 'canada',
    'juntendo-skyra': 'japan',
    'unf': 'canada',
    'oxford': 'uk',
    'juntendo-prisma': 'japan',
    'brno': 'somewhere',
    'perform': 'somewhere',
    'stanford': 'us',
    'tokyo-750w': 'japan',
    'nottwil': 'ch',
    'sherbrooke': 'canada',
    'tokyo-ingenia': 'japan',
    'vuiis-achieva': 'us',
    'vuiis-ingenia': 'us',
    'amu': 'france',
    'balgrist': 'ch',
    'barcelona': 'spain',
    'brno-prisma': 'somewhere',
    'cardiff': 'uk',
    'geneva': 'ch',
    'hamburg': 'germany',
    'mgh': 'us',
    'milan': 'italy',
    'mni': 'canada',
    'mpicbs': 'somewhere',
    'nwu': 'south-africa',
    'oxford-fmrib': 'uk',
    'oxford-ohba': 'uk',
    'queensland': 'australia',
    'strasbourg': 'france',
    'tehran': 'iran',
    'tokyo-skyra': 'japan',
    'vall-hebron': 'spain'
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
    for i in tqdm.tqdm(range(len(dict_results)), unit='iter', unit_scale=False, desc="Parse json files", ascii=False,
                       ncols=80):
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


def label_bar_model(ax, bar_plot, model_lst):
    """
    Add ManufacturersModelName embedded in each bar.
    :param ax Matplotlib axes
    :param bar_plot Matplotlib object
    :param model_lst sorted list of model names
    """
    for idx,rect in enumerate(bar_plot):
        height = rect.get_height()
        ax.text(rect.get_x() + rect.get_width()/2., 0.1 * height,
                model_lst[idx], color='white', weight='bold',
                ha='center', va='bottom', rotation=90)
    return ax


def get_flag(name):
    """
    Get the flag of a country from the folder flags.
    :param name Name of the country
    """
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'flags', '{}.png'.format(name))
    im = plt.imread(path)
    return im


def offset_flag(coord, name, ax):
    """
    Add flag images to the plot.
    :param coord Coordinate of the xtick
    :param name Name of the country
    :param ax Matplotlib ax
    """
    img = get_flag(name)
    img_rot = ndimage.rotate(img, 45)
    im = OffsetImage(img_rot, zoom=0.2)
    im.image.axes = ax

    ab = AnnotationBbox(im, (coord, 0), frameon=False, pad=0, xycoords='data')

    ax.add_artist(ab)
    return ax


def add_stats_per_vendor(ax, x_i, x_j, y_max, mean, std, cov, f, color):
    # add stats as strings
    txt = "{0:.2f} $\pm$ {1:.2f} ({2:.2f}%)".format(mean * f, std * f, cov * 100.)
    ax.annotate(txt, xy = (np.mean([x_i, x_j]), y_max), va='center', ha='center',
        bbox=dict(edgecolor='none', fc=color, alpha=0.3))
    # add rectangle for variance
    rect = patches.Rectangle((x_i, (mean - std) * f), x_j - x_i, 2 * std * f,
                             edgecolor=None, facecolor=color, alpha=0.3)
    ax.add_patch(rect)
    # add dashed line for mean value
    ax.plot([x_i, x_j], [mean * f, mean * f], "k--", alpha=0.5)
    return ax


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
        if not 'mean' in stats.keys():
            stats['mean'] = {}
        if not 'std' in stats.keys():
            stats['std'] = {}
        # fetch vals for specific vendor
        val_per_vendor = df['mean'][df['vendor'] == vendor].values

        stats['mean'][vendor] = np.mean(val_per_vendor)
        stats['std'][vendor] = np.std(val_per_vendor)
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
        logger.info('\nProcessing: '+csv_file)
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
        model_sorted = df['model'][site_sorted].values

        # Scale values (for display)
        mean_sorted = mean_sorted * scaling_factor[metric]
        std_sorted = std_sorted * scaling_factor[metric]

        # Get color based on vendor
        list_colors = [vendor_to_color[i] for i in vendor_sorted]

        # Create figure and plot bar graph
        fig, ax = plt.subplots(figsize=(15, 8))
        # TODO: show only superior part of STD
        plt.grid(axis='y')
        bar_plot = plt.bar(range(len(site_sorted)), height=mean_sorted, width=0.5,
                           tick_label=site_sorted, yerr=[[0 for v in std_sorted], std_sorted], color=list_colors)
        ax = label_bar_model(ax, bar_plot, model_sorted)  # add ManufacturersModelName embedded in each bar
        plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg, align at end
        plt.xlim([-1, len(site_sorted)])
        ax.set_xticklabels([s + '   ' for s in site_sorted])  # spaces are added after the site name to allow space for flag
        # ax.get_xaxis().set_visible(True)
        ax.tick_params(labelsize=15)
        plt.ylabel(metric_to_label[metric], fontsize=15)

        # add country flag of each site
        for i, c in enumerate(site_sorted):
            ax = offset_flag(i, flags[c], ax)

        x_init_vendor = 0
        for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
            n_site = list(vendor_sorted).count(vendor)
            i_max = x_init_vendor+np.argmax(mean_sorted[x_init_vendor:x_init_vendor+n_site])
            ax = add_stats_per_vendor(ax=ax,
                                      x_i=x_init_vendor-0.5,
                                      x_j=x_init_vendor+n_site-1+0.5,
                                      y_max=mean_sorted[i_max]+std_sorted[i_max] * 1.2,
                                      mean=stats['mean'][vendor],
                                      std=stats['std'][vendor],
                                      cov=stats['cov'][vendor],
                                      f=scaling_factor[metric],
                                      color=list_colors[x_init_vendor])
            x_init_vendor += n_site

        # plt.ylim(ylim[contrast])
        # plt.yticks(np.arange(ylim[contrast][0], ylim[contrast][1], step=ystep[contrast]))
        # plt.title(contrast)
        plt.tight_layout()  # make sure everything fits
        fname_fig = os.path.join(path_data, 'results/fig_'+metric+'.png')
        plt.savefig(fname_fig)
        logger.info('Created: '+fname_fig)


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
