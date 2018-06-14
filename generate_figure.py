#!/usr/bin/env python
#
# Automatically generate a figure for generic spine data displaying metric values for a specified contrast (t1, t2, dmri, mt, or gre-me).
#
# USAGE:
# The script should be launched within the "spine_generic" folder, where all data folders are located.
# To run:
#   ${SCT_DIR}/python/bin/python ${PATH_TO_SPINE_GENERIC}/generate_figure.py -c {t1, t2, dmri, mt, t2s}
#
# OUTPUT:
# results_per_center.csv: metric results for each center
# Figure displaying results across centers
#
# DEPENDENCIES:
# - SCT
# 
# Authors: Stephanie Alley
# License: https://github.com/neuropoly/sct_pipeline/spine_generic/blob/master/LICENSE

# TODO: make -c mandatory

import os, argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Create a dictionary of centers: key: folder name, value: dataframe name
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
    'oxford_spine-generic_20171209': 'Oxford-Prisma',
    'juntendo-prisma_spine-generic_20180523': 'Juntendo-Prisma',
}

# because dictionaries are unsorted, we need to create another list to sort them
centers_order = [
    'chiba_spine-generic_20180608-750',
    'juntendo-750w_spine-generic_20180529',
    'tokyo-univ_spine-generic_20180604-750w',
    'tokyo-univ_spine-generic_20180604-signa1',
    'tokyo-univ_spine-generic_20180604-signa2',
    'ucl_spine-generic_20171207',
    'juntendo-achieva_spine-teneric_20180524',
    'glen_spine-generic_20171128',
    'tokyo-univ_spine-generic_20180604-ingenia',
    'chiba_spine-generic_20180608-ingenia',
    'mgh-bay3_spine-generic_20171201',
    'douglas_spine-generic_20171127',
    'poly_spine-generic_20171221',
    'juntendo-skyra_spine-generic_20180509',
    'tokyo-univ_spine-generic_20180604-skyra',
    'oxford_spine-generic_20171209',
    'juntendo-prisma_spine-generic_20180523',
]

# color to assign to each MRI model for the figure
colors = {
    '750': 'black',
    'Signa': 'black',
    'Ingenia': 'dodgerblue',
    'Achieva': 'dodgerblue',
    'Trio': 'limegreen',
    'Skyra': 'limegreen',
    'Prisma': 'limegreen',
}

# path to metric based on contrast
file_metric = {
    't1': 'csa/csa_mean.xls',
    't2': 'csa/csa_mean.xls',
    'dmri': 'fa.xls',
    'mt': 'mtr.xls',
    't2s': 'csa/csa_mean.xls',
}


def get_parameters():
    parser = argparse.ArgumentParser(description='Generate a figure to display metric values across centers.')
    parser.add_argument("-c", "--contrast",
                        help="Contrast for which figure should be generated.")
    parser.add_argument("-l", "--levels",
                        help='Index of vertebral levels to include (will average them all). Separate with ",". '
                             'Example: -l 0,1,2,3')
    args = parser.parse_args()
    return args


def get_color(center_name):
    """
    Find color based on MRI system
    :param center_name: should include MRI vendor model
    :return: str: color for colorbar
    """
    for system, color in colors.iteritems():
        if system in center_name:
            return color


def main():
    # Data folder containing all centers. Here we assume that user launches the script within the folder that contains
    # all the data.
    folder_dir = os.path.abspath(os.curdir)  # '/Volumes/projects/generic_spine_procotol/data'
    file_output = "results_per_center.csv"

    # parse levels
    ind_levels = map(int, levels.split(','))  # split string into list and convert to list ot int

    # order centers dictionary for custom display
    from collections import OrderedDict
    centers_ordered = OrderedDict(sorted(centers.items(), key=lambda i: centers_order.index(i[0])))

    # Initialize pandas series
    results_per_center = pd.Series(index=centers_ordered.values())

    list_colors = []
    # Generate figure and results file for contrast
    # if contrast == 't1':
    for folder_center, name_center in centers_ordered.iteritems():
        # Read in metric results for contrast
        data = pd.read_excel(os.path.join(folder_dir, folder_center, contrast, file_metric[contrast]), parse_cols="G")
        # Add results to dataframe
        results_per_center[name_center] = np.mean(data['MEAN across slices'].values[ind_levels])
        list_colors.append(get_color(name_center))

    # Write results to file
    results_per_center.to_csv(file_output)

    # Generate figure for results
    fig, ax = plt.subplots(figsize=(12, 8))
    results_per_center.plot(kind='bar', color=list_colors, legend=False, fontsize=15, align='center')
    # fig.set_xlabel("Center", fontsize=15, rotation='horizontal')
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg and align at end
    ax.set_xticklabels(centers_ordered.values())
    plt.ylabel("CSA ($mm^2$)", fontsize=15)
    plt.grid(axis='y')
    plt.title(contrast)
    plt.tight_layout()  # make sure everything fits
    plt.savefig('fig_'+contrast+'_levels'+levels+'.png')
    # plt.show()


if __name__ == "__main__":
    args = get_parameters()
    contrast = args.contrast
    levels = args.levels
    main()
