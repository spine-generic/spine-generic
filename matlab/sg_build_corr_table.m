function tbl = sg_build_corr_table(r,p,r_norm,p_norm,fs_r,fs_p,fs_r_norm,fs_p_norm,thick_r,thick_p,thick_r_norm,thick_p_norm)
%SG_BUILD_CORR_TABLE Summary of this function goes here
%   Detailed explanation goes here

    tbl{3,1} = 'Correlation pair';
    tbl{1,2} = 'Absolute values';
    tbl{2,2} = 'All';tbl{3,2} = 'r';tbl{3,3} = 'p';
    tbl{2,4} = 'Female';tbl{3,4} = 'r';tbl{3,5} = 'p';
    tbl{2,6} = 'Male';tbl{3,6} = 'r';tbl{3,7} = 'p';
    tbl{1,8} = 'Normalized values';
    tbl{2,8} = 'All';tbl{3,8} = 'r';tbl{3,9} = 'p';
    tbl{2,10} = 'Female';tbl{3,10} = 'r';tbl{3,11} = 'p';
    tbl{2,12} = 'Male';tbl{3,12} = 'r';tbl{3,13} = 'p';
    tbl{4,1} = 'Age vs CSA-SC';
    tbl{5,1} = 'Age vs CSA-WM';
    tbl{6,1} = 'Age vs CSA-GM';
    tbl{7,1} = 'Height vs CSA-SC';
    tbl{8,1} = 'Height vs CSA-WM';
    tbl{9,1} = 'Height vs CSA-GM';
    tbl{10,1} = 'Weight vs CSA-SC';
    tbl{11,1} = 'Weight vs CSA-WM';
    tbl{12,1} = 'Weight vs CSA-GM';
    tbl{13,1} = 'Age vs FA-WM';
    tbl{14,1} = 'Age vs MD-WM';
    tbl{15,1} = 'Age vs RD-WM';
    tbl{16,1} = 'Height vs FA-WM';
    tbl{17,1} = 'Height vs MD-WM';
    tbl{18,1} = 'Height vs RD-WM';
    tbl{19,1} = 'Weight vs FA-WM';
    tbl{20,1} = 'Weight vs MD-WM';
    tbl{21,1} = 'Weight vs RD-WM';
    tbl{22,1} = 'Age vs MTR-WM';
    tbl{23,1} = 'Height vs MTR-WM';
    tbl{24,1} = 'Weight vs MTR-WM';
    mdl = 1;
    for modality = [1 3 6]
        for gender = 1:size(r,3) 
            for dm = 1:size(r,2)
                for sc = 1:size(r,1)
                    if modality==6 && sc == 1
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1)-(size(r,2)-1)*(dm-1),2+2*(gender-1)} = r(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1)-(size(r,2)-1)*(dm-1),3+2*(gender-1)} = p(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1)-(size(r,2)-1)*(dm-1),8+2*(gender-1)} = r_norm(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1)-(size(r,2)-1)*(dm-1),9+2*(gender-1)} = p_norm(sc,dm,gender,modality);
                    elseif ~(modality==6 && sc>1)
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1),2+2*(gender-1)} = r(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1),3+2*(gender-1)} = p(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1),8+2*(gender-1)} = r_norm(sc,dm,gender,modality);
                        tbl{3+sc+size(r,1)*(dm-1)+size(r,2)*size(r,1)*(mdl-1),9+2*(gender-1)} = p_norm(sc,dm,gender,modality);
                    end
                end
            end
        end
        mdl = mdl + 1;
    end

    row_shift = size(tbl,1);
    mdl = 1;
    for modality = [1 2]
        for gender = 1:size(fs_r,3) 
            for dm = 1:size(fs_r,2)
                for sc = 1:size(fs_r,1)
                    tbl{row_shift+sc+size(fs_r,1)*(dm-1)+size(fs_r,2)*size(fs_r,1)*(mdl-1),2+2*(gender-1)} = fs_r(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(fs_r,1)*(dm-1)+size(fs_r,2)*size(fs_r,1)*(mdl-1),3+2*(gender-1)} = fs_p(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(fs_r,1)*(dm-1)+size(fs_r,2)*size(fs_r,1)*(mdl-1),8+2*(gender-1)} = fs_r_norm(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(fs_r,1)*(dm-1)+size(fs_r,2)*size(fs_r,1)*(mdl-1),9+2*(gender-1)} = fs_p_norm(sc,dm,gender,modality);
                end
            end
        end
        mdl = mdl + 1;
    end
    tbl{25,1} = 'BrainVol vs CSA-SC';
    tbl{26,1} = 'BrainVol vs CSA-WM';
    tbl{27,1} = 'BrainVol vs CSA-GM';
    tbl{28,1} = 'BrainGMVol vs CSA-SC';
    tbl{29,1} = 'BrainGMVol vs CSA-WM';
    tbl{30,1} = 'BrainGMVol vs CSA-GM';
    tbl{31,1} = 'CortexVol vs CSA-SC';
    tbl{32,1} = 'CortexVol vs CSA-WM';
    tbl{33,1} = 'CortexVol vs CSA-GM';
    tbl{34,1} = 'CorticalWMVol vs CSA-SC';
    tbl{35,1} = 'CorticalWMVol vs CSA-WM';
    tbl{36,1} = 'CorticalWMVol vs CSA-GM';
    tbl{37,1} = 'SubCortGMVol vs CSA-SC';
    tbl{38,1} = 'SubCortGMVol vs CSA-WM';
    tbl{39,1} = 'SubCortGMVol vs CSA-GM';
    tbl{40,1} = 'ThalamusVol vs CSA-SC';
    tbl{41,1} = 'ThalamusVol vs CSA-WM';
    tbl{42,1} = 'ThalamusVol vs CSA-GM';
    tbl{43,1} = 'CerebellumVol vs CSA-SC';
    tbl{44,1} = 'CerebellumVol vs CSA-WM';
    tbl{45,1} = 'CerebellumVol vs CSA-GM';
    tbl{46,1} = 'BrainStemVol vs CSA-SC';
    tbl{47,1} = 'BrainStemVol vs CSA-WM';
    tbl{48,1} = 'BrainStemVol vs CSA-GM';

    row_shift = size(tbl,1);
    mdl = 1;
    for modality = 1
        for gender = 1:size(thick_r,3) 
            for dm = 1:size(thick_r,2)
                for sc = 1:size(thick_r,1)
                    tbl{row_shift+sc+size(thick_r,1)*(dm-1)+size(thick_r,2)*size(thick_r,1)*(mdl-1),2+2*(gender-1)} = thick_r(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(thick_r,1)*(dm-1)+size(thick_r,2)*size(thick_r,1)*(mdl-1),3+2*(gender-1)} = thick_p(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(thick_r,1)*(dm-1)+size(thick_r,2)*size(thick_r,1)*(mdl-1),8+2*(gender-1)} = thick_r_norm(sc,dm,gender,modality);
                    tbl{row_shift+sc+size(thick_r,1)*(dm-1)+size(thick_r,2)*size(thick_r,1)*(mdl-1),9+2*(gender-1)} = thick_p_norm(sc,dm,gender,modality);
                end
            end
        end
        mdl = mdl + 1;
    end
    tbl{49,1} = 'Cortical Thickness vs CSA-SC';
    tbl{50,1} = 'Cortical Thickness vs CSA-WM';
    tbl{51,1} = 'Cortical Thickness vs CSA-GM';
    tbl{52,1} = 'Precentral Thickness vs CSA-SC';
    tbl{53,1} = 'Precentral Thickness vs CSA-WM';
    tbl{54,1} = 'Precentral Thickness vs CSA-GM';
    tbl{55,1} = 'Postcentral Thickness vs CSA-SC';
    tbl{56,1} = 'Postcentral Thickness vs CSA-WM';
    tbl{57,1} = 'Postcentral Thickness vs CSA-GM';
    tbl{58,1} = 'PrecentralGMVol vs CSA-SC';
    tbl{59,1} = 'PrecentralGMVol vs CSA-WM';
    tbl{60,1} = 'PrecentralGMVol vs CSA-GM';
    tbl{61,1} = 'PostcentralGMVol vs CSA-SC';
    tbl{62,1} = 'PostcentralGMVol vs CSA-WM';
    tbl{63,1} = 'PostcentralGMVol vs CSA-GM';
end