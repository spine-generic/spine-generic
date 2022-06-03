function data = sg_extract_csv(data_name,csv_path,filename,lvl,column_name,participants,excl)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    if ispc
        delimiter = '\';
    else
        delimiter = '/';
    end
    data = NaN*ones(size(participants.age,1),size(filename,2));
    for vr = 1:size(data_name,2)
        tbl = readtable(fullfile(csv_path,filename{1,vr}),'PreserveVariableNames',1);
        for ind = 1:size(tbl,1)
            if strcmp('brain',lvl{1,vr})
                subid = table2cell(tbl(ind,'SubID'));
                id = {subid; subid; subid};
            elseif strcmp(char(table2cell(tbl(ind,'VertLevel'))),lvl{1,vr})
                id = split(char(table2cell(tbl(ind,'Filename'))),delimiter);
            else
                id = 'n/a';
            end
            if ~strcmp(id,'n/a')
                notuse = 0;
                if ~isempty(excl{1,vr})
                    for wrng = 1:size(excl{1,vr},2)
                        notuse = notuse + double(contains(id{end-2},excl{1,vr}{1,wrng}));
                    end
                end
                if notuse == 0
                    val = table2cell(tbl(ind,column_name));
                    val = val{1,1};
                    if ischar(val)
                        val = str2double(val);
                    end
                    data(strcmp(participants.participant_id,id{end-2}),vr) = val;
                end
            end
        end
    end
end

