function [footprint_flag Xpct_out] = run_mcm_footprint(site,year, pause_flag) %, year_start, year_end)
%%% run_mcm_footprint.m
%%% usage: [] = run_mcm_footprint(site)
%%% This function is the top footprint calculation function.  It executes
%%% the main footprint program (mcm_footprint.m), with pre-set input
%%% parameters -- these can be modified as necessary.
%%% Created: June, 2010 by JJB.
%
%
% Revision History:
%
% Aug 3, 2010, JJB
%  - Commented function.  Changed year end to 2014 (from
% 2012), so it better matches the setup of rest of the files.
%  - Added a line to display the Ustar threshold used.

if nargin == 1
    year = [];
    save_flag = [];
    pause_flag = 1;
elseif nargin == 2
    pause_flag = 1;
    save_flag = [];
else
    save_flag = 1;
end

disp('Please make sure you''ve run mcm_data_compiler since last changes to the met/flux data.');
if pause_flag == 1;
    disp('Hit Enter to confirm > ');
    pause;
end


if isempty(save_flag)==1;
    commandwindow;
    save_resp = input('Save the output to the footprint flag file? (y/n) > ','s');
    if strcmp(save_resp,'y')==1
        save_flag = 1;
    else
        save_flag = 0;
    end
end

if save_flag == 1
    disp('File will be saved.');
else
    disp('File will not be saved.');
end

% Disabled --> Users get no choice.
% if isempty(year)==1
%     year = input('Enter Years to process, as integer (e.g. 2008) or sequence (e.g. 2003:2008): ');
% end
% year_start = min(year);
% year_end = max(year);


% Set Starting parameters
% year_start = 2002;
% year_end = 2014;
% year = 2002:1:2014;

clear year;
disp(['site = ' site]);
% Set default ustar threshold
switch site
    case 'TP39'
        Ustar_th = 0.3;
    case 'TP74'
        Ustar_th = 0.25;
    case 'TP89'
        Ustar_th = 0.3;
    case 'TP02'
        Ustar_th = 0.15;
    case 'TPD'
        Ustar_th = 0.3;        
    case 'TPAg'
        Ustar_th = 0.10;
    case 'TP_VDT'
        Ustar_th = 0.10;       
end
% Give the user option to change from the default value:

% disp('Must set u_{*} threshold.');
% resp = input(['Press <enter> to use default (' num2str(Ustar_th) '), or <1> to enter new threshold: ']);
% if ~isempty(resp)
%     Ustar_th = input('Enter New u_{*} threshold: ');
% end
disp(['Using default u_{*} threshold of ' num2str(Ustar_th) '.  If you want to change, edit run_mcm_footprint.']);

% Set up cumulative flux source distance acceptance thresholds (e.g. the
% proportion of measured flux that must come from within the footprint in
% order for a given measurement to be deemed acceptable for use.
XCrit_list = (0.6:0.05:0.9)'; %[0.6 0.7 0.8];

% Set Footprint Types:
% fptypes = {'Schuepp';'Kljun'};
%%% Modified by JJB 22-Jan-2014 --> Removed Schuepp from footprint
%%% operations -- It's pretty much garbage.  Instead, I've replaced it with
%%% 'Kljun_all'
fptypes = {'Kljun';'Kljun_all'};

%%% Set Paths:
ls = addpath_loadstart;
fig_path = [ls 'Matlab/Figs/Footprint/'];
data_path = [ls 'Matlab/Data/Master_Files/' site '/'];
save_path = [ls 'Matlab/Data/Flux/Footprint/'];
%%% Load the data file, trim off unnecessary years:
load([data_path site '_gapfill_data_in.mat']);
%%% Find the earliest and latest years that we have data:
year_start = data.Year(find(~isnan(data.Ta),1,'first'));
year_end = data.Year(find(~isnan(data.Ta),1,'last'));

data = trim_data_files(data,year_start, year_end);

% %%% Load the footprint_flag file (if it exists)
% if exist([save_path site '_footprint_flag.mat'],'file')==2
%     load([save_path site '_footprint_flag.mat']);
%     exist_flag = 1;
% else
%     footprint_flag = struct;
%     year_start = 2002;
%     year_end = 2018;
%     disp('footprint_flag.mat file not found.  Creating a new one and running from 2002-2015.');
%     exist_flag = 0;
% end


year_list = [];
for year = year_start:1:year_end
    year_list = [year_list; year.*ones(yr_length(year),1)];
end
% if exist_flag ==0
%     footprint_flag.Year = year_list;
% end
%% Run the footprint program...
%%% For each input year, footprint model, and XCrit value:
XCrit_raw = (0.5:0.05:0.90)'; % All the internal footprint programs run between 50 and 90%
% for XCrit_ctr = 1:1:length(XCrit_list)
%     XCrit = XCrit_list(XCrit_ctr);
for fp_ctr = 1:1:length(fptypes)
    %     disp(['Now running ' char(fptypes(fp_ctr,1)) ' for XCrit = ' num2str(XCrit_list(XCrit_ctr)) '.']);
    disp(['Now running ' char(fptypes(fp_ctr,1)) '.']);
    
    [flag_file, max_fetch, Xpct_all] = ...
        mcm_footprint(data, site, year_start, year_end, fptypes{fp_ctr,1}, XCrit_list, Ustar_th,'on');
    
    for XCrit_ctr = 1:1:length(XCrit_list)
        XCrit = XCrit_list(XCrit_ctr);
        right_col = find(XCrit_raw == XCrit);
        eval(['footprint_flag.' fptypes{fp_ctr,1} num2str(XCrit.*100) ...
            ' =[year_list flag_file(:,' num2str(right_col) ')];']);
        clear XCrit;          
    end
    eval(['Xpct_out.' fptypes{fp_ctr,1} ' = Xpct_all;']);
    %     disp(['footprint_flag.' fptypes{fp_ctr,1} num2str(XCrit.*100) '
    %     =[year_list flag_file];']);
    clear flag_file max_fetch Xpct_all
end
%     clear XCrit;
% end
%%% Added 06-Jan-2011 by JJB - Put a field with year in top structure:
footprint_flag.Year = year_list;
Xpct_out.Year = year_list;
%%% Save the Output Data:
if save_flag == 1;
    save([save_path site '_footprint_flag.mat'],'footprint_flag');
    save([save_path site '_XPct_out.mat'],'Xpct_out');
    disp(['footprint flag file saved as: ' save_path site '_footprint_flag.mat']);
end
mcm_start_mgmt;