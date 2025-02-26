function tblStepWise = sg_build_mixture_model_table(tblStepWise,mdl2,XX_name,Y_name,vr,Y,...
    csa,dwi,mtr,csa_name,dwi_name,mtr_name,tblR2,...
    averaged_subtracted_sc_measurement,averaged_subtracted_sc_measurement_name,icv_name_y,r_icv,r_icv_pos,R2_icv_pos,R2_height_pos)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    var = XX_name(1,mdl2(vr,1).inmodel);
    beta = mdl2(vr,1).b(mdl2(vr,1).inmodel);

    if strcmp(Y_name{1,vr},'CSA-WM')           
        y0 = mdl2(vr,1).stats.intercept + averaged_subtracted_sc_measurement(strcmp(averaged_subtracted_sc_measurement_name,'CSA-WM'));
        ystr = [ Y_name{1,vr} ' ∝ ' num2str(y0,'%.2f') ' '];
    elseif strcmp(Y_name{1,vr},'CSA-SC')
        y0 = mdl2(vr,1).stats.intercept + averaged_subtracted_sc_measurement(strcmp(averaged_subtracted_sc_measurement_name,'CSA-SC'));
        ystr = [ Y_name{1,vr} ' ∝ ' num2str(y0,'%.2f') ' '];
    elseif strcmp(Y_name{1,vr},'MD-SC-WM')
        y0 = mdl2(vr,1).stats.intercept + averaged_subtracted_sc_measurement(strcmp(averaged_subtracted_sc_measurement_name,'MD-SC-WM'));
        ystr = [ Y_name{1,vr} ' ∝ ' num2str(y0,'%.3f') ' '];
    elseif strcmp(Y_name{1,vr},'MTR-SC-WM')
        y0 = mdl2(vr,1).stats.intercept + averaged_subtracted_sc_measurement(strcmp(averaged_subtracted_sc_measurement_name,'MTR-SC-WM'));
        ystr = [ Y_name{1,vr} ' ∝ ' num2str(y0,'%.1f') ' '];
    else
        y0 = mdl2(vr,1).stats.intercept;
        if abs(y0)<0.001
            y0 = round(1000000*y0)/1000000;
        elseif abs(y0)<0.01
            y0 = round(10000*y0)/10000;
        elseif abs(y0)<1
            y0 = round(1000*y0)/1000;
        elseif abs(y0)<10
            y0 = round(100*y0)/100;
        elseif abs(y0)<100
            y0 = round(10*y0)/10; 
        else
            y0 = round(y0);
        end
        ystr = [ Y_name{1,vr} ' ∝ ' num2str(y0) ' '];
    end
    for md = 1:size(var,2)
        if abs(beta(md,1))<0.001
            c = round(1000000*beta(md,1))/1000000;
        elseif abs(beta(md,1))<0.01
            c = round(10000*beta(md,1))/10000;
        elseif abs(beta(md,1))<1
            c = round(1000*beta(md,1))/1000;
        elseif abs(beta(md,1))<10
            c = round(100*beta(md,1))/100;
        elseif abs(beta(md,1))<100
            c = round(10*beta(md,1))/10; 
        else
            c = round(beta(md,1));
        end
        if beta(md,1) >= 0
            ystr = [ystr ' +' num2str(c) '*' var{1,md}];
        else
            ystr = [ystr ' ' num2str(c) '*' var{1,md}];
        end
    end

    tblStepWise{vr+1,1} = ystr;
    tblStepWise{vr+1,2} = [num2str(mdl2(vr,1).R2,'%.1f') '%'];
    tblStepWise{vr+1,3} = [num2str(100*tblR2{R2_icv_pos,vr+1},'%.1f') '%'];
    tblStepWise{vr+1,4} = [num2str(100*tblR2{R2_height_pos,vr+1},'%.1f') '%'];
    tblStepWise{vr+1,5} = num2str(mdl2(vr,1).r,'%.3f');
    tblStepWise{vr+1,6} = r_icv(contains(icv_name_y,Y_name{1,vr}),r_icv_pos);

    if contains(Y_name{1,vr},'Vol')
        tblStepWise{vr+1,7} = [ num2str(round(mdl2(vr,1).rmse)) 'mm^3'];
        vec = Y(:,vr);
        vec_mean = round(mean(vec,'omitnan'));
        vec_std = round(std(vec,0,'omitnan'));
        tblStepWise{vr+1,8} = [ num2str(vec_mean) '±' num2str(vec_std) 'mm^3'];
    elseif contains(Y_name{1,vr},'CSA-')
        g = round(10*mdl2(vr,1).rmse)/10;
        tblStepWise{vr+1,7} = [ num2str(g,'%.1f') 'mm^2'];
        if strcmp(Y_name{1,vr},'CSA-WM')
            vec = csa(:,strcmp(csa_name,'CSA-WM [mm^2]'));
        elseif strcmp(Y_name{1,vr},'CSA-SC')
            vec = csa(:,strcmp(csa_name,'CSA-SC [mm^2]'));
        end    
        vec_mean = mean(vec,'omitnan');
        vec_std = std(vec,0,'omitnan');
        tblStepWise{vr+1,8} = [ num2str(vec_mean,'%.1f') '±' num2str(vec_std,'%.1f') 'mm^2'];
    elseif contains(Y_name{1,vr},'MD-')
        g = round(100*mdl2(vr,1).rmse)/100;
        tblStepWise{vr+1,7} = [ num2str(g,'%.2f') '*10^-9 m^2/s'];
        if strcmp(Y_name{1,vr},'MD-SC-WM')
            vec = dwi(:,strcmp(dwi_name,'MD-SC-WM [*10^{-9}m^2/s]'));
        end
        vec_mean = mean(vec,'omitnan');
        vec_std = std(vec,0,'omitnan');
        tblStepWise{vr+1,8} = [ '(' num2str(vec_mean,'%.2f') '±' num2str(vec_std,'%.2f') ')*10^-9 m^2/s'];
    elseif contains(Y_name{1,vr},'MTR-')
        g = round(10*mdl2(vr,1).rmse)/10;
        tblStepWise{vr+1,7} = [ num2str(g,'%.1f') '%'];
        if strcmp(Y_name{1,vr},'MTR-SC-WM')
            vec = mtr(:,strcmp(mtr_name,'MTR-SC-WM [%]'));
        end
        vec_mean = mean(vec,'omitnan');
        vec_std = std(vec,0,'omitnan');
        tblStepWise{vr+1,8} = [ num2str(vec_mean,'%.1f') '±' num2str(vec_std,'%.1f') '%'];
    elseif contains(Y_name{1,vr},'Thickness')
        g = round(100*mdl2(vr,1).rmse)/100;
        tblStepWise{vr+1,7} = [ num2str(g,'%.2f') 'mm'];

        vec = Y(:,vr);
        vec_mean = round(100*mean(vec,'omitnan'))/100;
        vec_std = round(100*std(vec,0,'omitnan'))/100;
        tblStepWise{vr+1,8} = [ num2str(vec_mean,'%.2f') '±' num2str(vec_std,'%.2f') 'mm'];
    end

end

