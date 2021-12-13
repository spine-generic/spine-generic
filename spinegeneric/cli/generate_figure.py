#!/usr/bin/env python
#
# Generate figures for the spine-generic project.
#
# Note: Matplotlib crashes when running debugger in Pycharm with python 3.7.3. To fix the problem, run this script
# using a virtual env python 3.7.0. More info at: https://github.com/MTG/sms-tools/issues/36
#
# Authors: Julien Cohen-Adad, Jan Valosek


import os
import argparse
import importlib.resources
import tqdm
import sys
import csv
import pandas as pd
import subprocess
from textwrap import dedent
import yaml
import math

import numpy as np
from scipy import ndimage
from scipy.stats import f_oneway
from collections import OrderedDict
from collections import defaultdict
import logging
import matplotlib.pyplot as plt
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
import matplotlib.patches as patches
from sklearn.linear_model import LinearRegression
from statsmodels.stats.multicomp import pairwise_tukeyhsd

import spinegeneric as sg
import spinegeneric.utils
import spinegeneric.flags

from plotly.subplots import make_subplots
import plotly.graph_objs as go
import plotly.express as px

# Initialize logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)  # default: logging.DEBUG, logging.INFO
hdlr = logging.StreamHandler(sys.stdout)
logging.root.addHandler(hdlr)

FNAME_LOG = 'log_stats.txt'

# country dictionary: key: site, value: country name
# Flags are downloaded from: https://emojipedia.org/
flags = {
    'amu': 'france',
    'balgrist': 'ch',
    'barcelona': 'spain',
    'beijing750': 'china',
    'beijingPrisma': 'china',
    'beijingVerio': 'china',
    'brno': 'cz',
    'brnoCeitec': 'cz',
    'brnoPrisma': 'cz',
    'brnoUhb': 'cz',
    'cardiff': 'uk',
    'chiba': 'japan',
    'chiba750': 'japan',
    'chibaIngenia': 'japan',
    'cmrra': 'us',
    'cmrrb': 'us',
    'douglas': 'canada',
    'dresden': 'germany',
    'juntendo750w': 'japan',
    'juntendoAchieva': 'japan',
    'juntendoPrisma': 'japan',
    'juntendoSkyra': 'japan',
    'geneva': 'ch',
    'glen': 'canada',
    'hamburg': 'germany',
    'mgh': 'us',
    'milan': 'italy',
    'mni': 'canada',
    'mountSinai': 'us',
    'mpicbs': 'germany',
    'nottwil': 'ch',
    'nwu': 'us',
    'oxfordFmrib': 'uk',
    'oxfordOhba': 'uk',
    'pavia': 'italy',
    'perform': 'canada',
    'poly': 'canada',
    'queensland': 'australia',
    'fslAchieva': 'italy',
    'fslPrisma': 'italy',
    'sherbrooke': 'canada',
    'stanford': 'us',
    'strasbourg': 'france',
    'tehran': 'iran',
    'tokyo': 'japan',
    'tokyo750w': 'japan',
    'tokyoSigna1': 'japan',
    'tokyoSigna2': 'japan',
    'tokyoSkyra': 'japan',
    'tokyoIngenia': 'japan',
    'ubc': 'canada',
    'ucl': 'uk',
    'ucdavis': 'us',
    'unf': 'canada',
    'vallHebron': 'spain',
    'vuiisAchieva': 'us',
    'vuiisIngenia': 'us',
}

# color to assign to each MRI model for the figure
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
    'MTR.csv': 'mtr',
    'MTsat.csv': 'mtsat',
    'T1.csv': 't1',
    'DWI_FA.csv': 'dti_fa',
    'DWI_MD.csv': 'dti_md',
    'DWI_RD.csv': 'dti_rd',
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
    'dti_md': 'Mean diffusivity [$mm^2.s^{-1}$]',
    'dti_rd': 'Radial diffusivity [$mm^2.s^{-1}$]',
    'mtr': 'Magnetization transfer ratio [%]',
    'mtsat': 'Magnetization transfer saturation [%]',
    't1': 'T1 [ms]',
}

# fetch metric field for Plotly
# need to create new label so superscripts can display, since Plotly does not understand Latex, 
metric_to_label_plotly = {
    'csa_t1': 'Cord CSA from T1w [mm<sup>2</sup>]',
    'csa_t2': 'Cord CSA from T2w [mm<sup>2</sup>]',
    'csa_gm': 'Gray Matter CSA [mm<sup>2</sup>]',
    'dti_fa': 'Fractional anisotropy',
    'dti_md': 'Mean diffusivity [mm<sup>2</sup>s<sup>-1</sup>]',
    'dti_rd': 'Radial diffusivity [mm<sup>2</sup>s<sup>-1</sup>]',
    'mtr': 'Magnetization transfer ratio [%]',
    'mtsat': 'Magnetization transfer saturation [%]',
    't1': 'T1 [ms]',
}

# fetch metric field for Plotly
# need to create new label so superscripts can display, since Plotly does not understand Latex 
metric_to_label_plotly = {
    'csa_t1': 'Cord CSA from T1w [mm<sup>2</sup>]',
    'csa_t2': 'Cord CSA from T2w [mm<sup>2</sup>]',
    'csa_gm': 'Gray Matter CSA [mm<sup>2</sup>]',
    'dti_fa': 'Fractional anisotropy',
    'dti_md': 'Mean diffusivity [mm<sup>2</sup>s<sup>-1</sup>]',
    'dti_rd': 'Radial diffusivity [mm<sup>2</sup>s<sup>-1</sup>]',
    'mtr': 'Magnetization transfer ratio [%]',
    'mtsat': 'Magnetization transfer saturation [%]',
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

# FIGURE PARAMETERS
FONTSIZE = 15
TICKSIZE = 10
LABELSIZE = 15


def get_parser():
    parser = argparse.ArgumentParser(
        description="Generate figures for the spine-generic project. Statistical resuls are output in the file '{}'. "
                    "The following metrics will be computed:\n {}".format(FNAME_LOG, list(metric_to_field.keys())),
        formatter_class=sg.utils.SmartFormatter,
    )
    parser.add_argument(
        '-path-results',
        required=False,
        metavar='<dir_path>',
        help="Folder that includes all the output csv files (generated by process_data.sh). By default, takes the "
             "current folder.")
    parser.add_argument(
        '-no-sub',
        action='store_false',
        help="Do not display the value of each individual subject (red dot).")
    parser.add_argument(
        '-show-ci',
        action='store_true',
        help="Show 95%% confidence interval on the plot.")
    parser.add_argument(
        '-output-text',
        required=False,
        action='store_true',
        help="Write statistical results into sentences for easy copy/paste into a manuscript.")
    parser.add_argument(
        '-exclude',
        required=False,
        help=
        "R|Config yaml file listing subjects (starting with 'sub') or sites to remove from the statistics."
        "See the list of computed metrics in the description above for the accepted keys."
        "Yaml file can be validated at this website: http://www.yamllint.com/. Below is an example yaml file:\n"
        + dedent(
            """
            csa_t1:
                - sub-oxfordFmrib04
                - sub-mountSinai03
            csa_t2:
                - oxfordFmrib  # Here, removing site entirely
            dti_fa:
                - sub-beijingPrisma03
            mtsat:
                - sub-geneva02\n
            """)
    )
    parser.add_argument(
        '-v',
        action='store_true',
        help="Increase verbosity; interactive figure (for debugging).")
    parser.add_argument(
        '-output-html',
        action='store_true',
        help="Generate interactive graph in .html with Plotly"
    )
    return parser


def aggregate_per_site(dict_results, metric, dict_exclude_subj):
    """
    Aggregate metrics per site.
    folder.
    :param dict_results:
    :param metric: Metric type
    :return:
    """
    # Build Panda DF of participants based on participants.tsv file
    participants = load_participants_file()

    # Fetch specific field for the selected metric
    metric_field = metric_to_field[metric]
    # Build a dictionary that aggregates values per site
    results_agg = {}
    # Loop across lines and fill dict of aggregated results
    subjects_removed = []
    for i in tqdm.tqdm(range(len(dict_results)), unit='iter', unit_scale=False, desc="Loop across subjects",
                       ascii=True, ncols=80):
        filename = dict_results[i]['Filename']
        logger.debug('Filename: ' + filename)
        # Fetch metadata for the site
        # dataset_description = read_dataset_description(filename, path_data)
        # cluster values per site
        subject = fetch_subject(filename)
        # check if subject needs to be discarded
        if not remove_subject(subject, metric, dict_exclude_subj):
            # Fetch index of row corresponding to subject
            rowIndex = participants[participants['participant_id'] == subject].index
            # Add column "val" with metric value
            participants.loc[rowIndex, 'val'] = dict_results[i][metric_field]
            site = participants['institution_id'][rowIndex].array[0]
            if not site in results_agg.keys():
                # if this is a new site, initialize sub-dict
                results_agg[site] = {}
                results_agg[site][
                    'site'] = site  # need to duplicate in order to be able to sort using vendor AND site with Pandas
                results_agg[site]['vendor'] = participants['manufacturer'][rowIndex].array[0]
                results_agg[site]['model'] = participants['manufacturers_model_name'][rowIndex].array[0]
                results_agg[site]['val'] = []
                results_agg[site]['subject'] = []
            # add val for site (ignore None)
            val = dict_results[i][metric_field]
            if not val == 'None':
                results_agg[site]['val'].append(float(val))
                results_agg[site]['subject'].append(subject)
        else:
            subjects_removed.append(subject)
    logger.info("Subjects removed: {}".format(subjects_removed))
    return results_agg


def add_stats_per_vendor(ax, x_i, x_j, y_max, mean, std, ci, cov_intra, cov_inter, f, color, show_ci=False):
    """"
    Add stats per vendor to the plot.
    :param ax
    :param x_i coordinate where current vendor is starting
    :param x_j coordinate where current vendor is ending
    :param y_max top of the higher bar of the current vendor
    :param mean
    :param std
    :param ci
    :param cov_intra
    :param cov_inter
    :param f scaling factor
    :param color
    :param show_ci: Bool: Show 95% confidence interval
    """
    # add stats as strings
    if cov_intra == 0:
        txt = "{0:.2f} $\pm$ {1:.2f}\nCOV inter:{2:.2f}%". \
            format(mean * f, std * f, cov_inter * 100.)
    else:
        txt = "{0:.2f} $\pm$ {1:.2f}\nCOV intra:{2:.2f}%, inter:{3:.2f}%". \
            format(mean * f, std * f, cov_intra * 100., cov_inter * 100.)

    ax.annotate(txt, xy=(np.mean([x_i, x_j]), y_max), va='center', ha='center',
                bbox=dict(edgecolor='none', fc=color, alpha=0.3))
    # add rectangle for variance
    rect = patches.Rectangle((x_i, (mean - std) * f), x_j - x_i, 2 * std * f,
                             edgecolor=None, facecolor=color, alpha=0.3)
    ax.add_patch(rect)
    # add dashed line for mean value
    ax.plot([x_i, x_j], [mean * f, mean * f], "k--", alpha=0.5)
    # add line for 95% CI
    if show_ci:
        ax.plot([x_i, x_j], [(mean - ci) * f, (mean - ci) * f], "r--", alpha=0.5)
        ax.plot([x_i, x_j], [(mean + ci) * f, (mean + ci) * f], "r--", alpha=0.5)
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
    # Compute statistics within site
    for site in df.index:
        mean_per_row.append(np.mean(df['val'][site]))
        std_per_row.append(np.std(df['val'][site]))
    # Update Dataframe
    df['mean'] = mean_per_row  # mean within each site (e.g., if there are 35 sites, this will be a vector of length 35)
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
        if not '95ci' in stats.keys():
            stats['95ci'] = {}
        if not 'anova_site' in stats.keys():
            stats['anova_site'] = {}
        # fetch within-site mean values for a specific vendor
        val_per_vendor = df['mean'][(df['vendor'] == vendor) & ~df['exclude']]
        # compute mean within vendor (mean of the within-site means)
        stats['mean'][vendor] = np.mean(val_per_vendor)
        # compute std within vendor (std of the within-site means)
        stats['std'][vendor] = np.std(val_per_vendor)
        # compute 95% confidence interval
        stats['95ci'][vendor] = 1.96 * np.std(val_per_vendor) / np.sqrt(len(val_per_vendor))
        # compute within-vendor inter-site COV (based on the within-site means)
        stats['cov_inter'][vendor] = np.std(val_per_vendor) / np.mean(val_per_vendor)
        # compute intra-site COV, and average it across all the sites within the same vendor
        stats['cov_intra'][vendor] = \
            np.mean(df['std'][(df['vendor'] == vendor) & ~df['exclude']].values /
                    df['mean'][(df['vendor'] == vendor) & ~df['exclude']].values)
        # ANOVA: category=[site]
        values_per_site = [df['val'][(df['vendor'] == vendor) & (df['site'] == i_site)][0]
                           for i_site in df['site'][(df['vendor'] == vendor) & ~df['exclude']]]
        stats['anova_site'][vendor] = f_oneway(*values_per_site)
        logger.info("ANOVA[site] for {}: {}".format(vendor, stats['anova_site'][vendor]))

    # ANOVA: category=[vendor]
    stats['anova_vendor'] = f_oneway(*[df['mean'][(df['vendor'] == i_vendor) & ~df['exclude']] for i_vendor in vendors])
    logger.info("ANOVA[vendor]: {}".format(stats['anova_vendor']))
    # Multiple pairwise comparison with Tukey Honestly Significant Difference (HSD) test
    stats['tukey_test'] = pairwise_tukeyhsd(df['mean'], df['vendor'])
    logger.info("Tukey Honestly Significant Difference (HSD):\n{}".format(stats['tukey_test']))
    return df, stats


def output_text(stats):
    """
    Embed statistical results into sentences so they can easily be copy/pasted into a manuscript.
    :param stats: dict with stat resutls
    """

    def format_p_value(p_val):
        """
        If p-value is lower than 0.01, change it to "<0.01", otherwise, round it to two decimals
        :param p_val: input p-value as a float
        :return: p_val: processed p-value (replaced by "<0.01" or rounded to two decimals) as a str
        """
        if p_val < 0.01:
            p_val = "<0.01"
        else:
            p_val = '=' + str(round(p_val, 2))

        return p_val

    txt = ""

    # Find out if this is single-subject data (single value per site)
    if max(stats['cov_intra'].values()) == 0.0:
        single_subject = True
    else:
        single_subject = False

    # Find and write highest intra-site COV (rounded up)
    if not single_subject:
        txt += "The intra-site COVs were averaged for each vendor and found to be all under " \
               "{:.1f}%. ".format(math.ceil(max(stats['cov_intra'].values()) * 1000) / 10)

    # Write inter-site COVs and ANOVA p-values
    if single_subject:
        txt += "The inter-site COVs were "
    else:
        txt += "The inter-site COVs (and inter-site ANOVA p-values) were "

    for count, vendor in enumerate(stats['cov_inter'].keys()):
        cov_inter = stats['cov_inter'][vendor] * 100
        p_val = stats['anova_site'][vendor][1]
        p_val = format_p_value(p_val)
        if single_subject:
            txt += "{:.1f}% for {}".format(cov_inter, vendor)
        else:
            txt += "{:.1f}% (p{}) for {}".format(cov_inter, p_val, vendor)
        if count == 0:
            txt += ", "
        elif count == 1:
            txt += " and "
        elif count == 2:
            txt += ". "

    p_val_anova = stats['anova_vendor'][1]
    # Write post-hoc Tukey results if inter-vendor difference was significant
    if p_val_anova < 0.05:
        p_val_anova = format_p_value(p_val_anova)
        txt += "The inter-vendor difference was significant (p{}), with the Tukey test showing significant " \
               "differences ".format(p_val_anova)

        # Get significant post-hoc results
        index = sum(stats['tukey_test'].reject == True)  # total number of significant post-hoc tests
        # Loop across between vendor tests (i.e, GE-Philips, GE-Siemens, Philips-Siemens)
        for counter in range(1, 4):
            # Check if post-hoc test was rejected or not
            if stats['tukey_test']._results_table[counter][6].data:
                vendor1 = stats['tukey_test']._results_table[counter][0].data  # 1st vendor
                vendor2 = stats['tukey_test']._results_table[counter][1].data  # 2nd vendor
                p_adj = stats['tukey_test']._results_table[counter][3].data  # adjusted p-val
                p_adj = format_p_value(p_adj)
                txt += "between {} and {} (p-adj{})".format(vendor1, vendor2, p_adj)
                index -= 1
                # Decide which conjunction will be used
                if index == 2:
                    txt += ", "
                elif index == 1:
                    txt += " and "
    # Inter-vendor difference was not significant
    else:
        p_val_anova = format_p_value(p_val_anova)
        txt += "The inter-vendor difference was not significant (p{})".format(p_val_anova)

    txt += "."
    logger.info(txt)


def fetch_subject(filename):
    """
    Get subject from filename
    :param filename:
    :return: subject
    """
    path, file = os.path.split(filename)
    subject = path.split(os.sep)[-2]
    return subject


def load_participants_file():
    """
    Load participants.tsv file and build pandas DF of participants
    This function assumes that the file participants.tsv is present in the -path-results
    :return: participants: pandas dataframe
    """
    participants = pd.read_csv(os.path.join('participants.tsv'), sep="\t")
    return participants


def compute_age_statistics():
    """
    Compute age statistics across subjects and write them into output txt file
    :return:
    """
    participants = load_participants_file()
    logger.info('Age statistics:')
    # Compute min, max and median for age across all subjects and save it to log
    age_stats = participants['age'].agg(['median', 'min', 'max'])
    logger.info('..., age between {} and {} y.o., median age {} y.o..'.format(age_stats['min'],
                                                                              age_stats['max'],
                                                                              age_stats['median']))


def generate_figure_metric(df, metric, stats, display_individual_subjects, show_ci=False):
    """
    Generate bar plot across sites
    :param df:
    :param metric:
    :param stats:
    :param display_individual_subjects:
    :param show_ci: Bool: Show 95% confidence interval
    :return:
    """

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
            with importlib.resources.path(spinegeneric.flags, f'{name}.png') as path_flag:
                return plt.imread(path_flag.__str__())

        img = _get_flag(name)
        img_rot = ndimage.rotate(img, 45)
        im = OffsetImage(img_rot.clip(0, 1), zoom=0.18)
        im.image.axes = ax

        ab = AnnotationBbox(im, (coord, ax.get_ylim()[0]), frameon=False, pad=0, xycoords='data')

        ax.add_artist(ab)
        return ax

    def label_bar_model(ax, bar_plot, model_lst):
        """
        Add ManufacturersModelName embedded in each bar.
        :param ax Matplotlib axes
        :param bar_plot Matplotlib object
        :param model_lst sorted list of model names
        """
        for idx, rect in enumerate(bar_plot):
            ax.text(rect.get_x() + rect.get_width() / 2.,
                    ax.get_ylim()[0] * 1.2,
                    model_lst[idx], color='white', weight='bold',
                    ha='center', va='bottom', rotation=90)
        return ax

    if logger.level == logging._nameToLevel['DEBUG']:
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
    # The horizontal size of the figure is proportional to the number of sites
    fig, ax = plt.subplots(figsize=(len(site_sorted) * 0.4, 8))
    plt.grid(axis='y')
    ax.set_axisbelow(True)
    bar_plot = plt.bar(range(len(site_sorted)), height=mean_sorted, width=0.5,
                       tick_label=site_sorted, yerr=[[0 for v in std_sorted], std_sorted], color=list_colors)

    # Display individual subjects
    if display_individual_subjects:
        for site in site_sorted:
            index = list(site_sorted).index(site)
            val = df['val'][site]
            # Set scaling
            val = [value * scaling_factor.get(metric) for value in val]
            plt.plot([index] * len(val), val, 'r.')

    # Deal with xticklabels
    # Rotate xticklabels at 45deg, align at end
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")
    plt.xlim([-1, len(site_sorted)])
    # Add space after the site name to allow space for flag
    ax.set_xticklabels([s for s in site_sorted])
    ax.tick_params(labelsize=15)

    # plt.ylim(ylim[contrast])
    # plt.yticks(np.arange(ylim[contrast][0], ylim[contrast][1], step=ystep[contrast]))
    plt.ylabel(metric_to_label[metric], fontsize=15)
    ax.set_ylim(0.3 * mean_sorted.max(), 1.1 * mean_sorted.max())

    # Add country flag of each site
    for i, c in enumerate(site_sorted):
        try:
            ax = add_flag(i, flags[c], ax)
        except KeyError:
            logger.error('ERROR: Flag {} is not defined in dict flags'.format(c))
            sys.exit(1)

    # Add ManufacturersModelName embedded in each bar
    ax = label_bar_model(ax, bar_plot, model_sorted)

    # Add a red cross for sites not considered in the statistics
    for idx, rect in enumerate(bar_plot):
        if df['exclude'][site_sorted[idx]]:
            ax.text(rect.get_x() + rect.get_width() / 2., rect._height, 'x', color='red', weight='bold', ha='center',
                    va='center', size=20)

    # Add stats per vendor
    x_init_vendor = 0
    # height_bar = [rect.get_height() for idx,rect in enumerate(bar_plot)]
    # y_max = height_bar[i_max]+std_sorted[i_max]  # used to display stats
    y_max = ax.get_ylim()[1] * 95 / 100  # stat will be located at the top 95% of the graph
    for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
        n_site = list(vendor_sorted).count(vendor)
        ax = add_stats_per_vendor(ax=ax,
                                  x_i=x_init_vendor - 0.5,
                                  x_j=x_init_vendor + n_site - 1 + 0.5,
                                  y_max=y_max,
                                  mean=stats['mean'][vendor],
                                  std=stats['std'][vendor],
                                  ci=stats['95ci'][vendor],
                                  cov_intra=stats['cov_intra'][vendor],
                                  cov_inter=stats['cov_inter'][vendor],
                                  f=scaling_factor[metric],
                                  color=list_colors[x_init_vendor],
                                  show_ci=show_ci)
        x_init_vendor += n_site

    # Save figure
    plt.tight_layout()
    fname_fig = os.path.join('fig_' + metric + '.png')
    plt.savefig(fname_fig)
    logger.info('Created: ' + fname_fig)


def generate_figure_metric_plotly(df, metric, stats):
    """
    Generate interactive bar plot across sites
    :param df:
    :param metric:
    :param stats:
    :return:
    """
    # Sort values per vendor
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

    fig = go.Figure()

    # Display individual subjects
    i = 0
    for site in site_sorted:
        index = list(site_sorted).index(site)
        val = df['val'][site]
        val = [value * scaling_factor.get(metric) for value in val]
        x = site_sorted[i]
        fig.add_trace(go.Scatter(
            x=[x, x, x, x, x, x], 
            y=val, 
            mode='markers', 
            marker_color='red', 
            name=x
        ))
        i = i + 1
    fig.update_traces(marker=dict(size=4))

    fig.add_trace(go.Bar(
        y=mean_sorted,
        x=site_sorted,
        text=model_sorted,
        textfont=dict(color="white", size=30),
        textposition="inside",
        insidetextanchor="start",
        textangle=-90,
        error_y=dict(array=std_sorted,
                    color='#000000',
                    width=3),
        marker_color=(list_colors)))

    # Add stats per vendor
    x_init_vendor = 0
    for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
        n_site = list(vendor_sorted).count(vendor)
        x_i=x_init_vendor - 0.5
        x_j=x_init_vendor + n_site - 1 + 0.5
        mean=stats['mean'][vendor]
        std=stats['std'][vendor]
        ci=stats['95ci'][vendor]
        cov_intra=stats['cov_intra'][vendor]
        cov_inter=stats['cov_inter'][vendor]
        f=scaling_factor[metric]
        color=list_colors[x_init_vendor]

        fig.add_trace(go.Scatter(
            x=[site_sorted[x_init_vendor], site_sorted[x_init_vendor-1 + n_site]],
            y=[mean*f,mean*f],
            line=dict(color='black', width=1, dash='dash')
        ))

        fig.add_shape(type="rect",
            x0=x_i, y0=(mean-std)*f, x1=x_j, y1=(mean+std)*f,
            line=dict(width=0),
            opacity=0.2,
        fillcolor=color)

        x_init_vendor += n_site

    fig.update_layout(
        showlegend=False,
        yaxis_title=metric_to_label_plotly[metric],
        xaxis_tickangle=-45,
        bargap=0.4
    )

    fig.write_html(metric+'.html')


def generate_figure_t1_t2(df, csa_t1, csa_t2):
    """
    Generate CSA_T1w vs. CSA_T2w
    :param df:
    :param csa_t1:
    :param csa_t2:
    :return:
    """

    def compute_regression(x, y):
        """
        Compute linear regression between x and y:
        y = Slope * x + Intercept
        :param x: list:
        :param y: list:
        :return: results of linear regression
        """
        # create object for the class
        linear_regression = LinearRegression()
        # perform linear regression (compute slope and intercept)
        linear_regression.fit(x.reshape(-1, 1), y.reshape(-1, 1))
        intercept = linear_regression.intercept_
        slope = linear_regression.coef_
        # compute prediction
        reg_predictor = linear_regression.predict(x)
        # compute coefficient of determination R^2 of the prediction
        r2_sc = linear_regression.score(x, y)
        return intercept, slope, reg_predictor, r2_sc

    def format_number(number):
        """
        Round number to two decimals
        :param number: input number
        :return: number rounded to two decimals
        """
        return format(float(number), '.2f')

    # Sort values per vendor
    site_sorted = df.sort_values(by=['vendor', 'model', 'site']).index.values
    vendor_sorted = df['vendor'][site_sorted].values

    # Create dictionary with CSA for T1w and T2w per vendors
    CSA_dict = defaultdict(list)
    # loop across sites
    for index, line in enumerate(csa_t1):
        vendor = line[1]
        # Loop across subjects, making sure to only populate the dictionary with subjects existing both for T1 and T2
        for subject in csa_t1[index][4]:
            if subject in csa_t2[index, 4]:
                CSA_dict[vendor + '_t1'].append(csa_t1[index, 3][csa_t1[index, 4].index(subject)])
                CSA_dict[vendor + '_t2'].append(csa_t2[index, 3][csa_t2[index, 4].index(subject)])

    # Generate figure for T1w and T2w agreement for all vendors together
    fig, ax = plt.subplots(figsize=(7, 7))
    # Loop across vendors
    for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
        plt.scatter(CSA_dict[vendor + '_t2'],
                    CSA_dict[vendor + '_t1'],
                    s=50,
                    linewidths=2,
                    facecolors='none',
                    edgecolors=vendor_to_color[vendor],
                    label=vendor)
    ax.tick_params(labelsize=LABELSIZE)
    plt.plot([50, 100], [50, 100], ls="--", c=".3")  # add diagonal line
    plt.title("CSA agreement between T1w and T2w data")
    plt.xlim(50, 100)
    plt.ylim(50, 100)
    plt.gca().set_aspect('equal', adjustable='box')
    plt.xlabel("T2w CSA", fontsize=FONTSIZE)
    plt.ylabel("T1w CSA", fontsize=FONTSIZE)
    plt.grid(True)
    plt.legend(fontsize=FONTSIZE)
    plt.tight_layout()
    fname_fig = 'fig_t1_t2_agreement.png'
    plt.savefig(fname_fig, dpi=200)
    logger.info('Created: ' + fname_fig)

    # Generate figure for T1w and T2w agreement per vendor
    plt.subplots(figsize=(15, 5))
    # Loop across vendors (create subplot for each vendor)
    for index, vendor in enumerate(list(OrderedDict.fromkeys(vendor_sorted))):
        ax = plt.subplot(1, 3, index + 1)
        x = CSA_dict[vendor + '_t2']
        y = CSA_dict[vendor + '_t1']
        plt.scatter(x,
                    y,
                    s=50,
                    linewidths=2,
                    facecolors='none',
                    edgecolors=vendor_to_color[vendor],
                    label=vendor)
        ax.tick_params(labelsize=TICKSIZE)
        # Define vendor name position
        legend = ax.legend(loc='lower right', handletextpad=0, fontsize=FONTSIZE)
        # Change box's frame color to black (to be same as box around linear fit equation)
        frame = legend.get_frame()
        frame.set_edgecolor('black')
        ax.add_artist(legend)
        # Dynamic scaling of individual subplots based on data
        offset = 2
        lim_min = min(min(x), min(y))
        lim_max = max(max(x), max(y))
        plt.xlim(lim_min - offset, lim_max + offset)
        plt.ylim(lim_min - offset, lim_max + offset)
        # Add bisection (diagonal) line
        plt.plot([lim_min - offset, lim_max + offset],
                 [lim_min - offset, lim_max + offset],
                 ls="--", c=".3")
        plt.xlabel("T2w CSA", fontsize=FONTSIZE)
        plt.ylabel("T1w CSA", fontsize=FONTSIZE)
        # Move grid to background (i.e. behind other elements)
        ax.set_axisbelow(True)
        plt.grid(True)
        # Enforce square grid
        plt.gca().set_aspect('equal', adjustable='box')
        # Compute linear fit
        intercept, slope, reg_predictor, r2_sc = \
            compute_regression(np.array(CSA_dict[vendor + '_t2']).reshape(-1, 1),
                               np.array(CSA_dict[vendor + '_t1']).reshape(-1, 1))
        # Place regression equation to upper-left corner
        plt.text(0.1, 0.9, 'y = {}x + {}\nR\u00b2 = {}'.format(format_number(slope),
                                                               format_number(intercept),
                                                               format_number(r2_sc)),
                 ha='left', va='center', transform=ax.transAxes, fontsize=TICKSIZE, color='red',
                 bbox=dict(boxstyle='round', facecolor='white', alpha=1))  # box around equation
        # Plot linear fit
        axes = plt.gca()
        x_vals = np.array(axes.get_xlim())
        y_vals = intercept + slope * x_vals
        y_vals = np.squeeze(y_vals)  # change shape from (1,N) to (N,)
        plt.plot(x_vals, y_vals, color='red')
        # Add title above middle subplot
        if index == 1:
            plt.title("CSA agreement between T1w and T2w data per vendors", fontsize=FONTSIZE, pad=20)
    # Move subplots closer to each other
    plt.subplots_adjust(wspace=-0.5)
    plt.tight_layout()
    fname_fig = 'fig_t1_t2_agreement_per_vendor.png'
    plt.savefig(fname_fig, dpi=200)
    logger.info('Created: ' + fname_fig)


def generate_figure_t1_t2_plotly(df, csa_t1, csa_t2):
    """
    Generate inteactive CSA_T1w vs. CSA_T2w figure
    :param df:
    :param csa_t1:
    :param csa_t2:
    :return:
    """

    # Sort values per vendor
    site_sorted = df.sort_values(by=['vendor', 'model', 'site']).index.values
    vendor_sorted = df['vendor'][site_sorted].values

    # Create dictionary with CSA for T1w and T2w per vendors
    CSA_dict = defaultdict(list)
    # loop across sites
    for index, line in enumerate(csa_t1):
        vendor = line[1]
        # Loop across subjects, making sure to only populate the dictionary with subjects existing both for T1 and T2
        for subject in csa_t1[index][4]:
            if subject in csa_t2[index, 4]:
                CSA_dict[vendor + '_t1'].append(csa_t1[index, 3][csa_t1[index, 4].index(subject)])
                CSA_dict[vendor + '_t2'].append(csa_t2[index, 3][csa_t2[index, 4].index(subject)])
    
    fig_v = go.Figure()
    # Loop across vendors
    for vendor in list(OrderedDict.fromkeys(vendor_sorted)):
        fig_v.add_trace(go.Scatter(
            x=CSA_dict[vendor + '_t2'],
            y=CSA_dict[vendor + '_t1'],
            mode='markers',
            marker=dict(symbol="circle-open", size=10),
            marker_color=vendor_to_color[vendor],
            name=vendor
            ))
    x = np.linspace(50, 100, 50)
    y = np.linspace(50, 100, 50)
    fig_v.add_trace(go.Scatter(x=x, y=y, line=dict(color='black', width=2, dash='dash'), showlegend=False))
    fig_v.update_layout(
        showlegend=True,
        yaxis_title="T1w CSA",
        xaxis_title="T2w CSA"
    )

    fig_v.update_yaxes(range=[50, 100])
    fig_v.update_xaxes(range=[50, 100])
    fig_v.update_layout(width=700, height=700)

    fig_v.write_html("fig_t1_t2_agreement.html")

    # Figure T1w vs t2w per vendor
    fig_2 = go.Figure()
    fig_2 = make_subplots(rows=1, cols=3)
    i = 1
    # Loop across vendors (create subplot for each vendor)
    for index, vendor in enumerate(list(OrderedDict.fromkeys(vendor_sorted))):
        x = CSA_dict[vendor + '_t2']
        y = CSA_dict[vendor + '_t1']
        fig_2.add_trace(
            go.Scatter(
                x=x,
                y=y,
                mode='markers',
                marker=dict(symbol="circle-open", size=10),
                marker_color=vendor_to_color[vendor],
                name=vendor,
                showlegend=False),
                row=1, col=i
        )

        # Dynamic scaling of individual subplots based on data
        offset = 2
        lim_min = min(min(x), min(y))
        lim_max = max(max(x), max(y))

        fig_2.update_yaxes(range=[lim_min - offset, lim_max + offset], title_text="T1w CSA", row=1, col=i)
        fig_2.update_xaxes(range=[lim_min - offset, lim_max + offset], title_text="T2w CSA", row=1, col=i)

        # Add bisection (diagonal) line
        fig_2.add_trace(go.Scatter(
                x=[lim_min-offset, lim_max+offset], 
                y=[lim_min-offset, lim_max+offset], 
                line=dict(color='black', width=1, dash='dash'), 
                showlegend=False), 
            row=1, col=i
        )

        # Compute linear fit
        linear_regression = LinearRegression()
        # perform linear regression (compute slope and intercept)
        linear_regression.fit((np.array(x).reshape(-1, 1)).reshape(-1, 1), (np.array(y).reshape(-1, 1)).reshape(-1, 1))
        intercept = linear_regression.intercept_
        slope = linear_regression.coef_
        # compute prediction
        reg_predictor = linear_regression.predict(np.array(x).reshape(-1, 1))

        # Plot linear fit
        x_vals = np.linspace(50, 100, 50)
        y_vals = np.squeeze(intercept + (slope * x_vals))
        fig_2.add_trace(go.Scatter(
                x=x_vals, 
                y=y_vals, 
                line=dict(color='red', width=1), 
                showlegend=False, name='regression'),
            row=1, col=i
        )
        i=i+1

    fig_2.write_html("fig_t1_t2_agreement_per_vendor.html")


def get_env(file_param):
    """
    Get shell environment variables from a shell script.
    Source: https://stackoverflow.com/a/19431112
    :param file_param:
    :return: env: dictionary of all environment variables declared in the shell script
    """
    logger.debug("\nFetch environment variables from file: {}".format(file_param))
    env = {}
    p = subprocess.Popen('env', stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    oldEnv = p.communicate()[0].decode('utf-8')
    p = subprocess.Popen('source {} ; env'.format(file_param), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                         shell=True)
    newEnv = p.communicate()[0].decode('utf-8')
    for newStr in newEnv.split('\n'):
        flag = True
        for oldStr in oldEnv.split('\n'):
            if newStr == oldStr:
                # not exported by setenv.sh
                flag = False
                break
        if flag:
            # exported by setenv.sh
            logger.debug("  {}".format(newStr))
            # add to dictionary
            env[newStr.split('=')[0]] = newStr.split('=')[1]
    return env


def remove_subject(subject, metric, dict_exclude_subj):
    """
    Check if subject should be removed
    :param subject:
    :param metric:
    :param dict_exclude_subj:
    :return: Bool
    """
    if metric in dict_exclude_subj.keys():
        if subject in dict_exclude_subj[metric]:
            return True
    return False


def main(argv=sys.argv[1:]):
    parser = get_parser()
    args = parser.parse_args(argv)
    if args.v:
        logger.setLevel(logging.DEBUG)

    display_individual_subjects = args.no_sub

    # create dict with subjects to exclude if input yml config file is passed
    if args.exclude is not None:
        # check if input yml file exists
        if os.path.isfile(args.exclude):
            fname_yml = args.exclude
        else:
            sys.exit("ERROR: Input yml file {} does not exist or path is wrong.".format(args.exclude))

        # fetch input yml file as dict
        with open(fname_yml, 'r') as stream:
            try:
                dict_exclude_subj = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                logger.error(exc)
    else:
        # initialize empty dict if no config yml file is passed
        dict_exclude_subj = dict()

    if args.path_results is not None:
        if os.path.isdir(args.path_results):
            # Go to results directory defined by user
            os.chdir(args.path_results)
        else:
            raise FileNotFoundError("Directory '{}' was not found.".format(args.path_results))

    # Dump log file there
    if os.path.exists(FNAME_LOG):
        os.remove(FNAME_LOG)
    fh = logging.FileHandler(os.path.join(os.path.abspath(os.curdir), FNAME_LOG))
    logging.root.addHandler(fh)

    # Compute age statistics and write them at the beginning of output txt file
    compute_age_statistics()

    # loop across individual *.csv files and generate figures and compute statistics
    for csv_file in file_to_metric.keys():

        # skip metric, if *.csv file does not exist
        if not os.path.isfile(csv_file):
            logger.info('\n{} file is missing. Skipping to the next metric.'.format(csv_file))
            continue

        # Open CSV file and create dict
        logger.info("\n{}\n====================================================".format(csv_file))
        dict_results = []
        with open(csv_file, newline='') as f_csv:
            reader = csv.DictReader(f_csv)
            for row in reader:
                dict_results.append(row)

        # Fetch metric name
        _, csv_file_small = os.path.split(csv_file)
        metric = file_to_metric[csv_file_small]

        # Fetch mean, std, etc. per site
        results_dict = aggregate_per_site(dict_results, metric, dict_exclude_subj)

        # Make it a pandas structure (easier for manipulations)
        df = pd.DataFrame.from_dict(results_dict, orient='index')

        # Add column to DF with excluded sites
        df['exclude'] = False
        if metric in dict_exclude_subj.keys():
            for subject in dict_exclude_subj[metric]:
                if not subject.startswith('sub-'):
                    df['exclude'][subject] = True

        # Excluded sites
        logger.info('Sites removed: {}'.format(list(df[df['exclude'] == True]['site'].values)))

        # Compute statistics
        df, stats = compute_statistics(df)

        # Write statistical results into text file
        if args.output_text:
            output_text(stats)

        # Generate figure
        generate_figure_metric(df, metric, stats, display_individual_subjects, show_ci=args.show_ci)

        if args.output_html:
            # Generate interactive html figure
            generate_figure_metric_plotly(df, metric, stats)

        # Get T1w and T2w CSA (will be used later for another figure)
        if metric == "csa_t1":
            csa_t1 = df.sort_values('site').values
        elif metric == "csa_t2":
            csa_t2 = df.sort_values('site').values

    # Generate T1w vs. T2w figure
    generate_figure_t1_t2(df, csa_t1, csa_t2)

    if args.output_html:
        # Generate interactive html T1w vs. T2w figure
        generate_figure_t1_t2_plotly(df, csa_t1, csa_t2)


if __name__ == "__main__":
    main()

