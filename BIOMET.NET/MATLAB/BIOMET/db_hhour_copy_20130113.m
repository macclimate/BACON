function db_hhour_copy

% Revisions:
%
% Jan 6, 2013 (Zoran)
%   - Added a catch statement when reading lastTime.
% Nov 23, 2011
%	- added HP11 (Nick)
% July 8, 2011
%  - stop doing the previous year on every run.
%  - added HDF11, new eddy file copy for PA and BS
% October 26, 2010
%   -added copy for MPB4, HP09
% May 17, 2010
%   -added copy for MPB1, MPB2, MPB3
% Dec 5, 2008
%   -added copy for HJP94
% Oct 17, 2008
%   -added xcopy of ACS .mat files from CR to Annex001 (Nick)
% Jan 7, 2008
%   -removed hard coding of database path ( 'y:\' ) so that it is now
%       assigned by a call to db_pth_root (Nick)
% July 3, 2007 
%   -revised test for doing update to now-lastTime >= 1-1/24 to stop the update
%       of the log file from moving 1 hour each day! (Nick)

try
	x = textread('D:\met-data\log\last_run_of_hhour_copy.log','%s','whitespace','\b\t');
	lastTime = datenum(char(x(end,1)));
catch
    lastTime = datenum(2000,1,1);
end

%if now - lastTime > 1
if now - lastTime >= 1-1/24  % July 3, 2007: Nick changed
	dateVec = datevec(now);
	%for YearX = dateVec(1)-1:dateVec(1)
    for YearX = dateVec(1) % stop doing the previous year on every run, Nick July 8, 2011
        strYear = num2str(YearX);
        
        pth_db = db_pth_root; % Jan 7, 2008: Nick added
        
        % BS
        pthHH_db = [pth_db strYear '\bs\hhour_database']; % Jan 7, 2008: parsing of all paths now uses pth_db instead of hard-coded ('y:\') 
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_BS\met-data\hhour\' strYear(3:4) '????.hb.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_BS\met-data\hhour\' strYear(3:4) '????.hb_ch.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        % for new eddy files
        cmdStr = ['xcopy \\fluxnet02\HFREQ_BS\met-data\hhour\' strYear(3:4) '????.hBS.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % CR 
        pthHH_db = [pth_db strYear '\cr\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_CR\met-data\hhour\' strYear(3:4) '????.hc.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_CR\met-data\hhour\' strYear(3:4) '????s.hc_ch.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\Fluxnet02\HFREQ_CR\MET-DATA\acs-dc\MET-DATA\hhour\' strYear(3:4) '*.ACS_Flux_CR16.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        
        % HDF11 (CR clearcut site)
        pthHH_db = [pth_db strYear '\HDF11\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HDF11\met-data\hhour\' strYear(3:4) '????.hHDF11.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HDF11\met-data\hhour\' strYear(3:4) '????.TallTowerSonic.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
%         cmdStr = ['xcopy \\fluxnet02\HFREQ_HDF11\met-data\hhour\' strYear(3:4) '????s.hc_ch.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
%         dos(cmdStr)
        cmdStr = ['xcopy \\Fluxnet02\HFREQ_HDF11\MET-DATA\acs-dc\MET-DATA\hhour\' strYear(3:4) '*.ACS_Flux_CR16.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % HJP02
        pthHH_db = [pth_db strYear '\hjp02\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HJP02\met-data\hhour\' strYear(3:4) '????.hHJP02.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % HJP75
        pthHH_db = [pth_db strYear '\hjp75\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HJP75\met-data\hhour\' strYear(3:4) '????.hHJP75.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
                
        % HJP94
        pthHH_db = [pth_db strYear '\hjp94\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HJP94\met-data\hhour\' strYear(3:4) '????.hHJP94.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        
        % OY
        pthHH_db = [pth_db strYear '\oy\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_OY\met-data\hhour\' strYear(3:4) '????.hoy.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % PA 
        pthHH_db = [pth_db strYear '\pa\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_PA\met-data\hhour\' strYear(3:4) '????.hp.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_PA\met-data\hhour\' strYear(3:4) '????.hp_ch.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        % for new eddy files
        cmdStr = ['xcopy \\fluxnet02\HFREQ_PA\met-data\hhour\' strYear(3:4) '????.hPA.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        
        % YF
        pthHH_db = [pth_db strYear '\yf\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_YF\met-data\hhour\' strYear(3:4) '????.hy.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_YF\met-data\hhour\' strYear(3:4) '????.hy_ch.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % MPB1
        pthHH_db = [pth_db strYear '\mpb1\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_MPB1\met-data\hhour\' strYear(3:4) '????.hMPB1.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % MPB2
        pthHH_db = [pth_db strYear '\mpb2\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_MPB2\met-data\hhour\' strYear(3:4) '????.hMPB2.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % MPB3
        pthHH_db = [pth_db strYear '\mpb3\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_MPB3\met-data\hhour\' strYear(3:4) '????.hMPB3.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % MPB4
        pthHH_db = [pth_db strYear '\mpb4\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_MPB4\met-data\hhour\' strYear(3:4) '????.hMPB4.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % HP09
        pthHH_db = [pth_db strYear '\hp09\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HP09\met-data\hhour\' strYear(3:4) '????.hHP09.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
        
        % HP11
        pthHH_db = [pth_db strYear '\hp11\hhour_database'];
        cmdStr = ['echo ========================================================================================      >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['echo ' datestr(Now) ' >' '> ' pthHH_db '\hhour_copy.log']
        dos(cmdStr)
        cmdStr = ['xcopy \\fluxnet02\HFREQ_HP11\met-data\hhour\' strYear(3:4) '????.hHP11.mat ' pthHH_db '  /D /F /Y >' '> ' pthHH_db '\hhour_copy.log' ];
        dos(cmdStr)
	end
	fid = fopen('D:\met-data\log\last_run_of_hhour_copy.log','wt')
	fprintf(fid,'%s',datestr(now))
	fclose(fid)
end