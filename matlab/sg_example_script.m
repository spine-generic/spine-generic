% EXAMPLE SCRIPT HOW TO EXECUTE VISUALIZATION OF RESULTS FOR THE ANALYSIS
% INVESTIGATING INFLUENCE OF BODY SIZE ON THE STRUCTURE OF THE CENTRAL
% NERVOUS SYSTEM
% 
%   OUTPUTS:
%   stat ... structure type variable consisting of all statistical analysis
%            values
%
%   The stat_labounek2022.mat file with stat variable and all graphical outputs are
%   stored in the folder fullfile(path_results,'results')
%
%   AUTHORS:
%   Rene Labounek (1), Julien Cohen-Adad (2), Christophe Lenglet (3), Igor Nestrasil (1,3)
%   email: rlaboune@umn.edu
%
%   INSTITUTIONS:
%   (1) Masonic Institute for the Developing Brain, Division of Clinical Behavioral Neuroscience, Deparmtnet of Pediatrics, University of Minnesota, Minneapolis, Minnesota, USA
%   (2) NeuroPoly Lab, Institute of Biomedical Engineering, Polytechnique Montreal, Montreal, Quebec, Canada
%   (3) Center for Magnetic Resonance Research, Department of Radiology, University of Minnesota, Minneapolis, Minnesota, USA

%% Clean matlab workspace, close all MATLAB windows/figures and clean MATLAB Command Window
clear all;
close all;
clc;
%% Set paths for necessary toolboxes
path_yamltoolbox = '/home/range1-raid1/labounek/toolbox/matlab/YAMLMatlab_0.4.3'; % Set regarding your HDD storage
path_spinegeneric = '/home/range1-raid1/labounek/git/spine-generic'; % Set regarding your HDD storage
%% Set paths to results and source data
path_results='/home/porto-raid2/nestrasil-data/spine-generic/results/data-multi-subject_20220408'; % Set regarding your HDD storage
path_data='/home/porto-raid2/nestrasil-data/spine-generic/data-multi-subject'; % Set regarding your HDD storage
%% Add MATLAB code of these toolboxes into toolbox path of the current MATLAB session
addpath(path_yamltoolbox);
addpath(fullfile(path_spinegeneric,'matlab'))
%% Execute visualization of Results of influence of body size on the structure of the central nervous system
stat = sg_structure_versus_demography(path_results,path_data);