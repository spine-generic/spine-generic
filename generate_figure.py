#!/usr/bin/env python
#
# Automatically generate a figure for generic spine data displaying metric values for a specified contrast (t1, t2, dmri, mt, or gre-me).
#
# USAGE:
# The script should be launched using SCT's python:
#   ${SCT_DIR}/python/bin/python ${PATH_TO_SPINE_GENERIC}generate_figure.py -c contrast
#
# OUTPUT:
# results_per_center.csv: metric results for each center
# Figure displaying results across centers
#
# Authors: Stephanie Alley
# License: https://github.com/neuropoly/sct_pipeline/spine_generic/blob/master/LICENSE

import os, argparse
import pandas as pd
import matplotlib.pyplot as plt

def get_parameters():
    parser = argparse.ArgumentParser(description='Generate a figure to display metric values across centers.')
    parser.add_argument("-c", "--contrast",
                        help="Contrast for which figure should be generated.")
    args = parser.parse_args()
    return args

def main():
	# Data folder containing all centers
    folder_dir = '/Volumes/projects/generic_spine_procotol/data'
    # Folder name for each center
    folder_list = ['20171128_glen', '20171207_ucl', '20171127_douglas', '20171221_poly', '20171209_oxford']
    # Column labels in dataframe
    centers = ['Ingenia-Glen', 'Achieva-UCL', 'Trio-Douglas', 'Skyra-Polytechnique', 'Prisma-Oxford']
    # Row labels in dataframe
    if contrast == 't1' or contrast == 't2':
        vert_levels = ['C2', 'C3', 'C4', 'C5', 'C6', 'C7']
    elif contrast == 'dmri' or contrast == 'mt':
        vert_levels = ['C2', 'C3', 'C4', 'C5']
    elif contrast == 'gre-me':
        vert_levels = ['C3', 'C4']
    # Define colors for each bar in graph
    colors = ['dodgerblue', 'dodgerblue', 'limegreen', 'limegreen', 'limegreen']
    # Output file containing metric values for all centers
    file_output = "results_per_center.csv"

    # Initialize dataframe
    results_per_center = pd.DataFrame(columns=centers, index=vert_levels)
    
    # Generate figure and results file for contrast
    if contrast == 't1':
        for folder in folder_list:
            # Read in metric results for contrast
            data = pd.read_excel(os.path.join(folder_dir, folder, contrast, 'csa/csa_mean.xls'), parse_cols = "G")
            # Add results to dataframe
            results_per_center[str(centers[folder_list.index(folder)])] = data['MEAN across slices'].values
    
        # Write results to file
        results_per_center.to_csv(file_output)

        # Generate figure for results
        fig = results_per_center.plot(kind='bar', color=colors, figsize=(8, 8), legend=True, fontsize=15, align='center')
        fig.set_xlabel("Vertebral level", fontsize=15, rotation='horizontal')
        fig.set_ylabel("CSA ($mm^2$)", fontsize=15)
        plt.title('T1w')
        plt.savefig('t1.png')
    elif contrast =='t2':
        for folder in folder_list:
            # Read in metric results for contrast
            data = pd.read_excel(os.path.join(folder_dir, folder, contrast, 'csa/csa_mean.xls'), parse_cols = "G")
            # Add results to dataframe
            results_per_center[str(centers[folder_list.index(folder)])] = data['MEAN across slices'].values
    
        # Write results to file
        results_per_center.to_csv(file_output)

        # Generate figure for results
        fig = results_per_center.plot(kind='bar', color=colors, figsize=(8, 8), legend=True, fontsize=15, align='center')
        fig.set_xlabel("Vertebral level", fontsize=15, rotation='horizontal')
        fig.set_ylabel("CSA ($mm^2$)", fontsize=15)
        plt.title('T2w')
        plt.savefig('t2.png')
    elif contrast == 'dmri':
        for folder in folder_list:
            # Read in metric results for contrast
            data = pd.read_excel(os.path.join(folder_dir, folder, contrast, 'fa.xls'), parse_cols = "I")
            # Add results to dataframe
            results_per_center[str(centers[folder_list.index(folder)])] = data['Metric value'].values
    
        # Write results to file
        results_per_center.to_csv(file_output)

        # Generate figure for results
        fig = results_per_center.plot(kind='bar', color=colors, figsize=(8, 8), legend=True, fontsize=15, align='center')
        fig.set_xlabel("Vertebral level", fontsize=15, rotation='horizontal')
        fig.set_ylabel("FA", fontsize=15)
        plt.title('DWI')
        plt.savefig('dwi.png')
    elif contrast == 'mt':
        for folder in folder_list:
            # Read in metric results for contrast
            data = pd.read_excel(os.path.join(folder_dir, folder, contrast, 'mtr.xls'), parse_cols = "I")
            # Add results to dataframe
            results_per_center[str(centers[folder_list.index(folder)])] = data['Metric value'].values
    
        # Write results to file
        results_per_center.to_csv(file_output)

        # Generate figure for results
        fig = results_per_center.plot(kind='bar', color=colors, figsize=(8, 8), legend=True, fontsize=15, align='center')
        fig.set_xlabel("Vertebral level", fontsize=15, rotation='horizontal')
        fig.set_ylabel("MTR (%)", fontsize=15)
        plt.title('MTR')
        plt.savefig('mt.png')
    elif contrast == 'gre-me':
        for folder in folder_list:
            # Read in metric results for contrast
            data = pd.read_excel(os.path.join(folder_dir, folder, contrast, 'csa/csa_mean.xls'), parse_cols = "G")
            # Add results to dataframe
            results_per_center[str(centers[folder_list.index(folder)])] = data['MEAN across slices'].values
    
        # Write results to file
        results_per_center.to_csv(file_output)

        # Generate figure for results
        fig = results_per_center.plot(kind='bar', color=colors, figsize=(8, 8), legend=True, fontsize=15, align='center')
        fig.set_xlabel("Vertebral level", fontsize=15, rotation='horizontal')
        fig.set_ylabel("CSA ($mm^2$)", fontsize=15)
        plt.title('GRE-ME')
        plt.savefig('gre-me.png')

    plt.show()

if __name__ == "__main__":
    args = get_parameters()
    contrast = args.contrast
    main()
