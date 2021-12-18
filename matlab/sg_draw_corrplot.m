function [r,p] = sg_draw_corrplot(xdata,ydata,sex,participants,corr_text)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    [rr, pp]=corrcoef(xdata,ydata,'Rows','Pairwise');
    r(1)=rr(1,2);
    p(1)=pp(1,2);
    [rr, pp]=corrcoef(xdata(sex==1),ydata(sex==1),'Rows','Pairwise');
    r(2)=rr(1,2);
    p(2)=pp(1,2);
    [rr, pp]=corrcoef(xdata(sex==0),ydata(sex==0),'Rows','Pairwise');
    r(3)=rr(1,2);
    p(3)=pp(1,2);
    
    minx=min(xdata);
    maxx=max(xdata);
    miny=min(ydata);
    maxy=max(ydata);

    ps = ~isnan(xdata) & ~isnan(ydata);
    c = polyfit(xdata(ps),ydata(ps),1);
    x = [minx maxx];
    y = c(1)*x + c(2);


    sie_female = strcmp(participants.manufacturer,'Siemens') & sex==1;
    sie_male = strcmp(participants.manufacturer,'Siemens') & sex==0;
    ge_female = strcmp(participants.manufacturer,'GE') & sex==1;
    ge_male = strcmp(participants.manufacturer,'GE') & sex==0;
    phi_female = strcmp(participants.manufacturer,'Philips') & sex==1;
    phi_male = strcmp(participants.manufacturer,'Philips') & sex==0;


    plot(x,y,'k-.','LineWidth',4)
    hold on
    plot(xdata(sie_female),ydata(sie_female),'go','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(sie_male),ydata(sie_male),'gx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(phi_female),ydata(phi_female),'bo','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(phi_male),ydata(phi_male),'bx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(ge_female),ydata(ge_female),'ro','LineStyle','none','LineWidth',3,'MarkerSize',11)
    plot(xdata(ge_male),ydata(ge_male),'rx','LineStyle','none','LineWidth',3,'MarkerSize',11)
    hold off
    
    if miny > 0.45
        coefy1 = 1.15;
        coefy2 = 0.05;
    elseif miny <= 0.45 && miny > 0.3
        if maxy < 1
            coefy1 = 1.25;
            coefy2 = 0.07;
        else
            coefy1 = 1.32;
            coefy2 = 0.10;
        end
    else
        coefy1 = 1.75;
        coefy2 = 0.25;
    end
    if p(1) < 0.05
        for cr = 1:3
            if p(cr) < 0.0001
                text(0.99*maxx,(coefy1-coefy2*(cr-1))*miny,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p<0.0001'],'HorizontalAlignment','right','FontWeight','bold')
            else
                if p(cr) < 0.05
                    text(0.99*maxx,(coefy1-coefy2*(cr-1))*miny,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p=' num2str(p(cr),'%.4f')],'HorizontalAlignment','right','FontWeight','bold')
                else
                    text(0.99*maxx,(coefy1-coefy2*(cr-1))*miny,[corr_text{1,cr} num2str(r(cr),'%.3f') '; p=' num2str(p(cr),'%.4f')],'HorizontalAlignment','right')
                end
            end
        end
    end
    axis([minx maxx miny maxy])
    grid on
    set(gca,'FontSize',14,'LineWidth',2)
end

