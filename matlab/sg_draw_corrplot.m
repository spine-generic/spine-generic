function [r, p, r_norm, p_norm, rho, p_rho, rho_norm, p_rho_norm] = sg_draw_corrplot(xdata,ydata,participants,usedata,fig_ind,p_thr,xlbl,ylbl)
%SG_DRAW_CORRPLOT Summary of this function goes here
%   
%   OUTPUTS:
%   r(1) ... Pearson correlation for all dataset (including or excluding GE scanner values based on the usedata input)
%   r(2) ... Pearson correlation for females (including or excluding GE scanner values based on the usedata input)
%   r(3) ... Pearson correlation for males (including or excluding GE scanner values based on the usedata input)
%
%   p(1) ... p-value of Pearson correlation for all dataset (including or excluding GE scanner values based on the usedata input)
%   p(2) ... p-value of Pearson correlation for females (including or excluding GE scanner values based on the usedata input)
%   p(3) ... p-value of Pearson correlation for males (including or excluding GE scanner values based on the usedata input)
%
%   AUTHORS:
%   Rene Labounek (1), Julien Cohen-Adad (2), Christophe Lenglet (3), Igor Nestrasil (1,3)
%   email: rlaboune@umn.edu
%
%   INSTITUTIONS:
%   (1) Masonic Institute for the Developing Brain, Division of Clinical Behavioral Neuroscience, Deparmtnet of Pediatrics, University of Minnesota, Minneapolis, Minnesota, USA
%   (2) NeuroPoly Lab, Institute of Biomedical Engineering, Polytechnique Montreal, Montreal, Quebec, Canada
%   (3) Center for Magnetic Resonance Research, Department of Radiology, University of Minnesota, Minneapolis, Minnesota, USA

    sie_female = strcmp(participants.manufacturer,'Siemens') & strcmp(participants.sex,'F');
    sie_male = strcmp(participants.manufacturer,'Siemens') & strcmp(participants.sex,'M');
    ge_female = strcmp(participants.manufacturer,'GE') & strcmp(participants.sex,'F');
    ge_male = strcmp(participants.manufacturer,'GE') & strcmp(participants.sex,'M');
    phi_female = strcmp(participants.manufacturer,'Philips') & strcmp(participants.sex,'F');
    phi_male = strcmp(participants.manufacturer,'Philips') & strcmp(participants.sex,'M');

    sie_pos = strcmp(participants.manufacturer,'Siemens');
    ge_pos = strcmp(participants.manufacturer,'GE');
    phi_pos = strcmp(participants.manufacturer,'Philips');
    
    mean_siemens = mean(ydata(sie_pos & ~isnan(ydata)));
    mean_philips = mean(ydata(phi_pos & ~isnan(ydata)));
    mean_ge = mean(ydata(ge_pos & ~isnan(ydata)));
    mean_vec = zeros(size(ydata));
    mean_vec(sie_pos)= mean_siemens;
    mean_vec(phi_pos)= mean_philips;
    mean_vec(ge_pos)= mean_ge;
    
    ydata_norm = ydata - mean_vec;

    minx=min(xdata);
    maxx=max(xdata);
    miny=min(ydata);
    maxy=max(ydata);
    x = [minx maxx];
    
    if strcmp(usedata,'All')
        [rr, pp]=corrcoef(xdata,ydata,'Rows','Pairwise');
        r(1)=rr(1,2);p(1)=pp(1,2);
        [rho, p_rho]=corr(xdata,ydata,'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'F')),ydata(strcmp(participants.sex,'F')),'Rows','Pairwise');
        r(2)=rr(1,2);p(2)=pp(1,2);
        [rho(2), p_rho(2)]=corr(xdata(strcmp(participants.sex,'F')),ydata(strcmp(participants.sex,'F')),'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'M')),ydata(strcmp(participants.sex,'M')),'Rows','Pairwise');
        r(3)=rr(1,2);p(3)=pp(1,2);
        [rho(3), p_rho(3)]=corr(xdata(strcmp(participants.sex,'M')),ydata(strcmp(participants.sex,'M')),'Rows','Pairwise','Type','Spearman');
        ps = ~isnan(xdata) & ~isnan(ydata);
    elseif strcmp(usedata,'GEout')
        useonly=~strcmp(participants.manufacturer,'GE');
        [rr, pp]=corrcoef(xdata(useonly),ydata(useonly),'Rows','Pairwise');
        r(1)=rr(1,2);p(1)=pp(1,2);
        [rho, p_rho]=corr(xdata(useonly),ydata(useonly),'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(useonly & strcmp(participants.sex,'F')),ydata(useonly & strcmp(participants.sex,'F')),'Rows','Pairwise');
        r(2)=rr(1,2);p(2)=pp(1,2);
        [rho(2), p_rho(2)]=corr(xdata(useonly & strcmp(participants.sex,'F')),ydata(useonly & strcmp(participants.sex,'F')),'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(useonly & strcmp(participants.sex,'M')),ydata(useonly & strcmp(participants.sex,'M')),'Rows','Pairwise');
        r(3)=rr(1,2);p(3)=pp(1,2);
        [rho(3), p_rho(3)]=corr(xdata(useonly & strcmp(participants.sex,'M')),ydata(useonly & strcmp(participants.sex,'M')),'Rows','Pairwise','Type','Spearman');
        ps = ~isnan(xdata) & ~isnan(ydata) & useonly;
        ps2 = ~isnan(xdata) & ~isnan(ydata) & ~useonly;
        c2 = polyfit(xdata(ps2),ydata(ps2),1);
        y2 = c2(1)*x + c2(2);
    elseif strcmp(usedata,'normalize')
        x1mean = mean(xdata(sie_pos),'omitnan');
        x2mean = mean(xdata(phi_pos),'omitnan');
        x3mean = mean(xdata(ge_pos),'omitnan');
        
        xmean_vec = zeros(size(xdata));
        xmean_vec(sie_pos) = x1mean;
        xmean_vec(phi_pos) = x2mean;
        xmean_vec(ge_pos) = x3mean;
        
        xdata = xdata - xmean_vec;
        ydata = ydata_norm;
        
        minx=min(xdata);
        maxx=max(xdata);
        miny=min(ydata);
        maxy=max(ydata);
        x = [minx maxx];
        
        [rr, pp]=corrcoef(xdata,ydata,'Rows','Pairwise');
        r(1)=rr(1,2);p(1)=pp(1,2);
        [rho, p_rho]=corr(xdata,ydata,'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'F')),ydata(strcmp(participants.sex,'F')),'Rows','Pairwise');
        r(2)=rr(1,2);p(2)=pp(1,2);
        [rho(2), p_rho(2)]=corr(xdata(strcmp(participants.sex,'F')),ydata(strcmp(participants.sex,'F')),'Rows','Pairwise','Type','Spearman');
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'M')),ydata(strcmp(participants.sex,'M')),'Rows','Pairwise');
        r(3)=rr(1,2);p(3)=pp(1,2);
        [rho(3), p_rho(3)]=corr(xdata(strcmp(participants.sex,'M')),ydata(strcmp(participants.sex,'M')),'Rows','Pairwise','Type','Spearman');
        ps = ~isnan(xdata) & ~isnan(ydata);
    end

    [rr, pp]=corrcoef(xdata,ydata_norm,'Rows','Pairwise');
    r_norm(1)=rr(1,2);p_norm(1)=pp(1,2);
    [rho_norm, p_rho_norm]=corr(xdata,ydata_norm,'Rows','Pairwise','Type','Spearman');
    [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'F')),ydata_norm(strcmp(participants.sex,'F')),'Rows','Pairwise');
    r_norm(2)=rr(1,2);p_norm(2)=pp(1,2);
    [rho_norm(2), p_rho_norm(2)]=corr(xdata(strcmp(participants.sex,'F')),ydata_norm(strcmp(participants.sex,'F')),'Rows','Pairwise','Type','Spearman');
    [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'M')),ydata_norm(strcmp(participants.sex,'M')),'Rows','Pairwise');
    r_norm(3)=rr(1,2);p_norm(3)=pp(1,2);
    [rho_norm(3), p_rho_norm(3)]=corr(xdata(strcmp(participants.sex,'M')),ydata_norm(strcmp(participants.sex,'M')),'Rows','Pairwise','Type','Spearman');

    c = polyfit(xdata(ps),ydata(ps),1);
    y = c(1)*x + c(2);

    plot(x,y,'k-.','LineWidth',4)
    hold on
    if strcmp(usedata,'GEout')
        plot(x,y2,'r:','LineWidth',3)
    end
    plot(xdata(sie_female),ydata(sie_female),'go','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(sie_male),ydata(sie_male),'gx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(phi_female),ydata(phi_female),'bo','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(phi_male),ydata(phi_male),'bx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(ge_female),ydata(ge_female),'ro','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(ge_male),ydata(ge_male),'rx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    hold off
    
    if fig_ind == 20
        vertalign = 'Top';
        horizalign = 'left';
        txty = 0.995*maxy;
        txtx = 1.01*minx;
    elseif fig_ind == 1 || (r(1)>0 && fig_ind ~= 2 && fig_ind ~= 17 && fig_ind ~= 22)
        vertalign = 'Bottom';
        horizalign = 'right';
        txty = 1.01*miny;
        txtx = 0.99*maxx;
    else
        vertalign = 'Top';
        horizalign = 'right';
        txty = 0.995*maxy;
        txtx = 0.99*maxx;
    end
    if p(1) < p_thr
        set(gca,'Color',[255 255 224]/255)
%         if contains(xlbl,'Age') || contains(ylbl,'Age') || contains(xlbl,'MTR') || contains(ylbl,'MTR')
            text(txtx,txty,{['r=' num2str(r(1),'%.3f')],['\rho=' num2str(rho(1),'%.3f')]},'HorizontalAlignment',horizalign,'FontWeight','bold','FontSize',14,'VerticalAlignment',vertalign)
%         else
%             text(0.99*maxx,txty,['r=' num2str(r(1),'%.3f')],'HorizontalAlignment','right','FontWeight','bold','FontSize',14,'VerticalAlignment',vertalign)
%         end
    else
%         if contains(xlbl,'Age') || contains(ylbl,'Age') || contains(xlbl,'MTR') || contains(ylbl,'MTR')
            text(txtx,txty,{['r=' num2str(r(1),'%.3f')],['\rho=' num2str(rho(1),'%.3f')]},'HorizontalAlignment',horizalign,'FontSize',14,'Color',[0.4 0.4 0.4],'VerticalAlignment',vertalign)
%         else
%             text(0.99*maxx,txty,['r=' num2str(r(1),'%.3f')],'HorizontalAlignment','right','FontSize',14,'Color',[0.4 0.4 0.4],'VerticalAlignment',vertalign)
%         end
    end
    axis([minx maxx miny maxy])
    grid on
    set(gca,'FontSize',14,'LineWidth',2)
end

