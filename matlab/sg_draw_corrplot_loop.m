function [r, p, r_norm, p_norm] = sg_draw_corrplot_loop(xdata,ydata,xdata_name,ydata_name,participants,fig_ind,fig_dimensions,usedata,tick_xdata,tick_ydata,fig_filename)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    r = zeros(size(ydata,2),size(xdata,2),3);p=r;r_norm=r;p_norm=r;
    pl=1;
    h.fig=figure(fig_ind);
    set(h.fig,'Position',fig_dimensions)
    for cs = 1:size(ydata,2)
        for dm = 1:size(xdata,2)
            subplot(size(ydata,2),size(xdata,2),pl)
            [r(cs,dm,:), p(cs,dm,:), r_norm(cs,dm,:), p_norm(cs,dm,:)] = sg_draw_corrplot(xdata(:,dm),ydata(:,cs),participants,usedata);
            if cs == size(ydata,2)
                xlabel(xdata_name{1,dm})
                set(gca,'Xtick',tick_xdata{dm,1},'Xticklabel',tick_xdata{dm,1})
            elseif cs < size(ydata,2)
                set(gca,'Xtick',tick_xdata{dm,1},'Xticklabel',' ')
            end
            if dm == 1
                ylabel(ydata_name{1,cs})
                set(gca,'Ytick',tick_ydata{cs,1},'Yticklabel',tick_ydata{cs,1})
            else
                set(gca,'Ytick',tick_ydata{cs,1},'Yticklabel',' ')
            end
            pl = pl + 1;
        end
    end
    set(gcf, 'color', [1 1 1])
    set(gcf, 'InvertHardcopy', 'off')
    print(fig_filename, '-dpng', '-r300')
    pause(0.2)
end
