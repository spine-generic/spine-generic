function [csa_r, csa_p_r] = sg_structure_versus_demography(path_results)
%SG_STRUCTURE_VERSUS_DEMOGRAPHY Summary of this function goes here
%   Detailed explanation goes here

    if ispc
        delimiter = '\';
    else
        delimiter = '/';
    end
    
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
    csa = NaN*ones(size(participants.age,1),size(csa_filename,2));
    
    dwi_filename = {'DWI_FA.csv', 'DWI_MD.csv', 'DWI_RD.csv'};
    dwi_name = {'FA-SC-C25', 'MD-SC-C25' 'RD-SC-C25'};
    dwi_lvl = {'2:5', '2:5', '2:5'};
    dwi = NaN*ones(size(participants.age,1),size(dwi_filename,2));
    
    tick_csat1 = 55:5:85;
    tick_csat2 = 55:5:95;
    tick_csat2star_gm = 8:2:20;
    tick_age = 20:5:55;
    tick_height = 150:10:200;
    tick_weight = 50:10:120;
    tick_bmi = 18:3:33;
    
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
    
    for vr = 1:size(csa_name,2)
        tbl = readtable(fullfile(csv_path,csa_filename{1,vr}),'PreserveVariableNames',1);
        for ind = 1:size(tbl,1)
            if strcmp(char(table2cell(tbl(ind,'VertLevel'))),csa_lvl{1,vr})
                id = split(char(table2cell(tbl(ind,'Filename'))),delimiter);
                val = table2cell(tbl(ind,'MEAN(area)'));
                val = val{1,1};
                if ischar(val)
                    val = str2double(val);
                end
                csa(strcmp(participants.participant_id,id{end-2}),vr) = val; % table2array(val) str2double(char(table2cell(val)))
            end
        end
    end
    csa(strcmp(participants.participant_id,'sub-oxfordFmrib04'),2)=NaN;
    
    for vr = 1:size(dwi_name,2)
        tbl = readtable(fullfile(csv_path,dwi_filename{1,vr}),'PreserveVariableNames',1);
        for ind = 1:size(tbl,1)
            if strcmp(char(table2cell(tbl(ind,'VertLevel'))),dwi_lvl{1,vr})
                id = split(char(table2cell(tbl(ind,'Filename'))),delimiter);
                val = table2cell(tbl(ind,'WA()'));
                val = val{1,1};
                if ischar(val)
                    val = str2double(val);
                end
                dwi(strcmp(participants.participant_id,id{end-2}),vr) = val;
            end
        end
    end
    dwi(:,2:3) = 1000*dwi(:,2:3);
    
    csa_r = zeros(size(csa,2),size(demography,2),3);csa_p_r = csa_r;
    h.fig=figure(1);
    set(h.fig,'Position',[1550 600 2200 1270])
    pl=1;
    for cs = 1:size(csa,2)
        for dm = 1:size(demography,2)
            subplot(size(csa,2),size(demography,2),pl)
            [csa_r(cs,dm,:), csa_p_r(cs,dm,:)] = sg_draw_corrplot(demography(:,dm),csa(:,cs),sex,participants,corr_text);
            if cs == size(csa,2)
                xlabel(demography_name{1,dm})
            end
            if dm == 1
                ylabel(csa_name{1,cs})
            end
            if dm == 1
                if cs ==1
                    set(gca,'Ytick',tick_csat1,'Yticklabel',tick_csat1)
                elseif cs == 2
                    set(gca,'Ytick',tick_csat2,'Yticklabel',tick_csat2)
                elseif cs == size(csa,2)
                    set(gca,'Ytick',tick_csat2star_gm,'Yticklabel',tick_csat2star_gm)
                end
            end
            if dm >=2
                if cs == 1
                    set(gca,'Ytick',tick_csat1,'Yticklabel',' ')
                elseif cs == 2
                    set(gca,'Ytick',tick_csat2,'Yticklabel',' ')
                elseif cs == 3
                    set(gca,'Ytick',tick_csat2star_gm,'Yticklabel',' ')
                end
            end
            if cs<size(csa,2)
                if dm == 1
                    set(gca,'Xtick',tick_age,'Xticklabel',' ')
                elseif dm == 2
                    set(gca,'Xtick',tick_height,'Xticklabel',' ')
                elseif dm == 3
                    set(gca,'Xtick',tick_weight,'Xticklabel',' ')
                elseif dm == 4
                    set(gca,'Xtick',tick_bmi,'Xticklabel',' ')
                end
            end
            if cs == size(csa,2)
                if dm == 1
                    set(gca,'Xtick',tick_age,'Xticklabel',tick_age)
                elseif dm == 2
                    set(gca,'Xtick',tick_height,'Xticklabel',tick_height)
                elseif dm == 3
                    set(gca,'Xtick',tick_weight,'Xticklabel',tick_weight)
                elseif dm == 4
                    set(gca,'Xtick',tick_bmi,'Xticklabel',tick_bmi)
                end
            end
            pl = pl + 1;
        end
    end
    
    
    dwi_r = zeros(size(dwi,2),size(demography,2),3);dwi_p_r = dwi_r;
    h(2).fig=figure(2);
    set(h(2).fig,'Position',[1550 600 2200 1270])
    pl=1;
    for cs = 1:size(dwi,2)
        for dm = 1:size(demography,2)
            subplot(size(dwi,2),size(demography,2),pl)
            [dwi_r(cs,dm,:), dwi_p_r(cs,dm,:)] = sg_draw_corrplot(demography(:,dm),dwi(:,cs),sex,participants,corr_text);
            if cs == size(dwi,2)
                xlabel(demography_name{1,dm})
            end
            if dm == 1
                ylabel(dwi_name{1,cs})
            end
            pl = pl + 1;
        end
    end
end

