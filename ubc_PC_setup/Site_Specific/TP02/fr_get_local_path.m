function [dataPth,hhourPth,databasePth,csi_netPth] = fr_get_local_path

ls = addpath_loadstart;
% dataPth  = 'd:\met-data\data\';
% hhourPth  = 'd:\met-data\hhour\';
% databasePth  = '';

% dataPth  = 'D:\SiteData\TP02\met-data\data\';
% hhourPth  = 'D:\SiteData\TP02\met-data\hhour\';
% databasePth  = 'D:\SiteData\TP02\met-data\Database\';
% csi_netPth = '[]';

%%% Paths for operation on arainserv linux system:
dataPth  = [ls 'SiteData/TP02/MET-DATA/data/'];
hhourPth  = [ls 'SiteData/TP02/MET-DATA/hhour/'];
databasePth  = [ls 'SiteData/TP02/MET-DATA/meteo/'];
csi_netPth = '[]';