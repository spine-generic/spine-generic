function stat = sg_structure_versus_demography(path_results,path_data)
%SG_STRUCTURE_VERSUS_DEMOGRAPHY proceeds cross-correlation anallysis
%between demographical measurements (such as age, height, weight) and
%available structural measurements of spinal cord and brain, tests
%between-group differences for selected variables via two-sample t-tests,
%estimates descriptive statistics for selected variables, and simplyfies
%variable space via principal component analysis.
%
%The SG_STRUCTURE_VERSUS_DEMOGRAPHY function also provides graphical outputs
%which are all stored in the the csv_path folder. A mat file with the
%output stat variable is also stored in the csv_path folder.
%
%   INPUTS:
%   path_results ... path to results folder generated by the spine-generic
%                    proces_data.sh shell script
%                    Typical subfolders:
%                    path_results/data_processed
%                    path_results/log
%                    path_results/qc
%                    path_results/results
%
%   path_data ... path to spine-generic raw data (looking for the exclude.yml file)
%
%   OUTPUTS:
%   stat ... structure type variable consisting of all statistical analysis
%            values
%
%   The stat_labounek2022.mat file with stat variable and all graphical outputs are
%   stored in the folder (variable) csv_path=path_results/results
%
%   AUTHOR:
%   Rene Labounek
%   email: rlaboune@umn.edu
%
%   Masonic Institute for the Developing Brain
%   Division of Clinical Behavioral Neuroscience
%   Deparmtnet of Pediatrics
%   University of Minnesota
%   Minneapolis, Minnesota, USA

    %% Basic setups
    include_body_indexes = 0;
    fig_biplot_size=[10 42 1450 1290]; % Define biplot figure dimensions

    %% Graph tick ranges:
    tick_csa = 35:5:100;      % CSA-range [mm^2]
    tick_csagm = 8:2:20;      % CSA-GM-range [mm^2]
    tick_age = 20:5:55;       % Age-range [y.o.]
    tick_height = 150:10:200; % Height-range [cm]
    tick_weight = 50:15:140;  % Weight-range [kg]
    tick_fa = 0.55:0.05:0.8;  % FA-range
    tick_md = 0.5:0.1:1.3;    % MD-range [*10^{-9}m^2/s]
    tick_rd = 0.3:0.1:0.8;    % RD-range [*10^{-9}m^2/s]
    tick_mtrrange = 30:5:60;       % MTR-range [%]
    tick_thickness = 1:0.1:3; % Thickness-range [mm]
    tick_BrainVol = 1000000:100000:1500000; % BrainVol-range [mm^3]
    tick_BrainGMVol = 5.2e5:0.5e5:8.2e5;    % BrainGMVol-range [mm^3]
    tick_CorticalGMVol = 3.6e5:0.5e5:6.4e5; % CorticalGMVol-range [mm^3]
    tick_CorticalWMVol = 3.5e5:0.5e5:7.0e5; % CorticalWMVol-range [mm^3]
    tick_SubCortGMVol = 50000:5000:85000;   % SubCortGMVol-range [mm^3]
    tick_ThalamusVol = 1.3e4:0.2e4:2.3e4;   % ThalamusVol-range [mm^3]
    tick_CerebellumVol = 1e5:0.2e5:2.0e5;   % CerebellumVol-range [mm^3]
    tick_BrainStemVol = 16000:2000:30000;   % BrainStemVol-range [mm^3]
    tick_PrecentralGMVol = 16000:2000:39000; % PrecentralGMVol-range [mm^3]
    tick_PostcentralGMVol = 11000:2000:29000; % PostcentralGMVol-range [mm^3]
    
    tick_csa = {tick_csa; tick_csa; tick_csagm};
    tick_dwi = {tick_fa; tick_md; tick_rd};
    tick_mtr = {tick_mtrrange; tick_mtrrange; tick_mtrrange};
    tick_dwimtr = {tick_md; tick_rd; tick_mtrrange};
    tick_fs = {tick_BrainVol; tick_BrainGMVol; tick_CorticalGMVol; tick_CorticalWMVol; tick_SubCortGMVol; tick_ThalamusVol; tick_CerebellumVol; tick_BrainStemVol};
    tick_thick = {tick_thickness; tick_thickness; tick_thickness; tick_PrecentralGMVol; tick_PostcentralGMVol};

    %% Graph label variables start as text_*
    text_age = 'Age [y.o.]';
    text_height = 'Height [cm]';
    text_weight = 'Weight [kg]';

    %% Set variables for analysis with or without body indexes
    if include_body_indexes == 1
        tick_bmi = 18:3:33;  %  BMI-range
        tick_bsa = 38:4:68;  %  BSA-range
        tick_lbw = 35:10:75; % LBW-range
        text_bmi = 'Body Mass Index';
        text_bsa = 'Body Surface Area';
        text_lbw = 'Lean Body Weight [kg]';
        tick_demography = {tick_age; tick_height; tick_weight; tick_bmi; tick_bsa; tick_lbw};
        demography_name={text_age,text_height,text_weight,text_bmi,text_bsa,text_lbw};
        fig_dimensions = [10 50 2500 1100]; % Define basic figure dimensions
    else
        tick_demography = {tick_age; tick_height; tick_weight};
        demography_name={text_age,text_height,text_weight};
        fig_dimensions = [10 50 1450 1250]; % Define basic figure dimensions
    end

    %% Read participants.tsv file and exclude.yml file
    csv_path=fullfile(path_results,'results');
    participants = sg_load_participants(fullfile(csv_path,'participants.tsv'));
    yml = ReadYaml(fullfile(path_data,'exclude.yml'));

    %% Define filenames and other values for spinal cord and cerebral structural measurements
    % All *.csv files are stored in the results folder

    csa_filename = {'csa-SC_T2w_c34.csv', 'csa-SC_T2s.csv', 'csa-GM_T2s.csv'};
%     csa_filename = {'csa-SC_T1w_c34.csv', 'csa-SC_T2s.csv', 'csa-GM_T2s.csv'};
%     csa_filename = {'csa-SC_T2s.csv', 'csa-SC_T2s.csv', 'csa-GM_T2s.csv'};
    csa_name = {'CSA-SC [mm^2]', 'CSA-WM [mm^2]', 'CSA-GM [mm^2]'};
    csa_lvl = {'3:4', '3:4', '3:4'};
    csa_excl = {yml.csa_t2, yml.csa_gm, yml.csa_gm};   % for SC csa-SC_T2w_c34.csv file (i.e., 1st csa_filename value)
%     csa_excl = {yml.csa_gm, yml.csa_gm, yml.csa_gm}; % for SC csa-SC_T2s.csv file (i.e., 1st csa_filename value)
%     csa_excl = {yml.csa_t1, yml.csa_gm, yml.csa_gm}; % for SC csa-SC_T1w_c34.csv file (i.e., 1st csa_filename value)
    
    dwi_filename = {'DWI_FA.csv', 'DWI_MD.csv', 'DWI_RD.csv'};
    dwi_name = {'FA-WM', 'MD-WM [*10^{-9}m^2/s]', 'RD-WM [*10^{-9}m^2/s]'};
    dwi_lvl = {'2:5', '2:5', '2:5'};
    dwi_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwilcst_filename = {'DWI_FA_LCST.csv', 'DWI_MD_LCST.csv', 'DWI_RD_LCST.csv'};
    dwilcst_name = {'FA-LCST', 'MD-LCST [*10^{-9}m^2/s]', 'RD-LCST [*10^{-9}m^2/s]'};
    dwilcst_lvl = {'2:5', '2:5', '2:5'};
    dwilcst_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwidc_filename = {'DWI_FA_DC.csv', 'DWI_MD_DC.csv', 'DWI_RD_DC.csv'};
    dwidc_name = {'FA-DC', 'MD-DC [*10^{-9}m^2/s]' 'RD-DC [*10^{-9}m^2/s]'};
    dwidc_lvl = {'2:5', '2:5', '2:5'};
    dwidc_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    mtr_filename = {'MTR.csv', 'MTR_LCST.csv', 'MTR_DC.csv'};
    mtr_name = {'MTR-WM [%]', 'MTR-LCST [%]', 'MTR-DC [%]'};
    mtr_lvl = {'2:5', '2:5', '2:5'};
    mtr_excl = {yml.mtr, yml.mtr, yml.mtr};

    dwimtr_name = {'MD-WM [*10^{-9}m^2/s]', 'RD-WM [*10^{-9}m^2/s]', 'MTR-WM [%]'};

    thickL_filename = {'sg.lh.aparc.stats.precentral.csv', 'sg.lh.aparc.stats.postcentral.csv'};
    thickR_filename = {'sg.rh.aparc.stats.precentral.csv', 'sg.rh.aparc.stats.postcentral.csv'};
    thick_name = {'PrecentralG Thickness [mm]', 'PostcentralG Thickness [mm]'};
    thick_lvl = {'brain', 'brain'};
    thick_excl = {cell(0,0), cell(0,0)};
    thickGMvol_name = {'PrecentralGMVol [mm^3]', 'PostcentralGMVol [mm^3]'};

    %% Define position (column) of age, height and weight in the demogprahy variable
    age_pos = strcmp(demography_name,text_age)==1;
    height_pos = strcmp(demography_name,text_height)==1;
    weight_pos = strcmp(demography_name,text_weight)==1;

    %% Build demography variable and fill it with demographical data + calculate bmi
    demography = zeros(size(participants.age,1),size(demography_name,2));
    demography(:,1)=participants.age;
    for ind = 1:size(participants.age,1)
        if strcmp(participants.height(ind,1),'-')
            demography(ind,height_pos) = NaN;
        else
            demography(ind,height_pos) = str2double(participants.height(ind,:));
        end
        if strcmp(participants.weight(ind,1),'-')
            demography(ind,weight_pos) = NaN;
        else
%             demography(ind,weight_pos) = str2double(participants.weight(ind,:));
            demography(ind,weight_pos) = participants.weight(ind,:);
        end
    end
    if include_body_indexes == 1
        bmi_pos = strcmp(demography_name,text_bmi)==1;
        bsa_pos = strcmp(demography_name,text_bsa)==1;
        lbw_pos = strcmp(demography_name,text_lbw)==1;
        demography(:,bmi_pos) = demography(:,weight_pos) ./ (demography(:,height_pos)/100).^2;
        
        demography(:,bsa_pos) = 0.20247 * demography(:,height_pos).^0.725 .* demography(:,weight_pos).^0.425;
        
        demography(strcmp(participants.sex,'F'),lbw_pos) = (1.07*demography(strcmp(participants.sex,'F'),weight_pos)) - 148*(demography(strcmp(participants.sex,'F'),weight_pos).^2 ./ demography(strcmp(participants.sex,'F'),height_pos).^2);
        demography(strcmp(participants.sex,'M'),lbw_pos) = (1.10*demography(strcmp(participants.sex,'M'),weight_pos)) - 128*(demography(strcmp(participants.sex,'M'),weight_pos).^2 ./ demography(strcmp(participants.sex,'M'),height_pos).^2);
    else
        bmi = demography(:,weight_pos) ./ (demography(:,height_pos)/100).^2;
    end

    %% Calculate correlation coefficient between body height and weight
    [r_HW, p_HW]= corrcoef(demography(:,weight_pos),demography(:,height_pos),'Rows','Pairwise');r_HW=r_HW(1,2);p_HW=p_HW(1,2);

    %% Two-sample t-tests examining differences between females and males in age, height, weight and BMI
    [~, pttest2_AHWB] = ttest2( demography(strcmp(participants.sex,'M'),age_pos) , demography(strcmp(participants.sex,'F'),age_pos) );
    [~, pttest2_AHWB(1,2)] = ttest2( demography(strcmp(participants.sex,'M'),height_pos) , demography(strcmp(participants.sex,'F'),height_pos) );
    [~, pttest2_AHWB(1,3)] = ttest2( demography(strcmp(participants.sex,'M'),weight_pos) , demography(strcmp(participants.sex,'F'),weight_pos) );
    if include_body_indexes == 1
        [~, pttest2_AHWB(1,4)] = ttest2( demography(strcmp(participants.sex,'M'),bmi_pos) , demography(strcmp(participants.sex,'F'),bmi_pos) );
    else
        [~, pttest2_AHWB(1,4)] = ttest2( bmi(strcmp(participants.sex,'M'),1) , bmi(strcmp(participants.sex,'F'),1) );
    end

    %% Estimate descriptive demogprahical statistics (mean, STD, median, min, max) for all participants and females/males separately
    demography_stats = mean(demography,'omitnan');
    demography_stats(2,:) = std(demography,'omitnan');
    demography_stats(3,:) = median(demography,'omitnan');
    demography_stats(4,:) = min(demography);
    demography_stats(5,:) = max(demography);
    demography_stats_females = mean(demography(strcmp(participants.sex,'F'),:),'omitnan');
    demography_stats_females(2,:) = std(demography(strcmp(participants.sex,'F'),:),'omitnan');
    demography_stats_females(3,:) = median(demography(strcmp(participants.sex,'F'),:),'omitnan');
    demography_stats_females(4,:) = min(demography(strcmp(participants.sex,'F'),:));
    demography_stats_females(5,:) = max(demography(strcmp(participants.sex,'F'),:));
    demography_stats_males = mean(demography(strcmp(participants.sex,'M'),:),'omitnan');
    demography_stats_males(2,:) = std(demography(strcmp(participants.sex,'M'),:),'omitnan');
    demography_stats_males(3,:) = median(demography(strcmp(participants.sex,'M'),:),'omitnan');
    demography_stats_males(4,:) = min(demography(strcmp(participants.sex,'M'),:));
    demography_stats_males(5,:) = max(demography(strcmp(participants.sex,'M'),:));
    if include_body_indexes == 0
        demography_stats(1,end+1) = mean(bmi,'omitnan');
        demography_stats(2,end) = std(bmi,'omitnan');
        demography_stats(3,end) = median(bmi,'omitnan');
        demography_stats(4,end) = min(bmi);
        demography_stats(5,end) = max(bmi);

        demography_stats_females(1,end+1) = mean(bmi(strcmp(participants.sex,'F'),1),'omitnan');
        demography_stats_females(2,end) = std(bmi(strcmp(participants.sex,'F'),1),'omitnan');
        demography_stats_females(3,end) = median(bmi(strcmp(participants.sex,'F'),1),'omitnan');
        demography_stats_females(4,end) = min(bmi(strcmp(participants.sex,'F'),1));
        demography_stats_females(5,end) = max(bmi(strcmp(participants.sex,'F'),1));

        demography_stats_males(1,end+1) = mean(bmi(strcmp(participants.sex,'M'),1),'omitnan');
        demography_stats_males(2,end) = std(bmi(strcmp(participants.sex,'M'),1),'omitnan');
        demography_stats_males(3,end) = median(bmi(strcmp(participants.sex,'M'),1),'omitnan');
        demography_stats_males(4,end) = min(bmi(strcmp(participants.sex,'M'),1));
        demography_stats_males(5,end) = max(bmi(strcmp(participants.sex,'M'),1));
    end
    %% Calculate male/female frequencies
    females = sum(strcmp(participants.sex,'F'));
    males = size(demography,1)-females;
    sex_stat = [size(demography,1) females males];
    %% Calculate manufacturer frequencies
    manufacturer_stats = [ sum(strcmp(participants.manufacturer,'Siemens')) sum(strcmp(participants.manufacturer,'Philips')) sum(strcmp(participants.manufacturer,'GE')) ];
    
    %% Read spinal cord CSA measurements and store them in csa variable
    csa = sg_extract_csv(csa_name,csv_path,csa_filename,csa_lvl,'MEAN(area)',participants,csa_excl);
    if strcmp(csa_name{1,2}(5:6),'WM')
        csa(:,2) = csa(:,2) - csa(:,3);
    end
    %% Two-sample t-tests examining differences in CSA measurements over manufacturers
    pttest2_csa = zeros(size(csa,2),3);
    for ind = 1:size(csa,2)
        [~, pttest2_csa(ind,1)] = ttest2( csa(strcmp(participants.manufacturer,'Siemens'),ind), csa(strcmp(participants.manufacturer,'Philips'),ind) );
        [~, pttest2_csa(ind,2)] = ttest2( csa(strcmp(participants.manufacturer,'Siemens'),ind), csa(strcmp(participants.manufacturer,'GE'),ind) );
        [~, pttest2_csa(ind,3)] = ttest2( csa(strcmp(participants.manufacturer,'Philips'),ind), csa(strcmp(participants.manufacturer,'GE'),ind) );
    end
    
    %% Read spinal cord DTI measurements (FA, MD, RD respectively) from WM ROI
    dwi = sg_extract_csv(dwi_name,csv_path,dwi_filename,dwi_lvl,'WA()',participants,dwi_excl);
    dwi(:,2:3) = 1000*dwi(:,2:3);
    %% Read spinal cord DTI measurements (FA, MD, RD respectively) from bilateral LCST ROI
    dwilcst = sg_extract_csv(dwilcst_name,csv_path,dwilcst_filename,dwilcst_lvl,'WA()',participants,dwilcst_excl);
    dwilcst(:,2:3) = 1000*dwilcst(:,2:3);
    %% Read spinal cord DTI measurements (FA, MD, RD respectively) from bilateral DC ROI
    dwidc = sg_extract_csv(dwidc_name,csv_path,dwidc_filename,dwidc_lvl,'WA()',participants,dwidc_excl);
    dwidc(:,2:3) = 1000*dwidc(:,2:3);
    %% Read spinal cord MTR measurements from WM, bilateral LCST and bilateral DC ROIs
    mtr = sg_extract_csv(mtr_name,csv_path,mtr_filename,mtr_lvl,'WA()',participants,mtr_excl);
    %% Reorganize spinal cord data of major analysis interest
    dwimtr = [dwi(:,2:3), mtr(:,1)];
    sc_data = [csa, dwimtr];
    sc_data_name = [csa_name, dwimtr_name];

    %% Read cerebral moprhological measurements from the file results/fs-measurements.xlsx
    [fs, fs_name] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),[47 57 52 55 56 75 72 12],participants);
    fs_name{1,strcmp(fs_name,'Total cerebellum')} = 'CerebellumVol';
    fs_name{1,strcmp(fs_name,'Brain-Stem')} = 'BrainStemVol';
    fs_name{1,strcmp(fs_name,'Thalamus')} = 'ThalamusVol';
    fs_name{1,strcmp(fs_name,'CorticalWhiteMatterVol')} = 'CorticalWMVol';
    fs_name{1,strcmp(fs_name,'CortexVol')} = 'CorticalGMVol';
    fs_name{1,strcmp(fs_name,'SubCortGrayVol')} = 'SubCortGMVol';
    fs_name{1,strcmp(fs_name,'TotalGrayVol')} = 'BrainGMVol';
    fs_name{1,strcmp(fs_name,'BrainSegVol')} = 'BrainVol';
    for fsid = 1:size(fs,2)
        fs_name{1,fsid} = [fs_name{1,fsid} ' [mm^3]'];
    end

    %% Read cortical thickness measurements (average them over hemispheres if necessary) and volumes of precentral and postcentral gyri
    % Final values stored in the thick variable and variable names are stored in the thick_name variable
    thickL = sg_extract_csv(thick_name,csv_path,thickL_filename,thick_lvl,'ThickAvg',participants,thick_excl);
    thickR = sg_extract_csv(thick_name,csv_path,thickR_filename,thick_lvl,'ThickAvg',participants,thick_excl);
    thick = (thickL + thickR) / 2;
    [tmp, ~] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),79,participants);
    thickL = sg_extract_csv(thickGMvol_name,csv_path,thickL_filename,thick_lvl,'GrayVol',participants,thick_excl);
    thickR = sg_extract_csv(thickGMvol_name,csv_path,thickR_filename,thick_lvl,'GrayVol',participants,thick_excl);
    thickGMvol = thickL + thickR;
    thick = [tmp thick thickGMvol];
    thick_name = [ {'Cortical Thickness [mm]'} thick_name thickGMvol_name];
    
    %% Draw figures 1-9 and store them on HDD in the folder csv_path (results)
    % Last input into the function sg_draw_corrplot_loop is the figure filename
    % r ... array of correlation coefficients from raw data
    % p ... array of p-values of correlation coefficients from raw data
    % r_norm ... array of correlation coefficients from normalized y-axis data
    % p_norm ... array of p-values of correlation coefficients from normalized y-axis data
    [r(:,:,:,1),p(:,:,:,1),r_norm(:,:,:,1),p_norm(:,:,:,1)] = sg_draw_corrplot_loop(demography,csa,demography_name,csa_name,participants,1,fig_dimensions,'All',tick_demography,tick_csa,fullfile(csv_path,'fig_corr_body_csa'));
    [r(:,:,:,2),p(:,:,:,2),r_norm(:,:,:,2),p_norm(:,:,:,2)] = sg_draw_corrplot_loop(demography,dwimtr,demography_name,dwimtr_name,participants,2,fig_dimensions,'GEout',tick_demography,tick_dwimtr,fullfile(csv_path,'fig_corr_body_dtimtr'));
    [r(:,:,:,3),p(:,:,:,3),r_norm(:,:,:,3),p_norm(:,:,:,3)] = sg_draw_corrplot_loop(demography,dwi,demography_name,dwi_name,participants,3,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti'));
    [r(:,:,:,4),p(:,:,:,4),r_norm(:,:,:,4),p_norm(:,:,:,4)] = sg_draw_corrplot_loop(demography,dwilcst,demography_name,dwilcst_name,participants,4,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_lcst'));
    [r(:,:,:,5),p(:,:,:,5),r_norm(:,:,:,5),p_norm(:,:,:,5)] = sg_draw_corrplot_loop(demography,dwidc,demography_name,dwidc_name,participants,5,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_dc'));
    [r(:,:,:,6),p(:,:,:,6),r_norm(:,:,:,6),p_norm(:,:,:,6)] = sg_draw_corrplot_loop(demography,mtr,demography_name,mtr_name,participants,6,fig_dimensions,'GEout',tick_demography,tick_mtr,fullfile(csv_path,'fig_corr_body_mtr'));
    [r(:,:,:,7),p(:,:,:,7),r_norm(:,:,:,7),p_norm(:,:,:,7)] = sg_draw_corrplot_loop(thick(:,1:3),dwilcst,thick_name(1:3),dwilcst_name,participants,7,fig_dimensions,'GEout',tick_thick(1:3),tick_dwi,fullfile(csv_path,'fig_corr_thick_dtilcst'));
    [r(:,:,:,8),p(:,:,:,8),r_norm(:,:,:,8),p_norm(:,:,:,8)] = sg_draw_corrplot_loop(thick(:,1:3),dwidc,thick_name(1:3),dwidc_name,participants,8,fig_dimensions,'GEout',tick_thick(1:3),tick_dwi,fullfile(csv_path,'fig_corr_thick_dtidc'));
    [r(:,:,:,9),p(:,:,:,9),r_norm(:,:,:,9),p_norm(:,:,:,9)] = sg_draw_corrplot_loop(thick(:,1:3),mtr,thick_name(1:3),mtr_name,participants,9,fig_dimensions,'GEout',tick_thick(1:3),tick_mtr,fullfile(csv_path,'fig_corr_thick_mtr'));

    %% Draw figures 10-15 and store them on HDD in the folder csv_path (results)
    % Last input into the function sg_draw_corrplot_loop is the figure filename
    % fs_r ... array of correlation coefficients from raw data
    % fs_p ... array of p-values of correlation coefficients from raw data
    % fs_r_norm ... array of correlation coefficients from normalized y-axis data
    % fs_p_norm ... array of p-values of correlation coefficients from normalized y-axis data
    [fs_r(:,:,:,1),fs_p(:,:,:,1),fs_r_norm(:,:,:,1),fs_p_norm(:,:,:,1)] = sg_draw_corrplot_loop(fs(:,1:4),csa,fs_name(1:4),csa_name,participants,10,[10 50 1935 1200],'All',tick_fs(1:4),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_1'));
    [fs_r(:,:,:,2),fs_p(:,:,:,2),fs_r_norm(:,:,:,2),fs_p_norm(:,:,:,2)] = sg_draw_corrplot_loop(fs(:,5:end),csa,fs_name(5:end),csa_name,participants,11,[10 50 1935 1200],'All',tick_fs(5:end),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_2'));
    [fs_r(:,:,:,3),fs_p(:,:,:,3),fs_r_norm(:,:,:,3),fs_p_norm(:,:,:,3)] = sg_draw_corrplot_loop(fs(:,1:4),dwimtr,fs_name(1:4),dwimtr_name,participants,12,[10 50 1935 1200],'GEout',tick_fs(1:4),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_1'));
    [fs_r(:,:,:,4),fs_p(:,:,:,4),fs_r_norm(:,:,:,4),fs_p_norm(:,:,:,4)] = sg_draw_corrplot_loop(fs(:,5:end),dwimtr,fs_name(5:end),dwimtr_name,participants,13,[10 50 1935 1200],'GEout',tick_fs(5:end),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_2'));
    [fs_r(:,:,:,5),fs_p(:,:,:,5),fs_r_norm(:,:,:,5),fs_p_norm(:,:,:,5)] = sg_draw_corrplot_loop(fs(:,1:4),demography,fs_name(1:4),demography_name,participants,14,[10 50 1935 1200],'All',tick_fs(1:4),tick_demography,fullfile(csv_path,'fig_corr_fs_demography_1'));
    [fs_r(:,:,:,6),fs_p(:,:,:,6),fs_r_norm(:,:,:,6),fs_p_norm(:,:,:,6)] = sg_draw_corrplot_loop(fs(:,5:end),demography,fs_name(5:end),demography_name,participants,15,[10 50 1935 1200],'All',tick_fs(5:end),tick_demography,fullfile(csv_path,'fig_corr_fs_demography_2'));

    %% Draw figures 16-18 and store them on HDD in the folder csv_path (results)
    % Last input into the function sg_draw_corrplot_loop is the figure filename
    % thick_r ... array of correlation coefficients from raw data
    % thick_p ... array of p-values of correlation coefficients from raw data
    % thick_r_norm ... array of correlation coefficients from normalized y-axis data
    % thick_p_norm ... array of p-values of correlation coefficients from normalized y-axis data
    [thick_r(:,:,:,1),thick_p(:,:,:,1),thick_r_norm(:,:,:,1),thick_p_norm(:,:,:,1)] = sg_draw_corrplot_loop(thick,csa,thick_name,csa_name,participants,16,[10 50 2415 1200],'All',tick_thick,tick_csa,fullfile(csv_path,'fig_corr_thick_csa'));
    [thick_r(:,:,:,2),thick_p(:,:,:,2),thick_r_norm(:,:,:,2),thick_p_norm(:,:,:,2)] = sg_draw_corrplot_loop(thick,dwimtr,thick_name,dwimtr_name,participants,17,[10 50 2415 1200],'GEout',tick_thick,tick_dwimtr,fullfile(csv_path,'fig_corr_thick_dwimtr'));
    [thick_r(:,:,:,3),thick_p(:,:,:,3),thick_r_norm(:,:,:,3),thick_p_norm(:,:,:,3)] = sg_draw_corrplot_loop(thick,demography,thick_name,demography_name,participants,18,[10 50 2415 1200],'All',tick_thick,tick_demography,fullfile(csv_path,'fig_corr_thick_demography'));

    %% Estimate manufacturer-specific mean for spinal cord structural measurements
    sc_data_manufacturer_mean = zeros(size(sc_data));
    for ind = 1:size(sc_data,2)
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'Siemens'),ind) = mean(sc_data(strcmp(participants.manufacturer,'Siemens'),ind),'omitnan');
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'Philips'),ind) = mean(sc_data(strcmp(participants.manufacturer,'Philips'),ind),'omitnan');
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'GE'),ind) = mean(sc_data(strcmp(participants.manufacturer,'GE'),ind),'omitnan');
    end

    %% Subtract manufacturere-specific mean from spinal cord structural measurements
    sc_data_pca = sc_data - sc_data_manufacturer_mean;

    %% Make data matrix serving as input for the principal component analysis (PCA), estimate PCA in the sg_draw_biplot function which also draw biplot projections
    data = [demography sc_data_pca fs thick];
    data_colorid = [ ones(1,size(demography,2)) 2*ones(1,size(sc_data_pca,2)/2) 3*ones(1,size(sc_data_pca,2)/2) 4*ones(1,size(fs,2)) 5*ones(1,3) 4*ones(1,2) ]; % different color-coding for different groups of variables
    [pc.coeff,pc.score,pc.latent,pc.tsquared,pc.explained,pc.mu] = sg_draw_biplot(data,[demography_name sc_data_name fs_name thick_name],111,fig_biplot_size,fullfile(csv_path,'fig_pca'),data_colorid);

    %% Extract correlation coefficients (+ its p-values) of interest and organize them into the tbl table
    tbl = sg_build_corr_table(r,p,r_norm,p_norm,fs_r,fs_p,fs_r_norm,fs_p_norm,thick_r,thick_p,thick_r_norm,thick_p_norm);

    %% Store all results into the output stat variable
    stat.demography = demography_stats;
    stat.demography_male = demography_stats_males;
    stat.demography_female = demography_stats_females;
    stat.r_fig1to9 = r;
    stat.r_fig10to15 = fs_r;
    stat.r_fig16to18 = thick_r;
    stat.r_HeightWeight = r_HW;
    stat.r_norm_fig1to9 = r_norm;
    stat.r_norm_fig10to15 = fs_r_norm;
    stat.r_norm_fig16to18 = thick_r_norm;
    stat.p_fig1to9 = p;
    stat.p_fig10to15 = fs_p;
    stat.p_fig16to18 = thick_p;
    stat.p_HeightWeight = p_HW;
    stat.p_norm_fig1to9 = p_norm;
    stat.p_norm_fig10to15 = fs_p_norm;
    stat.p_norm_fig16to18 = thick_p_norm;  
    stat.p_ttest2_AgeHeightWeightBmi_MALEvsFEMALE = pttest2_AHWB;
    stat.p_ttest2_CSA_MALEvsFEMALE = pttest2_csa;
    stat.manufacturer = manufacturer_stats;
    stat.pca = pc;
    stat.sex = sex_stat;
    stat.tbl = tbl;  

    %% Save the results in  the stat variable as .mat file at HDD
    save(fullfile(csv_path,'stat_labounek2022.mat'),'stat','-mat')
end