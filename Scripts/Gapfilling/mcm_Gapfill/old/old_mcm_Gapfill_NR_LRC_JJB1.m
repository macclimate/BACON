function final_out = mcm_Gapfill_NR_LRC_JJB1(data, plot_flag, debug_flag)
%%% mcm_Gapfill_NR_LRC_JJB1.m
%%% usage: master = mcm_Gapfill_NR_LRC_JJB1(data, plot_flag, debug_flag)
%%%
%%% This function fills NEE data using the non-linear LRC method described
%%%  by Gilmanov, 2003. Two different approaches for Light Response Curve (LRC)
%%% application were presented: using a VPD-regulated GPP formulation, and
%%% a simpler method that does not use the VPD-regulated term.  This
%%% function determines both, but ideally will use the VPD-regulated filled
%%% NEE as the final filled output.
%%%
%%% Inputs:
%%% data (master structure file with all met, flux, and ancillary info
%%% plot_flag - set to 1 if you want figure output displayed and saved
%%% debug_flag - used to skip given sections of code when developing
%%%
%%% Created Nov 18, 2010 by JJB.

if nargin == 1;
plot_flag = 1;
debug_flag = 0;
elseif nargin == 2
    debug_flag = 0;
end

if plot_flag == 1;
    ls = addpath_loadstart;
    fig_path = [ls 'Matlab/Figs/Gapfilling/NR_LRC_JJB1/' data.site '/'];
    jjb_check_dirs(fig_path);
    
    %%% Pre-defined variables, mostly for plotting:
    test_Ts = (-10:2:26)';
    test_PAR = (0:200:2400)';
    [clrs clr_guide] = jjb_get_plot_colors;
end
NEE_tags = {'NR_LRC_noVPD_const';'NR_LRC_VPD_const'; 'NR_LRC_noVPD_unconst';'NR_LRC_VPD_unconst'};

year_start = data.year_start;
year_end = data.year_end;

%% Part 1: Establish the appropriate u* threshold:
%%% 1 Reichstein, 2005 approach, but calculated for different intervals:
ctr = 1;
data.recnum = NaN.*ones(length(data.PAR),1);
win_size = 16*48;
centres(:,1) = (10*48:16*48:17520);
for year = year_start:1:year_end
    data.recnum(data.Year == year) = 1:1:yr_length(year,30);
    dt_ctr = 1;
    for dt_centres = 10*48:16*48:yr_length(year,30)%seas = 1:1:4
        ind_bot = max(1,dt_centres-win_size);
        ind_top = min(dt_centres+win_size,yr_length(year,30));
        ind = find(data.Year == year & data.recnum >= ind_bot & data.recnum <= ind_top);
        [u_th_est biweek_u_th(dt_ctr,ctr)] = Reichsten_uth(data.NEE(ind), data.Ts5(ind), data.Ustar(ind), data.RE_flag(ind));
        dt_ctr = dt_ctr+1;
    end
    ctr = ctr+1;
end

%%% Average for each data window over all years (using median or mean):
Ustar_th_all = nanmedian(biweek_u_th,2);
Ustar_th_all2 = nanmean(biweek_u_th,2);
ctr = 1;
for year = year_start:1:year_end
    %%% interpolate between points:
    % step 1: interpolate out to the ends:
    use_pts = (1:1:(yr_length(year,30)-centres(end))+(centres(1)))';
    ust_fill = [Ustar_th_all2(end); Ustar_th_all2(1)];
    x = [1; use_pts(end)];
    ust_interp = interp1(x,ust_fill,use_pts);
    centres_tmp = [1; centres; yr_length(year,30)];
    Ustar_th_all_tmp = [ust_interp(yr_length(year,30)-centres(end)+1); Ustar_th_all2; ust_interp(yr_length(year,30)-centres(end))];
    Ustar_th_interp = interp1(centres_tmp,Ustar_th_all_tmp,(1:1:yr_length(year,30))');
    data.Ustar_th(data.Year == year,1) = Ustar_th_interp;
    ctr = ctr+1;
    clear centres_tmp Ustar_th_all_tmp Ustar_th_interp ust_interp x ust_fill use_pts;
end

if plot_flag == 1
    figure(1);clf;
    for k = 1:1:ctr-1
        h1(k) = plot(centres,biweek_u_th(:,k),'.-','Color',clrs(k,:));hold on;
    end
    h1(k+1) = plot(centres,Ustar_th_all,'-','LineWidth',5,'Color',[0.5 0.5 0.5]); hold on;
    h1(k+2) = plot(centres,Ustar_th_all2,'-','LineWidth',5,'Color',[1 0 0.5]); hold on;
    legend(h1,'2003','2004','2005','2006','2007','2008','2009','Median','Mean')
    ylabel('u^{*}', 'FontSize',16)
    set(gca, 'FontSize',14);
    print('-dpdf',[fig_path 'u*_th']);
    close all;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Deriving Eo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if debug_flag ~= 2
    %%%
    Ts_in = data.Ts2; %%% Using 2cm soil temperature as temperature for regression.
    %%%
    RE_raw = NaN.*data.NEE;
    xi = (1:1:length(RE_raw))';
    ind_param.RE = find((data.Ustar >= data.Ustar_th & ~isnan(data.Ts5) & ~isnan(data.NEE) & data.PAR < 15 ) |... % growing season
        ( data.Ustar >= data.Ustar_th & ~isnan(data.NEE) & ((data.dt < 85 | data.dt > 335) & data.Ts5 < 0.2)  ) );  % non-growing season
    RE_raw(ind_param.RE,1) = data.NEE(ind_param.RE,1);
    %     RE_filled = NaN.*ones(length(RE_raw),1);
    options.min_method ='NM'; options.f_coeff = [];options.costfun = 'OLS';
    win_size = round(12*48/2); % 12 days of hhours (divided by 2 to make one-sided)
    incr = (2*48); % increment by 2 days
    wrap_RE = [RE_raw(end-win_size+1:end,1); RE_raw; RE_raw(1:win_size,1)];
    wrap_Ts = [Ts_in(end-win_size+1:end,1); Ts_in; Ts_in(1:win_size,1)];
    wrap_ind = [xi(length(xi)-win_size+1:end,1); xi; xi(1:win_size,1)];
    centres = (win_size+1:incr:length(wrap_ind)-win_size)';
    Eo_wrap = NaN.*ones(length(wrap_ind),2);
    rRMSE_wrap = NaN.*ones(length(wrap_ind),2);
    if centres(end) < length(wrap_RE)-win_size; centres = [centres; length(wrap_RE)-win_size]; end
    %%%% Variables to use within loop:
    c_hat_RE = NaN.*ones(length(centres),2);
    stats_RE = NaN.*ones(length(centres),2);
    rel_error_RE = NaN.*ones(length(centres),1);
    num_pts = NaN.*ones(length(centres),1);
    
    %%% Windowed Parameterization for Eo (Eo_short): %%%%%%%%%%%%%%%%%%%%%%%%%
    for i = 1:1:length(centres)
        try
            RE_temp = wrap_RE(centres(i)-win_size:centres(i)+win_size);
            Ts_temp = wrap_Ts(centres(i)-win_size:centres(i)+win_size);
            ind_use = find(~isnan(RE_temp));
            RE_use = RE_temp(ind_use);
            Ts_use = Ts_temp(ind_use);
            num_pts(i,1) = length(RE_use);
            if num_pts(i,1) < 10
                c_hat_RE(i,1:2) = NaN;
                stats_RE(i,1:2) = NaN;
                rel_error_RE(i,1) = NaN;
            elseif (max(Ts_use) - min(Ts_use)) < 5
                c_hat_RE(i,1:2) = NaN;
                stats_RE(i,1:2) = NaN;
                rel_error_RE(i,1) = NaN;
            else
                % Run parameterization, gather c_hat values:
                [c_hat_RE(i,:), y_hat(i).RE, y_pred(i).RE, stats(i).RE, sigma(i).RE, err(i).RE, exitflag(i).RE, num_iter(i).RE] = ...
                    fitresp([10 100], 'fitresp_1C', Ts_use , RE_use, wrap_Ts(centres(i)-win_size:centres(i)+win_size),[], options);
                % gather stats:
                stats_RE(i,1:2) = [stats(i).RE.rRMSE stats(i).RE.MAE];
                rel_error_RE(i,1) = std(y_pred(i).RE)./nanmean(y_pred(i).RE);
                if c_hat_RE(i,2) > 75 && c_hat_RE(i,2) < 450 && stats_RE(i,1) < 0.65
                    Eo_wrap(centres(i)-win_size:centres(i)+win_size, rem(i,2)+1) = c_hat_RE(i,2);
                    rRMSE_wrap(centres(i)-win_size:centres(i)+win_size, rem(i,2)+1) = stats_RE(i,1);
                end
            end
        catch
            disp(i);
        end
        clear *_temp *_use;
    end
end

%%%
%%% There will be occasions where we get 2 estimates of Eo for a given
%%% half-hour.  Resolve this by taking a weighted mean of the two values,
%%% inversely weighted by the value of rRMSE associated with the Eo
%%% measurement:
sum_rRMSE = nansum(rRMSE_wrap,2); sum_rRMSE(sum_rRMSE==0) = NaN;
rRMSE_weights = [rRMSE_wrap(:,2)./sum_rRMSE rRMSE_wrap(:,1)./sum_rRMSE ];
ind_r1 = find(rRMSE_weights(:,1) == 1);
ind_r2 = find(rRMSE_weights(:,2) == 1);
rRMSE_weights(ind_r1,1) = NaN; rRMSE_weights(ind_r1,2) = 1;
rRMSE_weights(ind_r2,2) = NaN; rRMSE_weights(ind_r2,1) = 1;
weighted_Eomean = nansum([Eo_wrap(:,1).*rRMSE_weights(:,1) Eo_wrap(:,2).*rRMSE_weights(:,2)],2 );
weighted_Eomean(weighted_Eomean == 0,1) = NaN;
Eo_mean = nanmean(Eo_wrap,2);
figure(5);clf
plot(Eo_mean,'b');hold on;
plot(weighted_Eomean,'r');
legend('Un-weighted', 'rRMSE-weighted');
clear sum_rRMSE rRMSE_weights ind_r*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Fill in gaps in Eo by using previous values for each of the windows:
% First, fill in what we can using previous data:
for i = 1:1:length(centres)
    %%% Find the last non-NAN number of Eo:
    last_good = weighted_Eomean(find(~isnan( weighted_Eomean(1:centres(i)-win_size,1) ) ,1, 'last'),1);
    if ~isempty(last_good)
        if ~isempty(find(isnan(weighted_Eomean(centres(i)-win_size:centres(i)+win_size)), 1))
            weighted_Eomean(centres(i)-win_size:centres(i)+win_size) = last_good;
        end
    end
    clear last_good;
end

for i = 1:1:length(centres)
    %%% Find the last non-NAN number of Eo:
    last_good = weighted_Eomean(find(~isnan( weighted_Eomean(1:centres(i)-win_size,1) ) ,1, 'last'),1);
    if isempty(last_good)
        % if it's empty, that means we have to take the last good at
        % the end of the year:
        last_good = weighted_Eomean(find(~isnan(weighted_Eomean),1,'last'),1);
    end
    if ~isempty(find(isnan(weighted_Eomean(centres(i)-win_size:centres(i)+win_size)), 1))
        weighted_Eomean(centres(i)-win_size:centres(i)+win_size) = last_good;
    else
    end
    clear last_good;
end

% Trim weighted_Eomean to the proper size:
Eo_weighted = weighted_Eomean(win_size+1:length(weighted_Eomean)-win_size,1);
clear weighted_Eomean;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Step 1a: All-year parametization for Eo (Eo_long):
RE_param = RE_raw(~isnan(RE_raw));
Ts_param = Ts_in(~isnan(RE_raw));
% Run parameterization, gather c_hat values:
[c_hat_RE_all, y_hat_RE_all, y_pred_RE_all, stats_RE_all, sigma_RE_all, err_RE_all, exitflag_RE_all, num_iter_RE_all] = ...
    fitresp([10 100], 'fitresp_1C', Ts_param , RE_param, Ts_in,[], options);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot rRMSE vs rel error:
f3 = figure(3);clf;
plot(rel_error_RE,stats_RE(:,1),'k.');
ylabel('rRMSE'); xlabel('rel error')

%%% Plot rel error, rRMSE vs Eo
f4 = figure(4);clf;
subplot(211)
plot(rel_error_RE,c_hat_RE(:,2),'b.')
title('relative error vs E_{0}');
ylabel('E_{0}'); xlabel('rel error');
axis([0 1.5 -200 1000 ]);
subplot(212)
plot(stats_RE(:,1),c_hat_RE(:,2),'g.')
title('rRMSE vs E_{0}');
ylabel('E_{0}'); xlabel('rRMSE');
axis([0.2 1 -200 1000 ]);

%%%% Looking at this, it may be more suitable to use rRMSE cutoff of 0.65
%%%% (65%), instead of a relative error cutoff, since the relative error is
%%%% going to be directly determined by the value of Eo.

%%% Step 1b: Estimate Dynamic Eo:
%%% Filter out to use only good periods (Eo 50-450, rel error < %50)
% ind_use_Eo1 = find(c_hat_RE(:,2) > 50 & c_hat_RE(:,2) < 450 & rel_error_RE < 0.5);
ind_use_Eo = find(c_hat_RE(:,2) > 75 & c_hat_RE(:,2) < 500 & stats_RE(:,1) < 0.65);

Eo_use = c_hat_RE(ind_use_Eo,2);
centres_use = centres(ind_use_Eo,1);
%%% Interpolate Between good estimates of Eo:
Eo_interp = interp1(centres_use-win_size,Eo_use,xi);
%%% Fill in NaNs outside first and last data points:
early_nans = find(xi < xi(end)/2 & isnan(Eo_interp));
Eo_interp(early_nans, 1) = Eo_interp(find(~isnan(Eo_interp),1,'first'),1);
late_nans = find(xi >= xi(end)/2 & isnan(Eo_interp));
Eo_interp(late_nans, 1) = Eo_interp(find(~isnan(Eo_interp),1,'last'),1);

%%% Plot results for Eo:
f2 = figure(2);clf;
ctr = 1;
for year = year_start:1:year_end
    if year_start-year_end > 7
        subplot(5,2,ctr);
    else
        subplot(4,2,ctr);
    end
    plot([1 17568],[c_hat_RE_all(1,2) c_hat_RE_all(1,2)],'r--','LineWidth', 1.5); hold on;
    ind_st(ctr,1) = find(data.Year==year,1,'first');
    ind_end(ctr,1) = find(data.Year==year,1,'last');
    centres_tmp = centres_use(centres_use >= ind_st(ctr,1) & centres_use <= ind_end(ctr,1));
    Eo_tmp = Eo_use(centres_use >= ind_st(ctr,1) & centres_use <= ind_end(ctr,1));
    plot(centres_tmp-ind_st(ctr,1)+1,Eo_tmp,'.','Color',clrs(ctr,:));hold on;
    plot(xi(ind_st(ctr,1)-ind_st(ctr,1)+1:ind_end(ctr,1)-ind_st(ctr,1)+1,1),...
        Eo_weighted(ind_st(ctr,1):ind_end(ctr,1),1),'--','Color',clrs(ctr,:), 'LineWidth',2);
    h1(ctr,1) = plot(xi(ind_st(ctr,1)-ind_st(ctr,1)+1:ind_end(ctr,1)-ind_st(ctr,1)+1,1),...
        Eo_interp(ind_st(ctr,1):ind_end(ctr,1),1),'-','Color',clrs(ctr,:));
    title(num2str(year));
    ylabel('E_{0}');
    set(gca,'YTick', [0:100:500]);
    if ctr == 1
        title('E_{0} estimates - no VPD');
    end
    ctr = ctr+1;
end
% legend('boxoff')
print('-dpdf',[fig_path 'LRC_noVPD_Eo_annual']);

f1 = figure(1);clf;
plot(centres_use,Eo_use(:,1),'go'); hold on;
plot([xi(1) xi(end)],[c_hat_RE_all(1,2) c_hat_RE_all(1,2)],'c--','LineWidth', 1.5);
plot(xi,Eo_interp, 'b-');
plot(xi,Eo_weighted,'r-');
title(['Years ' num2str(year_start) '-' num2str(year_end) ', E_{0} estimates - no VPD']);
set(gca,'XTick', ind_st, 'XTickLabel', {year_start:1:year_end}, 'FontSize', 14);
axis([1 xi(end) 50 450])
legend('Obs E_{0}','Eo-annual','Inerp E_{0}','Weighted E_{0}',3,'Orientation','Horizontal');
print('-dpdf',[fig_path 'LRC_noVPD_Eo_all']);

clear wrap_* centres
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Step 2: Estimate NEE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Estimation of NEE occurs in 3 different ways:
% 1. _noVPD
%%% Use nighttime-estimated Eo (above).  Derive other params from daytime
% 2. _noVPDall
%%% Derive Eo and other params from daytime.  Eo is static and singular.
% 3. _VPD
%%% Use nighttime-estimated Eo (above).  Modify Beta value based on VPD
%%% value.  Introduce new parameter for Beta scaling -- k.

NEE_clean = data.NEE;
NEE_clean(data.PAR < 15 & data.Ustar < data.Ustar_th, 1) = NaN;
%%% Preliminary NEE fill column vectors:
NEE_fill = NaN.*ones(length(NEE_clean),2);
NEE_fillu = NaN.*ones(length(NEE_clean),2);

for i = 1:1:2
    NEE_fill(~isnan(NEE_clean),i) = NEE_clean(~isnan(NEE_clean),1);
end

win_size = round(4*48/2);
incr = 2*48;
%%% Wrap the variables:
wrap_Ts = [data.Ts2(end-win_size+1:end,1); data.Ts2; data.Ts2(1:win_size,1)];
wrap_PAR = [data.PAR(end-win_size+1:end,1); data.PAR; data.PAR(1:win_size,1)];
wrap_Eo = [Eo_weighted(end-win_size+1:end,1); Eo_weighted; Eo_weighted(1:win_size,1)];
wrap_VPD = [data.VPD(end-win_size+1:end,1); data.VPD; data.VPD(1:win_size,1)];
wrap_ind = [xi(length(xi)-win_size+1:end,1); xi; xi(1:win_size,1)];
wrap_NEE = [NEE_clean(end-win_size+1:end,1); NEE_clean; NEE_clean(1:win_size,1)];
wrap_Ta = [data.Ta(end-win_size+1:end,1); data.Ta; data.Ta(1:win_size,1)];


centres = (win_size+1:incr:length(wrap_ind)-win_size)';
if centres(end) < length(wrap_NEE)-win_size; centres = [centres; length(wrap_NEE)-win_size]; end

%%
%%%% Variables to use within loop:
c_hat1 = NaN.*ones(length(centres),5);c_hat2 = NaN.*ones(length(centres),5);

% c_hat3 = NaN.*ones(length(centres),5);
stats1= NaN.*ones(length(centres),2); stats2= NaN.*ones(length(centres),2);
% stats3= NaN.*ones(length(centres),2);
y_pred1 = NaN.*ones(length(wrap_NEE),2); y_pred2 = NaN.*ones(length(wrap_NEE),2);
% y_pred3 = NaN.*ones(length(wrap_NEE),2);
num_pts = NaN.*ones(length(centres),1); num_pts_d = NaN.*ones(length(centres),1);
num_pts_n = NaN.*ones(length(centres),1);
Ts_Ta_means = NaN.*ones(length(centres),2);
Rref_start= NaN.*ones(length(centres),1);
beta_start = NaN.*ones(length(centres),1);

c_hat1u = NaN.*ones(length(centres),5);c_hat2u = NaN.*ones(length(centres),5);
stats1u= NaN.*ones(length(centres),2); stats2u= NaN.*ones(length(centres),2);
y_pred1u = NaN.*ones(length(wrap_NEE),2); y_pred2u = NaN.*ones(length(wrap_NEE),2);
% stats1u_redo= NaN.*ones(length(centres),2); stats2u_redo= NaN.*ones(length(centres),2);
% c_hat_fix = NaN.*ones(length(centres),5);c_hat_con = NaN.*ones(length(centres),5);

clear global;
%%% Windowed Parameterization:
for i = 1:1:length(centres)
    tic
    Ta_temp = wrap_Ta(centres(i)-win_size:centres(i)+win_size);
    Ts_temp = wrap_Ts(centres(i)-win_size:centres(i)+win_size);
    PAR_temp = wrap_PAR(centres(i)-win_size:centres(i)+win_size);
    Eo_temp = wrap_Eo(centres(i)-win_size:centres(i)+win_size);
    VPD_temp = wrap_VPD(centres(i)-win_size:centres(i)+win_size);
    NEE_temp = wrap_NEE(centres(i)-win_size:centres(i)+win_size);
    ind_check = Ts_temp.*PAR_temp.*Eo_temp.*VPD_temp.*NEE_temp;
    Ts_Ta_means(i,1:2) = [nanmean(Ts_temp) nanmean(Ta_temp)];
    %%% Determine the starting values for Rref:
    try Rref_start(i,1) = nanmean(NEE_temp(PAR_temp< 15,1)); catch; Rref_start(i,1) = NaN; end
    if isempty(Rref_start(i,1))==1 || isnan(Rref_start(i,1))==1 || Rref_start(i,1) >15; Rref_start(i,1) = 5;
    elseif Rref_start(i,1)<0; Rref_start(i,1) = 2;
    end
    %%% Determine the starting values for beta:
    try beta_start(i,1) = abs(quantile(NEE_temp,0.03)-quantile(NEE_temp,0.97));
    catch; beta_start(i,1) = NaN; end
    if isempty(beta_start(i,1))==1 || isnan(beta_start(i,1))==1 || beta_start(i,1) > 50; beta_start(i,1) = 20;
    elseif beta_start(i,1)<=0; beta_start(i,1) = 0.5;
    end
        %%% If mean Ts2cm is less than 4 degrees for the period, fix alpha=0.01
            if Ts_Ta_means(i,1) < 4
                fix_flag = 1;
            else
                fix_flag = 0;
            end
    
    % Run parameterization, gather c_hat values:
    X_eval = [PAR_temp Ts_temp Eo_temp VPD_temp];
    X_in = [PAR_temp(~isnan(ind_check)==1) Ts_temp(~isnan(ind_check)==1) ...
        Eo_temp(~isnan(ind_check)==1) VPD_temp(~isnan(ind_check)==1)];
    num_pts(i,1) = size(X_in,1);
    num_pts_d(i,1) = length(find(X_in(:,1)>15));
    num_pts_n(i,1) = length(find(X_in(:,1)<=15));
      
    %%%%%%%%%%% 1. _noVPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        options.costfun ='OLS'; options.min_method ='NMC';%options.f_coeff = []; %
        options.lbound = [1e-2 1e-3 1e-2 0];    options.ubound = [0.15 50 1 12];
    
    if fix_flag == 1
        options.f_coeff = [0.01 NaN NaN NaN];
    else
        options.f_coeff = [];
    end
    [c_hat, y_hat, y_pred, stats, sigma, err, exitflag, num_iter] = ...
        fitGEP([0.01 beta_start(i,1) 0.5 Rref_start(i,1)], 'fitGEP_LRC_NR', X_in ,NEE_temp(~isnan(ind_check)),  X_eval, [], options);
    % predicted values:
    y_pred1(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_pred;
    % gather stats:
    stats1(i,1:4) = [stats.rRMSE stats.MAE stats.R2 stats.Ei];
    % Coefficients: [alpha beta rRef]
    c_hat1(i,1:4) = c_hat;
    clear c_hat y_pred stats options;
    clear global;
    
        %%%%%%%%%%% 2. _VPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        options.costfun ='OLS'; options.min_method ='NMC';options.f_coeff = [];
        options.lbound = [1e-2 1e-3  1e-2 0.5 0];    options.ubound = [0.15 50 1 12 3];
    
        if fix_flag == 1
            options.f_coeff = [0.01 NaN NaN NaN NaN];
        else
            options.f_coeff = [];
        end
        [c_hat, y_hat, y_pred, stats, sigma, err, exitflag, num_iter] = ...
            fitGEP([0.01 beta_start(i,1) 0.5 Rref_start(i,1) 0], 'fitGEP_LRC_NR_VPD', X_in ,NEE_temp(~isnan(ind_check)),  X_eval, [], options);
        % predicted values:
        y_pred2(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_pred;
        % gather stats:
        stats2(i,1:4) = [stats.rRMSE stats.MAE stats.R2 stats.Ei];
        % Coefficients: [alpha beta rRef Eo]
        c_hat2(i,1:5) = c_hat;
        clear c_hat y_pred stats options y_hat;
        clear global;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%% UNCONSTRAINED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%% 1. _noVPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         options.costfun ='OLS'; options.min_method ='NMC';%options.f_coeff = []; %
%         options.lbound = [1e-2 1e-3 0 0];    options.ubound = [0.15 50 1 10];
    options.costfun ='OLS'; options.min_method ='NM';%options.f_coeff = [];
    
    if fix_flag == 1
        options.f_coeff = [0.01 NaN NaN NaN];
    else
        options.f_coeff = [];
    end
    [c_hat, y_hat, y_pred, stats, sigma, err, exitflag, num_iter] = ...
        fitGEP([0.01 beta_start(i,1) 0.5 Rref_start(i,1)], 'fitGEP_LRC_NR', X_in ,NEE_temp(~isnan(ind_check)),  X_eval, [], options);
    
    % predicted values:
    y_pred1u(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_pred;
    % gather stats:
    stats1u(i,1:4) = [stats.rRMSE stats.MAE stats.R2 stats.Ei];
%         [junk_RMSE junk_rRMSE junk_MAE junk_BE junk_R2 junk_Ei junk_R2b] = model_stats(real(y_hat),NEE_temp(~isnan(ind_check)));
%         stats1u_redo(i,1:5) = [junk_RMSE,junk_MAE,junk_R2,junk_Ei, junk_R2b];

    % Coefficients: [alpha beta rRef]
    c_hat1u(i,1:4) = c_hat;
    clear c_hat y_pred stats options stats_tmp junk_* y_hat;
    clear global;
    
        %%%%%%%%%%% 2. _VPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         options.costfun ='OLS'; options.min_method ='NMC';options.f_coeff = [];
%         options.lbound = [1e-2 1e-3  0 0 0];    options.ubound = [0.15 50 1 10 5];
         options.costfun ='OLS'; options.min_method ='NM';%options.f_coeff = [];
    
        if fix_flag == 1
            options.f_coeff = [0.01 NaN NaN NaN NaN];
        else
            options.f_coeff = [];
        end
        [c_hat, y_hat, y_pred, stats, sigma, err, exitflag, num_iter] = ...
            fitGEP([0.01 beta_start(i,1) 0.5 Rref_start(i,1) 0], 'fitGEP_LRC_NR_VPD', X_in ,NEE_temp(~isnan(ind_check)),  X_eval, [], options);
        % predicted values:
        y_pred2u(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_pred;
        % gather stats:
        stats2u(i,1:4) = [stats.rRMSE stats.MAE stats.R2 stats.Ei];
%         [junk_RMSE junk_rRMSE junk_MAE junk_BE junk_R2 junk_Ei] = model_stats(real(y_hat),NEE_temp(~isnan(ind_check)));
%         stats2u_redo(i,1:5) = [junk_RMSE,junk_MAE,junk_R2,junk_Ei];
        % Coefficients: [alpha beta rRef Eo]
        c_hat2u(i,1:5) = c_hat;
        clear c_hat y_pred stats options stats_tmp;
        clear global;
%     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    t = toc;
    disp(['run ' num2str(i) ' completed in ' num2str(t) ' seconds.'])
end

%%
figure(99);clf;
title('Constrained');

% h3 = plot((1:1:size(c_hat1,1)), Ts_Ta_means(:,1),'r'); hold on;
subplot(311)
h1 = plot((1:1:size(c_hat1,1)), c_hat1(:,1),'Color',clrs(1,:)); hold on;
% h1b = plot((1:1:size(c_hat1,1)), c_hat1u(:,1),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h2 = plot((1:1:size(c_hat2,1)), c_hat2(:,1),'Color',clrs(2,:)); hold on;
% h2b = plot((1:1:size(c_hat2,1)), c_hat2u(:,1),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1) -0.05 0.4])
legend([h1 h2],'No VPD', 'VPD');
ylabel('\alpha','FontSize',16)
set(gca,'FontSize',16)

subplot(312)
h3 = plot((1:1:size(c_hat1,1)), c_hat1(:,2),'Color',clrs(1,:)); hold on;
% h3b = plot((1:1:size(c_hat1,1)), c_hat1u(:,2),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h4 = plot((1:1:size(c_hat2,1)), c_hat2(:,2),'Color',clrs(2,:)); hold on;
% h4b = plot((1:1:size(c_hat2,1)), c_hat2u(:,2),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1) -5 60])
legend([h3 h4],'No VPD', 'VPD');
ylabel('\beta','FontSize',16)
set(gca,'FontSize',16)

subplot(313)
h5 = plot((1:1:size(c_hat1,1)), c_hat1(:,3),'Color',clrs(1,:)); hold on;
% h3b = plot((1:1:size(c_hat1,1)), c_hat1u(:,2),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h6 = plot((1:1:size(c_hat2,1)), c_hat2(:,3),'Color',clrs(2,:)); hold on;
% h4b = plot((1:1:size(c_hat2,1)), c_hat2u(:,2),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1) 0.5 1])
legend([h5 h6],'No VPD', 'VPD');
ylabel('\eta','FontSize',16)
set(gca,'FontSize',16)

figure(98);clf;
title('Unconstrained');
% h3 = plot((1:1:size(c_hat1,1)), Ts_Ta_means(:,1),'r'); hold on;
subplot(311)
h1 = plot((1:1:size(c_hat1u,1)), c_hat1u(:,1),'Color',clrs(1,:)); hold on;
% h1b = plot((1:1:size(c_hat1,1)), c_hat1u(:,1),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h2 = plot((1:1:size(c_hat2u,1)), c_hat2u(:,1),'Color',clrs(2,:)); hold on;
% h2b = plot((1:1:size(c_hat2,1)), c_hat2u(:,1),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1u) -0.05 0.4])
legend([h1 h2],'No VPD', 'VPD');
ylabel('\alpha','FontSize',16)
set(gca,'FontSize',16)

subplot(312)
h3 = plot((1:1:size(c_hat1u,1)), c_hat1u(:,2),'Color',clrs(1,:)); hold on;
% h3b = plot((1:1:size(c_hat1,1)), c_hat1u(:,2),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h4 = plot((1:1:size(c_hat2u,1)), c_hat2u(:,2),'Color',clrs(2,:)); hold on;
% h4b = plot((1:1:size(c_hat2,1)), c_hat2u(:,2),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1u) -5 60])
legend([h3 h4],'No VPD', 'VPD');
ylabel('\beta','FontSize',16)
set(gca,'FontSize',16)

subplot(313)
h5 = plot((1:1:size(c_hat1u,1)), c_hat1u(:,3),'Color',clrs(1,:)); hold on;
% h3b = plot((1:1:size(c_hat1,1)), c_hat1u(:,2),'Color',clrs(1,:),'LineWidth',2,'LineStyle','--'); hold on;
h6 = plot((1:1:size(c_hat2u,1)), c_hat2u(:,3),'Color',clrs(2,:)); hold on;
% h4b = plot((1:1:size(c_hat2,1)), c_hat2u(:,2),'Color',clrs(2,:),'LineWidth',2,'LineStyle','--'); hold on;
axis([1 length(c_hat1u) 0 1])
legend([h5 h6],'No VPD', 'VPD');
ylabel('\eta','FontSize',16)
set(gca,'FontSize',16)

% [AX h1 h2] = plotyy((1:1:size(c_hat1,1)),c_hat1(:,2), (1:1:size(c_hat1,1)), c_hat1(:,1),@line, @line);hold on;
% set(AX(1),'XLim',[1 size(c_hat1,1)],'YLim',[0 50])
% set(AX(2),'XLim',[1 size(c_hat1,1)], 'YLim', [0 0.2])
% set(AX(1),'YTick',(0:2:50))
% set(AX(2),'YTick',(0:0.01:0.2))
% [AXb h1b h2b] = plotyy((1:1:size(c_hat1,1)),c_hat2(:,2), (1:1:size(c_hat1,1)), c_hat2(:,1),@line, @line);hold on;
% set(AXb(1),'XLim',[1 size(c_hat2,1)],'YLim',[0 50])
% set(AXb(2),'XLim',[1 size(c_hat2,1)], 'YLim', [0 0.2])
% set(AXb(1),'YTick',(0:2:50))
% set(AXb(2),'YTick',(0:0.01:0.2))
% set(h1b,'Color',clrs(7,:));
% set(h2b,'Color',clrs(8,:));

% legend([h3 h2 h1], 'Ts2', '\alpha','\beta')

%%% Plot some stuff for checking:
f3 = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(real(y_pred1))
axis([1 length(y_pred1u) -25 15]);title('noVPD');
subplot(212);plot(wrap_NEE,'k.-');hold on;plot(real(y_pred2u));
axis([1 length(y_pred1u) -25 15]);title('VPD');
% subplot(313);plot(wrap_NEE,'k.-');hold on;plot(y_pred3);
% axis([1 length(y_pred1) -25 15]);title('VPD');
f3b = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(real(y_pred1u))
axis([1 length(y_pred1u) -25 15]);title('noVPD - unconstr.');
subplot(212);plot(wrap_NEE,'k.-');hold on;plot(real(y_pred2u));
axis([1 length(y_pred1u) -25 15]);title('VPD - unconstr.');




%%%%%%%%%%%%%%%  CLEANING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Now, we need to go through the estimated parameters, and deal with any
%%% unacceptible values:
%%%%%%%%%%%%%%%% A: Constrained values: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Any instance of rRMSE being NaN results in coefficients being NaN:
ind_nan1 = find(isnan(stats1(:,1))); ind_nan2 = find(isnan(stats2(:,1))); %ind_nan3 = find(isnan(stats3(:,1)));
c_hat1(ind_nan1,:) = NaN; c_hat2(ind_nan2,:) = NaN; %c_hat3(ind_nan3,:) = NaN;
% 2. If there is less than 10 daytime or nighttime points in any period, make NaN:
ind_nan_pts = find(num_pts_d < 10 | num_pts_n < 10);
c_hat1(ind_nan_pts,:) = NaN; c_hat2(ind_nan_pts,:) = NaN; %c_hat3(ind_nan_pts,:) = NaN;
% % 3. Remove data from any period with a rRMSE > 0.85:
% ind_bad_stats1 = find(stats1(:,1) > 0.85);ind_bad_stats2 = find(stats2(:,1) > 0.85);
% ind_bad_stats3 = find(stats3(:,1) > 0.85);
% c_hat1(ind_bad_stats1,:) = NaN; c_hat2(ind_bad_stats2,:) = NaN; c_hat3(ind_bad_stats3,:) = NaN;
% 4. Find where beta == 50, make NaN to all parameters:
c_hat1(c_hat1(:,2)>=49.5,:) = NaN;c_hat2(c_hat2(:,2)>=49.5,:) = NaN; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 4. k value less than 0 = 0 (c_hat3 only):
c_hat2(c_hat2(:,5)<0,5)= 0;
% 5. Alpha less than 0 = 0:
c_hat1(c_hat1(:,1)<0,1) = 0;c_hat2(c_hat2(:,1)<0,1) = 0; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 5. Alpha greater than 0.49 = NaN:
c_hat1(c_hat1(:,1)>0.148,:) = NaN;c_hat2(c_hat2(:,1)>0.148,:) = NaN; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 6. Curve parameter must be more than 0:
c_hat1(c_hat1(:,3)<0,3) = NaN; c_hat2(c_hat2(:,3)<0,3) = NaN;

%%%%%%%%%%%%%%% B: Unconstrained values: %%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Any instance of rRMSE being NaN results in coefficients being NaN:
ind_nan1 = find(isnan(stats1u(:,1))); ind_nan2u = find(isnan(stats2(:,1))); %ind_nan3 = find(isnan(stats3(:,1)));
c_hat1u(ind_nan1,:) = NaN; c_hat2u(ind_nan2,:) = NaN; %c_hat3(ind_nan3,:) = NaN;
% 2. If there is less than 10 daytime or nighttime points in any period, make NaN:
ind_nan_pts = find(num_pts_d < 10 | num_pts_n < 10);
c_hat1u(ind_nan_pts,:) = NaN; c_hat2u(ind_nan_pts,:) = NaN; %c_hat3(ind_nan_pts,:) = NaN;
% % 3. Remove data from any period with a rRMSE > 0.85:
% ind_bad_stats1 = find(stats1(:,1) > 0.85);ind_bad_stats2 = find(stats2(:,1) > 0.85);
% ind_bad_stats3 = find(stats3(:,1) > 0.85);
% c_hat1(ind_bad_stats1,:) = NaN; c_hat2(ind_bad_stats2,:) = NaN; c_hat3(ind_bad_stats3,:) = NaN;
% 4. Find where beta == 50, make NaN to all parameters:
c_hat1(c_hat1(:,2)>=100,:) = NaN;c_hat2(c_hat2(:,2)>=100,:) = NaN; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 4. k value less than 0 = 0 (c_hat3 only):
c_hat2u(c_hat2u(:,5)<0,5)= 0;
% 5. Alpha less than 0 = 0:
c_hat1u(c_hat1u(:,1)<0,1) = 0;c_hat2u(c_hat2u(:,1)<0,1) = 0; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 5. Alpha greater than 0.30 = NaN:
c_hat1(c_hat1(:,1)>0.3,:) = NaN;c_hat2(c_hat2(:,1)>0.3,:) = NaN; %c_hat3(c_hat3(:,2)>=49.5,:) = NaN;
% 6. Curve parameter must be more than 0:
c_hat1(c_hat1(:,3)<0,3) = NaN; c_hat2(c_hat2(:,3)<0,3) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% FILL EMPTY SPOTS IN PARAMETERS, PREDICT NEE: %%%%%%%%%%%%%%%%

%%% We should also be able to model RE and GEP as well, using the filled
%%% parameters and the given equations:

y_pred1NEE = NaN.*ones(length(wrap_NEE),2); y_pred2NEE = NaN.*ones(length(wrap_NEE),2);
y_pred1RE = NaN.*ones(length(wrap_NEE),2); y_pred2RE = NaN.*ones(length(wrap_NEE),2);
y_pred1GEP = NaN.*ones(length(wrap_NEE),2); y_pred2GEP = NaN.*ones(length(wrap_NEE),2);
y_pred1uNEE = NaN.*ones(length(wrap_NEE),2); y_pred2uNEE = NaN.*ones(length(wrap_NEE),2);
y_pred1uRE = NaN.*ones(length(wrap_NEE),2); y_pred2uRE = NaN.*ones(length(wrap_NEE),2);
y_pred1uGEP = NaN.*ones(length(wrap_NEE),2); y_pred2uGEP = NaN.*ones(length(wrap_NEE),2);


clear global;

for i = 1:1:length(centres)
    %%% Fix for _noVPD:
    for k = 1:1:4 % cycle through coefficient columns:
        % If the first value is NaN, set it to the last previous OK value:
        if i ==1
            if isnan(c_hat1(1,k))==1; c_hat1(1,k) = c_hat1(find(~isnan(c_hat1(:,k)),1,'last'),k); end
        else
            if isnan(c_hat1(i,k))==1; c_hat1(i,k) = c_hat1(find(~isnan(c_hat1(1:i,k)),1,'last'),k); end
        end
    end
    %%% Fix for _VPD:
    try
        for k = 1:1:5 % cycle through coefficient columns:
            % If the first value is NaN, set it to the last previous OK value:
            if i ==1
                if isnan(c_hat2(1,k))==1; c_hat2(1,k) = c_hat2(find(~isnan(c_hat2(:,k)),1,'last'),k); end
            else
                if isnan(c_hat2(i,k))==1; c_hat2(i,k) = c_hat2(find(~isnan(c_hat2(1:i,k)),1,'last'),k); end
            end
        end
    catch
    end

    %%% Fix for _noVPD - unconstrained:
    for k = 1:1:4 % cycle through coefficient columns:
        % If the first value is NaN, set it to the last previous OK value:
        if i ==1
            if isnan(c_hat1u(1,k))==1; c_hat1u(1,k) = c_hat1u(find(~isnan(c_hat1u(:,k)),1,'last'),k); end
        else
            if isnan(c_hat1u(i,k))==1; c_hat1u(i,k) = c_hat1u(find(~isnan(c_hat1u(1:i,k)),1,'last'),k); end
        end
    end
    %%% Fix for _VPD - unconstrained: 
    try
        for k = 1:1:5 % cycle through coefficient columns:
            % If the first value is NaN, set it to the last previous OK value:
            if i ==1
                if isnan(c_hat2u(1,k))==1; c_hat2u(1,k) = c_hat2u(find(~isnan(c_hat2u(:,k)),1,'last'),k); end
            else
                if isnan(c_hat2u(i,k))==1; c_hat2u(i,k) = c_hat2u(find(~isnan(c_hat2u(1:i,k)),1,'last'),k); end
            end
        end
    catch
    end    
    
    %%%% Now, we can use the filled numbers to make new predictions:
    Ts_temp = wrap_Ts(centres(i)-win_size:centres(i)+win_size);
    PAR_temp = wrap_PAR(centres(i)-win_size:centres(i)+win_size);
    Eo_temp = wrap_Eo(centres(i)-win_size:centres(i)+win_size);
    VPD_temp = wrap_VPD(centres(i)-win_size:centres(i)+win_size);
    NEE_temp = wrap_NEE(centres(i)-win_size:centres(i)+win_size);
    
    X_eval = [PAR_temp Ts_temp Eo_temp VPD_temp];
    
    %%%% Estimate for _noVPD:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NEE:
    y_tmp = fitGEP_NR_LRC(c_hat1(i,1:4),X_eval);
    y_pred1NEE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % RE - We'll make alpha = 0, which removes GEP:
    y_tmp = fitGEP_NR_LRC([0 c_hat1(i,2:4)],X_eval);
    y_pred1RE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % GEP - We'll make Rref = 0, which removes RE:
    y_tmp = fitGEP_NR_LRC([c_hat1(i,1:3) 0],X_eval);
    y_pred1GEP(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = -1.*y_tmp;clear y_tmp;
    
    %%%% Estimate for _VPD: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    y_tmp = fitGEP_NR_LRC_VPD(c_hat2(i,1:5),X_eval);
    y_pred2NEE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % RE - We'll make alpha = 0, which removes GEP:
    y_tmp = fitGEP_NR_LRC_VPD([0 c_hat2(i,2:5)],X_eval);
    y_pred2RE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % GEP - We'll make Rref = 0, which removes RE:
    y_tmp = fitGEP_NR_LRC_VPD([c_hat2(i,1:3) 0 c_hat2(i,5)],X_eval);
    y_pred2GEP(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = -1.*y_tmp;clear y_tmp;

    %%%% Estimate for _noVPD -- Unconstrained: %%%%%%%%%%%%%%%%%%%%
    % NEE:
    y_tmp = fitGEP_NR_LRC(c_hat1u(i,1:4),X_eval);
    y_pred1NEE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % RE - We'll make alpha = 0, which removes GEP:
    y_tmp = fitGEP_NR_LRC([0 c_hat1u(i,2:4)],X_eval);
    y_pred1RE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % GEP - We'll make Rref = 0, which removes RE:
    y_tmp = fitGEP_NR_LRC([c_hat1u(i,1:3) 0],X_eval);
    y_pred1GEP(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = -1.*y_tmp;clear y_tmp;
    
    %%%% Estimate for _VPD -- Unconstrained: %%%%%%%%%%%%%%%%%%%%
    y_tmp = fitGEP_NR_LRC_VPD(c_hat2u(i,1:5),X_eval);
    y_pred2NEE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % RE - We'll make alpha = 0, which removes GEP:
    y_tmp = fitGEP_NR_LRC_VPD([0 c_hat2u(i,2:5)],X_eval);
    y_pred2RE(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = y_tmp;clear y_tmp;
    % GEP - We'll make Rref = 0, which removes RE:
    y_tmp = fitGEP_NR_LRC_VPD([c_hat2u(i,1:3) 0 c_hat2u(i,5)],X_eval);
    y_pred2GEP(centres(i)-win_size:centres(i)+win_size,rem(i,2)+1) = -1.*y_tmp;clear y_tmp;

    
    %%% Make a vector the same length as y_pred that records the centre
    %%% position associated with that window:
    win_start = centres(i)-win_size;
    win_end = centres(i)+win_size;
    c_loc(win_start:win_end,rem(i,2)+1) = centres(i);
end

%%% Why are we getting complex numbers????%%%%%%%%%%%%%
% y_pred1GEP = real(y_pred1GEP); y_pred1NEE = real(y_pred1NEE);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Plot the newly predicted NEE for checking:
% Constrained
f4a = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(y_pred1NEE)
axis([1 length(y_pred1NEE) -25 15]);title('noVPD');
subplot(212);plot(y_pred1RE,'r');hold on; plot(-1.*y_pred1GEP,'g');
axis([1 length(y_pred1NEE) -45 25]);title('noVPD');
print('-djpeg', [fig_path 'model_results_noVPD_const']);
legend('RE','GEE')

f4b = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(y_pred2NEE)
axis([1 length(y_pred2NEE) -25 15]);title('noVPDall-NEE');
subplot(212);plot(y_pred2RE,'r');hold on; plot(-1.*y_pred2GEP,'g');
axis([1 length(y_pred2NEE) -45 25]);title('VPD-RE, GEP');
legend('RE','GEE')
print('-djpeg', [fig_path 'model_results_VPD_const']);

% Unconstrained
f5a = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(y_pred1uNEE)
axis([1 length(y_pred1uNEE) -25 15]);title('noVPD');
subplot(212);plot(y_pred1uRE,'r');hold on; plot(-1.*y_pred1uGEP,'g');
axis([1 length(y_pred1uNEE) -45 25]);title('noVPD');
print('-djpeg', [fig_path 'model_results_noVPD_unconst']);
legend('RE','GEE')

f5b = figure();clf;
subplot(211);plot(wrap_NEE,'k.-');hold on; plot(y_pred2uNEE)
axis([1 length(y_pred2uNEE) -25 15]);title('noVPDall-NEE');
subplot(212);plot(y_pred2uRE,'r');hold on; plot(-1.*y_pred2uGEP,'g');
axis([1 length(y_pred2uNEE) -45 25]);title('VPD-RE, GEP');
legend('RE','GEE')
print('-djpeg', [fig_path 'model_results_VPD_unconst']);


% f4c = figure();clf;
% subplot(211);plot(wrap_NEE,'k.-');hold on; plot(y_pred3NEE)
% axis([1 length(y_pred3NEE) -25 15]);title('VPD-NEE');
% subplot(212);plot(y_pred3RE,'r');hold on; plot(-1.*y_pred3GEP,'g');
% axis([1 length(y_pred3NEE) -45 25]);title('VPD- RE, GEP');
% legend('RE','GEE')
% print('-djpeg', [fig_path 'model_results_VPD']);


% f10 = figure();clf;
% subplot(311);
% plot(y_pred1(:,1),'k');
% axis([1 length(y_pred1) -20 20])
% subplot(312);
% plot((1:2*48:size(c_hat1,1).*2*48),stats1(:,1),'k');
% axis([1 length(stats1)*2*48 0 1])
% subplot(313);
% [AX h1 h2] = plotyy((1:2*48:size(c_hat1,1).*2*48),c_hat1(:,1), (1:2*48:size(c_hat1,1).*2*48), c_hat1(:,2),@line, @line);hold on;
% set(get(AX(2),'YLabel'), 'String','\beta','FontSize', 16,'Color', [0 0.6 0])
% set(get(AX(1),'YLabel'), 'String','\alpha','FontSize', 16, 'Color','b')
% set(h1,'LineWidth', 2);
% set(h2,'LineWidth', 1.5);
% % Set y ticks and labels:
% set(AX(1),'YTick', [-0.05:0.05:0.2]', 'YTickLabel',{-0.05:0.05:0.2},'FontSize',16)
% set(AX(2),'YTick', [-5:5:55]', 'YTickLabel',{-5:5:55},'FontSize',16)
% set(AX(1),'XLim',[1 size(c_hat1,1)*2*48],'YLim',[-0.05 0.2])
% set(AX(2),'XLim',[1 size(c_hat1,1)*2*48], 'YLim', [-5 55])
% title(['All years, \alpha and \beta']);
% set(AX(2), 'FontSize', 14, 'YGrid', 'on');
% set(AX(1), 'FontSize', 14);
% print('-djpeg', [fig_path 'fixed_alpha_NEE_results']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% GET FINAL NEE, RE, GEP ESTIMATES: %%%%%%%%%%%%%%%%

%%% Merge the two columns of y_pred data into a single estimated value
% Do this by weighting the data by its proximity to the centre of the
% estimation window:
NEE_pred = NaN.*ones(length(y_pred1NEE),4);
GEP_pred = NaN.*ones(length(y_pred1NEE),4);
RE_pred = NaN.*ones(length(y_pred1NEE),4);
% NEE_predu = NaN.*ones(length(y_pred1uNEE),3);
% GEP_predu = NaN.*ones(length(y_pred1uNEE),3);
% RE_predu = NaN.*ones(length(y_pred1uNEE),3);

centre_dist = [abs(c_loc(:,1) - (1:1:length(y_pred1NEE))') abs(c_loc(:,2) - (1:1:length(y_pred1NEE))')];
total_dist = nansum(centre_dist,2);
ind_nan1 = find(isnan(centre_dist(:,1))==1);
ind_nan2 = find(isnan(centre_dist(:,2))==1);
weights = [(total_dist - centre_dist(:,1))./total_dist (total_dist - centre_dist(:,2))./total_dist ];
% First, apply the weighted mean measurement into appropriate hhour:
NEE_pred(:,1) = sum(y_pred1NEE.*weights,2);NEE_pred(:,2) = sum(y_pred2NEE.*weights,2);
GEP_pred(:,1) = sum(y_pred1GEP.*weights,2);GEP_pred(:,2) = sum(y_pred2GEP.*weights,2);
RE_pred(:,1) = sum(y_pred1RE.*weights,2);RE_pred(:,2) = sum(y_pred2RE.*weights,2);

NEE_pred(:,3) = sum(y_pred1uNEE.*weights,2);NEE_pred(:,4) = sum(y_pred2uNEE.*weights,2);
GEP_pred(:,3) = sum(y_pred1uGEP.*weights,2);GEP_pred(:,4) = sum(y_pred2uGEP.*weights,2);
RE_pred(:,3) = sum(y_pred1uRE.*weights,2);RE_pred(:,4) = sum(y_pred2uRE.*weights,2);

% Second, if we only have a measurement from one column, use it:
NEE_pred(ind_nan1,1) = y_pred1NEE(ind_nan1,2); NEE_pred(ind_nan2,1) = y_pred1NEE(ind_nan2,1);
NEE_pred(ind_nan1,2) = y_pred2NEE(ind_nan1,2); NEE_pred(ind_nan2,2) = y_pred2NEE(ind_nan2,1);
NEE_pred(ind_nan1,3) = y_pred1uNEE(ind_nan1,2); NEE_pred(ind_nan2,3) = y_pred1uNEE(ind_nan2,1);
NEE_pred(ind_nan1,4) = y_pred2uNEE(ind_nan1,2); NEE_pred(ind_nan2,4) = y_pred2uNEE(ind_nan2,1);

GEP_pred(ind_nan1,1) = y_pred1GEP(ind_nan1,2); GEP_pred(ind_nan2,1) = y_pred1GEP(ind_nan2,1);
GEP_pred(ind_nan1,2) = y_pred2GEP(ind_nan1,2); GEP_pred(ind_nan2,2) = y_pred2GEP(ind_nan2,1);
GEP_pred(ind_nan1,3) = y_pred1uGEP(ind_nan1,2); GEP_pred(ind_nan2,3) = y_pred1uGEP(ind_nan2,1);
GEP_pred(ind_nan1,4) = y_pred2uGEP(ind_nan1,2); GEP_pred(ind_nan2,4) = y_pred2uGEP(ind_nan2,1);

RE_pred(ind_nan1,1) = y_pred1RE(ind_nan1,2); RE_pred(ind_nan2,1) = y_pred1RE(ind_nan2,1);
RE_pred(ind_nan1,2) = y_pred2RE(ind_nan1,2); RE_pred(ind_nan2,2) = y_pred2RE(ind_nan2,1);
RE_pred(ind_nan1,3) = y_pred1uRE(ind_nan1,2); RE_pred(ind_nan2,3) = y_pred1uRE(ind_nan2,1);
RE_pred(ind_nan1,4) = y_pred2uRE(ind_nan1,2); RE_pred(ind_nan2,4) = y_pred2uRE(ind_nan2,1);

%%% Constrained
f11 = figure();clf;
subplot(3,1,1)
h1 = plot(wrap_NEE,'k.-');hold on;h2 = plot(NEE_pred(1:2,:));
legend(h2, NEE_tags)
ylabel('NEE');
subplot(3,1,2)
h2 = plot(GEP_pred(1:2,:));
legend(h2, NEE_tags)
ylabel('GEP');
subplot(3,1,3)
h2 = plot(RE_pred(1:2,:));
legend(h2, NEE_tags)
ylabel('RE');
print('-djpeg', [fig_path 'NEE_RE_GEP_pred_const']);

%%% Unconstrained
f11b = figure();clf;
subplot(3,1,1)
h1 = plot(wrap_NEE,'k.-');hold on;h2 = plot(NEE_pred(3:4,:));
legend(h2, NEE_tags)
ylabel('NEE');
subplot(3,1,2)
h2 = plot(GEP_pred(3:4,:));
legend(h2, NEE_tags)
ylabel('GEP');
subplot(3,1,3)
h2 = plot(RE_pred(3:4,:));
legend(h2, NEE_tags)
ylabel('RE');
print('-djpeg', [fig_path 'NEE_RE_GEP_pred_unconst']);


%%% Trim the datafiles to the appropriate length:
NEE_pred_final = NEE_pred(win_size+1:length(NEE_pred)-win_size,:);
GEP_pred_final = GEP_pred(win_size+1:length(GEP_pred)-win_size,:);
RE_pred_final = RE_pred(win_size+1:length(RE_pred)-win_size,:);

% %%% Trim the datafiles to the appropriate length:
% NEE_pred_finalu = NEE_predu(win_size+1:length(NEE_predu)-win_size,:);
% GEP_pred_finalu = GEP_predu(win_size+1:length(GEP_predu)-win_size,:);
% RE_pred_finalu = RE_predu(win_size+1:length(RE_predu)-win_size,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SAVE THE FINAL NEE, GEP, RE DATA and SUMS: %%%%%%%%%%%%%%%%
final_out = struct;
sum_labels = {'Year';'NEE_filled';'NEE_pred'; 'GEP_pred'; 'RE_pred'};

for i = 1:1:size(NEE_tags,1)
    NEE_fill(isnan(NEE_fill(:,i)),i) = NEE_pred_final(isnan(NEE_fill(:,i)),i);
    
    num_gaps(i,1) = length(find(isnan(NEE_fill(:,i))));
    disp(['Total of ' num2str(num_gaps(i,1)) ' gaps in ' NEE_tags{i,1}])

    % Constrained:
    master.NEE_clean = NEE_clean;
    master.NEE_filled = NEE_fill(:,i);
    master.NEE_pred = NEE_pred_final(:,i);
    master.GEP_pred = GEP_pred_final(:,i);
    master.RE_pred = RE_pred_final(:,i);
    ctr = 1;
    for year = year_start:1:year_end
        master.sums(ctr,1) = year;
        master.sums(ctr,2) = sum(master.NEE_filled(data.Year==year)).*0.0216;
        master.sums(ctr,3) = sum(master.NEE_pred(data.Year==year)).*0.0216;
        master.sums(ctr,4) = sum(master.GEP_pred(data.Year==year)).*0.0216;
        master.sums(ctr,5) = sum( master.RE_pred(data.Year==year)).*0.0216;
        ctr = ctr + 1;
    end
    master.sum_labels = sum_labels;
%     save([ls 'Matlab/Data/Gapfilling/TP39/NR_LRC_' NEE_tags{i,1} '_fill_2003-2009.mat'],'master')
    final_out(i).master = master;
    final_out(i).tag = NEE_tags{i,1};
    clear master    
end

end

%% END OF MAIN FUNCTION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% SUBFUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% REMOVED LINES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
