%%% To use on CR1000, CR3000 data
%%% This script iterates through all subdirectories in the run_dir folder
%%% making copies of the met files within and putting them in the run_dir
%%% directory with a datestamp. This allows the user to put many files in a
%%% single directory for rapid batch processing of met data. 

run_dir = 'D:\Matlab\Data\Met\Raw1\TPAg\2025'

d = dir(run_dir);

for i = 3:1:length(d)
    switch d(i).isdir
        case 1
            cd([run_dir '\' d(i).name])
            datestamp = d(i).name(end-7:end);
            d2 = dir([run_dir '\' d(i).name]);
            for j =3:1:length(d2)
            copyfile([run_dir '\' d(i).name '\' d2(j).name],[run_dir '\' datestamp '-' d2(j).name]);
            end
        otherwise
    end
end

