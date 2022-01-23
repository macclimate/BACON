function [dataPth,hhourPth,databasePth,csi_netPth] = fr_get_local_path
loadstart = addpath_loadstart;

% dataPth  = 'D:\SiteData\TP74\met-data\data\';
% hhourPth  = 'D:\SiteData\TP74\met-data\hhour\';
% databasePth  = 'D:\SiteData\TP74\met-data\Database\';
% csi_netPth = '[]';

%%% Paths used when calculating from LACIE at HOME:
% dataPth  = 'G:\SiteData\TP74\MET-DATA\data\';
% hhourPth  = 'G:\SiteData\TP74\MET-DATA\hhour\';
% databasePth  = 'G:\SiteData\TP74\MET-DATA\Database\';
% csi_netPth = '[]';


%%% Paths for operation on arainserv linux system:

dataPth  = [loadstart 'SiteData/TP_VDT/MET-DATA/data/'];
hhourPth  = [loadstart 'SiteData/TP_VDT/MET-DATA/hhour/'];
databasePth  = [loadstart 'SiteData/TP_VDT/MET-DATA/meteo/'];
csi_netPth = '[]';