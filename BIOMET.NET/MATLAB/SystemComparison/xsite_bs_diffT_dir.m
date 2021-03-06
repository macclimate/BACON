function xsite_bs_diffT_dir

%----------------------------------------------------
% Load new data
%----------------------------------------------------
cd C:\UBC_PC_Setup\Site_specific\BS_new_eddy

% new_calc_and_save(datenum(2004,4,30),'bs')
tv_dat = datenum(2004,5,[14:19]);

Stats_new = fcrn_load_data(tv_dat,'bs')

cd C:\UBC_PC_Setup\Site_specific\xsite

Stats_xsite = fcrn_load_data(tv_dat,'xsite')

Stats_all = fcrn_merge_stats(Stats_new,Stats_xsite)

%----------------------------------------------------
% Plot diagnostics
%----------------------------------------------------

% Find broken records
[N_CP,tv] = get_stats_field(Stats_xsite,'XSITE_CP.MiscVariables.NumOfSamples');
[N_OP,tv] = get_stats_field(Stats_xsite,'XSITE_OP.MiscVariables.NumOfSamples');
[N_EC,tv] = get_stats_field(Stats_new,'MainEddy.MiscVariables.NumOfSamples');
tv = fr_round_hhour(tv);

T_air         = get_stats_field(Stats_xsite,'MiscVariables.Tair');
p_bar         = get_stats_field(Stats_xsite,'MiscVariables.BarometricP');
Rn            = 200.*sin([1:length(T_air)].*2*pi/48)+50;
%WindDirection = get_stats_field(Stats_xsite,'Instrument(1).MiscVariables.WindDirection');
WindDirection = read_bor(fullfile(biomet_path(2004,'bs','clean\secondstage\'),'wind_direction_main'));
WindDirection_tv = fr_round_hhour(read_bor(fullfile(biomet_path(2004,'bs','clean\secondstage\'),'clean_tv'),8));
[junk,ind_tv,ind_dir]=intersect(tv,WindDirection_tv);
WindDirection = WindDirection(ind_dir);

ind_n = find(N_CP<3.5e4 | N_OP<3.5e4 | N_EC<3.5e4 | isnan(N_CP.*N_EC));

% Find calibration times:
[co2_min,tv] = get_stats_field(Stats_xsite,'Instrument(2).Min(1)');
[h2o_min,tv] = get_stats_field(Stats_xsite,'Instrument(2).Min(2)');

ind_cal_h2o = find(h2o_min < 1);
ind_cal = find(co2_min < 340);

% Find bad winddirection times:
wind_dir = get_stats_field(Stats_xsite,'Instrument(1).MiscVariables.WindDirection');

% Find crazy fluxes
[Fc_EC,tv] = get_stats_field(Stats_new,'MainEddy.Three_Rotations.AvgDtr.Fluxes.Fc');
[Fc_CP,tv] = get_stats_field(Stats_xsite,'XSITE_CP.Three_Rotations.AvgDtr.Fluxes.Fc');
[LE_EC,tv] = get_stats_field(Stats_new,'MainEddy.Three_Rotations.AvgDtr.Fluxes.LE_L');
[LE_CP,tv] = get_stats_field(Stats_xsite,'XSITE_CP.Three_Rotations.AvgDtr.Fluxes.LE_L');
[Hs_EC,tv] = get_stats_field(Stats_new,'MainEddy.Three_Rotations.AvgDtr.Fluxes.Hs');
[Hs_CP,tv] = get_stats_field(Stats_xsite,'XSITE_CP.Three_Rotations.AvgDtr.Fluxes.Hs');
[Us_EC,tv] = get_stats_field(Stats_new,'MainEddy.Three_Rotations.AvgDtr.Fluxes.Ustar');
[Us_CP,tv] = get_stats_field(Stats_xsite,'XSITE_CP.Three_Rotations.AvgDtr.Fluxes.Ustar');
ind_flux = find(Fc_EC < -30 | Fc_EC > 15 | ...
                Fc_CP < -30 | Fc_CP > 15 | ...
                LE_EC < -50 | LE_EC > 1000 | ...
                LE_CP < -50 | LE_CP > 1000 | ...
                Us_EC < 0.1 | Us_EC > 15 | ...
                Us_CP < 0.1 | Us_CP > 15);
ind_flux=[];
% Define bad sectors:
dir_min = 5;
dir_max = 355;

ind_dir = find(wind_dir < dir_min | wind_dir > dir_max);
%ind_manual = [2 3 86 87 88 42 153 154 155 15 173 28    32   106   193   194   195   196   197   198   199   200   201]';  % indexes valid for May 7 ->
%ind_manual = [9    10    77    78    97    98    99   101   102   103   104   105 57    74    96   100 1    55    58    59    95 2     4     5     6    54    56    60    62]';
%ind_manual = [103   134   135   136   137   138   139   140   141   142   143   144 ...
 %               74    75    90    92   104   124   128 127   129   130   131   132   133 ...
 %               102   105   111]';
%ind_select = tv(sort([find_selected(h_cpme,Stats_all)]))';
ind_manual = [7 38:52 70:77 233]';

ind_time = find((tv > datenum(2004,1,0)+130.3 & tv < datenum(2004,1,0)+131.1) | ...
                (tv > datenum(2004,1,0)+133 & tv < datenum(2004,1,0)+133.3)); 

ind_exclude = unique([ind_n; ind_cal; ind_cal_h2o; ind_dir; ind_manual ; ind_flux;ind_time]);
ind_include = setdiff(1:length(wind_dir),ind_exclude);

[dir_hist] = get_stats_field(Stats_xsite,'MiscVariables.WindDirHistogram');
dir_cum_hist = cumsum(dir_hist,2);
[n_max,ind_max] = max(dir_cum_hist,[],2);
[n_min,ind_min] = min(dir_cum_hist(:,36:-1:1),[],2);
plot(tv,WindDirection,tv,ind_max.*10,tv,(36-ind_min).*10)
xlabel('Time')
ylabel('Wind direction')

% This code is good to crash matlab 6
%h=surf(dir_hist);
%view(2)
%set(h,'edgecolor','none','facecol','interp')
%caxis([0 10000])


figure
plot(WindDirection(ind_include),(Hs_CP(ind_include)-Hs_EC(ind_include))./Hs_EC(ind_include).*100,'.')
xlabel('Wind direction')
ylabel('\DeltaH (%)')

