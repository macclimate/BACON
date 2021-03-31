function [] = mcm_quickplot_met(year, site)
% This function provides a quick plot of data (either organized (level 2)
% or cleaned (level 3), for a given site and year of interest.
% Created ~July 2009 by JJB.
% Last revised - Aug 31, 2009 by JJB

% Revision History:
%
%

%%%Paths and Variable Types:
loadstart = addpath_loadstart;
dstr = datestr(now, 30);
fig_path = [loadstart 'Matlab/Figs/Quickplot/' site '/met/' site '_met_figs_'  dstr(1:8) '/' ];
jjb_check_dirs([loadstart 'Matlab/Figs/Quickplot/' site '/met/']);
% unix(['mkdir ' fig_path]);
jjb_check_dirs(fig_path,1);


if isstr(year) == 1;
    year = str2num(year);
end
yr_str = num2str(year);

%%% Header Path
% hdr_path = [loadstart 'Matlab/Data/Met/Raw1/Docs/'];
hdr_path = [loadstart 'Matlab/Config/Met/Organizing-Header_OutputTemplate/']; % Changed 01-May-2012

%%% Load Path -- let the user choose where the data comes from:
% commandwindow;
% resp = input('Data Location: <1> for Organized, <2> for Cleaned: ');
resp = menu('Select Data Level to Plot:', 'Organized', 'Cleaned');
if resp == 2
load_path = [loadstart 'Matlab/Data/Met/Cleaned3/' site '/'];%[loadstart 'Matlab/Data/Met/Cleaned3/' site '/Column/30min/' site '_' year '.'];        
else
load_path = [loadstart 'Matlab/Data/Met/Organized2/' site '/Column/30min/'];%[loadstart 'Matlab/Data/Met/Cleaned3/' site '/Column/30min/' site '_' year '.'];
end
        
%%% Load Header
header = jjb_hdr_read([hdr_path site '_OutputTemplate.csv'],',', 3);

%%% Load thresholds (if they exist):
% % if exist([loadstart 'Matlab\Data\Met\Cleaned3\Threshold\' site '_thresh_' yr_str '.dat'],'file')
% % thresh = load([loadstart 'Matlab\Data\Met\Cleaned3\Threshold\' site '_thresh_' yr_str '.dat']);
% % scale_flag = 1; % turns on or off scaling the plots using thresholds:
% % else
% %     scale_flag = 0;
% % end

%%% Take information from columns of the header file
%%% Column vector number
col_num = str2num(char(header(:,1)));
%%% Title of variable
var_names = char(header(:,2));
%%% Minute intervals
header_min = str2num(char(header(:,3)));
%%% Use minute intervals to find 30-min variables only
vars30 = find(header_min == 30);
%%% Create list of extensions needed to load all of these files
vars30_ext = create_label(col_num(vars30),3);
%%% Create list of titles that are 30-minute variables:
names30 = header(vars30,2);
if isleapyear(year) == 1;
    len_yr = 17568;
else
    len_yr = 17520;
end

%% Step 1: Plot All Variables in 6-per-figure fashion:
 close all;
incr = 6;
subplot_rows = 3;
subplot_cols = 2;
plot_x = ((2:1:len_yr+1)')./48;

for j = 1:incr:length(vars30)
           f1(j) = figure(ceil(j./incr)); clf
    for k = 1:1:incr
        if j+k-1 <= length(vars30)
        temp_var = load([load_path site '_' yr_str '.' vars30_ext(j+k-1,:)]);
    subplot(subplot_rows,subplot_cols,k)
    plot(plot_x,temp_var)
    title(var_names(vars30(j+k-1),:));
% %     if scale_flag == 1;
% %         axis([0 plot_x(end) (thresh(j+k-1,2) - 0.1.*thresh(j+k-1,2)) (thresh(j+k-1,3) + 0.1.*thresh(j+k-1,3))  ])
% %     end
        
        end
    end
    print(f1(j),'-dpng',[fig_path site '_' yr_str '_' num2str(ceil(j./incr))]);
    saveas(f1(j),[fig_path site '_' yr_str '_' num2str(ceil(j./incr)) '.fig']);
    
    
end
%%% Brings back the GUI
mcm_start_mgmt
        
    