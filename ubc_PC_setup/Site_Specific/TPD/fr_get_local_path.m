function [dataPth,hhourPth,databasePth,csi_netPth] = fr_get_local_path
% Commented by JJB - changed to linux paths:
ls = addpath_loadstart;
all_path = set_all_biomet_paths;
% dataPth  = [all_path.DATA.Root '\'];
% hhourPth  = [all_path.HHOUR.Root '\'];
% databasePth  = [all_path.DATABASE.Root '\'];
% csiPth  = [all_path.CSI_NET.Root '\'];
dataPth  = [ls 'SiteData/TPD/MET-DATA/data/'];
hhourPth  = [ls 'SiteData/TPD/MET-DATA/hhour/'];
databasePth  = [ls 'SiteData/TPD/MET-DATA/meteo/'];
csi_netPth = '';
