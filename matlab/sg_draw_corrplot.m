function [r,p] = sg_draw_corrplot(xdata,ydata,participants,corr_text,usedata)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    sie_female = strcmp(participants.manufacturer,'Siemens') & strcmp(participants.sex,'F');
    sie_male = strcmp(participants.manufacturer,'Siemens') & strcmp(participants.sex,'M');
    ge_female = strcmp(participants.manufacturer,'GE') & strcmp(participants.sex,'F');
    ge_male = strcmp(participants.manufacturer,'GE') & strcmp(participants.sex,'M');
    phi_female = strcmp(participants.manufacturer,'Philips') & strcmp(participants.sex,'F');
    phi_male = strcmp(participants.manufacturer,'Philips') & strcmp(participants.sex,'M');

    minx=min(xdata);
    maxx=max(xdata);
    miny=min(ydata);
    maxy=max(ydata);
    x = [minx maxx];
    
    if strcmp(usedata,'All')
        [rr, pp]=corrcoef(xdata,ydata,'Rows','Pairwise');
        r(1)=rr(1,2);p(1)=pp(1,2);
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'F')),ydata(strcmp(participants.sex,'F')),'Rows','Pairwise');
        r(2)=rr(1,2);p(2)=pp(1,2);
        [rr, pp]=corrcoef(xdata(strcmp(participants.sex,'M')),ydata(strcmp(participants.sex,'M')),'Rows','Pairwise');
        r(3)=rr(1,2);p(3)=pp(1,2);
        ps = ~isnan(xdata) & ~isnan(ydata);
    elseif strcmp(usedata,'GEout')
        useonly=~strcmp(participants.manufacturer,'GE');
        [rr, pp]=corrcoef(xdata(useonly),ydata(useonly),'Rows','Pairwise');
        r(1)=rr(1,2);p(1)=pp(1,2);
        [rr, pp]=corrcoef(xdata(useonly & strcmp(participants.sex,'F')),ydata(useonly & strcmp(participants.sex,'F')),'Rows','Pairwise');
        r(2)=rr(1,2);p(2)=pp(1,2);
        [rr, pp]=corrcoef(xdata(useonly & strcmp(participants.sex,'M')),ydata(useonly & strcmp(participants.sex,'M')),'Rows','Pairwise');
        r(3)=rr(1,2);p(3)=pp(1,2);
        ps = ~isnan(xdata) & ~isnan(ydata) & useonly;
        ps2 = ~isnan(xdata) & ~isnan(ydata) & ~useonly;
        c2 = polyfit(xdata(ps2),ydata(ps2),1);
        y2 = c2(1)*x + c2(2);
    end

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
    
    if miny > 0.7
        coefy1 = 1.15;
        coefy2 = 0.05;
    else
        coefy2 = 0.10;
    end
    if p(1) < 0.05
        set(gca,'Color',[255 255 224]/255)
        for cr = 1:3
            if miny > 0.7 && miny < 40
                txty = (coefy1-coefy2*(cr-1))*miny;
            else
                txty = maxy - coefy2*cr*miny;
            end
            if p(cr) < 0.0001
                text(0.99*maxx,txty,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p<0.0001'],'HorizontalAlignment','right','FontWeight','bold')
            else
                if p(cr) < 0.05
                    text(0.99*maxx,txty,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p=' num2str(p(cr),'%.4f')],'HorizontalAlignment','right','FontWeight','bold')
                else
                    text(0.99*maxx,txty,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p=' num2str(p(cr),'%.4f')],'HorizontalAlignment','right')
                end
            end
        end
    end
    axis([minx maxx miny maxy])
    grid on
    set(gca,'FontSize',14,'LineWidth',2)
end

