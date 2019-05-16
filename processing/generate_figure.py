#!/usr/bin/env python
#
# Generate figures for the spine-generic dataset. Figures are output in the sub-folder /results of the path specified
# by -p.
# IMPORTANT: the input path (-p) should include subfolders data/ (has all the processed data) and results/
#
# USAGE:
#   ${SCT_DIR}/python/bin/python generate_figure.py -d PATH_DATA -r PATH_RESULTS
#
#   Example:
#   ${SCT_DIR}/python/bin/python generate_figure.py -p /home/bob/spine_generic/data -r /home/bob/spine_generic/results
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
import pandas as pd

import numpy as np
from scipy import ndimage
from collections import OrderedDict
import logging
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage,AnnotationBbox
import matplotlib.patches as patches


# Initialize global variables
DISPLAY_INDIVIDUAL_SUBJECT = True
# List subject to remove, associated with contrast
SUBJECTS_TO_REMOVE = [
    {'subject': 'sub-oxfordFmrib04', 'metric': 'csa_t2'},
    {'subject': 'sub-oxfordFmrib01', 'metric': 'dti_fa'},
    {'subject': 'sub-queensland04', 'metric': 'dti_fa'},
    {'subject': 'sub-perform02', 'metric': 'dti_fa'},
    {'subject': 'sub-tehranS04', 'metric': 'mtr'},
    {'subject': 'sub-geneva02', 'metric': 'mtr'},
    {'subject': 'sub-tehranS04', 'metric': 'mtsat'},
    {'subject': 'sub-geneva02', 'metric': 'mtsat'},
    {'subject': 'sub-sapienza03', 'metric': 't1'},
    {'subject': 'sub-sapienza04', 'metric': 't1'},
    {'subject': 'sub-sapienza05', 'metric': 't1'},
    {'subject': 'sub-sapienza06', 'metric': 't1'},
]

# Initialize logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # default: logging.DEBUG, logging.INFO
hdlr = logging.StreamHandler(sys.stdout)
logging.root.addHandler(hdlr)


# country dictionary: key: site, value: country name
flags = {
    'amu': 'france',
    'balgrist': 'ch',
    'barcelona': 'spain',
    'brno': 'cz',
    'brnoPrisma': 'cz',
    'cardiff': 'uk',
    'chiba': 'japan',
    'douglas': 'canada',
    'dresden': 'germany',
    'juntendo750w': 'japan',
    'juntendoAchieva': 'japan',
    'juntendoSkyra': 'japan',
    'juntendoPrisma': 'japan',
    'geneva': 'ch',
    'hamburg': 'germany',
    'mgh': 'us',
    'milan': 'italy',
    'mni': 'canada',
    'mpicbs': 'germany',
    'nottwil': 'ch',
    'nwu': 'us',
    'oxfordFmrib': 'uk',
    'oxfordOhba': 'uk',
    'perform': 'canada',
    'poly': 'canada',
    'queensland': 'australia',
    'sapienza': 'italy',
    'sherbrooke': 'canada',
    'stanford': 'us',
    'strasbourg': 'france',
    'tehran': 'iran',
    'tokyo': 'japan',
    'tokyo750w': 'japan',
    'tokyoSkyra': 'japan',
    'tokyoIngenia': 'japan',
    'ucl': 'uk',
    'unf': 'canada',
    'vallHebron': 'spain',
    'vuiisAchieva': 'us',
    'vuiisIngenia': 'us',
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
    'DWI_FA.csv': 'dti_fa',
    'DWI_MD.csv': 'dti_md',
    'DWI_RD.csv': 'dti_rd',
    'MTR.csv': 'mtr',
    'MTsat.csv': 'mtsat',
    'T1.csv': 't1',
}

# fetch metric field
metric_to_field = {
    'csa_t1': 'MEAN(area)',
    'csa_t2': 'MEAN(area)',
    'csa_gm': 'MEAN(area)',
    'dti_fa': 'WA()',
    'dti_md': 'WA()',
    'dti_rd': 'WA()',
    'mtr': 'WA()',
    'mtsat': 'WA()',
    't1': 'WA()',
}

# fetch metric field
metric_to_label = {
    'csa_t1': 'Cord CSA from T1w [$mm^2$]',
    'csa_t2': 'Cord CSA from T2w [$mm^2$]',
    'csa_gm': 'Gray Matter CSA [$mm^2$]',
    'dti_fa': 'Fractional anisotropy',
    'dti_md': 'Mean diffusivity [$mm^2.s^-1$]',
    'dti_rd': 'Radial diffusivity [$mm^2.s^-1$]',
    'mtr': 'Magnetization transfer ratio [%]',
    'mtsat': 'Magnetization transfer saturation [a.u.]',
    't1': 'T1 [ms]',
}

# scaling factor (for display)
scaling_factor = {
    'csa_t1': 1,
    'csa_t2': 1,
    'csa_gm': 1,
    'dti_fa': 1,
    'dti_md': 1000,
    'dti_rd': 1000,
    'mtr': 1,
    'mtsat': 1,
    't1': 1000,
}

# OLD STUFF FOR SINGLE CENTER
# # Create a dictionary of centers: key: folder name, val: dataframe name
# centers = {
#     'chiba_spine-generic_20180608-750': 'Chiba-750',
#     'juntendo-750w_spine-generic_20180529': 'Juntendo-750w',
#     'tokyo-univ_spine-generic_20180604-750w': 'TokyoUniv-750w',
#     'tokyo-univ_spine-generic_20180604-signa1': 'TokyoUniv-Signa1',
#     'tokyo-univ_spine-generic_20180604-signa2': 'TokyoUniv-Signa2',
#     'ucl_spine-generic_20171207': 'UCL-Achieva',
#     'juntendo-achieva_spine-teneric_20180524': 'Juntendo-Achieva',
#     'glen_spine-generic_20171128': 'Glen-Ingenia',
#     'tokyo-univ_spine-generic_20180604-ingenia': 'TokyoUniv-Ingenia',
#     'chiba_spine-generic_20180608-ingenia': 'Chiba-Ingenia',
#     'mgh-bay3_spine-generic_20171201': 'MGH-Trio',
#     'douglas_spine-generic_20171127': 'Douglas-Trio',
#     'poly_spine-generic_20171221': 'Polytechnique-Skyra',
#     'juntendo-skyra_spine-generic_20180509': 'Juntendo-Skyra',
#     'tokyo-univ_spine-generic_20180604-skyra': 'TokyoUniv-Skyra',
#     'unf_sct_026': 'UNF-Prisma',
#     'oxford_spine-generic_20171209': 'Oxford-Prisma',
#     'juntendo-prisma_spine-generic_20180523': 'Juntendo-Prisma',
# }
# # ylim for figure
# ylim = {
#     't1': [40, 90],
#     't2': [40, 90],
#     'dmri': [0.4, 0.9],
#     'mt': [30, 65],
#     't2s': [10, 20],
# }
#
#
# # ystep (in yticks) for figure
# ystep = {
#     't1': 5,
#     't2': 5,
#     'dmri': 0.1,
#     'mt': 5,
#     't2s': 1,
# }


def aggregate_per_site(dict_results, metric):
    """
    Aggregate metrics per site
    :param dict_results:
    :param metric: Metric type
    :return:
    """
    # Build Panda DF of participants based on participants.tsv file
    participants = pd.read_csv(os.path.join(path_data, 'participants.tsv'), sep="\t")

    # Fetch specific field for the selected metric
    metric_field = metric_to_field[metric]
    # Build a dictionary that aggregates values per site
    results_agg = {}
    # Loop across lines and fill dict of aggregated results
    for i in tqdm.tqdm(range(len(dict_results)), unit='iter', unit_scale=False, desc="Loop across subjects", ascii=False,
                       ncols=80):
        filename = dict_results[i]['Filename']
        logger.debug('Filename: '+filename)
        # Fetch metadata for the site
        # dataset_description = read_dataset_description(filename, path_data)
        # cluster values per site
        subject = fetch_subject(filename)
        # check if subject needs to be discarded
        if not remove_subject(subject, metric):
            # Fetch index of row corresponding to subject
            rowIndex = participants[participants['participant_id'] == subject].index
            # Add column "val" with metric value
            participants.loc[rowIndex, 'val'] = dict_results[i][metric_field]
            site = participants['institution_id'][rowIndex].get_values()[0]
            if not site in results_agg.keys():
                # if this is a new site, initialize sub-dict
                results_agg[site] = {}
                results_agg[site]['site'] = site  # need to duplicate in order to be able to sort using vendor AND site with Pandas
                results_agg[site]['vendor'] = participants['manufacturer'][rowIndex].get_values()[0]
                results_agg[site]['model'] = participants['manufacturers_model_name'][rowIndex].get_values()[0]
                results_agg[site]['val'] = []
            # add val for site (ignore None)
            val = dict_results[i][metric_field]
            if not val == 'None':
                results_agg[site]['val'].append(float(val))
    return results_agg


def add_flag(coord, name, ax):
    """
    Add flag images to the plot.
    :param coord Coordinate of the xtick
    :param name Name of the country
    :param ax Matplotlib ax
    """
    def _get_flag(name):
        """
        Get the flag of a country from the folder flags.
        :param name Name of the country
        """
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'flags', '{}.png'.format(name))
        im = plt.imread(path)
        return im

    img = _get_flag(name)
    img_rot = ndimage.rotate(img, 45)
    im = OffsetImage(img_rot.clip(0, 1), zoom=0.2)
    im.image.axes = ax

    ab = AnnotationBbox(im, (coord, 0), frameon=False, pad=0, xycoords='data')

    ax.add_artist(ab)
    return ax


def add_stats_per_vendor(ax, x_i, x_j, y_max, mean, std, cov_intra, cov_inter, f, color):
    """"
    Add stats per vendor to the plot.
    :param ax
    :param x_i coordinate where current vendor is starting
    :param x_j coordinate where current vendor is ending
    :param y_max top of the higher bar of the current vendor
    :param mean
    :param std
    :param cov_intra
    :param cov_inter
    :param f scaling factor
    :param color
    """
    # add stats as strings
    txt = "{0:.2f} $\pm$ {1:.2f}\nCOV intra:{2:.2f}%, inter:{3:.2f}%".\
        format(mean * f, std * f, cov_intra * 100., cov_inter * 100.)
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
        if not 'cov_inter' in stats.keys():
            stats['cov_inter'] = {}
        if not 'cov_intra' in stats.keys():
            stats['cov_intra'] = {}
        if not 'mean' in stats.keys():
            stats['mean'] = {}
        if not 'std' in stats.keys():
            stats['std'] = {}
        # fetch vals for specific vendor
        val_per_vendor = df['mean'][df['vendor'] == vendor].values

        stats['mean'][vendor] = np.mean(val_per_vendor)
        stats['std'][vendor] = np.std(val_per_vendor)
        # compute inter-subject COV
        stats['cov_inter'][vendor] = np.std(val_per_vendor) / np.mean(val_per_vendor)
        # compute intra-subject COV (averaged across subjects, within vendor)
        stats['cov_intra'][vendor] = \
            np.mean(df['std'][df['vendor'] == vendor].values / df['mean'][df['vendor'] == vendor].values)
    return df, stats


def fetch_subject(filename):
    """
    Get subject from filename
    :param filename:
    :return: subject
    """
    path, file = os.path.split(filename)
    subject = path.split(os.sep)[-2]
    return subject


def get_parameters():
    parser = argparse.ArgumentParser(
        description='Generate figures for the spine-generic dataset. Figures are output in the sub-folder specified by '
                    'flag -r.')
    parser.add_argument('-r', '--result',
                        required=True,
                        help='Path to results data, which contains all the output csv files.')
    parser.add_argument('-d', '--data',
                        required=True,
                        help='Path to the input BIDS dataset, which contains the tsv file used for building the '
                             'site-specific figures.')
    args = parser.parse_args()
    return args


def label_bar_model(ax, bar_plot, model_lst):
    """
    Add ManufacturersModelName embedded in each bar.
    :param ax Matplotlib axes
    :param bar_plot Matplotlib object
    :param model_lst sorted list of model names
    """
    height = bar_plot[0].get_height() # in order to align all the labels along y-axis
    for idx,rect in enumerate(bar_plot):
        ax.text(rect.get_x() + rect.get_width()/2., 0.1 * height,
                model_lst[idx], color='white', weight='bold',
                ha='center', va='bottom', rotation=90)
    return ax


def remove_subject(subject, metric):
    """
    Check if subject should be removed
    :param subject:
    :param metric:
    :return: Bool
    """
    for subject_to_remove in SUBJECTS_TO_REMOVE:
        if subject_to_remove['subject'] == subject and subject_to_remove['metric'] == metric:
            return True
    return False


def main():
    # TODO: make "results" an input param

    # fetch all .csv result files
    csv_files = glob.glob(os.path.join(path_result, '*.csv'))

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
        results_dict = aggregate_per_site(dict_results, metric)

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
        site_sorted = df.sort_values(by=['vendor', 'model', 'site']).index.values
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
        ax.set_axisbelow(True)
        bar_plot = plt.bar(range(len(site_sorted)), height=mean_sorted, width=0.5,
                           tick_label=site_sorted, yerr=[[0 for v in std_sorted], std_sorted], color=list_colors)

        if DISPLAY_INDIVIDUAL_SUBJECT:
            for site in site_sorted:
                index = list(site_sorted).index(site)
                val = df['val'][site]
                plt.plot([index] * len(val), val, 'r.')
        ax = label_bar_model(ax, bar_plot, model_sorted)  # add ManufacturersModelName embedded in each bar
        plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg, align at end
        plt.xlim([-1, len(site_sorted)])
        ax.set_xticklabels([s + ' ' for s in site_sorted])  # add space after the site name to allow space for flag
        # ax.get_xaxis().set_visible(True)
        ax.tick_params(labelsize=15)
        # plt.ylim(ylim[contrast])
        # plt.yticks(np.arange(ylim[contrast][0], ylim[contrast][1], step=ystep[contrast]))
        plt.ylabel(metric_to_label[metric], fontsize=15)

        # add country flag of each site
        for i, c in enumerate(site_sorted):
            ax = add_flag(i, flags[c], ax)

        # add stats per vendor
        x_init_vendor = 0
        # height_bar = [rect.get_height() for idx,rect in enumerate(bar_plot)]
        # y_max = height_bar[i_max]+std_sorted[i_max]  # used to display stats
        y_max = ax.get_ylim()[1] * 95 / 100  # stat will be located at the top 95% of the graph
        for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
            n_site = list(vendor_sorted).count(vendor)
            ax = add_stats_per_vendor(ax=ax,
                                      x_i=x_init_vendor-0.5,
                                      x_j=x_init_vendor+n_site-1+0.5,
                                      y_max=y_max,
                                      mean=stats['mean'][vendor],
                                      std=stats['std'][vendor],
                                      cov_intra=stats['cov_intra'][vendor],
                                      cov_inter=stats['cov_inter'][vendor],
                                      f=scaling_factor[metric],
                                      color=list_colors[x_init_vendor])
            x_init_vendor += n_site

        plt.tight_layout()  # make sure everything fits
        fname_fig = os.path.join(path_result, 'fig_'+metric+'.png')
        plt.savefig(fname_fig)
        logger.info('Created: '+fname_fig)


if __name__ == "__main__":
    args = get_parameters()
    path_data = args.data
    path_result = args.result
    main()
