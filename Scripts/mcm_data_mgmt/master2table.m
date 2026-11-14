function [] = master2table(input_path, write_path)
% This function takes a master file for a site and turns it into an excel
% and csv file. 
% input_path = the full file path to the master file of interest.
% write_path = the full file path where you would like to save the
% resulting file


load(input_path); % This will load a fill called 'master' with master.data and master.labels

% Create the table directly by mapping data to the labels
T = array2table(master.data, 'VariableNames', master.labels(:,1));

% Write the table to an Excel file
writetable(T, write_path);




