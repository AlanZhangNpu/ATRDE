function plot_population_diversity()

problemSet = {'G4', 'G7', 'G9', 'G10', 'G12', 'G16', 'G18', 'G19'};
problemName = {'g04', 'g07', 'g09', 'g10', 'g12', 'g16', 'g18', 'g19'};
clf;

COLOR_DE = [0, 114, 189] / 255.0;
COLOR_ATRDE_NDES = [217, 83, 25] / 255.0;
COLOR_ATRDE = [170, 0, 170] / 255.0;

LINE_WIDTH = 1.5;
MARKER_SIZE = 5.0;

for iii = 1:length(problemName)
    problem_id = problemName{iii};
    file_path = [problem_id '.mat'];
    if exist(file_path, 'file')
        load(file_path);
    else
        error('aaaa');
    end
    
    data = eval(problemSet{iii});
    
    subplot(2, 4, iii);
    set(gca,'LooseInset',get(gca,'TightInset'));
    
    % marker
    x = 1 : 2000;
    maker_idx = 1:200:length(x);
    
    plot(x, data.pd_DE, '-o','LineWidth',LINE_WIDTH, 'Color', COLOR_DE, 'MarkerSize', MARKER_SIZE, 'MarkerEdgeColor', COLOR_DE, 'MarkerFaceColor', COLOR_DE,'MarkerIndices',maker_idx); hold on;
    plot(x, data.pd_SADET2_SPF, '-^','LineWidth',LINE_WIDTH, 'Color', COLOR_ATRDE_NDES, 'MarkerSize', MARKER_SIZE, 'MarkerEdgeColor', COLOR_ATRDE_NDES, 'MarkerFaceColor', COLOR_ATRDE_NDES,'MarkerIndices',maker_idx);
    plot(x, data.pd_SADET2,  '-d','LineWidth',LINE_WIDTH, 'Color', COLOR_ATRDE, 'MarkerSize', MARKER_SIZE, 'MarkerEdgeColor', COLOR_ATRDE, 'MarkerFaceColor', COLOR_ATRDE,'MarkerIndices',maker_idx);
        
    if iii == 1
        legend('DE','ATRDE\_NDES','ATRDE');
    end
    xlabel('FEs');
    ylabel('Population Diversity');
    ylabel('PD');
    title(problemName{iii});
end

end