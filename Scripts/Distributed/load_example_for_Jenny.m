%%% How to load a .mat file as a structure array: 
load('D:\Matlab\Data\Master_Files\TPU\TPU_Jenny.mat');  % replace with the path to your downloaded file
% loads a structure array called 'data'
% data.table is the data table as a matrix/numeric array
% data.labels = the column headers

% To reference specific columns in the data matrix
plot(data.table(:,22));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% How to load a .xlsx file as a table
data_table = readtable('D:\Matlab\Data\Master_Files\TPU\TPU_Jenny.xlsx');   % replace with the path to your downloaded file

% To reference specific columns in the data matrix
plot(data_table.DownPAR_AbvCnpy_5m_umol_m2_s_);