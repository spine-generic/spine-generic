function [r, p] = sg_structure_versus_demography(path_results)
%SG_STRUCTURE_VERSUS_DEMOGRAPHY Summary of this function goes here
%   Detailed explanation goes here

    fig_dimensions = [50 50 2200 1270];
    fig_dimensions1 = [50 50 2200 423];

    tick_csa = 55:5:85;
    tick_csagm = 8:2:20;
    tick_age = 20:5:55;
    tick_height = 150:10:200;
    tick_weight = 50:10:120;
    tick_bmi = 18:3:33;
    
    tick_demography = {tick_age; tick_height; tick_weight; tick_bmi};
    tick_csa = {tick_csa; tick_csa; tick_csagm};
    tick_dwi = {0.55:0.05:0.8; 0.5:0.1:1.3; 0.3:0.1:0.8}; % {FA-range; MD-range; RD-range}
    tick_mtr = {30:5:60};
    
    csv_path=fullfile(path_results,'results');
    
    participants_file = fullfile(csv_path,'participants.tsv');
    participants = tdfread(participants_file);
    participants.participant_id=cellstr(participants.participant_id);
    participants.institution_id=cellstr(participants.institution_id);
    participants.manufacturer=cellstr(participants.manufacturer);
    
    demography_name={'Age [y.o.]','Height [cm]' 'Weight [kg]' 'BMI'};
    demography = zeros(size(participants.age,1),size(demography_name,2));
    demography(:,1)=participants.age;
    
    csa_filename = {'csa-SC_T1w.csv', 'csa-SC_T2w.csv', 'csa-GM_T2s.csv'};
    csa_name = {'CSA-SC-T1w-C23 [mm^2]', 'CSA-SC-T2w-C23 [mm^2]' 'CSA-GM-T2star-C34 [mm^2]'};
    csa_lvl = {'2:3', '2:3', '3:4'};
    
    dwi_filename = {'DWI_FA.csv', 'DWI_MD.csv', 'DWI_RD.csv'};
    dwi_name = {'FA-WM-C25', 'MD-WM-C25' 'RD-WM-C25'};
    dwi_lvl = {'2:5', '2:5', '2:5'};
    
    dwilcst_filename = {'DWI_FA_LCST.csv', 'DWI_MD_LCST.csv', 'DWI_RD_LCST.csv'};
    dwilcst_name = {'FA-LCST-C25', 'MD-LCST-C25' 'RD-LCST-C25'};
    dwilcst_lvl = {'2:5', '2:5', '2:5'};
    
    dwidc_filename = {'DWI_FA_DC.csv', 'DWI_MD_DC.csv', 'DWI_RD_DC.csv'};
    dwidc_name = {'FA-DC-C25', 'MD-DC-C25' 'RD-DC-C25'};
    dwidc_lvl = {'2:5', '2:5', '2:5'};
    
    mtr_filename = {'MTR.csv'};
    mtr_name = {'MTR-WM-C25 [%]'};
    mtr_lvl = {'2:5'};
    
    corr_text = {'all: r=', 'female: r=', 'male: r='};
    
    age_pos = strcmp(demography_name,'Age [y.o.]')==1;
    height_pos = strcmp(demography_name,'Height [cm]')==1;
    weight_pos = strcmp(demography_name,'Weight [kg]')==1;
    bmi_pos = strcmp(demography_name,'BMI')==1;
    sex = zeros(size(participants.age,1),1);
    
    for ind = 1:size(participants.age,1)
        if strcmp(participants.sex(ind),'F')
            sex(ind,1) = 1;
        end
        if strcmp(participants.height(ind,1),'-')
            demography(ind,height_pos) = NaN;
        else
            demography(ind,height_pos) = str2double(participants.height(ind,:));
        end
        if strcmp(participants.weight(ind,1),'-')
            demography(ind,weight_pos) = NaN;
        else
            demography(ind,weight_pos) = str2double(participants.weight(ind,:));
        end
    end
    demography(:,bmi_pos) = demography(:,weight_pos) ./ (demography(:,height_pos)/100).^2 ;
    
    csa = sg_extract_csv(csa_name,csv_path,csa_filename,csa_lvl,'MEAN(area)',participants);
    csa(strcmp(participants.participant_id,'sub-oxfordFmrib04'),2)=NaN;
    
    dwi = sg_extract_csv(dwi_name,csv_path,dwi_filename,dwi_lvl,'WA()',participants);
    dwi(:,2:3) = 1000*dwi(:,2:3);
    
    dwilcst = sg_extract_csv(dwilcst_name,csv_path,dwilcst_filename,dwilcst_lvl,'WA()',participants);
    dwilcst(:,2:3) = 1000*dwilcst(:,2:3);
    
    dwidc = sg_extract_csv(dwidc_name,csv_path,dwidc_filename,dwidc_lvl,'WA()',participants);
    dwidc(:,2:3) = 1000*dwidc(:,2:3);
    
    mtr = sg_extract_csv(mtr_name,csv_path,mtr_filename,mtr_lvl,'WA()',participants);
    mtr(strcmp(participants.participant_id,'sub-geneva02'),1)=NaN;
    
    [r(:,:,:,1),p(:,:,:,1)] = sg_draw_corrplot_loop(demography,csa,demography_name,csa_name,sex,participants,corr_text,1,fig_dimensions,'All',tick_demography,tick_csa);
    [r(:,:,:,2),p(:,:,:,2)] = sg_draw_corrplot_loop(demography,dwi,demography_name,dwi_name,sex,participants,corr_text,2,fig_dimensions,'GEout',tick_demography,tick_dwi);
    [r(:,:,:,3),p(:,:,:,3)] = sg_draw_corrplot_loop(demography,dwilcst,demography_name,dwilcst_name,sex,participants,corr_text,3,fig_dimensions,'GEout',tick_demography,tick_dwi);
    [r(:,:,:,4),p(:,:,:,4)] = sg_draw_corrplot_loop(demography,dwidc,demography_name,dwidc_name,sex,participants,corr_text,4,fig_dimensions,'GEout',tick_demography,tick_dwi);
    [r(1,:,:,5),p(1,:,:,5)] = sg_draw_corrplot_loop(demography,mtr,demography_name,mtr_name,sex,participants,corr_text,5,fig_dimensions1,'GEout',tick_demography,tick_mtr);
end