function response = RAE2822(x)

work_path   = 'C:\Users\zhangyw\rae2822\';
dv_path     = [work_path 'DV.txt'];
cmd_path    = [work_path 'run.bat'];
cal_path    = [work_path 'DESIGNS\'];
result_path = [work_path 'history_project.dat'];

f = zeros(size(x, 1), 1);
g = zeros(size(x, 1), 2);
for i = 1 : size(x, 1)
    % export design variables
    fp = fopen(dv_path,'wt');
    for j = 1 : size(x, 2)
        fprintf(fp, '%d\n', x(i, j));
    end
    fclose(fp);
    
    % run the SU2 solver
    exportCMDFile(cmd_path);
    rmdir(cal_path,'s');
    system(cmd_path);
    
    % extract the results
    data = importdata(result_path);
    LIFT = data.data(1, 2);
    DRAG = data.data(1, 3);
    AIRFOIL_AREA = data.data(1, 15);
    
    f(i,1) = DRAG;
    g(i,1) = 0.723 - LIFT;
    g(i,2) = 0.06 - AIRFOIL_AREA;
end

response = [f g];

    function exportCMDFile(bat_path)
        fid = fopen(bat_path,'w');
        if fid <= 0
            error(['open file failed:' file_path]);
        end
        
        cmd_str = 'C:\\Python27\\python.exe rae2822_eval.py -f DV20_ITER2000.cfg';
        
        fprintf(fid,'%s\n',work_path(1,1:2));
        fprintf(fid,'cd %s\n',work_path);
        fprintf(fid,'%s\n', cmd_str);
        fclose(fid);
    end

end