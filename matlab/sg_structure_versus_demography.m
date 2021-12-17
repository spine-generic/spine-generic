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
    csa_name = {'CSA-SC-T1w [mm^2]', 'CSA-SC-T2w [mm^2]' 'CSA-GM-T2star [mm^2]'};
    csa_lvl = {'2:3', '2:3', '3:4'};
    csa = NaN*ones(size(participants.age,1),size(csa_filename,2));
    
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
    
    h.fig=figure(1);
    set(h.fig,'Position',[50 50 2200 1270])
    pl=1;
    for cs = 1:size(csa,2)
        for dm = 1:size(demography,2)
            [rr, pp]=corrcoef(demography(:,dm),csa(:,cs),'Rows','Pairwise');
            csa_r(cs,dm,1)=rr(1,2);
            csa_p_r(cs,dm,1)=pp(1,2);
            [rr, pp]=corrcoef(demography(sex==1,dm),csa(sex==1,cs),'Rows','Pairwise');
            csa_r(cs,dm,2)=rr(1,2);
            csa_p_r(cs,dm,2)=pp(1,2);
            [rr, pp]=corrcoef(demography(sex==0,dm),csa(sex==0,cs),'Rows','Pairwise');
            csa_r(cs,dm,3)=rr(1,2);
            csa_p_r(cs,dm,3)=pp(1,2);
            
            mindem=min(demography(:,dm));
            maxdem=max(demography(:,dm));
            mincsa=min(csa(:,cs));
            maxcsa=max(csa(:,cs));
            
            ps = ~isnan(demography(:,dm)) & ~isnan(csa(:,cs));
            c = polyfit(demography(ps,dm),csa(ps,cs),1);
            x = [mindem maxdem];
            y = c(1)*x + c(2);
            
            
            sie_female = strcmp(participants.manufacturer,'Siemens') & sex==1;
            sie_male = strcmp(participants.manufacturer,'Siemens') & sex==0;
            ge_female = strcmp(participants.manufacturer,'GE') & sex==1;
            ge_male = strcmp(participants.manufacturer,'GE') & sex==0;
            phi_female = strcmp(participants.manufacturer,'Philips') & sex==1;
            phi_male = strcmp(participants.manufacturer,'Philips') & sex==0;
            
            subplot(size(csa,2),size(demography,2),pl)
            plot(x,y,'k-.','LineWidth',4)
            hold on
            plot(demography(sie_female,dm),csa(sie_female,cs),'go','LineStyle','none','LineWidth',2,'MarkerSize',8)
            plot(demography(sie_male,dm),csa(sie_male,cs),'gx','LineStyle','none','LineWidth',2,'MarkerSize',8)
            plot(demography(phi_female,dm),csa(phi_female,cs),'bo','LineStyle','none','LineWidth',2,'MarkerSize',8)
            plot(demography(phi_male,dm),csa(phi_male,cs),'bx','LineStyle','none','LineWidth',2,'MarkerSize',8)
            plot(demography(ge_female,dm),csa(ge_female,cs),'ro','LineStyle','none','LineWidth',2,'MarkerSize',8)
            plot(demography(ge_male,dm),csa(ge_male,cs),'rx','LineStyle','none','LineWidth',2,'MarkerSize',8)
            hold off
            if csa_p_r(cs,dm,1) < 0.05
                for cr = 1:3
                    if csa_p_r(cs,dm,cr) < 0.0001
                        text(0.99*maxdem,(1.15-0.05*(cr-1))*mincsa,[corr_text{1,cr} num2str(csa_r(cs,dm,cr),'%.3f') '; p<0.0001'],'HorizontalAlignment','right','FontWeight','bold')
                    else
                        if csa_p_r(cs,dm,cr) < 0.05
                            text(0.99*maxdem,(1.15-0.05*(cr-1))*mincsa,[corr_text{1,cr} num2str(csa_r(cs,dm,cr),'%.3f') '; p=' num2str(csa_p_r(cs,dm,cr),'%.4f')],'HorizontalAlignment','right','FontWeight','bold')
                        else
                            text(0.99*maxdem,(1.15-0.05*(cr-1))*mincsa,[corr_text{1,cr} num2str(csa_r(cs,dm,cr),'%.3f') '; p=' num2str(csa_p_r(cs,dm,cr),'%.4f')],'HorizontalAlignment','right')
                        end
                    end
                end
            end
            axis([mindem maxdem mincsa maxcsa])
            grid on
            if cs == size(csa,2)
                xlabel(demography_name{1,dm})
            end
            if dm == 1
                ylabel(csa_name{1,cs})
            end
            set(gca,'FontSize',14,'LineWidth',2)
            pl = pl + 1;
        end
    end
end

