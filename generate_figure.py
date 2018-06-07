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
import matplotlib.pyplot as plt

# Create a dictionary of centers: key: folder name, value: dataframe name
centers = {'20171128_glen': 'Ingenia-Glen',
           '20180529_julien-ge': 'MR750w-Juntendo',
           '20171207_ucl': 'Achieva-UCL',
           '20180524_julien-philips': 'Achieva-Juntendo',
           '20171127_douglas': 'Trio-Douglas',
           '20171221_poly': 'Skyra-Polytechnique',
           '20171209_oxford': 'Prisma-Oxford',
           '20171201_mgh-bay3': 'Trio-MGH',
           '20180509_julien-skyra': 'Skyra-Juntendo',
           '20180523_julien-prisma': 'Prisma-Juntendo'
           }

# color to assign to each MRI model for the figure
colors = {'750': 'black',
          'HDxt': 'black',
          'Ingenia': 'dodgerblue',
          'Achieva': 'dodgerblue',
          'Trio': 'limegreen',
          'Skyra': 'limegreen',
          'Prisma': 'limegreen',
          }

# path to metric based on contrast
file_metric = {'t1': 'csa/csa_mean.xls',
               't2': 'csa/csa_mean.xls',
               'dmri': 'fa.xls',
               'mt': 'mtr.xls',
               't2s': 'csa/csa_mean.xls'
               }


def get_parameters():
    parser = argparse.ArgumentParser(description='Generate a figure to display metric values across centers.')
    parser.add_argument("-c", "--contrast",
                        help="Contrast for which figure should be generated.")
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

    # Initialize pandas series
    results_per_center = pd.Series(index=centers.values())

    list_colors = []
    # Generate figure and results file for contrast
    # if contrast == 't1':
    for folder_center, name_center in centers.iteritems():
        # Read in metric results for contrast
        data = pd.read_excel(os.path.join(folder_dir, folder_center, contrast, file_metric[contrast]), parse_cols="G")
        # Add results to dataframe
        results_per_center[name_center] = data['MEAN across slices'].values[0]
        list_colors.append(get_color(name_center))

    # Write results to file
    results_per_center.to_csv(file_output)

    # Generate figure for results
    fig, ax = plt.subplots(figsize=(8, 8))
    results_per_center.plot(kind='bar', color=list_colors, legend=False, fontsize=15, align='center')
    # fig.set_xlabel("Center", fontsize=15, rotation='horizontal')
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg and align at end
    ax.set_xticklabels(centers.values())
    plt.ylabel("CSA ($mm^2$)", fontsize=15)
    plt.grid(axis='y')
    plt.title(contrast)
    plt.tight_layout()  # make sure everything fits
    plt.savefig('fig_'+contrast+'.png')
    plt.show()


if __name__ == "__main__":
    args = get_parameters()
    contrast = args.contrast
    main()
