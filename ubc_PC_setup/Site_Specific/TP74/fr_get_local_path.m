function [dataPth,hhourPth,databasePth,csi_netPth] = fr_get_local_path
ls = addpath_loadstart;

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

dataPth  = [ls 'SiteData/TP74/MET-DATA/data/'];
hhourPth  = [ls 'SiteData/TP74/MET-DATA/hhour/'];
databasePth  = [ls 'SiteData/TP74/MET-DATA/meteo/'];
csi_netPth = '[]';