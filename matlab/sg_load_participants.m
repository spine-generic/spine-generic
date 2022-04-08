function participants = sg_load_participants(participants_file)
%SG_LOAD_PARTICIPANTS Summary of this function goes here
%   Detailed explanation goes here

    participants = tdfread(participants_file);
    participants.participant_id=cellstr(participants.participant_id);
    participants.institution_id=cellstr(participants.institution_id);
    participants.manufacturer=cellstr(participants.manufacturer);
    participants.sex=cellstr(participants.sex);
end