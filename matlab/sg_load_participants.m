function participants = sg_load_participants(participants_file)
%SG_LOAD_PARTICIPANTS Summary of this function goes here
%   Detailed explanation goes here
%
%   AUTHORS:
%   Rene Labounek (1), Julien Cohen-Adad (2), Christophe Lenglet (3), Igor Nestrasil (1,3)
%   email: rlaboune@umn.edu
%
%   INSTITUTIONS:
%   (1) Masonic Institute for the Developing Brain, Division of Clinical Behavioral Neuroscience, Deparmtnet of Pediatrics, University of Minnesota, Minneapolis, Minnesota, USA
%   (2) NeuroPoly Lab, Institute of Biomedical Engineering, Polytechnique Montreal, Montreal, Quebec, Canada
%   (3) Center for Magnetic Resonance Research, Department of Radiology, University of Minnesota, Minneapolis, Minnesota, USA

    participants = tdfread(participants_file);
    participants.participant_id=cellstr(participants.participant_id);
    participants.institution_id=cellstr(participants.institution_id);
    participants.manufacturer=cellstr(participants.manufacturer);
    participants.sex=cellstr(participants.sex);
end