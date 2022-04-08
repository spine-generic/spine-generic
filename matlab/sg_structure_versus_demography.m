function [r, p] = sg_structure_versus_demography(path_results,path_data)
%SG_STRUCTURE_VERSUS_DEMOGRAPHY Summary of this function goes here
%   Detailed explanation goes here

    include_body_indexes = 0;
    
%     fig_dimensions1 = [50 50 2200 423];

    tick_csa = 55:5:100;
    tick_csagm = 8:2:20;
    tick_age = 20:5:55;
    tick_height = 150:10:200;
    tick_weight = 50:15:140;
    
    tick_csa = {tick_csa; tick_csa; tick_csagm};
    tick_dwi = {0.55:0.05:0.8; 0.5:0.1:1.3; 0.3:0.1:0.8}; % {FA-range; MD-range; RD-range}
    tick_mtr = {30:5:60; 30:5:60; 30:5:60};
    tick_dwimtr = {0.5:0.1:1.3; 0.3:0.1:0.8; 30:5:60};
    
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
    
    csv_path=fullfile(path_results,'results');
    
    participants = sg_load_participants(fullfile(csv_path,'participants.tsv'));
    
    yml = ReadYaml(fullfile(path_data,'exclude.yml'));
    
    
    demography = zeros(size(participants.age,1),size(demography_name,2));
    demography(:,1)=participants.age;
    
%     csa_filename = {'csa-SC_T1w.csv', 'csa-SC_T2w.csv', 'csa-GM_T2s.csv'};
%     csa_name = {'CSA-SC-T1w-C23 [mm^2]', 'CSA-SC-T2w-C23 [mm^2]' 'CSA-GM-T2star-C34 [mm^2]'};
%     csa_lvl = {'2:3', '2:3', '3:4'};
%     csa_excl = {yml.csa_t1, yml.csa_t2, yml.csa_gm};

    csa_filename = {'csa-SC_T1w_c34.csv', 'csa-SC_T2w_c34.csv', 'csa-GM_T2s.csv'};
    csa_name = {'CSA-SC-T1w-C34 [mm^2]', 'CSA-SC-T2w-C34 [mm^2]', 'CSA-GM-T2star-C34 [mm^2]'};
    csa_lvl = {'3:4', '3:4', '3:4'};
    csa_excl = {yml.csa_t1, yml.csa_t2, yml.csa_gm};
    
    dwi_filename = {'DWI_FA.csv', 'DWI_MD.csv', 'DWI_RD.csv'};
    dwi_name = {'FA-WM-C25', 'MD-WM-C25', 'RD-WM-C25'};
    dwi_lvl = {'2:5', '2:5', '2:5'};
    dwi_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwilcst_filename = {'DWI_FA_LCST.csv', 'DWI_MD_LCST.csv', 'DWI_RD_LCST.csv'};
    dwilcst_name = {'FA-LCST-C25', 'MD-LCST-C25', 'RD-LCST-C25'};
    dwilcst_lvl = {'2:5', '2:5', '2:5'};
    dwilcst_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    dwidc_filename = {'DWI_FA_DC.csv', 'DWI_MD_DC.csv', 'DWI_RD_DC.csv'};
    dwidc_name = {'FA-DC-C25', 'MD-DC-C25' 'RD-DC-C25'};
    dwidc_lvl = {'2:5', '2:5', '2:5'};
    dwidc_excl = {yml.dti_fa, yml.dti_md, yml.dti_rd};
    
    mtr_filename = {'MTR.csv', 'MTR_LCST.csv', 'MTR_DC.csv'};
    mtr_name = {'MTR-WM-C25 [%]', 'MTR-LCST-C25 [%]', 'MTR-DC-C25 [%]'};
    mtr_lvl = {'2:5', '2:5', '2:5'};
    mtr_excl = {yml.mtr, yml.mtr, yml.mtr};

    dwimtr_name = {'MD-WM-C25', 'RD-WM-C25', 'MTR-WM-C25 [%]'};
    
    corr_text = {'all: r=', 'female: r=', 'male: r='};
    
%     age_pos = strcmp(demography_name,text_age)==1;
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
    
    csa = sg_extract_csv(csa_name,csv_path,csa_filename,csa_lvl,'MEAN(area)',participants,csa_excl);
    if strcmp(csa_name{1,1}(5:6),'WM')
        csa(:,1) = csa(:,1) - csa(:,3);
        csa(:,2) = csa(:,2) - csa(:,3);
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

    [fs, fs_name] = sg_extract_xlsx(fullfile(csv_path,'fs-measurements.xlsx'),[12 48 52 55 56 57 69 71 72 74 75 79],participants);
    for fsid = 1:size(fs,2)
        for scid = 1:size(sc_data,2)
            [rr, pp] = corrcoef(sc_data(:,scid),fs(:,fsid),'Rows','Pairwise');
            r_fs(scid,fsid) = rr(1,2);
            p_fs(scid,fsid) = pp(1,2);
        end
    end

    figure(153)
    subplot(2,1,1)
    plot(r_fs')
    grid on
    subplot(2,1,2)
    plot(p_fs')
    ylim([-0.01 0.1])
    grid on
    legend(sc_data_name)
    
    [r(:,:,:,1),p(:,:,:,1)] = sg_draw_corrplot_loop(demography,csa,demography_name,csa_name,participants,corr_text,1,fig_dimensions,'All',tick_demography,tick_csa,fullfile(csv_path,'fig_corr_body_csa'));
    [r(:,:,:,2),p(:,:,:,2)] = sg_draw_corrplot_loop(demography,dwimtr,demography_name,dwimtr_name,participants,corr_text,2,fig_dimensions,'GEout',tick_demography,tick_dwimtr,fullfile(csv_path,'fig_corr_body_dtimtr'));
    [r(:,:,:,3),p(:,:,:,3)] = sg_draw_corrplot_loop(demography,dwi,demography_name,dwi_name,participants,corr_text,3,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti'));
    [r(:,:,:,4),p(:,:,:,4)] = sg_draw_corrplot_loop(demography,dwilcst,demography_name,dwilcst_name,participants,corr_text,4,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_lcst'));
    [r(:,:,:,5),p(:,:,:,5)] = sg_draw_corrplot_loop(demography,dwidc,demography_name,dwidc_name,participants,corr_text,5,fig_dimensions,'GEout',tick_demography,tick_dwi,fullfile(csv_path,'fig_corr_body_dti_dc'));
    [r(:,:,:,6),p(:,:,:,6)] = sg_draw_corrplot_loop(demography,mtr,demography_name,mtr_name,participants,corr_text,6,fig_dimensions,'GEout',tick_demography,tick_mtr,fullfile(csv_path,'fig_corr_body_mtr'));
    tick_fs = {16000:2000:30000; 900000:50000:1550000; 3.6e5:0.5e5:6.4e5; 3.5e5:0.5e5:7.0e5; 50000:5000:85000; 5.2e5:0.5e5:8.2e5; 2500:500:7000; 0.8e5:0.1e5:1.6e5; 1e5:0.2e5:2.0e5; 1.7e4:0.2e4:2.7e4; 1.3e4:0.1e4:2.4e4; 2.2:0.05:2.6};
    [tmp_r(:,:,:,1),tmp_p(:,:,:,1)] = sg_draw_corrplot_loop(fs(:,1:6),csa,fs_name(1:6),csa_name,participants,corr_text,7,[10 50 2520 1200],'All',tick_fs(1:6),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_1'));
    [tmp_r(:,:,:,2),tmp_p(:,:,:,2)] = sg_draw_corrplot_loop(fs(:,7:end),csa,fs_name(7:end),csa_name,participants,corr_text,8,[10 50 2520 1200],'All',tick_fs(7:end),tick_csa,fullfile(csv_path,'fig_corr_fs_csa_2'));
    [tmp_r(:,:,:,3),tmp_p(:,:,:,3)] = sg_draw_corrplot_loop(fs(:,1:6),dwimtr,fs_name(1:6),dwimtr_name,participants,corr_text,9,[10 50 2520 1200],'GEout',tick_fs(1:6),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_1'));
    [tmp_r(:,:,:,4),tmp_p(:,:,:,4)] = sg_draw_corrplot_loop(fs(:,7:end),dwimtr,fs_name(7:end),dwimtr_name,participants,corr_text,10,[10 50 2520 1200],'GEout',tick_fs(7:end),tick_dwimtr,fullfile(csv_path,'fig_corr_fs_dtimtr_2'));
end