function [r,p] = sg_draw_corrplot_loop(xdata,ydata,xdata_name,ydata_name,sex,participants,corr_text,fig_ind,fig_dimensions)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    r = zeros(size(ydata,2),size(xdata,2),3);p=r;
    pl=1;
    h.fig=figure(fig_ind);
    set(h.fig,'Position',fig_dimensions)
    for cs = 1:size(ydata,2)
        for dm = 1:size(xdata,2)
            subplot(size(ydata,2),size(xdata,2),pl)
            [r(cs,dm,:), p(cs,dm,:)] = sg_draw_corrplot(xdata(:,dm),ydata(:,cs),sex,participants,corr_text);
            if cs == size(ydata,2)
                xlabel(xdata_name{1,dm})
            end
            if dm == 1
                ylabel(ydata_name{1,cs})
            end
            pl = pl + 1;
        end
    end
end

