function [std_pred] = NEE_random_error_estimator_v4(data,tol, Ustar_th, plot_flag)
%%% This function estimates the error (standard deviation) associated with
%%% measured NEE, as a function of the value of NEE itself, separated into
%%% two conditions: non-growing season and growing-season.
%%% This version of the program uses the partioning-style method to
%%% estimate NEE, and uses the residuals between measured and modeled NEE
%%% to estimate error on the data, as a function of the modeled NEE value.

if nargin < 4
    plot_flag = 0;
end

if ~isfield(data, 'site')
    data.site = input('Enter Site Name: ', 's');
end

% Calculate VPD if it doesn't exist
if isfield(data,'VPD')==0;
    data.VPD = VPD_calc(data.RH, data.Ta);
end
% Calculate GDD if it doesn't exist:
if isfield(data,'GDD')==0;
    [junk data.GDD] = GDD_calc(data.Ta,10,48,[]);
end

%% Relationship for Respiration (i.e. Nighttime and Non-Growing Season)
% ind_param_RE = find((data.Ustar >= Ustar_th & ~isnan(data.Ts5) & ~isnan(data.NEE) & data.PAR < 15) |... % growing season
%     (data.Ustar >= Ustar_th & ~isnan(data.NEE) & data.Ts5 < -1  ) );                                   % non-growing season
ind_param_RE = find(data.Ustar >= data.Ustar_th & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE));

X_in = [data.Ts5(ind_param_RE) data.SM_a(ind_param_RE) data.PAR(ind_param_RE)];
Y_in = data.NEE(ind_param_RE);
stdev_in = ones(length(X_in),1);
X_eval = [data.Ts5 data.SM data.PAR];

options.costfun ='OLS'; options.min_method ='NM'; options.f_coeff = [NaN NaN NaN];
[c_hat_RE, y_hat_RE, pred_RE, stats_RE, sigma_RE, err_RE, exitflag_RE, num_iter_RE] = ...
    fitresp([9 0.2 12], 'fitresp_2A', X_in, Y_in, X_eval, stdev_in, options);

%%% In this version, we'll try and just use model residuals to give us an
%%% idea of the spread of the data:
error_RE = Y_in - y_hat_RE;

if plot_flag == 1
    %%% First plot will show historgrams for error for both RE and GEP:
    figure('Name', 'Error Distribution - RE, GEP','Tag','v4_Err_Dist');clf
    subplot(211)
    %%% Create histogram of error to check distribution:
    [y_RE xout_RE] = hist(error_RE,100);
    bar(xout_RE,y_RE)
    ylabel('count');
    xlabel('Error Bins');
    title('RE');
    
    %%% Second plot will show scatter of error as function of modeled RE, GEP:
    figure('Name', 'Error vs. RE, GEP', 'Tag', 'v4_Err_Scatter');clf
    %%% Create scatterplot -- let's see if data is homoscedastic:
    h1(1) = plot(y_hat_RE, error_RE,'r.'); hold on;
    xlabel('Predicted RE, GEP value');
    ylabel('Error');
    % axis([0 40 -10 10]);
end

if strcmp(data.site,'TP89')==1
    avg_interval = 2.5;
    avg_window = 1.25;
    min_samples = 20;
else
    avg_interval = 0.5;
    avg_window = 0.5;
    min_samples = 40;
end

%%% Output of jjb_mov_window_stats:
% 1 - Centre of window for x
% 2 - Centre of y for window
% 3 - Median of y for window
% 4 - Stdev  of y for window
% 5 - # of y pts used in window
[RE_std]= jjb_mov_window_stats(y_hat_RE,error_RE, avg_interval, avg_window);
ind_use_RE_std = find(RE_std(:,5)>min_samples);

if plot_flag == 1
    figure('Name', 'RE, GEP vs. std dev of error', 'Tag', 'v4_Std_Scatter');
    h2(1) = plot(RE_std(ind_use_RE_std,1),RE_std(ind_use_RE_std,4),'r.');hold on;
end

%% Calculate GEP from NEE and R:
GEPraw = pred_RE - data.NEE;
flag_gs = zeros(length(GEPraw),1); % variable to keep track of what is growing season and what isn't

%%% Model GEP based on PAR, Ts, Ta, VPD,
% ind_param_GEP = find(data.Ts5 >= -1 & data.VPD > 0 & data.Ta > -5 & data.PAR > 20 & ~isnan(GEPraw) & data.Ustar > Ustar_th ...
%     & data.dt > 95 & data.dt < 325 & data.GDD > 8);
        ind_param_GEP = find(~isnan(GEPraw.*data.Ts5.*data.PAR) & data.GEP_flag==2 & data.VPD > 0 & data.Ustar > data.Ustar_th);      

options.costfun ='OLS'; options.min_method ='NM'; options.f_coeff = NaN.*ones(1,6);
[c_hat_GEPL6, y_hat_GEPL6, pred_GEPL6, stats_GEPL6 sigma_GEPL6, err_GEPL6, exitflag_GEPL6, num_iter_GEPL6] = ...
    fitGEP([0.05 35 2 4 -2 -0.8], 'fitGEP_1H1_2L6', [data.PAR(ind_param_GEP) data.Ts5(ind_param_GEP) data.VPD(ind_param_GEP)], ...
    GEPraw(ind_param_GEP), [data.PAR data.Ts5 data.VPD], [], options);

% ind_GEP = find(data.PAR >= 20 & ((data.dt > 85 & data.dt < 330 & (data.GDD > 8 | data.Ts5 >= 1 & data.Ta > 2)) ...
%     | data.dt > 330 & data.Ts5 >= 1.25 & data.Ta > 2));
        ind_GEP = find(data.GEP_flag>=1);
% ind_gs =  (data.dt > 85 & data.dt < 330 & (data.GDD > 8 | data.Ts5 >= 1 & data.Ta > 2)) ...
%     | (data.dt > 330 & data.Ts5 >= 1.25 & data.Ta > 2) ;
flag_gs(ind_GEP,1) = 1;

pred_GEP(1:length(data.Year),1)= 0;
pred_GEP(ind_GEP,1) = pred_GEPL6(ind_GEP,1);

%%% Error in GEP prediction
error_GEP = GEPraw(ind_param_GEP) - y_hat_GEPL6;

if plot_flag == 1
    % figure('Name', 'Error Distribution - GEP')
    figure(findobj('Tag','v4_Err_Dist'));
    subplot(212)
    %%% Create histogram of error to check distribution:
    [y_GEP xout_GEP] = hist(error_GEP,100);
    bar(xout_GEP,y_GEP)
    ylabel('count');
    xlabel('Error Bins');
    title('GEP');
    
    figure(findobj('Tag','v4_Err_Scatter'));
    %%% Create scatterplot -- let's see if data is homoscedastic:
    h1(2) = plot(y_hat_GEPL6, error_GEP,'b.');
    xlabel('Predicted GEP value');
    ylabel('Error');
    axis([0 40 -10 10]);
    legend(h1,'RE','GEP');
end

%%% Output of jjb_mov_window_stats:
% 1 - Centre of window for x
% 2 - Centre of y for window
% 3 - Median of y for window
% 4 - Stdev  of y for window
% 5 - # of y pts used in window
[GEP_std]= jjb_mov_window_stats(y_hat_GEPL6,error_GEP, avg_interval, avg_window);
ind_use_GEP_std = find(GEP_std(:,5)>min_samples);

if plot_flag == 1
    figure(findobj('Tag','v4_Std_Scatter'));
    h2(2) = plot(GEP_std(ind_use_GEP_std,1),GEP_std(ind_use_GEP_std,4),'b.');
    axis([0 40 0 8]);
    legend(h2,{'RE';'GEP'});
end

%% ***********************************************************************
%%% This is where we diverge from previous versions -- instead of using GEP
%%% and RE as analogs for +/- NEE, we'll instead derive modeled NEE and use
%%% that to find the error directly in measured NEE:

NEE_model = pred_RE - pred_GEP;
% tot_xch = pred_RE+pred_GEP; % the total sum of RE and GEP exchanges:

%%% make indexed for data to include when scaling error to NEE value during
%%% growing season and non-growing season.  These criteria are different
%%% from those used to actually detect the start and end of growing season,
%%% as we want to avoid the start and end of the growing season, as that is
%%% where the method has the hardest time predicting fluxes, and a lot of
%%% the error is due to the model and not the measurements:
ind_comp_gs = find(~isnan(data.NEE.*NEE_model) & data.Ts5 > 2 & data.dt > 95 & data.dt < 325);
ind_comp_ngs = find(~isnan(data.NEE.*NEE_model) & (data.dt < 80 | data.dt > 340) & data.Ts5 < 0.75);
Error_NEE_gs = NEE_model(ind_comp_gs) - data.NEE(ind_comp_gs);
Error_NEE_ngs = NEE_model(ind_comp_ngs) - data.NEE(ind_comp_ngs);

%%% Plot both of these relationships:
if plot_flag == 1
   figure('Name', 'NEE vs error','Tag','v4_Error_NEE') ;clf
   subplot(211)
   plot(NEE_model(ind_comp_gs), Error_NEE_gs,'g.');
   title('Growing Season');
   subplot(212)
   plot(NEE_model(ind_comp_ngs), Error_NEE_ngs,'b.');
   title('Non Growing Season');
end

% Calculate standard deviation of errors:
[NEE_std_gs]= jjb_mov_window_stats(NEE_model(ind_comp_gs), Error_NEE_gs, avg_interval, avg_window);
ind_use_NEEgs_std = find(NEE_std_gs(:,5)>min_samples);
[NEE_std_ngs]= jjb_mov_window_stats(NEE_model(ind_comp_ngs), Error_NEE_ngs, 0.2, 0.2);
ind_use_NEEngs_std = find(NEE_std_ngs(:,5)>min_samples);

% Plot NEE value vs. std dev 
if plot_flag == 1
    figure('Name', 'NEE std','Tag','v4_Std_NEE')   ; clf  
    h3(1) = plot(NEE_std_gs(ind_use_NEEgs_std,1),NEE_std_gs(ind_use_NEEgs_std,4),'g.');hold on;
    h3(2) = plot(NEE_std_ngs(ind_use_NEEngs_std,1),NEE_std_ngs(ind_use_NEEngs_std,4),'b.');hold on;
    axis([-30 10 0 8]);
    legend(h3,'GS','Non-GS');
end

%% Fit lines through these relationships:
%%% We will need two lines (either side of 0) for NEEgs, but only one (+ve
%%% NEE) for NEEngs:

ind_gs_pos = find(NEE_std_gs(:,1) >= 0 & NEE_std_gs(:,5)>min_samples);
ind_gs_neg = find(NEE_std_gs(:,1) <= 0 & NEE_std_gs(:,5)>min_samples);
ind_ngs_pos = find(NEE_std_ngs(:,1) >= 0 & NEE_std_ngs(:,5)>min_samples);

%%% Find coefficients (int + slope) for NEE gs positive, and predict for bin centres:
M_NEEgs_pos = [ones(length(ind_gs_pos),1), NEE_std_gs(ind_gs_pos,1)];
coeff_NEEgs_pos = M_NEEgs_pos\NEE_std_gs(ind_gs_pos,4); % first is intercept, second is slope
NEEgs_pos_std_pred = coeff_NEEgs_pos(1) + NEE_std_gs(ind_gs_pos,1).*coeff_NEEgs_pos(2);
%%% Find coefficients (int + slope) for NEE gs negative, and predict for bin centres:
M_NEEgs_neg = [ones(length(ind_gs_neg),1), NEE_std_gs(ind_gs_neg,1)];
coeff_NEEgs_neg = M_NEEgs_neg\NEE_std_gs(ind_gs_neg,4); % first is intercept, second is slope
NEEgs_neg_std_pred = coeff_NEEgs_neg(1) + NEE_std_gs(ind_gs_neg,1).*coeff_NEEgs_neg(2);
%%% Find coefficients (int + slope) for NEE non-gs positive, and predict for bin centres:
M_NEEngs_pos = [ones(length(ind_ngs_pos),1), NEE_std_ngs(ind_ngs_pos,1)];
coeff_NEEngs_pos = M_NEEngs_pos\NEE_std_ngs(ind_ngs_pos,4); % first is intercept, second is slope
NEEngs_pos_std_pred = coeff_NEEngs_pos(1) + NEE_std_ngs(ind_ngs_pos,1).*coeff_NEEngs_pos(2);
if plot_flag == 1

%%% Plot them on the existing graph:
    figure(findobj('Tag','v4_Std_NEE'));
    plot(NEE_std_gs(ind_gs_pos,1), NEEgs_pos_std_pred,'g-','LineWidth',2);
    plot(NEE_std_gs(ind_gs_neg,1), NEEgs_neg_std_pred,'g-','LineWidth',2);
    plot(NEE_std_ngs(ind_ngs_pos,1), NEEngs_pos_std_pred,'b-','LineWidth',2);
end
    clear ind*
    
%% Predict std for every data point:
std_pred = NaN.*ones(length(NEE_model),1);

ind_gs_pos = find(flag_gs== 1 & NEE_model >= 0);
std_pred(ind_gs_pos,1) = coeff_NEEgs_pos(1) + NEE_model(ind_gs_pos,1).*coeff_NEEgs_pos(2);

ind_gs_neg = find(flag_gs== 1 & NEE_model < 0);
std_pred(ind_gs_neg,1) = coeff_NEEgs_neg(1) + NEE_model(ind_gs_neg,1).*coeff_NEEgs_neg(2);

ind_ngs_pos = find(flag_gs== 0 & NEE_model > 0);
std_pred(ind_ngs_pos,1) = coeff_NEEngs_pos(1) + NEE_model(ind_ngs_pos,1).*coeff_NEEngs_pos(2);


if plot_flag == 1;
        figure('Name','Estimated Std','Tag','v4_std_pred');

   plot(std_pred); 
end

if ~isempty(find(isnan(std_pred)))==1
    disp(['number of nans in predicted std = ' num2str(length(find(isnan(std_pred))))]);
end
% 
% %% Put together the estimated error in GEP and RE to span all of NEE:
% GEP_std(:,1) = GEP_std(:,1).*-1;
% NEE_std = [GEP_std ; RE_std];
% [B IX] = sort(NEE_std,1,'descend');
% NEE_std = NEE_std(IX(:,1),:);
% ind_use_NEE_std = find(NEE_std(:,5)>min_samples);
% 
% if plot_flag == 1
%     figure('Name', 'NEE vs. std dev');
%     plot(NEE_std(ind_use_NEE_std,1),NEE_std(ind_use_NEE_std,4),'b.'); title('NEE vs. std dev (in NEE)'); hold on;
% end
% 
% %% Fit lines through trends on both sides of 0:
% NEE_pred = pred_RE - pred_GEP;
% % 1. RE:
% ind_RE_std = find(NEE_std(:,1) > 0 & NEE_std(:,5) > min_samples);
% M_RE = [ones(length(ind_RE_std),1), NEE_std(ind_RE_std,1)];
% coeff_RE = M_RE\NEE_std(ind_RE_std,4); % first is intercept, second is slope
% RE_std_pred = coeff_RE(1) + NEE_std(ind_RE_std,1).*coeff_RE(2);
% if plot_flag == 1
%     plot(NEE_std(ind_RE_std,1),RE_std_pred,'r--')
% end
% % 2. GEP:
% ind_GEP_std = find(NEE_std(:,1) < 0 & NEE_std(:,5) > min_samples);
% M_GEP = [ones(length(ind_GEP_std),1), NEE_std(ind_GEP_std,1)];
% coeff_GEP = M_GEP\NEE_std(ind_GEP_std,4); % first is intercept, second is slope
% GEP_std_pred = coeff_GEP(1) + NEE_std(ind_GEP_std,1).*coeff_GEP(2);
% if plot_flag == 1
%     plot(NEE_std(ind_GEP_std,1),GEP_std_pred,'r--')
% end
% 
% %% Now, predict std for every data point, depending on whether we expect positive or negative
% %%% NEE
% ind_pos_NEE = find(NEE_pred >=0);
% std_pred(ind_pos_NEE,1) = coeff_RE(1) + NEE_pred(ind_pos_NEE).*coeff_RE(2);
% 
% ind_neg_NEE = find(NEE_pred < 0);
% std_pred(ind_neg_NEE,1) = coeff_GEP(1) + NEE_pred(ind_neg_NEE).*coeff_GEP(2);
% 
% if isnan(std_pred(1,1))==1;
%     std_pred(1:8,1) = std_pred(9,1);
% end
% 
% if ~isempty(find(isnan(std_pred)))==1
%     disp(['number of nans in predicted std = ' num2str(length(find(isnan(std_pred))))]);
% end
