function [t,x] = hdf11_pl(ind, year, select, fig_num_inc,pause_flag)
%
% [t,x] = frbc_pl(ind, year, select fig_num_inc)
%
%   This function plots selected data from the data-logger files. It reads from
%   the UBC data-base formated files.
%
%
% (c) Nesic Zoran           File created:       Jul  8, 1997
%                           Last modification:  Nov 10, 2011
%

% Revisions:
% Jan 10, 2012 (Eugenie)
%   -added site name to figures
%   -added cumulative traces for the short tower rain gauges
% Nov 10,2011 (Eugenie)
%   - added sonic snow depth sensor
% June 2,2011 (Eugenie)
%   -removed Licor box temperature
%   -added sample tube temperature from short tower, added rain gage
% May 27, 2011 (Eugenie)
%   -added climate data from scaffold tower: CNR1, HMP, PAR sensors, Panel
%   temperature
%   - change wind direction units to degree
% May 6, 2011
%   -created hdf11_pl based on frbc_pl
% Feb 3, 2011
%   -plots of below canopy sonic are now year dependent
% Mar 20, 2009 (Christian)
%  - Fixed a bug in plotting MPS Soil Water Potential Sensors
%
% Jan 18, 2009 (Zoran)
%   - Fixed a bug where somebody with a good sense of humor had hard coded the year
%   to be 2008 for some (but not all) of WaterQ plots.  The joker's name was
%   probably Zoran but Nick's chances to claim the title are not bad
%   either. ;-)
% Jan 14, 2009 (Christian)
%   - added 2 graphs showing wind speed and direction of the above (Gill) and below canopy sonic (RM Young 81000)
%   - added wind direction histogram of the below canopy sonic (RM Young 81000)
% Nov 19, 2008
%   - added compressor plot, move MPS logger diagnostic traces with other traces, added profile TC in diagnostic (Dom)
% Sep 26, 2008
%   - added MPS diagnostics and sensor traces (Nick)
% Sep 25, 2008
%   - changes to WaterQ plots (Zoran and Nick)
% Sept 23, 2008
%   -added WaterQ diagnostics (Nick)
% Sept 19, 2008
%   - added second reference pressure transducer trace
% Nov 09 2007
%   - added chamber pressure tank trace (Dom)
% Mar 13, 2006
%   - enabled zooming in Generator ON figure (Zoran)
% Jan 09, 2006 (Kai and Steph) 
% - Inserted an extra line to soil_moisture plots
%
% Nov 21, 2005 (Dominic)
%   - Changed panel T legend
%   - Remove Net 01, Net 02 and replaced them by CNR1 trace
%   - Remove 445ppm tank transducer trace
%   - Added PRT trace with HMP
% Mar 22, 2005
%   - added sing soil chamber system
% Jan 31, 2005
%   - added soil moisture logger data
% Dec 27, 2002
%   - changed AC_ON signal from FR_D (old,logger, removed) to FR_Gen (new ctrl. logger)
% Sep 27, 2002
%   - changed and added new measurements (FR_GEN - new logger)
% Jun 19, 2002
%   - added 24V battery voltage measurement
% Feb 1, 2002
%   - isolated diagnostic info in this program
% Dec 27, 2001
%   - matched the outputs of BB1 and BB2 (BB2-0.3V)
%   - changed axes for panel temps.
% Dec 16, 2001
%   - added plotting of BB1 using FR_CLIM measurement (Phone_bat.)
% Feb 1, 2001
%   - added gashound data trace, fixed up fr_c traces
% Jan 31, 2001
%   - changed some axes, added Gen-ON plots, changed the way Gen-Run-Time is
%     calculated (this time this is 100% accurate, AC sensing circuit is used)
% Jan 15, 2001
%   - changed some paths
% Jul 22, 2000
%   - removed a few graphs, adjusted some axes...
% Jun 27, 2000
%   - added a correction for the third Net and one extra 1:1 plot
% Jun 1, 2000
%   - added Net 1:1 plot
%
% Dec 30 ,1999
%   - changes in biomet_path calling syntax.
% Nov 21, 1999
%   - added estimation of N2 usage (kPa/Week)
%   Nov 14, 1999
%       - changed plotting of the closure graphs. Now the program does NOT
%         remove trailing and leading zeros before plotting (added ",0" in
%         read_sig(...) )
%   September 02, 1999
%       - added third R.M. Young at 3.5-m height
%   May 15, 1999
%       - introduced global paths (file biomet_path.m), removed LOCAL_PATH variable
%       - adjusted a few axes
%   March 24, 1999
%       - added dave datalogger battery voltage on separate fig with uvic voltage
%       - indicated HMP location and shield in figure legend
%   March 22, 1999
%       - added throughfall data (throughs only) from 'dave' datalogger
%   Feb 7, 1999
%       - fixed cumulative rain plotting for year!=1998 (offset adding removed
%         if year!=1998) for the second gauge.
%   Jan 1, 1999
%       - changes to alow for the new year (1999). The changes enabled
%         automatic handling of the "year" parameter.
%   Nov 6, 1998
%       - added RM Young at 3.5 m
%       Oct 30, 1998
%           - uvic_01 battery voltage, sap flow gauges and more tree thermocouples
%       Oct 14, 1998
%           - introduced WINTER_TEMP_OFFSET for easy rescaling of temperature axes
%             in the program
%       Aug 19, 1998
%           - Rick added new net, PSP, PAR, Soil Temps
%       June 9, 1998
%           -   added charging current plots

% More revisions at the end of the file
%

if ind(end) > datenum(0,4,15) & ind(end) < datenum(0,10,15);
    WINTER_TEMP_OFFSET = 0;
else
    WINTER_TEMP_OFFSET = 15;
end

colordef none

if nargin < 5
    pause_flag = 0;
end
if nargin < 4
    fig_num_inc = 1;
end
if nargin < 3
    select = 0;
end
if nargin < 2 | isempty(year)
    year = datevec(now);                    % if parameter "year" not given
    year = year(1);                         % assume current year
end
if nargin < 1 
    error 'Too few imput parameters!'
end

GMTshift = 8/24;                                    % offset to convert GMT to PST

[pth] = biomet_path(year,'HDF11','cl');            % get the climate data path
axis1 = [340 400];
axis2 = [-10 5];
axis3 = [-50 250];
axis4 = [-50 250];

% Find logger ini files
ini_climMain = fr_get_logger_ini('HDF11',year,'fr_clim','fr_clim_105');   % main climate-logger array
ini_clim2    = fr_get_logger_ini('HDF11',year,'fr_clim','fr_clim_106');   % secondary climate-logger array
ini_soilMain = fr_get_logger_ini('HDF11',year,'fr_soil','fr_soil_101');   % main soil-logger array


st = min(ind);                                      % first day of measurements
ed = max(ind)+1;                                      % last day of measurements (approx.)
ind = st:ed;

fileName = fr_logger_to_db_fileName(ini_climMain, '_dt', pth);
t=read_bor(fileName);                               % get decimal time from the data base

offset_doy=0;

t = t - offset_doy + 1 - GMTshift;                  % convert decimal time to
                                                    % decimal DOY local time
t_all = t;                                          % save time trace for later                                                    
ind = find( t >= st & t <= ed );                    % extract the requested period
t = t(ind);
fig_num = 1 - fig_num_inc;

if 1==1


%----------------------------------------------------------
% HMP air temperatures_Tall and short towers
%----------------------------------------------------------
trace_name  = 'HDF11: HMP air temperatures';
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'HMP_T_1_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'HMP_T_2_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'HMP_T_3_AVG', pth),...
                        [pth 'fr_b\fr_b.20'],fullfile(pth,'FR_clearcut','HMP_T_Avg'));
trace_legend = str2mat('HMP\_27m Gill','HMP\_41m Met-1','HMP\_4m Met-1','PRT\_41m Met-1','HMP\_short tower');
trace_units = '(degC)';
y_axis      = [0 35] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Battery voltage 24V
%----------------------------------------------------------
trace_name  = 'HDF11: Battery voltage 24V';
trace_path  = str2mat(  [pth 'fr_gen\fr_gen_101.7'],...
                        [pth 'fr_gen\fr_gen_101.22'],...
                        [pth 'fr_gen\fr_gen_101.37']);
trace_legend = str2mat('Avg','Max','Min');
trace_units = '(V)';
y_axis      = [23 31];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Dirty 12V in Hut
%----------------------------------------------------------
trace_name  = 'HDF11: Dirty 12V in Hut';
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'Phone_bat_AVG', pth),...
fr_logger_to_db_fileName(ini_climMain, 'Phone_bat_MAX', pth),...
fr_logger_to_db_fileName(ini_climMain, 'Phone_bat_MIN', pth));

trace_legend = str2mat('phone\_batt\_AVG','phone\_batt\_MAX','phone\_batt\_MIN');
trace_units = '(V)';
y_axis      = [10.5 14.5];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Clean 12V in Hut
%----------------------------------------------------------
trace_name  = 'HDF11: Clean 12V in Hut';
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'Batt_Volt_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'Batt_Volt_MAX', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'Batt_Volt_MIN', pth));
                            
%trace_path  = str2mat([pth 'fr_a\fr_a.5'],[pth 'fr_a\fr_a.6'],[pth 'fr_a\fr_a.8']);
trace_legend = str2mat('fr\_Clim Avg','fr\_Clim Max','fr\_Clim Min');
trace_units = '(V)';
y_axis      = [11 13.5];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Logger Voltages
%----------------------------------------------------------
trace_name  = 'HDF11: Logger voltages';
trace_path  = str2mat([pth 'fr_clim\fr_clim_105.5'], [pth 'fr_f\fr_f.5'],[pth 'fr_b\fr_b.5'], [pth 'fr_c\fr_c.5'],fullfile(pth, 'FR_clearcut','BattVolt_Avg'));
trace_legend = str2mat('FR\_Clim\_avg','FR\_F\_avg','FR\_B\_avg','FR\_C\_avg', 'Fr clearcut Avg');
trace_units = '(V)';
y_axis      = [10.5 14];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% FR_GEN voltage
%----------------------------------------------------------
trace_name  = 'HDF11: FR_Gen voltage';
%trace_path  = str2mat([pth 'fr_a\fr_a.11'],[pth 'fr_a\fr_a.12'],[pth 'fr_a\fr_a.14'],[pth 'fr_a\fr_a.50'],[pth 'fr_b\fr_b.11']);
trace_path  = str2mat(  [pth 'fr_gen\fr_gen_101.5'],...
                        [pth 'fr_gen\fr_gen_101.20'],...
                        [pth 'fr_gen\fr_gen_101.35']);
trace_legend = [];
trace_units = '(V)';
y_axis      = [12 14];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Generator hut temperatures
%----------------------------------------------------------
trace_name  = 'HDF11: Generator hut temperatures';
%trace_path  = str2mat([pth 'fr_c\fr_c.46'],[pth 'fr_a\fr_a.47']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'T_genhut_AVG', pth),[pth 'fr_b\fr_b.20']);

trace_legend = str2mat('Tc_genHut','Air\_PRT');
trace_units = '(degC)';
y_axis      = [-10 50];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Generator ON
%----------------------------------------------------------
trace_name  = 'HDF11: Generator ON';
trace_path = read_sig( [pth 'fr_gen\fr_gen_101.8'], ind,year, t, 0 );
trace_legend = [];
trace_units = '1';
y_axis      = [0 1.5];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );

h  = get(fig_num,'child');
for i = 1:length(h)
    junk = get(h(i),'tag');
    if strcmp(junk,''); break;end
end
axes(h(i))
ax = axis;
text((ax(2)-ax(1))*.1 + ax(1), 1.3, ...
    sprintf('Gen.run-time for this period = %5.1f hours or %5.1f hours per day.', ...
    sum(trace_path)/2,sum(trace_path)/2/(length(trace_path)/48)));
zoom on
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % Generator daily run-time 
% %----------------------------------------------------------
% trace_name  = 'Generator daily run-time';
% x = read_sig( [pth 'fr_gen\fr_gen_101.7'], ind,year, t, 0 );
% X=cumsum(x)/2;
% trace_path = [X(48) ;X(49:48:end)-X(1:48:end-48)];
% t_new = t(1:48:end);
% trace_legend = [];
% trace_units = 'hours/day';
% y_axis      = [];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t_new, fig_num );
% if pause_flag == 1;pause;end


%----------------------------------------------------------
% Tank Pressures
%----------------------------------------------------------
trace_name  = 'HDF11: Tank Pressures';
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'Press_Ref_AVG', pth),...
                     fr_logger_to_db_fileName(ini_climMain, 'Press_445_AVG', pth),...                      
                     fr_logger_to_db_fileName(ini_climMain, 'Press_zer_AVG', pth),...
                     fr_logger_to_db_fileName(ini_climMain, 'Press_335_AVG', pth));
                      
trace_legend = str2mat('Ref_R','Ref_L','Cal0','Cal1');
trace_units = '(psi)';
y_axis      = [0 3000];
fig_num = fig_num + fig_num_inc;
x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
x=x_all(:,1);
ref_lim = 400;                              % lower limit for the ref. gas tank-pressure
index = find(x > 0 & x <=2500);
px = polyfit(x(index),t(index),1);         % fit first order polynomial
lowLim = polyval(px,ref_lim);                   % return DOY when tank is going to hit lower limit
ax = axis;
perWeek = abs(7/px(1));
text(ax(1)+0.01*(ax(2)-ax(1)),250,sprintf('Rate of change = %4.0f psi per week',perWeek));
text(ax(1)+0.01*(ax(2)-ax(1)),100,sprintf('Low limit(%5.1f) will be reached on DOY = %4.0f',ref_lim,lowLim));
zoom on
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % Chamber compressor
% %----------------------------------------------------------
% 
% trace_name  = 'Chamber compressor';
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain,'Pchamber_AVG', pth));
% trace_legend = str2mat('Ch Compressor');
% trace_units = '(psi)';
% y_axis      = [0 150];
% fig_num = fig_num + fig_num_inc;
% x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% zoom on;
% if pause_flag == 1;pause;end


%----------------------------------------------------------
% Big Hut temperatures
%----------------------------------------------------------
trace_name  = 'HDF11: Big hut temperatures';
%trace_path  = str2mat([pth 'fr_a\fr_a.11'],[pth 'fr_a\fr_a.12'],[pth 'fr_a\fr_a.14'],[pth 'fr_a\fr_a.50'],[pth 'fr_b\fr_b.11']);
trace_path  = str2mat(  [pth 'fr_gen\fr_gen_101.9'],...
                        [pth 'fr_gen\fr_gen_101.10'],...
                        [pth 'fr_gen\fr_gen_101.6']);

trace_legend = str2mat('Hut','Battery Box','CR10x');
trace_units = '(degC)';
y_axis      = [5 40];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end
%----------------------------------------------------------
% Panel temperatures_Tall and short towers
%----------------------------------------------------------
trace_name  = 'HDF11: Panel temperatures';
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'Panel_T_AVG', pth),...
                      [pth 'fr_b\fr_b.11'],fullfile(pth,'FR_Clearcut','LoggerRefTemp_Avg'),...
                      fullfile(pth,'FR_Clearcut','AM25TRefTemp_Avg'),fullfile(pth,'FR_Clearcut','AM25TRefTemp2_Avg'));
                   
trace_legend = str2mat('fr\_clim T Avg','fr\_b T Avg','FR\_clearcut T Avg', 'AM25T #1 T Avg','AM25T #2 T Avg');
trace_units = '(degC)';
y_axis      = [0 50] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Sampling tube temp.
%----------------------------------------------------------
trace_name  = 'HDF11: Sample tube temp';
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','TubeHeatherTC_Avg1'),fullfile(pth, 'FR_clearcut','TubeHeatherTC_Avg2'), fullfile(pth, 'FR_clearcut','TubeHeatherTC_Avg3'),fullfile(pth, 'FR_clearcut','HMP_T_Avg'));
%trace_path  = str2mat([pth 'fr_f\fr_f.27'],[pth 'fr_f\fr_f.28'],...
                      %fr_logger_to_db_fileName(ini_climMain, 'HMP_T_2_AVG', pth));
trace_legend = str2mat('inlet','outlet','middle','HMP');
trace_units = '(degC)';
y_axis      = [0 40] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % LICOR box temperature
% %----------------------------------------------------------
% trace_name  = 'LICOR  box temperature';
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'T_box_AVG', pth));
% trace_legend = str2mat('Box');
% trace_units = '(degC)';
% y_axis      = [10 50] - WINTER_TEMP_OFFSET;
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end




% %----------------------------------------------------------
% % Rain 
% %----------------------------------------------------------
% trace_name  = 'Rain';
% %trace_path  = str2mat([pth 'fr_a\fr_a.24'],[pth 'fr_a\fr_a.79']);
% trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'TBRG_1_TOT', pth),...
%                         fr_logger_to_db_fileName(ini_climMain, 'TBRG_2_TOT', pth));
%                   
% trace_units = '(mm)';
% trace_legend = str2mat('Rain 1','Rain 2');
% y_axis      = [-1 10];
% fig_num = fig_num + fig_num_inc;
% %[x] = plt_sig(trace_path, ind,trace_name, year, trace_units, y_axis, t, fig_num );
% [x] = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% 
% if pause_flag == 1;pause;end
% 
%----------------------------------------------------------
% Snow depth
%----------------------------------------------------------
trace_name  = 'HDF11: Snow depth';

trace_path  = str2mat(fullfile(pth, 'FR_clearcut','Snow_Depth'));
                  
trace_units = '(m)';
trace_legend = str2mat('Tall tower Rain 1','Tall tower Rain 2','Short tower Rain');
y_axis      = [-0.2 1];
fig_num = fig_num + fig_num_inc;
[x] = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );

if pause_flag == 1;pause;end

%----------------------------------------------------------
% Rain 
%----------------------------------------------------------
trace_name  = 'HDF11: Rain';
%trace_path  = str2mat([pth 'fr_a\fr_a.24'],[pth 'fr_a\fr_a.79']);
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'TBRG_1_TOT', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'TBRG_2_TOT', pth),fullfile(pth, 'FR_clearcut','Rain_Tot'),fullfile(pth, 'FR_clearcut','RainSnow_Tot') );
                  
trace_units = '(mm)';
trace_legend = str2mat('Tall tower Rain 1','Tall tower Rain 2','Short tower Rain', 'Short tower RainSnow');
y_axis      = [-1 10];
fig_num = fig_num + fig_num_inc;
%[x] = plt_sig(trace_path, ind,trace_name, year, trace_units, y_axis, t, fig_num );
[x] = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );

if pause_flag == 1;pause;end



% %----------------------------------------------------------
% % Cumulative rain 
% %----------------------------------------------------------
indx = find( t_all >= 1 & t_all <= ed );                    % extract the period from
tx = t_all(indx);                                           % the beginning of the year

trace_name  = 'HDF11: Cumulative rain #1';

%ax = [st ed];
[x1,tx_new] = read_sig(trace_path(1,:), indx,year, tx,0);
[x2,tx_new] = read_sig(trace_path(2,:), indx,year, tx,0);
[x3,tx_new] = read_sig(trace_path(3,:), indx,year, tx,0);
[x4,tx_new] = read_sig(trace_path(4,:), indx,year, tx,0);
csx1=(cumsum(x1));
csx2=(cumsum(x2));
csx3=(cumsum(x3));
csx4=(cumsum(x4));
trace_path=[csx1 csx2 csx3 csx4];
trace_units = '(mm)';
trace_legend = str2mat('Tall tower Rain 1','Tall tower Rain 2','Short tower Rain', 'Short tower RainSnow');
y_axis      = [];
fig_num = fig_num + fig_num_inc;
if year==1998
    addRain = 856.9;
else 
    addRain = 0;
end
%plt_sig1( tx_new, [cumsum(x1) cumsum(x2)+addRain cumsum(x3) cumsum(x4)], trace_name, year, trace_units, ax, y_axis, fig_num );

%x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
x = plt_msig( trace_path, indx, trace_name, trace_legend, year, trace_units, y_axis, tx_new, fig_num );

if pause_flag == 1;pause;end

%----------------------------------------------------------
% Cumulative rain 
%----------------------------------------------------------
% indx = find( t_all >= 1 & t_all <= ed );                    % extract the period from
% tx = t_all(indx);                                           % the beginning of the year
% 
% trace_name  = 'HDF11: Cumulative rain #1';
% y_axis      = [];
% ax = [st ed];
% [x1,tx_new] = read_sig(trace_path(1,:), indx,year, tx,0);
% [x2,tx_new] = read_sig(trace_path(2,:), indx,year, tx,0);
% [x3,tx_new] = read_sig(trace_path(3,:), indx,year, tx,0);
% [x4,tx_new] = read_sig(trace_path(4,:), indx,year, tx,0);
% fig_num = fig_num + fig_num_inc;
% if year==1998
%     addRain = 856.9;
% else 
%     addRain = 0;
% end
% plt_sig1( tx_new, [cumsum(x1) cumsum(x2)+addRain cumsum(x3) cumsum(x4)], trace_name, year, trace_units, ax, y_axis, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Snow temperatures 
%----------------------------------------------------------
trace_name  = 'HDF11: Snow temperatures';
%trace_path  = str2mat([pth 'fr_a\fr_a.70'],[pth 'fr_a\fr_a.71'],[pth 'fr_a\fr_a.72'],[pth 'fr_a\fr_a.73'],[pth 'fr_a\fr_a.74']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_soilMain, 'Snow_T_1_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'Snow_T_2_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'Snow_T_3_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'Snow_T_4_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'Snow_T_5_AVG', pth));
trace_legend = str2mat('Snow 1 cm','Snow 5 cm','Snow 10 cm','Snow 20 cm','Snow 50 cm');
trace_units = '(degC)';
y_axis      = [0 30] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % Temperature profile
% %----------------------------------------------------------
% trace_name  = 'Temperature profile';
% %trace_path  = str2mat([pth 'fr_f\fr_f.17'],[pth 'fr_f\fr_f.18'],[pth 'fr_f\fr_f.19'],[pth 'fr_f\fr_f.20'], ...
%                   %    [pth 'fr_f\fr_f.21'],[pth 'fr_f\fr_f.22'],[pth 'fr_f\fr_f.23'],[pth 'fr_f\fr_f.24']);
% %trace_legend = str2mat('T2m','T5m','T9m','T15m','T21m','T27m','T33m','T44m');
% trace_path  = str2mat([pth 'fr_f\fr_f.21'],[pth 'fr_f\fr_f.22'],[pth 'fr_f\fr_f.23']);
% trace_legend = str2mat('T21m','T27m','T33m');
% 
% trace_units = '(degC)';
% y_axis      = [ 0 35] - WINTER_TEMP_OFFSET;
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end


%----------------------------------------------------------
% CNR1 temperature_Tall and short towers
%----------------------------------------------------------
trace_name  = 'HDF11: CNR1 temperature';
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'HMP_T_2_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'T_Pt100_AVG',pth),fullfile (pth, 'FR_clearcut','HMP_T_Avg'),fullfile(pth,'FR_clearcut','cnr1_Temp_Avg'));
                     
                        %[pth 'fr_a\fr_a.17'],[pth 'fr_a\fr_a.75'],[pth 'fr_a\fr_a.85']);
trace_legend = str2mat('HMP\_41m Met-1','Tall tower CNR1 PRT','Short tower HMP T','Short tower CNR1 PRT');
trace_units = '(degC)';
y_axis      = [0 35] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%-----------------------------------
% CNR1 Long and short wave_Tall tower
%-----------------------------------
trace_name  = 'HDF11: Tall Tower CNR1 Net Radiation components';
T_CNR1 = read_bor(fr_logger_to_db_fileName(ini_climMain, 'T_Pt100_AVG', pth));
LongWaveOffset =(5.67E-8*(273.15+T_CNR1).^4);
Net_cnr1_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'Net_cnr1_AVG', pth));
S_upper_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'S_upper_AVG', pth))* 21.758/19.686;
S_lower_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'S_lower_AVG', pth))* 21.758/19.686;
L_upper_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'L_upper_AVG', pth)) + LongWaveOffset;
L_lower_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'L_lower_AVG', pth)) + LongWaveOffset;

Net_cnr1_calc = (S_upper_AVG - S_lower_AVG) + (L_upper_AVG - L_lower_AVG);

trace_path = [Net_cnr1_AVG S_upper_AVG S_lower_AVG L_upper_AVG L_lower_AVG Net_cnr1_calc];
trace_legend = str2mat('Net_{logger}','S_{upper}','S_{lower}','L_{upper}','L_{lower}','Net_{calc}');
trace_units = '(W/m^2)';
y_axis      = [-200 1000];
fig_num = fig_num + fig_num_inc;
x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num);
if pause_flag == 1;pause;end


%-----------------------------------
% CNR1 Long and short wave_Short tower
%-----------------------------------
trace_name  = 'HDF11: Short Tower CNR1 Net Radiation components';
T_CNR1 = read_bor(fullfile(pth,'FR_Clearcut','cnr1_Temp_Avg'));
LongWaveOffset =(5.67E-8*(273.15+T_CNR1).^4);
%Net_cnr1_AVG = read_bor();
% S_upper_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'S_upper_AVG', pth))* 21.758/19.686;
% S_lower_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'S_lower_AVG', pth))* 21.758/19.686;
% L_upper_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'L_upper_AVG', pth)) + LongWaveOffset;
% L_lower_AVG = read_bor(fr_logger_to_db_fileName(ini_climMain, 'L_lower_AVG', pth)) + LongWaveOffset;

Short_Net_cnr1_AVG = read_bor(fullfile(pth, 'FR_clearcut','cnr1_net_Avg'));
Short_S_upper_AVG = read_bor(fullfile(pth,'FR_Clearcut','swd_Avg'));
Short_S_lower_AVG = read_bor(fullfile(pth,'FR_Clearcut','swu_Avg'));
Short_L_upper_AVG = read_bor(fullfile(pth,'FR_Clearcut','lwd_Avg')) + LongWaveOffset;
Short_L_lower_AVG = read_bor(fullfile(pth,'FR_Clearcut','lwu_Avg')) + LongWaveOffset;

Short_Net_cnr1_calc = (Short_S_upper_AVG - Short_S_lower_AVG) + (Short_L_upper_AVG - Short_L_lower_AVG);

trace_path = [Short_Net_cnr1_AVG Short_S_upper_AVG Short_S_lower_AVG Short_L_upper_AVG Short_L_lower_AVG Short_Net_cnr1_calc];

trace_legend = str2mat('Net_{logger}','S_{upper}','S_{lower}','L_{upper}','L_{lower}','Net_{calc}');
trace_units = '(W/m^2)';
y_axis      = [-200 1000];
fig_num = fig_num + fig_num_inc;
x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num);
if pause_flag == 1;pause;end


%-----------------------------------
% Barometric pressure
%-----------------------------------
trace_name  = 'HDF11: Pressure';
%trace_path  = [pth 'fr_a\fr_a.53'];
trace_path = fr_logger_to_db_fileName(ini_climMain, 'Pbarometr_AVG', pth);
trace_units = '(kPa)';
y_axis      = [96 100];
fig_num = fig_num + fig_num_inc;
x = plt_sig( trace_path, ind,trace_name, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end





%------------------------------------------
if select == 1 %diagnostics only
    if pause_flag ~= 1;
        childn = get(0,'children');
        childn = sort(childn);
        N = length(childn);
        for i=childn(:)';
            if i < 200 
                figure(i);
%                if i ~= childn(N-1)
                    pause;
%                end
            end
        end
    end
    return
end

%----------------------------------------------------------
% Soil Moisture Logger Battery Voltage
%----------------------------------------------------------
% trace_name  = 'Battery Voltage - Soil Moisture Logger';
% trace_path  = str2mat(  [pth 'fr_Moist\Batter_V_AVG']);
% trace_units = '(V)';
% %y_axis      = [23 31];
% fig_num = fig_num + fig_num_inc;
% Moist_ind = (ind(1)-14*48:ind(end))'; % Moist_ind index holds two weeks more data than other plots
% Moist_ind = Moist_ind(find(Moist_ind > 0));
% x = plt_msig( trace_path, Moist_ind, trace_name, trace_legend, year, trace_units, y_axis, t_all(Moist_ind), fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Soil Moisture Logger Panel Temp
%----------------------------------------------------------
% trace_name  = 'Panel Temp - Soil Moisture Logger';
% trace_path  = str2mat(  [pth 'fr_Moist\Pannel_T_AVG']);
% trace_units = '(^oC)';
% %y_axis      = [23 31];
% fig_num = fig_num + fig_num_inc;
% Moist_ind = (ind(1)-14*48:ind(end))'; % Moist_ind index holds two weeks more data than other plots
% Moist_ind = Moist_ind(find(Moist_ind > 0));
% x = plt_msig( trace_path, Moist_ind, trace_name, trace_legend, year, trace_units, y_axis, t_all(Moist_ind), fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Soil Moisture Probes
% %----------------------------------------------------------
%  %trace_name  = 'Volumetric Soil Water Content';
%  %trace_path  = str2mat(  [pth 'fr_Moist\swc_1_AVG'],...
%                          [pth 'fr_Moist\swc_2_AVG'],...
%                          [pth 'fr_Moist\swc_3_AVG'],...
%                          [pth 'fr_Moist\swc_4_AVG'],...
%                          [pth 'fr_Moist\swc_5_AVG']);
%  %trace_units = '(?)';
%  y_axis      = [0 0.6];
%  trace_legend = str2mat('2cm','10cm','20cm', '50cm','85cm');
%  fig_num = fig_num + fig_num_inc;
%  Moist_ind = (ind(1)-14*48:ind(end))'; % Moist_ind index holds two weeks more data than other plots
%  Moist_ind = Moist_ind(find(Moist_ind > 0));
%  x = plt_msig( trace_path, Moist_ind, trace_name, trace_legend, year, trace_units, y_axis, t_all(Moist_ind), fig_num );
%  if pause_flag == 1;pause;end


%-----------------------------------
% Soil Temperatures
%-----------------------------------
trace_name  = 'HDF11: Soil Temperatures ';
%trace_path  = str2mat([pth 'fr_a\fr_a.54'],[pth 'fr_a\fr_a.55'],[pth 'fr_a\fr_a.56'],...
%                      [pth 'fr_a\fr_a.57'],[pth 'fr_a\fr_a.58'],[pth 'fr_a\fr_a.59'],...
%                      [pth 'fr_a\fr_a.103'],[pth 'fr_a\fr_a.104'],[pth 'fr_a\fr_a.105'],...
%                      [pth 'fr_a\fr_a.106']);
%trace_legend = str2mat('1','2','3','4','5','6','7','8','9','10');
trace_path  = str2mat(fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_1_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_2_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_3_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_4_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_5_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_6_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_7_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_8_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_9_AVG', pth),...
                      fr_logger_to_db_fileName(ini_soilMain, 'T_Soil_10_AVG', pth));
trace_legend = [];
trace_units = 'deg C';
y_axis      = [5 25] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Tree temperatures 
%----------------------------------------------------------
% trace_name  = 'Tree temperatures';
% %trace_path  = str2mat([pth 'fr_a\fr_a.63'],[pth 'fr_a\fr_a.64'],[pth 'fr_a\fr_a.65'],...
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'Tr3_2mm_AVG', pth),...
%                       fr_logger_to_db_fileName(ini_climMain, 'Tr3_82mm_AVG', pth),...
%                       fr_logger_to_db_fileName(ini_climMain, 'Tr3_164mm_AVG', pth),...
%                       [pth 'uvic_01\uv01a.13'],[pth 'uvic_01\uv01a.14'],...
%                       [pth 'uvic_01\uv01a.15'],[pth 'uvic_01\uv01a.16'],...
%                       [pth 'uvic_01\uv01a.17'],[pth 'uvic_01\uv01a.18']);
%                    trace_legend = str2mat('#1-3m 0.2 cm','#1-3m 8.2 cm','#1-3m 16.4 cm','#2-3m 0.2 cm','#2-3m 5 cm',...
%                       '#2-3m 15 cm','#2-27m 0.2 cm','#2-27m 2.8 cm','#2-27m branch');
% trace_units = '(degC)';
% y_axis      = [0 35] - WINTER_TEMP_OFFSET;
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end


%----------------------------------------------------------
% MPS logger Tree temperatures 
%----------------------------------------------------------
% trace_name  = 'MPS logger Tree Temperatures';
% trace_path  = str2mat([pth 'MPS\TTC1_1cm_AVG'],[pth 'MPS\TTC1_2cm_AVG'],[pth 'MPS\TTC1_4cm_AVG'],...
%                       [pth 'MPS\TTC1_8cm_AVG'],[pth 'MPS\TTC1_16cm_AVG'],[pth 'MPS\TTC1_ext_AVG'],...
%                       [pth 'MPS\TTC2_1cm_AVG'],[pth 'MPS\TTC2_2cm_AVG'],[pth 'MPS\TTC2_4cm_AVG'],...
%                       [pth 'MPS\TTC2_8cm_AVG'],[pth 'MPS\TTC2_16cm_AVG'],[pth 'MPS\TTC2_ext_AVG'],...
%                       [pth 'MPS\TTC3_1cm_AVG'],[pth 'MPS\TTC3_2cm_AVG'],[pth 'MPS\TTC3_4cm_AVG'],...
%                       [pth 'MPS\TTC3_8cm_AVG'],[pth 'MPS\TTC3_16cm_AVG'],[pth 'MPS\TTC3_ext_AVG']);
% 
% trace_legend = str2mat('T1_{1cm}','T1_{2cm}','T1_{4cm}','T1_{8cm}','T1_{16cm}','T1_{ext}',...
%                        'T2_{1cm}','T2_{2cm}','T2_{4cm}','T2_{8cm}','T2_{16cm}','T2_{ext}',...
%                        'T3_{1cm}','T3_{2cm}','T3_{4cm}','T3_{8cm}','T3_{16cm}','T3_{ext}');
% trace_units = '(degC)';
% y_axis      = [0 35] - WINTER_TEMP_OFFSET;
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end


%----------------------------------------------------------
% Air temperatures at 35m
%----------------------------------------------------------
trace_name  = 'HDF11: Tall Tower Air temperatures at 35m and 42m';
%trace_path  = str2mat([pth 'fr_a\fr_a.17'],[pth 'fr_a\fr_a.75'],[pth 'fr_a\fr_a.21'],[pth 'fr_a\fr_a.47'],[pth 'fr_b\fr_b.23'],[pth 'fr_f\fr_f.25'],[pth 'fr_f\fr_f.26']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'HMP_T_1_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'HMP_T_2_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'TC_40m_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'TC_2m_AVG', pth),...
                      [pth 'fr_b\fr_b.23'],[pth 'fr_b\fr_b.20'] ,[pth 'fr_f\fr_f.25'],[pth 'fr_f\fr_f.26']);
trace_legend = str2mat('HMP\_27m Gill','HMP\_41m Met-1','TC','Hut\_{airT}','GillT','PRT','Prof 15\_3','Prof 44\_3');
trace_units = '(degC)';
y_axis      = [0 35] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end


%----------------------------------------------------------
% Relative humidity_Tall and short towers
%----------------------------------------------------------
trace_name  = 'HDF11: Relative humidity';
%trace_path  = str2mat([pth 'fr_a\fr_a.20'],[pth 'fr_a\fr_a.78'],[pth 'fr_a\fr_a.88']);
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'HMP_RH_1_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'HMP_RH_2_AVG', pth),...
                        fr_logger_to_db_fileName(ini_climMain, 'HMP_RH_3_AVG', pth), fullfile(pth, 'FR_clearcut','HMP_RH_Avg'));
trace_legend = str2mat('HMP\_27m Gill','HMP\_41m Met-1','HMP\_4m Met-1', 'HMP\_short');
trace_units = '(RH %)';
y_axis      = [10 120];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % HMP air temperatures
% %----------------------------------------------------------
% trace_name  = 'Tall Tower HMP air temperature';
% trace_path  = str2mat(  fr_logger_to_db_fileName(ini_climMain, 'HMP_T_1_AVG', pth),...
%                         fr_logger_to_db_fileName(ini_climMain, 'HMP_T_2_AVG', pth),...
%                         fr_logger_to_db_fileName(ini_climMain, 'HMP_T_3_AVG', pth));
% %[pth 'fr_a\fr_a.17'],[pth 'fr_a\fr_a.75'],[pth 'fr_a\fr_a.85']);
% trace_legend = str2mat('HMP\_27m Gill','HMP\_41m Met-1','HMP\_4m Met-1');
% trace_units = '(degC)';
% y_axis      = [0 35] - WINTER_TEMP_OFFSET;
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Soil Moisture (TDR)
%----------------------------------------------------------
 trace_name  = 'HDF11: Soil Moisture (TDR)';
%trace_path  = str2mat([pth 'fr_a\fr_a.81'],[pth 'fr_a\fr_a.82'],[pth 'fr_a\fr_a.83'],[pth 'fr_a\fr_a.84']);
trace_path  = str2mat(  fr_logger_to_db_fileName(ini_soilMain, 'TDR1_2_AVG', pth),...
                        fr_logger_to_db_fileName(ini_soilMain, 'TDR10_12_AVG', pth),...
                        fr_logger_to_db_fileName(ini_soilMain, 'TDR30_50_AVG', pth),...
                        fr_logger_to_db_fileName(ini_soilMain, 'TDR70_100_AVG', pth));
trace_legend = str2mat('2 to 3 cm','10 to 12 cm','35 to 48 cm','70 to 100 cm');
trace_units = 'VWC';
y_axis      = [0 0.4];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% SHFP in footprint of scaffold tower
%----------------------------------------------------------
trace_name  = 'HDF11: Soil heat flux plates';
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','Sheat_flux1_Avg'),...
                        fullfile(pth, 'FR_clearcut','Sheat_flux2_Avg'),...
                        fullfile(pth, 'FR_clearcut','Sheat_flux3_Avg'),...
                        fullfile(pth, 'FR_clearcut','Sheat_flux4_Avg'));
                    
trace_legend = str2mat('SHFP1','SHFP2', 'SHFP3', 'SHFP4');
trace_units = '';
y_axis      = [-150 150];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units,y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% TCs with SHFP in footprint of scaffold tower
%----------------------------------------------------------
trace_name  = 'HDF11: TCs with SHFPs';
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','Soil_TC1wSHFP1_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC2wSHFP2_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC3wSHFP3_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC4wSHFP4_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC5wSHFP4_Avg'));
                    
trace_legend = str2mat('TC1wSHFP1','TC2wSHFP2', 'TC3wSHFP3', 'TC4wSHFP4','TC5wSHFP4');
trace_units = 'degC';
y_axis      = [-10 50];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units,y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Soil pit #2_VWC
%----------------------------------------------------------
trace_name  = 'HDF11: Soil pit #2 VWC';
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','CS616_percent1'),...
                        fullfile(pth, 'FR_clearcut','CS616_percent2'),...
                        fullfile(pth, 'FR_clearcut','CS616_percent3'),...
                        fullfile(pth, 'FR_clearcut','CS616_percent4'),...
                        fullfile(pth, 'FR_clearcut','VWCEcho1'),...
                        fullfile(pth, 'FR_clearcut','VWCEcho2'),...
                        fullfile(pth, 'FR_clearcut','VWCEcho3'),...
                        fullfile(pth, 'FR_clearcut','VWCEcho4'));
                    
trace_legend = str2mat('10cm CS616','20cm CS616', '50cm CS616', '80cm CS616','10cm Echo','20cm Echo', '50cm Echo', '80cm Echo');
trace_units = 'VWC';
y_axis      = [0 0.6];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units,y_axis, t, fig_num );
if pause_flag == 1;pause;end

% %----------------------------------------------------------
% % Soil pit #2_MPS
% %----------------------------------------------------------
% trace_name  = 'Soil pit #2 MPS';
% trace_path  = str2mat(fullfile(pth, 'FR_clearcut','MPS_KPa1'),...
%                         fullfile(pth, 'FR_clearcut','MPS_KPa2'),...
%                         fullfile(pth, 'FR_clearcut','MPS_KPa3'),...
%                         fullfile(pth, 'FR_clearcut','MPS_KPa4'));
%                     
% trace_legend = str2mat('10cm MPS','20cm MPS', '50cm MPS', '80cm MPS');
% trace_units = '?';
% y_axis      = [-2000 0];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units,y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Soil pit #2_TCs
%----------------------------------------------------------
trace_name  = 'HDF11: Soil pit #2 TCs';
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','Soil_TC1_5cm_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC2_10cm_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC3_20cm_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC4_50cm_Avg'),...
                        fullfile(pth, 'FR_clearcut','Soil_TC5_80cm_Avg'));
                    
trace_legend = str2mat('3cm TC','10cm TC','20cm TC', '50cm TC', '80cm TC');
trace_units = 'degC';
y_axis      = [0 50] - WINTER_TEMP_OFFSET;
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units,y_axis, t, fig_num );
if pause_flag == 1;pause;end
%----------------------------------------------------------
% Soil Moisture (MPS logger)
%----------------------------------------------------------
% trace_name  = 'Soil Moisture (MPS logger)';
% trace_path  = str2mat([pth 'MPS\SWC_10cm_AVG'],[pth 'MPS\SWC_25cm_AVG'],...
%                       [pth 'MPS\SWC_50cm_AVG'],[pth 'MPS\SWC_100cm_AVG']);
% trace_legend = str2mat('10 cm','25 cm','50 cm','100 cm');
% trace_units = 'VWC';
% y_axis      = [0 0.4];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Decagon Moisture Potential Sensors
%----------------------------------------------------------
% trace_name  = 'Decagon Moisture Potential Sensors';
% trace_path  = str2mat([pth 'MPS\MPS_10cm_MAX'],[pth 'MPS\MPS_25cm_MAX'],...
%                       [pth 'MPS\MPS_50cm_AVG'],[pth 'MPS\MPS_100cm_AVG']);
% trace_legend = str2mat('10 cm','25 cm','50 cm','100 cm');
% trace_units = '(kPa)';
% y_axis      = [-100 0];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------
% Wind speed (RM Young)
%----------------------------------------------------------
trace_name  = 'HDF11: Tall Tower Wind speed averages (RM Young)';
%trace_path  = str2mat([pth 'fr_a\fr_a.27'], [pth 'fr_c\fr_c.28']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'WindSpeed_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'WSpd_3m_AVG', pth));

trace_legend = str2mat('37m (avg)','3.5m (avg)');
trace_units = '(m/s)';
y_axis      = [0 8];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Wind speed (max)(RM Young)
%----------------------------------------------------------
trace_name  = 'HDF11: Tall Tower Wind speed (max)(RM Young)';
%trace_path  = str2mat([pth 'fr_a\fr_a.28'],[pth 'fr_c\fr_c.29']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'WindSpeed_MAX', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'WSpd_3m_MAX', pth));
trace_legend = str2mat('37m (max)','3.5m (max)');
trace_units = '(m/s)';
y_axis      = [0 15];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Wind direction (RM Young)
%----------------------------------------------------------
trace_name  = 'HDF11: Tall Tower Wind directions (RM Young)';
%trace_path  = str2mat([pth 'fr_a\fr_a.32'],[pth 'fr_c\fr_c.33']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'WindDir_D1_WVT', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'WDir_3m_D1_WVT', pth));
trace_legend = str2mat('38m','3.5m');
trace_units = '(degrees)';
y_axis      = [0 360];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Gas Hound co2 concentration 
%----------------------------------------------------------
% trace_name  = '10m CO2 concentration (Gashound)';
% %trace_path  = str2mat([pth 'fr_c\fr_c.49'],[pth 'fr_c\fr_c.50'],[pth 'fr_c\fr_c.51']);
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'GH_co2_AVG', pth),...
%                       fr_logger_to_db_fileName(ini_clim2,    'GH_co2_MAX', pth),...
%                       fr_logger_to_db_fileName(ini_clim2,    'GH_co2_MIN', pth));
% 
% trace_legend = str2mat('avg','max','min');
% trace_units = '(umol/m2/s)';
% y_axis      = [360 440];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%-----------------------------------
% PAR 1,2_Tall tower
%-----------------------------------
trace_name  = 'HDF11: Tall Tower PAR ';
%trace_path  = str2mat([pth 'fr_a\fr_a.38'],[pth 'fr_a\fr_a.40']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'PAR_1_AVG', pth),...
    fr_logger_to_db_fileName(ini_climMain, 'PAR_2_AVG', pth),...
    fr_logger_to_db_fileName(ini_climMain, 'PAR_3_AVG', pth),...
    fr_logger_to_db_fileName(ini_climMain, 'PAR_Total_AVG', pth),...
    fr_logger_to_db_fileName(ini_climMain, 'PAR_Diff_AVG', pth) );
trace_legend = str2mat('downward','upward', '2.5m downward', 'BF2 total', 'BF2 diffuse');
trace_units = '(mmol m^{-2} s^{-1})';
y_axis      = [-100 1800];
fig_num = fig_num + fig_num_inc;
x_par = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

fig_num = fig_num + fig_num_inc;
figure('Name','PAR regression')
plot_regression(x_par(:,1),x_par(:,4),[],[],'ortho');
xlabel('PAR Quantum sensor (\mumol m^{-2} s^{-1})');
ylabel('PAR BF2 (\mumol m^{-2} s^{-1})');



%-----------------------------------
% CNR1 raw_Tall tower
%-----------------------------------
trace_name  = 'HDF11: Tall Tower CNR1';
%trace_path  = str2mat([pth 'fr_a\fr_a.42'],[pth 'fr_a\fr_a.44'],[pth 'fr_a\fr_a.101'],...
%   [pth 'fr_a\fr_a.119'],[pth 'fr_a\fr_a.120']);
trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'L_upper_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'L_lower_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'S_upper_AVG', pth),...
                      fr_logger_to_db_fileName(ini_climMain, 'S_lower_AVG', pth));
                  
                 
trace_legend = str2mat('L upper','L lower','S upper','S lower');
trace_units = '(W/m^2)';
y_axis      = [-200 1400];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

end

fig_num = fig_num + fig_num_inc;
figure('Name','Tall tower Downwelling light regression')
plot_regression(x(:,4),x_par(:,1)./1.95,[],[],'ortho');
title('Tall tower Downwelling light regression');
xlabel('CNR1 down (W m^{-2})');
ylabel('PAR Quantum sensor / 1.95 (\mumol m^{-2} s^{-1})');

% %-----------------------------------
% % PAR 1,2_Short tower
% %-----------------------------------
trace_name  = 'HDF11: Short Tower PAR ';
trace_path  = str2mat([pth 'fr_a\fr_a.38'],[pth 'fr_a\fr_a.40']);
trace_path  = str2mat(fullfile(pth, 'FR_clearcut','PAR1_Avg'),fullfile(pth, 'FR_clearcut','PAR2_Avg'));
trace_legend = str2mat('downward','upward');
trace_units = '(mmol m^{-2} s^{-1})';
y_axis      = [-100 1800];
fig_num = fig_num + fig_num_inc;
x_par = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

%-----------------------------------
% CNR1 raw_Short tower
%-----------------------------------
trace_name  = 'HDF11: Short Tower CNR1';
%trace_path  = str2mat([pth 'fr_a\fr_a.42'],[pth 'fr_a\fr_a.44'],[pth 'fr_a\fr_a.101'],...
%   [pth 'fr_a\fr_a.119'],[pth 'fr_a\fr_a.120']);
trace_path  = str2mat(fullfile(pth, 'FR_Clearcut','lwd_Avg'),fullfile(pth, 'FR_Clearcut', 'lwu_Avg'),...
                      fullfile(pth,'FR_Clearcut','swd_Avg'), fullfile(pth,'FR_Clearcut', 'swu_Avg'));
                  
                 
trace_legend = str2mat('L upper','L lower','S upper','S lower');
trace_units = '(W/m^2)';
y_axis      = [-200 1400];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
if pause_flag == 1;pause;end

fig_num = fig_num + fig_num_inc;
figure('Name','Short tower Downwelling light regression')
plot_regression(x(:,4),x_par(:,1)./1.95,[],[],'ortho');
title('Short tower Downwelling light regression');
xlabel('CNR1 down (W m^{-2})');
ylabel('PAR Quantum sensor / 1.95 (\mumol m^{-2} s^{-1})');



%-----------------------------------
% Net_Tall tower
%-----------------------------------
trace_name  = 'HDF11: Tall Tower Net Radiation';
%trace_path  = str2mat([pth 'fr_a\fr_a.51'],[pth 'fr_a\fr_a.99'],[pth 'fr_a\fr_a.125']);
trace_path  = str2mat( fr_logger_to_db_fileName(ini_climMain, 'Net_cnr1_AVG', pth),...
                       fr_logger_to_db_fileName(ini_climMain, 'Net_S_cnr_AVG', pth),... 
                       fr_logger_to_db_fileName(ini_climMain, 'Net_L_cnr_AVG', pth));


                  % Short_Net_cnr1_calc = (Short_S_upper_AVG - Short_S_lower_AVG) + (Short_L_upper_AVG - Short_L_lower_AVG);
%Short_L_net_calc = Short_L_upper_AVG - Short_L_lower_AVG;
%Short_S_net_calc = Short_S_upper_AVG - Short_S_lower_AVG;
trace_legend = str2mat('CNR1 Net','Shortwave Net','Longwave Net');
trace_units = '(W/m^2)';
y_axis      = [-200 1000];
fig_num = fig_num + fig_num_inc;
x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num, [1 21.758/19.686 1 ]);
if pause_flag == 1;pause;end

% %-----------------------------------
% % Net_Short tower
% %-----------------------------------
% trace_name  = 'ADD SCAFFOLD TOWER Rn: Tall Tower Net Radiation';
% %trace_path  = str2mat([pth 'fr_a\fr_a.51'],[pth 'fr_a\fr_a.99'],[pth 'fr_a\fr_a.125']);
% %trace_path  = (str2mat( fr_logger_to_db_fileName(ini_climMain, 'Net_cnr1_AVG', pth),...
%                        fr_logger_to_db_fileName(ini_climMain, 'Net_S_cnr_AVG', pth),... 
%                        fr_logger_to_db_fileName(ini_climMain, 'Net_L_cnr_AVG', pth));

trace_name  = 'HDF11: Short Tower Net Radiation';
T_CNR1 = read_bor(fullfile(pth,'FR_Clearcut','cnr1_Temp_Avg'));
LongWaveOffset =(5.67E-8*(273.15+T_CNR1).^4);


Short_S_upper_AVG = read_bor(fullfile(pth,'FR_Clearcut','swd_Avg'));
Short_S_lower_AVG = read_bor(fullfile(pth,'FR_Clearcut','swu_Avg'));
Short_L_upper_AVG = read_bor(fullfile(pth,'FR_Clearcut','lwd_Avg')) + LongWaveOffset;
Short_L_lower_AVG = read_bor(fullfile(pth,'FR_Clearcut','lwu_Avg')) + LongWaveOffset;

Short_Net_cnr1_calc = (Short_S_upper_AVG - Short_S_lower_AVG) + (Short_L_upper_AVG - Short_L_lower_AVG);
Short_L_net_calc = Short_L_upper_AVG - Short_L_lower_AVG;
Short_S_net_calc = Short_S_upper_AVG - Short_S_lower_AVG;

 
trace_path = [Short_Net_cnr1_calc Short_S_net_calc Short_L_net_calc];

 trace_legend = str2mat('CNR1 Net','Shortwave Net','Longwave Net');
trace_units = '(W/m^2)';
y_axis      = [-200 1000];
fig_num = fig_num + fig_num_inc; x_all = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num, [1 21.758/19.686 1 ]);
if pause_flag == 1;pause;end




% THE FOLLOWING GRAPH IS OBSOLETE (due to a 'new' Logger setup), removed Jan 14 (Christian)
%----------------------------------------------------------
%  OLD Wind speed (Gill R2)
%----------------------------------------------------------
% trace_name  = 'Wind speed (Gill R2)';
% trace_path  = str2mat([pth 'fr_b\fr_b.20'],[pth 'fr_b\fr_b.21'],[pth 'fr_b\fr_b.22']);
% trace_legend = str2mat('U','V','W');
% trace_units = '(m/s)';
% y_axis      = [-10 10];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num );
% if pause_flag == 1;pause;end

%----------------------------------------------------------------------------
% OLD Wind speed comparison, ONLY RM Young propeller (above canopy) is
% shown, revised Jan 15 (Christian)
%----------------------------------------------------------------------------
% trace_name  = 'Wind speed RM Young Propeller (above canooy)';
% trace_path  = str2mat([pth 'fr_b\fr_b.20']);
% trace_units = '(m/s)';
% y_axis      = [];
% ax = [st ed];
% indx = find( t_all >= st & t_all <= ed );                   % extract the requested period 
% tx = t_all(indx);                                           % 
% [U,tu] = read_sig(trace_path, indx,year, tx,0);
% trace_path  = str2mat([pth 'fr_b\fr_b.21']);
% [V,tv] = read_sig(trace_path, indx,year, tx,0);
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'WindSpeed_AVG', pth));
% [CupRMYoung,tc] = read_sig(trace_path, indx,year, tx,0);
% trace_path  = str2mat([pth 'fr_b\fr_b.47']);
% [CupGill,tc] = read_sig(trace_path, indx,year, tx,0);
% trace_path  = str2mat([pth 'fr_b\fr_b.48']);
% [CupGill3D,tc] = read_sig(trace_path, indx,year, tx,0);
% CupGill1 = (U.^2 + V .^2).^0.5;
% Ntc = length(tc);
% Ntu = length(tu);
% NNN = min(Ntc,Ntu);
% if tc(1) == tu(1)
%     nnn = 1:NNN;
% elseif  tc(Ntc) == tu(Ntu)
%     error 'I am not prepared to do this'
% end
% fig_num = fig_num + fig_num_inc;
% plt_sig1( tc, [CupRMYoung(nnn)], trace_name, year, trace_units, ax, y_axis, fig_num );
% legend('RM Young Propeller (43 m)',-1)
% if pause_flag == 1;pause;end


%--------------------------------------------------------------
% Wind speed comparison (above canopy vs. below canopy sonics)
%--------------------------------------------------------------
% trace_name  = 'Wind speed comparison (above canopy vs. below canopy sonics)';
% trace_units = '(m/s)';
% y_axis      = [];
% ax = [st ed];
% indx = find( t_all >= st & t_all <= ed );                  
% tx = t_all(indx);                                           
% yr = num2str(year);
% 
% if ismember(yr,[2008:2010])
% 
%     trace_path  = str2mat(['\\Annex001\database\' yr '\CR\Clean\ThirdStage\wind_speed_3D_main']);
%     [Gill3D,tc] = read_sig(trace_path,indx,year,tx,0);
% 
%     trace_path  = str2mat(['\\Annex001\database\' yr '\CR\below_canopy_sonic\MiscVariables.CupWindSpeed3D']);
%     [RMY3D,tc] = read_sig(trace_path,indx,year,tx,0);
% 
%     Ntc = length(tc);
%     Ntu = length(tu);
%     NNN = min(Ntc,Ntu);
%     if tc(1) == tu(1)
%         nnn = 1:NNN;
%     elseif  tc(Ntc) == tu(Ntu)
%         error 'I am not prepared to do this'
%     end
%     fig_num = fig_num + fig_num_inc;
%     plt_sig1( tc, [Gill3D(nnn) RMY3D(nnn)], trace_name, year, trace_units, ax, y_axis, fig_num);
%     legend('43 m (Gill R2)','4 m (RMY 81000)',-1)
%     if pause_flag == 1;pause;end


%     %-----------------------------------------------------------------
%     % Wind direction comparison (above canopy vs. below canopy sonic)
%     %-----------------------------------------------------------------
%     trace_name  = 'Wind direction comparison (above canopy vs. below canopy sonic)';
%     trace_units = '(deg)';
% 
%     trace_path  = str2mat(['\\Annex001\database\' yr '\CR\Clean\ThirdStage\wind_direction_main']);
%     [wd_Gill,tc] = read_sig(trace_path,indx,year,tx,0);
% 
%     trace_path  = str2mat(['\\Annex001\database\' yr '\CR\below_canopy_sonic\MiscVariables.WindDirection']);
%     [wd_RMY,tc] = read_sig(trace_path,indx,year,tx,0);
% 
%     trace_legend = str2mat('43 m (Gill R2)','4 m (RMY 81000)');
% 
%     y_axis      = [0 360];
%     fig_num = fig_num + fig_num_inc;
%     x = plt_msig([wd_Gill wd_RMY], ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num);
% 
%     if pause_flag == 1;pause;end


    %-----------------------------------------------------------------
    % Wind direction histogram
    %-----------------------------------------------------------------

%     wind_hist=[];
%     for i = 1:36
%         no = num2str(i);
%         p = str2mat(['\\Annex001\database\' yr '\CR\below_canopy_sonic\MiscVariables.WindDirection_Histogram_' no]);
%         his = read_sig(p,indx,year,tx,0);
%         wind_hist = [wind_hist his];
%     end
% 
%     fig_num = fig_num + fig_num_inc;
%     figure(fig_num);
%     bar(sum(wind_hist));
%     xlabel('x 10 (deg)'); ylabel('Number of samples in each bin'); title({'Wind Direction Histogram';'Below Canopy Sonic (4 m)'});
%     if pause_flag == 1;pause;end
% 
% end

%if 1==2
    
%----------------------------------------------------------
% Sensible and latent heat + Rn
%----------------------------------------------------------
trace_name  = 'HDF11: UPDATE using FR_clearcut traces: H_{Gill}, H_{tc}, LE and Rn';
trace_path  = str2mat([pth 'fr_b\fr_b.41'],[pth 'fr_b\fr_b.42'],...
                      [pth 'fr_b\fr_b.43'],...
                      fr_logger_to_db_fileName(ini_climMain, 'Net_01_AVG', pth));
trace_legend = str2mat('H\_{Gill}','H\_{tc}','LE','Rn');
trace_units = '(W/m^2)';
y_axis      = [-200 1000];
fig_num = fig_num + fig_num_inc;
x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num,[1150 1150 2540 1] );
if pause_flag == 1;pause;end

%----------------------------------------------------------
% Closure
%----------------------------------------------------------
% trace_name  = 'Closure';
% trace_path  = str2mat([pth 'fr_b\fr_b.41']);
% trace_units = '(W/m^2)';
% y_axis      = [-200 1000];
% ax = [st ed];
% indx = find( t_all >= st & t_all <= ed );                   % extract the requested period 
% tx = t_all(indx);                                           % 
% [H,tx_new] = read_sig(trace_path, indx,year, tx,0);
% H = H * 1150;
% trace_path  = str2mat([pth 'fr_b\fr_b.43']);
% [LE,tx_new] = read_sig(trace_path, indx,year, tx,0);
% LE = LE * 2540;
% trace_path  = str2mat(fr_logger_to_db_fileName(ini_climMain, 'Net_01_AVG', pth));
% [Rn,tx_rn] = read_sig(trace_path, indx,year, tx,0);
% fig_num = fig_num + fig_num_inc;
% Ntc = length(tx_new);
% Ntu = length(tx_rn);
% NNN = min(Ntc,Ntu);
% if tc(1) == tu(1)
%     nnn = 1:NNN;
% elseif  tc(Ntc) == tu(Ntu)
%     error 'I am not prepared to do this'
% end
% plt_sig1( tx_new(nnn), [H(nnn)+LE(nnn) Rn(nnn) Rn(nnn)-H(nnn)-LE(nnn)], trace_name, year, trace_units, ax, y_axis, fig_num );
% if pause_flag == 1;pause;end
%end
% %----------------------------------------------------------
% % Sensible heat Gill vs TC
% %----------------------------------------------------------
% trace_name  = 'H_{Gill} vs H_{tc}';
% trace_path  = str2mat([pth 'fr_b\fr_b.41'],[pth 'fr_b\fr_b.42']);
% trace_legend = str2mat('H\_{Gill}','H\_{tc}');
% trace_units = '(W/m^2)';
% y_axis      = [-200 1000];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num,[1150 1150] );
% if pause_flag == 1;pause;end
% 
% if 1==2
% %----------------------------------------------------------
% % LICOR heater/fan duty cycles
% %----------------------------------------------------------
% trace_name  = 'LICOR heater/fan duty cycles';
% trace_path  = str2mat([pth 'fr_c\fr_c.26'],[pth 'fr_c\fr_c.27']);
% trace_legend = str2mat('Heater','Fan');
% trace_units = '(%)';
% y_axis      = [-10 120];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num,[100 100]);
% if pause_flag == 1;pause;end
% end

%---------------------------------------------------------
% WaterQ data (Mark Johnson) 
%---------------------------------------------------------

%pl_waterQ(year,ind,ind_10min,[],fig_num);

%----------------------------------------------------------
% Single-Soil-chamber system
%----------------------------------------------------------
% trace_name  = 'Soil CO_2 efflux';
% trace_path  = str2mat([biomet_path(year,'CR','chambers') 'flux.1']);
% trace_legend = str2mat('Single soil chamber');
% trace_units = '\mumol m^{-2} s^{-1}';
% y_axis      = [0 2];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num, 1 );
% if pause_flag == 1;pause;end
% 
% trace_name  = 'Soil chamber CO_2 mixing ratio';
% trace_path  = str2mat([biomet_path(year,'CR','chambers') 'co2_after.1'],...
%     [biomet_path(year,'CR','profile') 'co2_avg.1']);
% trace_legend = str2mat('Single soil chamber','Profile system');
% trace_units = '\mumol mol^{-1}';
% y_axis      = [350 450];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num, [1 1] );
% if pause_flag == 1;pause;end

% trace_name  = 'FR_C Soil CO_2 probes';
% trace_path  = str2mat([biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.5'],...
%     [biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.6'],...
%     [biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.7'],...
%     [biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.8'],...
%     [biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.9'],...
%     [biomet_path(year,'HDF11','climate\fr_c') 'fr_c3.10']...
%     );
% trace_legend = str2mat('5 cm','10 cm','20 cm','50 cm','70 cm','100 cm');
% trace_units = '\mumol mol^{-1}';
% y_axis      = [0 12000];
% fig_num = fig_num + fig_num_inc;
% x = plt_msig( trace_path, ind, trace_name, trace_legend, year, trace_units, y_axis, t, fig_num, [1 1 1 1 1 1] );
% if pause_flag == 1;pause;end


%colordef white

if pause_flag ~= 1;
    childn = get(0,'children');
    childn = sort(childn);
    N = length(childn);
    for i=childn(:)';
        if i < 200 
            figure(i);
%            if i ~= childn(N-1)
                pause;
%            end
        end
    end
end

%========================================================
% local functions

function [p,x1,x2] = polyfit_plus(x1in,x2in,n)
    x1=x1in;
    x2=x2in;
    tmp = find(abs(x2-x1) < 0.5*abs(max(x1,x2)));
    if isempty(tmp)
        p = [1 0];
        return
    end
    x1=x1(tmp);
    x2=x2(tmp);
    p=polyfit(x1,x2,n);
    diffr = x2-polyval(p,x1);
    tmp = find(abs(diffr)<3*std(diffr));
    if isempty(tmp)
        p = [1 0];
        return
    end
    x1=x1(tmp);
    x2=x2(tmp);
    p=polyfit(x1,x2,n);
    diffr = x2-polyval(p,x1);
    tmp = find(abs(diffr)<3*std(diffr));
    if isempty(tmp)
        p = [1 0];
        return
    end
    x1=x1(tmp);
    x2=x2(tmp);
    p=polyfit(x1,x2,n);


%loggerName = 'FR_Clim';
%fileNamePrefix = 'FR_Clim_105';
%traceName = 'HMP_35_T_AVG';
%traceNum = '75';
