function [] = mcm_make_Gapfill_sums(dates_to_run)

% compile_stats

% dates_to_run = {'2024-07-08';'2024-07-09'};

base_path = 'D:\Matlab\Data\Flux\Gapfilling\';
sites = {'TP39';'TP74';'TP02';'TPD';'TPAg'};
f = fopen([base_path 'NEE_sums' dates_to_run{1} '.txt'],'w+');

for i = 1:1:length(sites)
    sums_path = [base_path sites{i} '\NEE_GEP_RE\Default'];
    
    d = dir(sums_path); 
    d_struct = (struct2cell(d))';
    clear to_use
    for j = 1:1:length(dates_to_run)
%     to_use(:,j) = strcmp(dates_to_run{j},d_struct(:,1));
    to_use(:,j) = strfind(d_struct(:,1),dates_to_run{j});
    end
    
    tmp = cellfun(@isempty,to_use);
    
    right_rows = find(sum(tmp,2)<size(dates_to_run,1));
    
    fprintf(f,'%s\n',['# ' sites{i}]);

    for j = 1:1:length(right_rows)
        f_in = fopen([sums_path '\' d_struct{right_rows(j),1}],'r');
        fprintf(f,'\n%s\n',['## ' d_struct{right_rows(j),1}(1:end-15)]);
        eof_f_in = feof(f_in);
        while eof_f_in == 0
        tmp = fgets(f_in);
        fprintf(f,'%s',tmp);
        eof_f_in = feof(f_in);
        end
        fprintf(f,'\n\n%s','');
        fclose(f_in);
    end
end

fclose(f);