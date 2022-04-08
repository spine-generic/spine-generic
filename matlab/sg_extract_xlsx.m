function [data, data_name] = sg_extract_xlsx(xlsx_file,cols_idx,participants)
%SG_EXTRACT_XLSX Summary of this function goes here
%   Detailed explanation goes here

    [~, ~, raw] = xlsread(xlsx_file);
    data = NaN*ones(size(participants,1),size(cols_idx,2));
    for ind = 3:size(raw,1)
        data(strcmp(participants.participant_id,raw{ind,1}),:) = [raw{ind,cols_idx}];
    end
    data(data(:,1)==0,:) = NaN;
    data_name = raw(1,cols_idx);
end