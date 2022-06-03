function [coeff,score,latent,tsquared,explained,mu] = sg_draw_biplot(data,data_name,fig_num,fig_size,fig_filename)
%SG_DRAW_BIPLOT Summary of this function goes here
%   Detailed explanation goes here

    data_mean = mean(data,'omitnan');
    data_std = std(data,'omitnan');
    data = ( data - repmat(data_mean,size(data,1),1) ) ./ repmat(data_std,size(data,1),1);
    [coeff,score,latent,tsquared,explained,mu] = pca(data);

    for ind = 1:size(data_name,2)
        brk_pos=find(data_name{1,ind}=='[');
        data_name{1,ind} = data_name{1,ind}(1:brk_pos-2);
    end

    h.fig = figure(fig_num);
    set(h.fig, 'Position', fig_size);

    subplot(2,3,1)
    cmp1=1;cmp2=2;
    bp=biplot(coeff(:,[cmp1 cmp2]),'VarLabels',data_name,'LineWidth',3,'MarkerSize',30);
    sg_mod_biplot(bp,explained,cmp1,cmp2)

    subplot(2,3,2)
    cmp1=1;cmp2=3;
    bp=biplot(coeff(:,[cmp1 cmp2]),'VarLabels',data_name,'LineWidth',3,'MarkerSize',30);
    sg_mod_biplot(bp,explained,cmp1,cmp2)

    subplot(2,3,3)
    cmp1=2;cmp2=3;
    bp=biplot(coeff(:,[cmp1 cmp2]),'VarLabels',data_name,'LineWidth',3,'MarkerSize',30);
    sg_mod_biplot(bp,explained,cmp1,cmp2)

    subplot(2,3,4)
    cmp1=1;cmp2=4;
    bp=biplot(coeff(:,[cmp1 cmp2]),'VarLabels',data_name,'LineWidth',3,'MarkerSize',30);
    sg_mod_biplot(bp,explained,cmp1,cmp2)

    subplot(2,3,5)
    cmp1=1;cmp2=5;
    bp=biplot(coeff(:,[cmp1 cmp2]),'VarLabels',data_name,'LineWidth',3,'MarkerSize',30);
    sg_mod_biplot(bp,explained,cmp1,cmp2)

    subplot(2,3,6)
    plot(explained,'-','LineWidth',4,'Marker','.','MarkerSize',60,'Color',[0 0.749 1])
    axis([1 size(data,2) 0 explained(1)+2])
    grid on
    xlabel('Component number')
    ylabel('Explained variability [%]')
    title('Variability explained per each component')
    set(gca,'FontSize',13,'LineWidth',2)

    pause(0.15)
    print(fig_filename, '-dpng', '-r300')
    pause(0.1)
end

function sg_mod_biplot(bp,explained,cmp1,cmp2)
    for ind = 1:(size(bp,1)-1)
        if bp(ind).Color(3) == 1
            bp(ind).Color = [0 0.749 1];
            bp(ind).LineWidth = 4;
            bp(ind).MarkerSize = 40;
        else     
            bp(ind).FontSize = 8;
            bp(ind).FontWeight = 'bold';
            if bp(ind).Position(1) < 0
                bp(ind).HorizontalAlignment = 'right';
            end
            if bp(ind).Position(2) >= 0 && bp(ind).Position(2) < 0.03
                bp(ind).Position(2) = bp(ind).Position(2)+0.015;
            elseif bp(ind).Position(2) <= 0 && bp(ind).Position(2) > -0.03
                bp(ind).Position(2) = bp(ind).Position(2)-0.015;
            end
        end
    end
    bp(end).LineWidth=3;
    xlabel(['Component ' num2str(cmp1) ' [variability: ' num2str(round(explained(cmp1,1)*100)/100,'%.2f') '%]'])
    ylabel(['Component ' num2str(cmp2) ' [variability: ' num2str(round(explained(cmp2,1)*100)/100,'%.2f') '%]'])
    title('PCA variable biplot projection')
    set(gca,'FontSize',13,'LineWidth',2)
    set(gca,'XTick',-1:0.1:1,'XTickLabel',num2str([-1:0.1:1]'))
    set(gca,'YTick',-1:0.1:1,'YTickLabel',num2str([-1:0.1:1]'))
end