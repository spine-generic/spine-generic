clear all;

%addpath('/home/range1-raid1/labounek/toolbox/matlab/spm12')
%addpath('/home/range1-raid1/labounek/toolbox/matlab/NIfTI_tools')

data_folder='/home/range1-raid1/labounek/data-on-porto/spine-generic/results/fs/sub-cmrra06/mri';
spine_folder = '/home/range1-raid1/labounek/data-on-porto/spine-generic/results/data-multi-subject_20231213/data_processed/sub-cmrra06/anat';

t1_filename = 'T1';
aseg_filename = 'aseg';
wmseg_filename = 'sub-cmrra06_T2star_rms_wmseg';

t1_file = fullfile(data_folder,t1_filename);
aseg_file = fullfile(data_folder,aseg_filename);
wmseg_file = fullfile(spine_folder,wmseg_filename);

t1 = importnifti(t1_file,1);
aseg = importnifti(aseg_file,1);
wmseg = importnifti(wmseg_file,1);

csa_corr_map = zeros(size(aseg));
height_corr_map = zeros(size(aseg));
height_sccorr_map = zeros(size(wmseg));

aseg_label{1,1} = 16; %brainstem
aseg_label{2,1} = [10 49 11 50 86 12 13 51 52 17 53 18 54 26 58 28 60]; %subcortgmvol
aseg_label{3,1}  = [2 41 251 252 253 254 255]; %corticalwmvol
aseg_label{4,1}  = [3 42]; %corticalgmvol
aseg_label{5,1}  = [7 46 8 47]; %cerebellumvol

csawm_corr(1,1) = 0.640;
csawm_corr(2,1) = 0.520;
csawm_corr(3,1) = 0.500;
csawm_corr(4,1) = 0.449;
csawm_corr(5,1) = 0.433;

height_corr(1,1) = 0.531;
height_corr(2,1) = 0.522;
height_corr(3,1) = 0.523;
height_corr(4,1) = 0.583;
height_corr(5,1) = 0.546;

for rid = 1:size(aseg_label,1)
    for lid = 1:size(aseg_label{rid,1},2)
        csa_corr_map(aseg==aseg_label{rid,1}(lid)) = csawm_corr(rid,1);
        height_corr_map(aseg==aseg_label{rid,1}(lid)) = height_corr(rid,1);
    end
end

height_sccorr_map(wmseg==1) = 0.437;

info = getniftiinfo(aseg_file,1);
info.Datatype = 'double';
% info2 = getniftiinfo('/home/porto-raid2/nestrasil-data/baby-infant/results/dmri79.backup20220718/20180502-ST001-MNBCP439083-v02-1-4mo/dti_MD',1);
niftiwrite(csa_corr_map, fullfile(data_folder,'csa_corr_map.nii'), info)
niftiwrite(height_corr_map, fullfile(data_folder,'height_corr_map.nii'), info)

infosc = getniftiinfo(wmseg_file,1);
infosc.Datatype = 'double';
niftiwrite(height_sccorr_map, fullfile(data_folder,'height_sccorr_map.nii'), infosc)

function vol = importnifti(nifti_file,gz)
    if gz == 1
        gunzip([nifti_file '.nii.gz']);
    end
%     nifti_file_hdr = spm_vol([nifti_file '.nii']);
%     vol = spm_read_vols(nifti_file_hdr);
    vol=niftiread([nifti_file '.nii']);
    if gz == 1
        delete([nifti_file '.nii']);
    end
end

function info = getniftiinfo(nifti_file,gz)
    if gz == 1
        gunzip([nifti_file '.nii.gz']);
    end
    info = niftiinfo([nifti_file '.nii']);
    if gz == 1
        delete([nifti_file '.nii']);
    end
end