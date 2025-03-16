thresh_dir = 'D:\Matlab\Config\Flux\CPEC\Cleaning-Thresholds';

site = {'TP39';'TP74';'TP02';'TPD'; 'TP_VDT'};
site_thresh_low = {};
site_thresh_high = {};
year_list = cellstr(num2str((2002:1:str2num(datestr(now,'yyyy')))'));


for i = 1:1:length(site)
    site_tmp = site{i};
 
%   Load variable names (to use in table)
    var_names_tmp = mcm_get_fluxsystem_info(site_tmp, 'varnames');
    t = struct2table(var_names_tmp);
    var_names = table2cell(t(:,2));

    site_thresh_low_tmp = NaN.*ones(size(var_names,1),size(year_list,1)); % Struture it with variables as rows and years as columns
    site_thresh_high_tmp = site_thresh_low_tmp;
    j = 1;
    for year = 2002:1:str2num(datestr(now,'yyyy'))
        
        try
            a = load([thresh_dir '\' site_tmp '_thresh_' num2str(year) '.dat']);
            site_thresh_low_tmp(1:size(a,1),j) = a(:,2);
            site_thresh_high_tmp(1:size(a,1),j) = a(:,3);
        catch
            
        end
        j = j+1;
    end
    
site_thresh_low{i} = array2table(site_thresh_low_tmp(1:size(var_names,1),:),'VariableNames',year_list,'RowNames',var_names);
site_thresh_high{i} = array2table(site_thresh_high_tmp(1:size(var_names,1),:),'VariableNames',year_list,'RowNames',var_names);

clear site_thresh_low_tmp site_thresh_high_tmp;
    
end
