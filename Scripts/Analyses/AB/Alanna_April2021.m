site = 'TP_VDT';
year_start = 2019; year_end = 2019;
loadstart = addpath_loadstart;
load_path = [loadstart 'Matlab/Data/Master_Files/' site '/'];
save_path = [loadstart 'Matlab/Data/Flux/Gapfilling/' site '/'];
footprint_path = [loadstart 'Matlab/Data/Flux/Footprint/'];

load([load_path site '_gapfill_data_in.mat']);
data = trim_data_files(data,year_start, year_end,1);
data.site = site; close all
% orig.data = data; % save the original data:
NEE_orig = data.NEE;

data.Ustar_th = mcm_Ustar_th_Reich(data,1);
