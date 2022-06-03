function [tbl, r, p, r_norm, p_norm, fs_r, fs_p, fs_r_norm, fs_p_norm, thick_r, thick_p, thick_r_norm, thick_p_norm, r_HW, p_HW, pttest2_AHW, pttest2_csa] = sg_structure_versus_demography(path_results,path_data)
%SG_STRUCTURE_VERSUS_DEMOGRAPHY Summary of this function goes here
%   Detailed explanation goes here

    include_body_indexes = 0;

    tick_csa = 35:5:100;
    tick_csagm = 8:2:20;
    tick_age = 20:5:55;
    tick_height = 150:10:200;
    tick_weight = 50:15:140;
    
    tick_csa = {tick_csa; tick_csa; tick_csagm};
    tick_dwi = {0.55:0.05:0.8; 0.5:0.1:1.3; 0.3:0.1:0.8}; % {FA-range; MD-range; RD-range}
    tick_mtr = {30:5:60; 30:5:60; 30:5:60};
    tick_dwimtr = {0.5:0.1:1.3; 0.3:0.1:0.8; 30:5:60};
%     tick_fs = {16000:2000:30000; 1000000:100000:1500000; 3.6e5:0.5e5:6.4e5; 3.5e5:0.5e5:7.0e5; 50000:5000:85000; 5.2e5:0.5e5:8.2e5; 2500:500:7000; 0.8e5:0.1e5:1.6e5; 1e5:0.2e5:2.0e5; 1.7e4:0.2e4:2.7e4; 1.3e4:0.2e4:2.3e4; 2.2:0.05:2.6};
    tick_fs = {1000000:100000:1500000; 5.2e5:0.5e5:8.2e5; 3.6e5:0.5e5:6.4e5; 3.5e5:0.5e5:7.0e5; 50000:5000:85000; 1.3e4:0.2e4:2.3e4; 1e5:0.2e5:2.0e5; 16000:2000:30000};
    tick_thick = {2:0.1:3; 1:0.1:3; 1:0.1:3; 16000:2000:39000; 11000:2000:29000};

    text_age = 'Age [y.o.]';
    text_height = 'Height [cm]';
    text_weight = 'Weight [kg]';
    if include_body_indexes == 1
        tick_bmi = 18:3:33;
        tick_bsa = 38:4:68;
        tick_lbw = 35:10:75;
        text_bmi = 'Body Mass Index';
        text_bsa = 'Body Surface Area';
        text_lbw = 'Lean Body Weight [kg]';
        tick_demography = {tick_age; tick_height; tick_weight; tick_bmi; tick_bsa; tick_lbw};
        demography_name={text_age,text_height,text_weight,text_bmi,text_bsa,text_lbw};
        fig_dimensions = [10 50 2500 1100];
    else
        tick_demography = {tick_age; tick_height; tick_weight};
        demography_name={text_age,text_height,text_weight};
        fig_dimensions = [10 50 1450 1250];
    end
    fig_biplot_size=[10 50 2350 1250];
    
    csv_path=fullfile(path_results,'results');
    
    participants = sg_load_participants(fullfile(csv_path,'participants.tsv'));
    
    yml = ReadYaml(fullfile(path_data,'exclude.yml'));
    
    
    demography = zeros(size(participants.age,1),size(demography_name,2));
    demography(:,1)=participants.age;
    
%     csa_filename = {'csa-SC_T1w.csv', 'csa-SC_T2w.csv', 'csa-GM_T2s.csv'};
%     csa_name = {'CSA-SC-T1w-C23 [mm^2]', 'CSA-SC-T2w-C23 [mm^2]' 'CSA-GM-T2star-C34 [mm^2]'};
%     csa_lvl = {'2:3', '2:3', '3:4'};
%     csa_excl = {yml.csa_t1, yml.csa_t2, yml.csa_gm};

%     csa_filename = {'csa-SC_T1w_c34.csv', 'csa-SC_T2w_c34.csv', 'csa-GM_T2s.csv'};
%     csa_name = {'CSA-SC-T1w-C34 [mm^2]', 'CSA-SC-T2w-C34 [mm^2]', 'CSA-GM-T2star-C34 [mm^2]'};
%     csa_lvl = {'3:4', '3:4', '3:4'};
%     csa_excl = {yml.csa_t1, yml.csa_t2, yml.csa_gm};

    csa_filename = {'csa-SC_T2w_c34.csv', 'csa-SC_T2s.csv', 'csa-GM_T2s.csv'};
%     csa_filename = {'csa-SC_T2s.csv', 'csa-SC_T2s.csv', 'csa-GM_T2s.csv'};
    csa_name = {'CSA-SC [mm^2]', 'CSA-WM [mm^2]', 'CSA-GM [mm^2]'};
    csa_lvl = {'3:4', '3:4', '3:4'};
    csa_excl = {yml.csa_t2, yml.csa_gm, yml.csa_gm};
    
    dwi_filename = {'DWI_FA.csv', 'DWI_MD.csv', 'DWI_RD.csv'};
    dwi_name = {'FA-WM-C25', 'MD-WM-C25 [*10^{-9}m^2/s]', 'RD-WM-C25 [*10^{-9}m^2/s]'};
    dwi_lvl = {'2:5', '2:5', '2:5'};
    dwi_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwilcst_filename = {'DWI_FA_LCST.csv', 'DWI_MD_LCST.csv', 'DWI_RD_LCST.csv'};
    dwilcst_name = {'FA-LCST-C25', 'MD-LCST-C25 [*10^{-9}m^2/s]', 'RD-LCST-C25 [*10^{-9}m^2/s]'};
    dwilcst_lvl = {'2:5', '2:5', '2:5'};
    dwilcst_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwidc_filename = {'DWI_FA_DC.csv', 'DWI_MD_DC.csv', 'DWI_RD_DC.csv'};
    dwidc_name = {'FA-DC-C25', 'MD-DC-C25 [*10^{-9}m^2/s]' 'RD-DC-C25 [*10^{-9}m^2/s]'};
    dwidc_lvl = {'2:5', '2:5', '2:5'};
    dwidc_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    mtr_filename = {'MTR.csv', 'MTR_LCST.csv', 'MTR_DC.csv'};
    mtr_name = {'MTR-WM-C25 [%]', 'MTR-LCST-C25 [%]', 'MTR-DC-C25 [%]'};
    mtr_lvl = {'2:5', '2:5', '2:5'};
    mtr_excl = {yml.mtr, yml.mtr, yml.mtr};

    dwimtr_name = {'MD-WM [*10^{-9}m^2/s]', 'RD-WM [*10^{-9}m^2/s]', 'MTR-WM [%]'};

    thickL_filename = {'sg.lh.aparc.stats.precentral.csv', 'sg.lh.aparc.stats.postcentral.csv'};
    thickR_filename = {'sg.rh.aparc.stats.precentral.csv', 'sg.rh.aparc.stats.postcentral.csv'};
    thick_name = {'Precentral Thickness [mm]', 'Postcentral Thickness [mm]'};
    thick_lvl = {'brain', 'brain'};
    thick_excl = {cell(0,0), cell(0,0)};
    thickGMvol_name = {'PrecentralGMVol [mm^3]', 'PostcentralGMVol [mm^3]'};

    
    corr_text = {'all: r=', 'female: r=', 'male: r='};
    
    age_pos = strcmp(demography_name,text_age)==1;
    height_pos = strcmp(demography_name,text_height)==1;
    weight_pos = strcmp(demography_name,text_weight)==1;
    
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
    end
    [r_HW, p_HW]= corrcoef(demography(:,weight_pos),demography(:,height_pos),'Rows','Pairwise');r_HW=r_HW(1,2);p_HW=p_HW(1,2);
    [~, pttest2_AHW] = ttest2( demography(strcmp(participants.sex,'M'),age_pos) , demography(strcmp(participants.sex,'F'),age_pos) );
    [~, pttest2_AHW(1,2)] = ttest2( demography(strcmp(participants.sex,'M'),height_pos) , demography(strcmp(participants.sex,'F'),height_pos) );
    [~, pttest2_AHW(1,3)] = ttest2( demography(strcmp(participants.sex,'M'),weight_pos) , demography(strcmp(participants.sex,'F'),weight_pos) );
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
    females = sum(strcmp(participants.sex,'F'));
    males = size(demography,1)-females;
    sex_stat = [size(demography,1) females males];
    manufacturer_stats = [ sum(strcmp(participants.manufacturer,'Siemens')) sum(strcmp(participants.manufacturer,'Philips')) sum(strcmp(participants.manufacturer,'GE')) ];


    csa = sg_extract_csv(csa_name,csv_path,csa_filename,csa_lvl,'MEAN(area)',participants,csa_excl);
    if strcmp(csa_name{1,2}(5:6),'WM')
        csa(:,2) = csa(:,2) - csa(:,3);
    end
    pttest2_csa = zeros(size(csa,2),3);
    for ind = 1:size(csa,2)
        [~, pttest2_csa(ind,1)] = ttest2( csa(strcmp(participants.manufacturer,'Siemens'),ind), csa(strcmp(participants.manufacturer,'Philips'),ind) );
        [~, pttest2_csa(ind,2)] = ttest2( csa(strcmp(participants.manufacturer,'Siemens'),ind), csa(strcmp(participants.manufacturer,'GE'),ind) );
        [~, pttest2_csa(ind,3)] = ttest2( csa(strcmp(participants.manufacturer,'Philips'),ind), csa(strcmp(participants.manufacturer,'GE'),ind) );
    end
    
    dwi = sg_extract_csv(dwi_name,csv_path,dwi_filename,dwi_lvl,'WA()',participants,dwi_excl);
    dwi(:,2:3) = 1000*dwi(:,2:3);
    
    dwilcst = sg_extract_csv(dwilcst_name,csv_path,dwilcst_filename,dwilcst_lvl,'WA()',participants,dwilcst_excl);
    dwilcst(:,2:3) = 1000*dwilcst(:,2:3);
    
    dwidc = sg_extract_csv(dwidc_name,csv_path,dwidc_filename,dwidc_lvl,'WA()',participants,dwidc_excl);
    dwidc(:,2:3) = 1000*dwidc(:,2:3);
    
    mtr = sg_extract_csv(mtr_name,csv_path,mtr_filename,mtr_lvl,'WA()',participants,mtr_excl);

    dwimtr = [dwi(:,2:3), mtr(:,1)];
    sc_data = [csa, dwimtr];
    sc_data_name = [csa_name, dwimtr_name];

%     [fs, fs_name] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),[12 48 52 55 56 57 69 71 72 74 75 79],participants);
    [fs, fs_name] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),[47 57 52 55 56 75 72 12],participants);
    fs_name{1,strcmp(fs_name,'Total cerebellum')} = 'CerebellumVol';
    fs_name{1,strcmp(fs_name,'Brain-Stem')} = 'BrainStemVol';
    fs_name{1,strcmp(fs_name,'Thalamus')} = 'ThalamusVol';
    fs_name{1,strcmp(fs_name,'CorticalWhiteMatterVol')} = 'CorticalWMVol';
    fs_name{1,strcmp(fs_name,'SubCortGrayVol')} = 'SubCortGMVol';
    fs_name{1,strcmp(fs_name,'TotalGrayVol')} = 'BrainGMVol';
    fs_name{1,strcmp(fs_name,'BrainSegVol')} = 'BrainVol';
    for fsid = 1:size(fs,2)
        fs_name{1,fsid} = [fs_name{1,fsid} ' [mm^3]'];
    end

    thickL = sg_extract_csv(thick_name,csv_path,thickL_filename,thick_lvl,'ThickAvg',participants,thick_excl);
    thickR = sg_extract_csv(thick_name,csv_path,thickR_filename,thick_lvl,'ThickAvg',participants,thick_excl);
    thick = (thickL + thickR) / 2;
    [tmp, ~] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),79,participants);
    thickL = sg_extract_csv(thickGMvol_name,csv_path,thickL_filename,thick_lvl,'GrayVol',participants,thick_excl);
    thickR = sg_extract_csv(thickGMvol_name,csv_path,thickR_filename,thick_lvl,'GrayVol',participants,thick_excl);
    thickGMvol = thickL + thickR;
    thick = [tmp thick thickGMvol];
    thick_name = [ {'Cortical Thickness [mm]'} thick_name thickGMvol_name];
    
    [r(:,:,:,1),p(:,:,:,1),r_norm(:,:,:,1),p_norm(:,:,:,1)] = sg_draw_corrplot_loop(demography,csa,demography_name,csa_name,participants,1,fig_dimensions,'All',tick_demography,tick_csa,fullfile(csv_path,'fig_corr_body_csa'));
    [r(:,:,:,2),p(:,:,:,2),r_norm(:,:,:,2),p_norm(:,:,:,2)] = sg_draw_corrplot_loop(demography,dwimtr,demography_name,dwimtr_name,participants,2,fig_dimensions,'GEout',tick_demography,tick_dwimtr,fullfile(csv_path,'fig_corr_body_dtimtr'));
    [r(:,:,:,3),p(:,:,:,3),r_norm(:,:,:,3),p_norm(:,:,:,3)] = sg_draw_corrplot_loop(demography,dwi,demography_name,dwi_name,participants,3,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti'));
    [r(:,:,:,4),p(:,:,:,4),r_norm(:,:,:,4),p_norm(:,:,:,4)] = sg_draw_corrplot_loop(demography,dwilcst,demography_name,dwilcst_name,participants,4,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_lcst'));
    [r(:,:,:,5),p(:,:,:,5),r_norm(:,:,:,5),p_norm(:,:,:,5)] = sg_draw_corrplot_loop(demography,dwidc,demography_name,dwidc_name,participants,5,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_dc'));
    [r(:,:,:,6),p(:,:,:,6),r_norm(:,:,:,6),p_norm(:,:,:,6)] = sg_draw_corrplot_loop(demography,mtr,demography_name,mtr_name,participants,6,fig_dimensions,'GEout',tick_demography,tick_mtr,fullfile(csv_path,'fig_corr_body_mtr'));
    
    [fs_r(:,:,:,1),fs_p(:,:,:,1),fs_r_norm(:,:,:,1),fs_p_norm(:,:,:,1)] = sg_draw_corrplot_loop(fs(:,1:4),csa,fs_name(1:4),csa_name,participants,7,[10 50 1935 1200],'All',tick_fs(1:4),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_1'));
    [fs_r(:,:,:,2),fs_p(:,:,:,2),fs_r_norm(:,:,:,2),fs_p_norm(:,:,:,2)] = sg_draw_corrplot_loop(fs(:,5:end),csa,fs_name(5:end),csa_name,participants,8,[10 50 1935 1200],'All',tick_fs(5:end),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_2'));
    [fs_r(:,:,:,3),fs_p(:,:,:,3),fs_r_norm(:,:,:,3),fs_p_norm(:,:,:,3)] = sg_draw_corrplot_loop(fs(:,1:4),dwimtr,fs_name(1:4),dwimtr_name,participants,9,[10 50 1935 1200],'GEout',tick_fs(1:4),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_1'));
    [fs_r(:,:,:,4),fs_p(:,:,:,4),fs_r_norm(:,:,:,4),fs_p_norm(:,:,:,4)] = sg_draw_corrplot_loop(fs(:,5:end),dwimtr,fs_name(5:end),dwimtr_name,participants,10,[10 50 1935 1200],'GEout',tick_fs(5:end),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_2'));

    [thick_r(:,:,:,1),thick_p(:,:,:,1),thick_r_norm(:,:,:,1),thick_p_norm(:,:,:,1)] = sg_draw_corrplot_loop(thick,csa,thick_name,csa_name,participants,11,[10 50 2415 1200],'All',tick_thick,tick_csa,fullfile(csv_path,'fig_corr_thick_csa'));
    [thick_r(:,:,:,2),thick_p(:,:,:,2),thick_r_norm(:,:,:,2),thick_p_norm(:,:,:,2)] = sg_draw_corrplot_loop(thick,dwimtr,thick_name,dwimtr_name,participants,12,[10 50 2415 1200],'GEout',tick_thick,tick_dwimtr,fullfile(csv_path,'fig_corr_thick_dwimtr'));

    
    sc_data_manufacturer_mean = zeros(size(sc_data));
    for ind = 1:size(sc_data,2)
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'Siemens'),ind) = mean(sc_data(strcmp(participants.manufacturer,'Siemens'),ind),'omitnan');
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'Philips'),ind) = mean(sc_data(strcmp(participants.manufacturer,'Philips'),ind),'omitnan');
        sc_data_manufacturer_mean(strcmp(participants.manufacturer,'GE'),ind) = mean(sc_data(strcmp(participants.manufacturer,'GE'),ind),'omitnan');
    end
    sc_data_pca = sc_data - sc_data_manufacturer_mean;
%     sc_data_pca(strcmp(participants.manufacturer,'GE'),size(csa,2)+1:end)=NaN;
    data = [demography sc_data_pca fs thick];
    [pc.coeff,pc.score,pc.latent,pc.tsquared,pc.explained,pc.mu] = sg_draw_biplot(data,[demography_name sc_data_name fs_name thick_name],111,fig_biplot_size,fullfile(csv_path,'fig_pca'));
    
    tbl = sg_build_corr_table(r,p,r_norm,p_norm,fs_r,fs_p,fs_r_norm,fs_p_norm,thick_r,thick_p,thick_r_norm,thick_p_norm);
end