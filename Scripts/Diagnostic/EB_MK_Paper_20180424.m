%% Load or create data
ls = addpath_loadstart;
% save_path = [ls 'Matlab/Data/Flux/Gapfilling/' site '/'];
footprint_path = [ls 'Matlab/Data/Flux/Footprint/'];
save_path = [ls 'Matlab/Data/Diagnostic/'];
if exist([ls 'Matlab/Data/Diagnostic/EB_MK_Paper.mat'],'file')~=2
    
    %%% Load TPD Data:
    site = 'TPD';
    year_start = 2012;
    year_end = 2017;
    
    load_path = [ls 'Matlab/Data/Master_Files/' site '/'];
    load([load_path site '_gapfill_data_in.mat']);
    data = trim_data_files(data,year_start, year_end,1);
    data.site = site; close all
    data.costfun = 'WSS';
    data.min_method = 'NM';
    % orig.data = data; % save the original data:
    NEE_orig = data.NEE;
    
    %%% Load Footprint file, apply footprint filter
    load([footprint_path site '_footprint_flag.mat'])
    tmp_fp_flag = footprint_flag.Kljun70;
    % Flag file for Kljun 75% footprint:
    fp_flag(:,1) = tmp_fp_flag(tmp_fp_flag(:,1) >= data.year_start & tmp_fp_flag(:,1) <= data.year_end,2);
    % Flag file for No footprint:
    fp_flag(:,2) = ones(length(fp_flag(:,1)),1); % The
    data.NEE = NEE_orig.*fp_flag(:,1);
    
    %%% Calculate and apply Ustar threshold
    Ustar_th_Reich = mcm_Ustar_th_Reich(data,0);
    Ustar_th_JJB = mcm_Ustar_th_JJB(data,0);
    data.Ustar_th = Ustar_th_Reich(:,1);
    
    %%% Estimate random error:
    [data.NEE_std, f_fit, f_std] = NEE_random_error_estimator_v6(data,[],[],0);
    
    TPD.data = data;
    clear data;    
    
    
    %% Load & calc TP39 data
    clear fp_flag;
    site = 'TP39';
    year_start = 2012;
    year_end = 2017;
    
    ls = addpath_loadstart;
    load_path = [ls 'Matlab/Data/Master_Files/' site '/'];
    % save_path = [ls 'Matlab/Data/Flux/Gapfilling/' site '/'];
    footprint_path = [ls 'Matlab/Data/Flux/Footprint/'];
    
    load([load_path site '_gapfill_data_in.mat']);
    data = trim_data_files(data,year_start, year_end,1);
    data.site = site; close all
    data.costfun = 'WSS';
    data.min_method = 'NM';
    % orig.data = data; % save the original data:
    NEE_orig = data.NEE;
    
    %%% Load Footprint file, apply footprint filter
    load([footprint_path site '_footprint_flag.mat'])
    tmp_fp_flag = footprint_flag.Kljun70;
    % Flag file for Kljun 75% footprint:
    fp_flag(:,1) = tmp_fp_flag(tmp_fp_flag(:,1) >= data.year_start & tmp_fp_flag(:,1) <= data.year_end,2);
    % Flag file for No footprint:
    fp_flag(:,2) = ones(length(fp_flag(:,1)),1); % The
    data.NEE = NEE_orig.*fp_flag(:,1);
    
    %%% Calculate and apply Ustar threshold
    Ustar_th_Reich = mcm_Ustar_th_Reich(data,0);
    Ustar_th_JJB = mcm_Ustar_th_JJB(data,0);
    data.Ustar_th = Ustar_th_Reich(:,1);
    
    %%% Estimate random error:
    [data.NEE_std, f_fit, f_std] = NEE_random_error_estimator_v6(data,[],[],0);
    
    TP39.data = data;
    clear data;
     
    
    save([save_path 'EB_MK_Paper.mat']);
    
else
    load([save_path 'EB_MK_Paper.mat']);
end

% TPD.data = TPD.data(TPD.data
%% RE
clear data;
sites = {'TP39';'TPD'};
begin_year_main = 2012;
end_year_main = 2017;

for i = 1:1:length(sites)
    close all; clear options;
    site = sites{i,1};
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year);
    
    %%%%%%%%%%%% RE %%%%%%%%%%%%%%%%%
    ind_param(1).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std));
    
    %%% Q10 Model
    %%%%%% Ts parameterization only:
    clear global;
    options.costfun=data.costfun; options.min_method = data.min_method;
    [c_hat(1).RE1all, y_hat(1).RE1all, y_pred(1).RE1all, stats(1).RE1all, sigma(1).RE1all, err(1).RE1all, exitflag(1).RE1all, num_iter(1).RE1all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(1).RE_all) data.SM_a_filled(ind_param(1).RE_all)] , data.NEE(ind_param(1).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(1).RE_all), options);
    
    %%%%%% Ts + SM parameterization:
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method; options.f_coeff = [NaN NaN];
    [c_hat(1).RE1all_Tsonly, y_hat(1).RE1all_Tsonly, y_pred(1).RE1all_Tsonly, stats(1).RE1all_Tsonly, sigma(1).RE1all_Tsonly, err(1).RE1all_Tsonly, exitflag(1).RE1all_Tsonly, num_iter(1).RE1all_Tsonly] = ...
        fitresp([2 3], 'fitresp_3A', [data.Ts5(ind_param(1).RE_all)] , data.NEE(ind_param(1).RE_all), [data.Ts5], data.NEE_std(ind_param(1).RE_all), options);
    
    %%% Logistic Model
    %%%%%% Ts parameterization only:
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    [c_hat(1).RE2all_Tsonly, y_hat(1).RE2all_Tsonly, y_pred(1).RE2all_Tsonly, stats(1).RE2all_Tsonly, sigma(1).RE2all_Tsonly, err(1).RE2all_Tsonly, exitflag(1).RE2all_Tsonly, num_iter(1).RE2all_Tsonly] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(1).RE_all), data.NEE(ind_param(1).RE_all), data.Ts5, data.NEE_std(ind_param(1).RE_all), options);
    
    %%%%%% Ts + SM parameterization:
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    [c_hat(1).RE2all, y_hat(1).RE2all, y_pred(1).RE2all, stats(1).RE2all, sigma(1).RE2all, err(1).RE2all, exitflag(1).RE2all, num_iter(1).RE2all] = ...
        fitresp([8,0.2,12,8,180], 'fitresp_2B', [data.Ts5(ind_param(1).RE_all) data.SM_a_filled(ind_param(1).RE_all)], data.NEE(ind_param(1).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(1).RE_all), options);
    
    %%%%%% Calculate and plot residuals
    resids.RE2all_Tsonly = data.NEE(ind_param(1).RE_all) - y_pred(1).RE2all_Tsonly(ind_param(1).RE_all);
    resids.RE2all = data.NEE(ind_param(1).RE_all) - y_pred(1).RE2all(ind_param(1).RE_all);
    
    resids.RE1all_Tsonly = data.NEE(ind_param(1).RE_all) - y_pred(1).RE1all_Tsonly(ind_param(1).RE_all);
    resids.RE1all = data.NEE(ind_param(1).RE_all) - y_pred(1).RE1all(ind_param(1).RE_all);
    
    %  [mov_avg_RE1] = jjb_mov_avg(data_in,winsize, st_option,lag_option)
    [mov_avg_RE1_fixSM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).RE_all),resids.RE1all_Tsonly, 0.005, 0.01);
    [mov_avg_RE2_fixSM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).RE_all),resids.RE2all_Tsonly, 0.005, 0.01);
    [mov_avg_RE1] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).RE_all),resids.RE1all, 0.005, 0.01);
    [mov_avg_RE2] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).RE_all),resids.RE2all, 0.005, 0.01);
    
    f1 = figure(1);clf;
    subplot(2,1,1)
    plot(data.SM_a_filled(ind_param(1).RE_all),resids.RE1all,'c.');hold on;
    plot(data.SM_a_filled(ind_param(1).RE_all),resids.RE1all_Tsonly,'.','Color',[0.7,0.7,0.7]);hold on;
    h1(1)= plot(mov_avg_RE1(:,1),mov_avg_RE1(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h1(2)= plot(mov_avg_RE1_fixSM(:,1),mov_avg_RE1_fixSM(:,2),'k.-','LineWidth',2);
    axis([0.045 0.1 -2 1]);
    ylabel('RE_{meas} - RE_{pred}');
    xlabel('VWC');
    legend(h1,'Q10 - all','Q10 - no SM')
    
    subplot(2,1,2)
    plot(data.SM_a_filled(ind_param(1).RE_all),resids.RE2all,'c.');hold on;
    plot(data.SM_a_filled(ind_param(1).RE_all),resids.RE2all_Tsonly,'.','Color',[0.7,0.7,0.7]);hold on;
    h1(1)= plot(mov_avg_RE2(:,1),mov_avg_RE2(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h1(2)= plot(mov_avg_RE2_fixSM(:,1),mov_avg_RE2_fixSM(:,2),'k.-','LineWidth',2);
    axis([0.045 0.1 -2 1]);
    ylabel('RE_{meas} - RE_{pred}');
    xlabel('VWC');
    legend(h1,'Logi - all','Logi - no SM')
    
    print(f1, [save_path site '_REmodel_resids_' num2str(begin_year) '-' num2str(end_year) '.png'],'-dpng','-r300');
    
    %%%%%%%%%%%%%%% Plot scaling relationships
    figure(2);clf;
    %%% SM relationship - Q10
    [x_out, y_out] = plot_SMlogi(c_hat.RE1all(3:4), 0);
    subplot(2,1,1);
    plot(x_out,y_out,'b-','LineWidth',2);
    ylabel('scaling factor');
    xlabel('VWC');
    title('Q10 model')
    grid on;
    axis([0.04 0.075 0 1]);
    
    %%% SM relationship - Logi
    [x_out, y_out] = plot_SMlogi(c_hat.RE2all(4:5), 0);
    subplot(2,1,2);
    plot(x_out,y_out,'b-','LineWidth',2);
    ylabel('scaling factor');
    xlabel('VWC');
    title('Logi model')
    grid on;
    axis([0.04 0.075 0 1]);
    
    print([save_path site '_REmodel_scalingfactors_' num2str(begin_year) '-' num2str(end_year) '.png'],'-dpng','-r300');
    
    %%%%%%%%%%%%%%%%%%%%%% GEP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    RE_model = y_pred(1).RE2all_Tsonly;
    
    GEPraw = RE_model - data.NEE;
    %%% Set GEP to zero when PAR < 15:
    % GEPraw(data.PAR < 15) = NaN;
    %%% Updated May 19, 2011 by JJB:
    GEPraw(data.PAR < 15 | (data.PAR <= 150 & data.Ustar < data.Ustar_th) ) = NaN;
    
    GEP_model = zeros(length(GEPraw),1);
    GEP_pred = NaN.*ones(length(GEPraw),1);
    GEP_pred_fixed = NaN.*ones(length(GEPraw),1);
    GEP_pred_fixed_noSM = NaN.*ones(length(GEPraw),1);
    
    %%% Index for all hhours available for parameterization of an all-years
    %%% relationship:
    % ind_param(1).GEPallold = find(data.Ts2 > 0.5 & data.Ta > 2 & data.PAR > 15 & ~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled) & data.VPD > 0 & data.Ustar > data.Ustar_th);
    ind_param(1).GEPall = find(~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled.*data.Ts5.*data.PAR) & data.GEP_flag==2 & data.VPD > 0);
    
    clear options global;
    %%% Set inputs for all-years parameterization
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(1,8);
    X_in = [data.PAR(ind_param(1).GEPall) data.Ts5(ind_param(1).GEPall) data.VPD(ind_param(1).GEPall) data.SM_a_filled(ind_param(1).GEPall)];
    X_eval = [data.PAR data.Ts5 data.VPD data.SM_a_filled];
    %%% All-years parameterization, All variables fitted:
    [c_hat(1).GEPall, y_hat(1).GEPall, y_pred(1).GEPall, stats(1).GEPall, sigma(1).GEPall, err(1).GEPall, exitflag(1).GEPall, num_iter(1).GEPall] = ...
        fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix Ts5 relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(3:4) = [-10000 100];
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixTs, y_hat(1).GEP_fixTs, y_pred(1).GEP_fixTs, stats(1).GEP_fixTs, sigma(1).GEP_fixTs, err(1).GEP_fixTs, exitflag(1).GEP_fixTs, num_iter(1).GEP_fixTs] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix VPD relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(5:6) = [-10000 100];
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixVPD, y_hat(1).GEP_fixVPD, y_pred(1).GEP_fixVPD, stats(1).GEP_fixVPD, sigma(1).GEP_fixVPD, err(1).GEP_fixVPD, exitflag(1).GEP_fixVPD, num_iter(1).GEP_fixVPD] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix SM relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(7:8) = [-10000 100];
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixSM, y_hat(1).GEP_fixSM, y_pred(1).GEP_fixSM, stats(1).GEP_fixSM, sigma(1).GEP_fixSM, err(1).GEP_fixSM, exitflag(1).GEP_fixSM, num_iter(1).GEP_fixSM] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix Ts5+VPD relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(3:6) = [-10000 100 -10000 100];
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixTsVPD, y_hat(1).GEP_fixTsVPD, y_pred(1).GEP_fixTsVPD, stats(1).GEP_fixTsVPD, sigma(1).GEP_fixTsVPD, err(1).GEP_fixTsVPD, exitflag(1).GEP_fixTsVPD, num_iter(1).GEP_fixTsVPD] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix Ts5+SM relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(3:4) = [-10000 100];
    options.f_coeff(7:8) = [-10000 100];
    
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixTsSM, y_hat(1).GEP_fixTsSM, y_pred(1).GEP_fixTsSM, stats(1).GEP_fixTsSM, sigma(1).GEP_fixTsSM, err(1).GEP_fixTsSM, exitflag(1).GEP_fixTsSM, num_iter(1).GEP_fixTsSM] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix SM+VPD relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(5:6) = [-10000 100];
    options.f_coeff(7:8) = [-10000 100];
    
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixVPDSM, y_hat(1).GEP_fixVPDSM, y_pred(1).GEP_fixVPDSM, stats(1).GEP_fixVPDSM, sigma(1).GEP_fixVPDSM, err(1).GEP_fixVPDSM, exitflag(1).GEP_fixVPDSM, num_iter(1).GEP_fixVPDSM] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    %%% All-years parameterization, fix all but PAR relationship:
    clear global;
    options.f_coeff = NaN.*ones(size(c_hat(1).GEPall));
    options.f_coeff(3:4) = [-10000 100];
    options.f_coeff(5:6) = [-10000 100];
    options.f_coeff(7:8) = [-10000 100];
    
    % [x_out, y_out] = plot_SMlogi([-10000 100], 1);
    [c_hat(1).GEP_fixall, y_hat(1).GEP_fixall, y_pred(1).GEP_fixall, stats(1).GEP_fixall, sigma(1).GEP_fixall, err(1).GEP_fixall, exitflag(1).GEP_fixall, num_iter(1).GEP_fixall] = ...
        fitGEP(c_hat(1).GEPall, 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEPall),  X_eval, data.NEE_std(ind_param(1).GEPall), options);
    
    
    
    %%% Compile a table of R2 stats and contributions:
    
    model_names = {'RE-all (Ts+SM)';'RE-noSM';'GEP-all (PAR+Ts+VPD+SM)';'GEP-noTs';'GEP-noVPD';'GEP-noSM'};
    rsqs = [stats.RE2all.R2; stats.RE2all_Tsonly.R2; stats.GEPall.R2; stats.GEP_fixTs.R2; stats.GEP_fixVPD.R2; stats.GEP_fixSM.R2];
    T_rsq = table(model_names,rsqs,'VariableNames',{'model';'R2'});
    writetable(T_rsq,[save_path site '_R2_values_' num2str(begin_year) '-' num2str(end_year) '.txt']);
    
    component_names = {'RE-Ts';'RE-SM';'GEP-PAR';'GEP-Ts';'GEP-VPD';'GEP-SM'};
    rsq_contrib = [stats.RE2all_Tsonly.R2; ...
        stats.RE2all.R2 - stats.RE2all_Tsonly.R2; ...
        stats.GEP_fixall.R2; ...
        stats.GEPall.R2 - stats.GEP_fixTs.R2; ...
        stats.GEPall.R2 - stats.GEP_fixVPD.R2; ...
        stats.GEPall.R2 - stats.GEP_fixSM.R2; ];
    T_contribs = table(component_names,rsq_contrib,'VariableNames',{'variable';'R2'});
    writetable(T_contribs,[save_path site '_R2_contributions_' num2str(begin_year) '-' num2str(end_year) '.txt']);
    
    %%%% PLOTS
    figure(4);clf;
    plot(y_pred(1).GEPall,'b-','LineWidth',2);hold on;
    plot(y_pred(1).GEP_fixTs,'r-');
    plot(y_pred(1).GEP_fixVPD,'y-');
    plot(y_pred(1).GEP_fixSM,'c-');
    plot(y_pred(1).GEP_fixTsVPD,'m-');
    plot(y_pred(1).GEP_fixTsSM,'k-');
    plot(y_pred(1).GEP_fixVPDSM,'g-');
    print([save_path site '_GEPmodel_results_' num2str(begin_year) '-' num2str(end_year) '.png'],'-dpng','-r300');
    
    
    %%%% Residuals
    resids.GEPall = GEPraw(ind_param(1).GEPall) - y_pred(1).GEPall(ind_param(1).GEPall);
    resids.GEP_fixTs = GEPraw(ind_param(1).GEPall) - y_pred(1).GEP_fixTs(ind_param(1).GEPall);
    resids.GEP_fixVPD = GEPraw(ind_param(1).GEPall) - y_pred(1).GEP_fixVPD(ind_param(1).GEPall);
    resids.GEP_fixSM = GEPraw(ind_param(1).GEPall) - y_pred(1).GEP_fixSM(ind_param(1).GEPall);
    
    %  [mov_avg_RE1] = jjb_mov_avg(data_in,winsize, st_option,lag_option)
    [mov_avg_GEPall_Ts] = jjb_mov_window_stats(data.Ts5(ind_param(1).GEPall),resids.GEPall, 0.01, 0.01);
    [mov_avg_GEP_fixTs] = jjb_mov_window_stats(data.Ts5(ind_param(1).GEPall),resids.GEP_fixTs, 0.01, 0.01);
    
    [mov_avg_GEPall_VPD] = jjb_mov_window_stats(data.VPD(ind_param(1).GEPall),resids.GEPall, 0.01, 0.01);
    [mov_avg_GEP_fixVPD] = jjb_mov_window_stats(data.VPD(ind_param(1).GEPall),resids.GEP_fixVPD, 0.01, 0.01);
    [mov_avg_GEP_fixVPD_bySM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).GEPall),resids.GEP_fixVPD, 0.005, 0.01);
    
    
    [mov_avg_GEPall_SM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).GEPall),resids.GEPall, 0.005, 0.01);
    [mov_avg_GEP_fixSM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).GEPall),resids.GEP_fixSM, 0.005, 0.01);
    
    
    
    figure(5);clf
    %%% Ts
    subplot(2,2,1)
    plot(data.Ts5(ind_param(1).GEPall),resids.GEPall,'c.');hold on;
    plot(data.Ts5(ind_param(1).GEPall),resids.GEP_fixTs,'.','Color',[0.7,0.7,0.7]);hold on;
    h1(1)= plot(mov_avg_GEPall_Ts(:,1),mov_avg_GEPall_Ts(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h1(2)= plot(mov_avg_GEP_fixTs(:,1),mov_avg_GEP_fixTs(:,2),'k.-','LineWidth',2);
    axis([4 24 -20 20]);
    ylabel('GEP_{meas} - GEP_{pred}');
    xlabel('Ts5');
    legend(h1,'GEP-all','GEP-noTs')
    
    %%% VPD
    subplot(2,2,2)
    plot(data.VPD(ind_param(1).GEPall),resids.GEPall,'c.');hold on;
    plot(data.VPD(ind_param(1).GEPall),resids.GEP_fixVPD,'.','Color',[0.7,0.7,0.7]);hold on;
    h2(1)= plot(mov_avg_GEPall_VPD(:,1),mov_avg_GEPall_VPD(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h2(2)= plot(mov_avg_GEP_fixVPD(:,1),mov_avg_GEP_fixVPD(:,2),'k.-','LineWidth',2);
    axis([-1 36 -20 20]);
    ylabel('GEP_{meas} - GEP_{pred}');
    xlabel('VPD (hPa)');
    legend(h2,'GEP-all','GEP-noVPD')
    
    %%% SM
    subplot(2,2,3)
    plot(data.SM_a_filled(ind_param(1).GEPall),resids.GEPall,'c.');hold on;
    plot(data.SM_a_filled(ind_param(1).GEPall),resids.GEP_fixSM,'.','Color',[0.7,0.7,0.7]);hold on;
    h3(1)= plot(mov_avg_GEPall_SM(:,1),mov_avg_GEPall_SM(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h3(2)= plot(mov_avg_GEP_fixSM(:,1),mov_avg_GEP_fixSM(:,2),'k.-','LineWidth',2);
    axis([0.03 0.2 -1 1]);
    ylabel('GEP_{meas} - GEP_{pred}');
    xlabel('SM');
    legend(h3,'GEP-all','GEP-noSM')
    
    %%% VPD by SM
    subplot(2,2,4)
    plot(data.SM_a_filled(ind_param(1).GEPall),resids.GEPall,'c.');hold on;
    plot(data.SM_a_filled(ind_param(1).GEPall),resids.GEP_fixVPD,'.','Color',[0.7,0.7,0.7]);hold on;
    h4(1)= plot(mov_avg_GEPall_SM(:,1),mov_avg_GEPall_SM(:,2),'.-','Color',[0 0 1],'LineWidth',2);
    h4(2)= plot(mov_avg_GEP_fixVPD_bySM(:,1),mov_avg_GEP_fixVPD_bySM(:,2),'k.-','LineWidth',2);
    axis([0.03 0.2 -1 1]);
    ylabel('GEP_{meas} - GEP_{pred}');
    xlabel('SM');
    legend(h4,'GEP-all','GEP-noVPD')
    
    print([save_path site '_GEPmodel_resids_' num2str(begin_year) '-' num2str(end_year) '.png'],'-dpng','-r300');
    
    %%%%%%%%%%%%%%% Plot scaling relationships
    figure(6);clf;
    %%% TS relationship
    [x_out, y_out] = plot_SMlogi(c_hat.GEPall(3:4), 0);
    subplot(2,2,1);
    plot(x_out,y_out,'b-','LineWidth',2);
    ylabel('scaling factor');
    xlabel('Ts');
    grid on;
    axis([-2 25 0 1]);
    
    %%% VPD relationship
    [x_out, y_out] = plot_SMlogi(c_hat.GEPall(5:6), 0);
    subplot(2,2,2);
    plot(x_out,y_out,'b-','LineWidth',2);
    ylabel('scaling factor');
    xlabel('VPD');
    grid on;
    axis([0 40 0 1]);
    
    %%% SM relationship
    [x_out, y_out] = plot_SMlogi(c_hat.GEPall(7:8), 0);
    subplot(2,2,3);
    plot(x_out,y_out,'b-','LineWidth',2);
    ylabel('scaling factor');
    xlabel('SM');
    grid on;
    axis([0.04 0.075 0 1]);
    
    print([save_path site '_GEPmodel_scalingfactors_' num2str(begin_year) '-' num2str(end_year) '.png'],'-dpng','-r300');
end


%% RE and GEP parameterization by season
clear data;
sites = {'TPD'};
begin_year_main = 2012;
end_year_main = 2018;
    close all; clear options;
    site = sites{1,1};
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year);

tmp_Ts = data.Ts5;

% year | SOS | EOG | BOB | EOS 
% NOTE: using mean values for 2018
gs_dates = ...
    [2012 2013 2014 2015 2016 2017 2018; ... 
    120 116 127 118 126 125 122; ...
    145	155	160	146	154	159 153; ...
    257	249	255	249	262	261 256; ...
    306	314	307	309	328	318 314]';


gs_flag = NaN.*ones(size(data.GEP_flag,1),1);
gs_sf = NaN.*ones(size(data.GEP_flag,1),1);
ctr = 1;
for yr = 2012:1:2018
%    data.Year==yr & (data.dt <= gs_dates(i,2) | data.dt >= gs_dates(i,5))
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 1; % off-season
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,3) & data.dt > gs_dates(ctr,2)),1) = 2; % spring shoulder
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 3;% peak uptake
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,5) & data.dt > gs_dates(ctr,4)),1) = 4;% fall shoulder

    % scaling factors
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 0; 
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 1;% peak uptake
    tmp = gs_sf(data.Year==yr);
    ind_bos = find(isnan(tmp),1,'first');
    ind_eog = find(tmp==1,1,'first')-1;
    
    ind_bob = find(tmp==1,1,'last')+1;
    ind_eos = find(isnan(tmp),1,'last');
    
    greenup = linspace(0,1,ind_eog-ind_bos+3)';
    browndown = linspace(1,0,ind_eos+3 - ind_bob)';
    tmp(ind_bos-1:ind_eog+1,1) = greenup;
    tmp(ind_bob-1:ind_eos+1) = browndown;
    gs_sf(data.Year==yr) = tmp;
    clear tmp greenup browndown
    ctr = ctr + 1;
end

%%%% RE

    
%%%%%%%%%%%% RE %%%%%%%%%%%%%%%%%
    RE_pred = NaN.*ones(size(data.GEP_flag,1),1);
    % off-season
    ind_param(1).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag==1);
    % green-up shoulder
    ind_param(2).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag==2);
    % main uptake
    ind_param(3).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag==3);
    % green-up shoulder
    ind_param(4).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag==4);
    ind_param(9).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std));
    
    %%% Q10 Model
    %%%%%% Ts + SM parameterization - off-season:
    clear global;
    options.costfun=data.costfun; options.min_method = data.min_method;
    [c_hat(1).RE_all, y_hat(1).RE_all, y_pred(1).RE_all, stats(1).RE_all, sigma(1).RE_all, err(1).RE_all, exitflag(1).RE_all, num_iter(1).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(1).RE_all) data.SM_a_filled(ind_param(1).RE_all)] , data.NEE(ind_param(1).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(1).RE_all), options);
    %%% Spring shoulder
        [c_hat(2).RE_all, y_hat(2).RE_all, y_pred(2).RE_all, stats(2).RE_all, sigma(2).RE_all, err(2).RE_all, exitflag(2).RE_all, num_iter(2).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(2).RE_all) data.SM_a_filled(ind_param(2).RE_all)] , data.NEE(ind_param(2).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(2).RE_all), options);
    %%% Main uptake period
        [c_hat(3).RE_all, y_hat(3).RE_all, y_pred(3).RE_all, stats(3).RE_all, sigma(3).RE_all, err(3).RE_all, exitflag(3).RE_all, num_iter(3).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(3).RE_all) data.SM_a_filled(ind_param(3).RE_all)] , data.NEE(ind_param(3).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(3).RE_all), options);
    %%% Fall shoulder
        [c_hat(4).RE_all, y_hat(4).RE_all, y_pred(4).RE_all, stats(4).RE_all, sigma(4).RE_all, err(4).RE_all, exitflag(4).RE_all, num_iter(4).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(4).RE_all) data.SM_a_filled(ind_param(4).RE_all)] , data.NEE(ind_param(4).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(4).RE_all), options);
    %%% All data
        [c_hat(9).RE_all, y_hat(9).RE_all, y_pred(9).RE_all, stats(9).RE_all, sigma(9).RE_all, err(9).RE_all, exitflag(9).RE_all, num_iter(9).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts5(ind_param(9).RE_all) data.SM_a_filled(ind_param(9).RE_all)] , data.NEE(ind_param(9).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(9).RE_all), options);
    %%% All data / using Ta instead of Ts
        [c_hat(8).RE_all, y_hat(8).RE_all, y_pred(8).RE_all, stats(8).RE_all, sigma(8).RE_all, err(8).RE_all, exitflag(8).RE_all, num_iter(8).RE_all] = ...
        fitresp([2 3 8 180], 'fitresp_3B', [data.Ts2(ind_param(9).RE_all) data.SM_a_filled(ind_param(9).RE_all)] , data.NEE(ind_param(9).RE_all), [data.Ts2 data.SM_a_filled], data.NEE_std(ind_param(9).RE_all), options);
    
%%%%%%%%%%%% Logistic
        [c_hat(1).RE_all_logi, y_hat(1).RE_all_logi, y_pred(1).RE_all_logi, stats(1).RE_all_logi, sigma(1).RE_all_logi, err(1).RE_all_logi, exitflag(1).RE_all_logi, num_iter(1).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(1).RE_all) data.SM_a_filled(ind_param(1).RE_all)] , data.NEE(ind_param(1).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(1).RE_all), options);
    %%% Spring shoulder
        [c_hat(2).RE_all_logi, y_hat(2).RE_all_logi, y_pred(2).RE_all_logi, stats(2).RE_all_logi, sigma(2).RE_all_logi, err(2).RE_all_logi, exitflag(2).RE_all_logi, num_iter(2).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(2).RE_all) data.SM_a_filled(ind_param(2).RE_all)] , data.NEE(ind_param(2).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(2).RE_all), options);
    %%% Main uptake period
        [c_hat(3).RE_all_logi, y_hat(3).RE_all_logi, y_pred(3).RE_all_logi, stats(3).RE_all_logi, sigma(3).RE_all_logi, err(3).RE_all_logi, exitflag(3).RE_all_logi, num_iter(3).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(3).RE_all) data.SM_a_filled(ind_param(3).RE_all)] , data.NEE(ind_param(3).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(3).RE_all), options);
    %%% Fall shoulder
        [c_hat(4).RE_all_logi, y_hat(4).RE_all_logi, y_pred(4).RE_all_logi, stats(4).RE_all_logi, sigma(4).RE_all_logi, err(4).RE_all_logi, exitflag(4).RE_all_logi, num_iter(4).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(4).RE_all) data.SM_a_filled(ind_param(4).RE_all)] , data.NEE(ind_param(4).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(4).RE_all), options);
    %%% All data
        [c_hat(9).RE_all_logi, y_hat(9).RE_all_logi, y_pred(9).RE_all_logi, stats(9).RE_all_logi, sigma(9).RE_all_logi, err(9).RE_all_logi, exitflag(9).RE_all_logi, num_iter(9).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(9).RE_all) data.SM_a_filled(ind_param(9).RE_all)] , data.NEE(ind_param(9).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(9).RE_all), options);

    
    
    
    f2 = figure(2);clf;
    %%% SM relationship - Q10
%     [x_out, y_out] = plot_SMlogi(c_hat(1).RE_all(3:4), 0);    h2(1) = plot(x_out,y_out,'b-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(2).RE_all(3:4), 0);    h2(2) = plot(x_out,y_out,'r-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(3).RE_all(3:4), 0);    h2(3) = plot(x_out,y_out,'y-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(4).RE_all(3:4), 0);    h2(4) = plot(x_out,y_out,'g-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(9).RE_all(3:4), 0);    h2(5) = plot(x_out,y_out,'k-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(8).RE_all(3:4), 0);    h2(6) = plot(x_out,y_out,'k--','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(1).RE_all_logi(4:5), 0);    h2(1) = plot(x_out,y_out,'b-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(2).RE_all_logi(4:5), 0);    h2(2) = plot(x_out,y_out,'r-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(3).RE_all_logi(4:5), 0);    h2(3) = plot(x_out,y_out,'y-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(4).RE_all_logi(4:5), 0);    h2(4) = plot(x_out,y_out,'g-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(9).RE_all_logi(4:5), 0);    h2(5) = plot(x_out,y_out,'k-','LineWidth',2); hold on;
%     [x_out, y_out] = plot_SMlogi(c_hat(8).RE_all_logi(4:5), 0);    h2(6) = plot(x_out,y_out,'k--','LineWidth',2); hold on;    
    ylabel('scaling factor');    xlabel('VWC');    title('Q10 model')
    grid on;    axis([0.04 0.2 0 1]);
    legend(h2,{'off-season';'spr shoulder';'main uptake';'fall shoulder';'all'});
    print([save_path site 'TPD-RE-VWC-logi.png'],'-dpng','-r300');

    RE_pred(gs_flag==1) = y_pred(1).RE_all(gs_flag==1);
    RE_pred(gs_flag==2) = y_pred(2).RE_all(gs_flag==2);
    RE_pred(gs_flag==3) = y_pred(3).RE_all(gs_flag==3);
    RE_pred(gs_flag==4) = y_pred(4).RE_all(gs_flag==4);

    
%%%%%%%%%%%% GEP %%%%%%%%%%%%%%%%%
%%% temporary - replace Ts with Ta 
% tmp_Ts = data.Ts5;
data.Ts5 = data.Ta;

    GEPraw = RE_pred - data.NEE;
    
    ind_param(9).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled.*data.Ts5.*data.PAR) & data.PAR > 15 & gs_flag>1); % All data
    ind_param(2).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled.*data.Ts5.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==2);
    ind_param(3).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled.*data.Ts5.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==3);
    ind_param(4).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.SM_a_filled.*data.Ts5.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==4);

    %%% Set GEP to zero when PAR < 15:
    % GEPraw(data.PAR < 15) = NaN;
    %%% Updated May 19, 2011 by JJB:
%     GEPraw(data.PAR < 15 | (data.PAR <= 150 & data.Ustar < data.Ustar_th) ) = NaN;

    clear options global;
    %%% Set inputs for all-years parameterization
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(1,4);
    
%%%%%%% All-years parameterization
%     X_eval_all = [data.PAR data.Ts5 data.VPD data.SM_a_filled gs_sf];    
%     X_in_all = [data.PAR(ind_param(9).GEP_all) data.Ts5(ind_param(9).GEP_all) data.VPD(ind_param(9).GEP_all) data.SM_a_filled(ind_param(9).GEP_all) gs_sf(ind_param(9).GEP_all)];
%         [c_hat(8).GEP_all, y_hat(8).GEP_all, y_pred(8).GEP_all, stats(8).GEP_all, sigma(8).GEP_all, err(8).GEP_all, exitflag(8).GEP_all, num_iter(8).GEP_all] = ...
%         fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6_pheno', X_in_all,GEPraw(ind_param(9).GEP_all),  X_eval_all, data.NEE_std(ind_param(9).GEP_all), options);
    
    X_eval_all = [data.PAR data.Ts5 gs_sf];    
    X_in_all = [data.PAR(ind_param(9).GEP_all) data.Ts5(ind_param(9).GEP_all) gs_sf(ind_param(9).GEP_all)];
        [c_hat(9).GEP_all, y_hat(9).GEP_all, y_pred(9).GEP_all, stats(9).GEP_all, sigma(9).GEP_all, err(9).GEP_all, exitflag(9).GEP_all, num_iter(9).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in_all,GEPraw(ind_param(9).GEP_all),  X_eval_all, data.NEE_std(ind_param(9).GEP_all), options);
    
    
    
%     X_eval = [data.PAR data.Ts5 data.VPD data.SM_a_filled];
    X_eval = [data.PAR data.Ts5 gs_sf];    
    
    %%% Spring shoulder
%         X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%    X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%         [c_hat(2).GEP_all, y_hat(2).GEP_all, y_pred(2).GEP_all, stats(2).GEP_all, sigma(2).GEP_all, err(2).GEP_all, exitflag(2).GEP_all, num_iter(2).GEP_all] = ...
%         fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_2L6', X_in,GEPraw(ind_param(2).GEP_all),  X_eval, data.NEE_std(ind_param(2).GEP_all), options);
   X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) gs_sf(ind_param(2).GEP_all)];
        [c_hat(2).GEP_all, y_hat(2).GEP_all, y_pred(2).GEP_all, stats(2).GEP_all, sigma(2).GEP_all, err(2).GEP_all, exitflag(2).GEP_all, num_iter(2).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in,GEPraw(ind_param(2).GEP_all),  X_eval, data.NEE_std(ind_param(2).GEP_all), options);
    
    %%% Main Uptake
        X_in = [data.PAR(ind_param(3).GEP_all) data.Ts5(ind_param(3).GEP_all) gs_sf(ind_param(3).GEP_all)];
    [c_hat(3).GEP_all, y_hat(3).GEP_all, y_pred(3).GEP_all, stats(3).GEP_all, sigma(3).GEP_all, err(3).GEP_all, exitflag(3).GEP_all, num_iter(3).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in,GEPraw(ind_param(3).GEP_all),  X_eval, data.NEE_std(ind_param(3).GEP_all), options);
  
     %%% Fall Shoulder
        X_in = [data.PAR(ind_param(4).GEP_all) data.Ts5(ind_param(4).GEP_all) gs_sf(ind_param(4).GEP_all)];
    [c_hat(4).GEP_all, y_hat(4).GEP_all, y_pred(4).GEP_all, stats(4).GEP_all, sigma(4).GEP_all, err(4).GEP_all, exitflag(4).GEP_all, num_iter(4).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in,GEPraw(ind_param(4).GEP_all),  X_eval, data.NEE_std(ind_param(4).GEP_all), options);   
    
    %%% Ts functional plots
    f3 = figure(3);clf;
    %%% Ts relationship GEP
    [x_out, y_out] = plot_SMlogi(c_hat(2).GEP_all(3:4), 0);    h3(1) = plot(x_out,y_out,'r-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(3).GEP_all(3:4), 0);    h3(2) = plot(x_out,y_out,'y-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(4).GEP_all(3:4), 0);    h3(3) = plot(x_out,y_out,'g-','LineWidth',2); hold on;
    [x_out, y_out] = plot_SMlogi(c_hat(9).GEP_all(3:4), 0);    h3(4) = plot(x_out,y_out,'k-','LineWidth',2); hold on;
    
    ylabel('scaling factor');    xlabel('Ta');    title('GEP Ta relationship')
    grid on;    axis([-5 30 0 1]);
    legend(h3,{'spr shoulder';'main uptake';'fall shoulder';'all'},'location','NorthWest');
    print([save_path site 'TPD-GEP-Ta.png'],'-dpng','-r300');

    f4 = figure(4);clf;
    x_out = [0:100:2200]'; 
    y_out = (c_hat(2).GEP_all(1)*c_hat(2).GEP_all(2)*x_out(:,1))./(c_hat(2).GEP_all(1)*x_out(:,1) + c_hat(2).GEP_all(2)); h4(1) = plot(x_out,y_out,'r-','LineWidth',2); hold on;
    y_out = (c_hat(3).GEP_all(1)*c_hat(3).GEP_all(2)*x_out(:,1))./(c_hat(3).GEP_all(1)*x_out(:,1) + c_hat(3).GEP_all(2)); h4(2) = plot(x_out,y_out,'y-','LineWidth',2); hold on;
    y_out = (c_hat(4).GEP_all(1)*c_hat(4).GEP_all(2)*x_out(:,1))./(c_hat(4).GEP_all(1)*x_out(:,1) + c_hat(4).GEP_all(2)); h4(3) = plot(x_out,y_out,'g-','LineWidth',2); hold on;
    y_out = (c_hat(9).GEP_all(1)*c_hat(9).GEP_all(2)*x_out(:,1))./(c_hat(9).GEP_all(1)*x_out(:,1) + c_hat(9).GEP_all(2)); h4(4) = plot(x_out,y_out,'k-','LineWidth',2); hold on;
    ylabel('GEP');    xlabel('PAR');    title('GEP PARrelationship')
    grid on;    axis([0 2200 0 30]);
    legend(h4,{'spr shoulder';'main uptake';'fall shoulder';'all'},'location','NorthWest');
    print([save_path site 'TPD-GEP-PAR.png'],'-dpng','-r300');

data.Ts5 = tmp_Ts;

%% Modeling what happens to fluxes with modest increases to temperature
% figure(12);clf;
% plot(data.Ta(data.Ts5>-1),data.Ts5(data.Ts5>-1),'k.');
% p = polyfit(data.Ta(data.Ts5>0),data.Ts5(data.Ts5>0),1); %p = [0.6339,3.3466];
% if Ta < 0 -- no change to Ts5; otherwise Ts = 0.6339*Ta_change
% begin_year = 2012;
% end_year = 2018;

clear data h1 h h3 *_sum
sites = {'TPD'};
begin_year_main = 2012;
end_year_main = 2017;
    close all; clear options;
    site = sites{1,1};
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year);

tmp_Ts = data.Ts5;

% year | SOS | EOG | BOB | EOS 
% NOTE: using mean values for 2018
gs_dates = ...
    [2012 2013 2014 2015 2016 2017 2018; ... 
    120 116 127 118 126 125 122; ...
    145	155	160	146	154	159 153; ...
    257	249	255	249	262	261 256; ...
    306	314	307	309	328	318 314]';


gs_flag = NaN.*ones(size(data.GEP_flag,1),1);
gs_sf = NaN.*ones(size(data.GEP_flag,1),1);
ctr = 1;
for yr = begin_year:1:end_year
%    data.Year==yr & (data.dt <= gs_dates(i,2) | data.dt >= gs_dates(i,5))
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 1; % off-season
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,3) & data.dt > gs_dates(ctr,2)),1) = 2; % spring shoulder
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 3;% peak uptake
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,5) & data.dt > gs_dates(ctr,4)),1) = 4;% fall shoulder

    % scaling factors
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 0; 
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 1;% peak uptake
    tmp = gs_sf(data.Year==yr);
    ind_bos = find(isnan(tmp),1,'first');
    ind_eog = find(tmp==1,1,'first')-1;
    
    ind_bob = find(tmp==1,1,'last')+1;
    ind_eos = find(isnan(tmp),1,'last');
    
    greenup = linspace(0,1,ind_eog-ind_bos+3)';
    browndown = linspace(1,0,ind_eos+3 - ind_bob)';
    tmp(ind_bos-1:ind_eog+1,1) = greenup;
    tmp(ind_bob-1:ind_eos+1) = browndown;
    gs_sf(data.Year==yr) = tmp;
    clear tmp greenup browndown
    ctr = ctr + 1;
end

% Respiration: Use 3-parameter logistic model fit to each year
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;

% Make VWC scaling function for all years for RE
    %%% Non-spring shoulder
    ind_param(1).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag~=2);
    [c_hat(1).RE_all_logi, y_hat(1).RE_all_logi, y_pred(1).RE_all_logi, stats(1).RE_all_logi, sigma(1).RE_all_logi, err(1).RE_all_logi, exitflag(1).RE_all_logi, num_iter(1).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(1).RE_all) data.SM_a_filled(ind_param(1).RE_all)] , data.NEE(ind_param(1).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(1).RE_all), options);
    
    %%% Spring shoulder
    ind_param(2).RE_all = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & gs_flag==2);
    [c_hat(2).RE_all_logi, y_hat(2).RE_all_logi, y_pred(2).RE_all_logi, stats(2).RE_all_logi, sigma(2).RE_all_logi, err(2).RE_all_logi, exitflag(2).RE_all_logi, num_iter(2).RE_all_logi] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(2).RE_all) data.SM_a_filled(ind_param(2).RE_all)] , data.NEE(ind_param(2).RE_all), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(2).RE_all), options);  

    vwc_sf = NaN.*ones(size(data.GEP_flag,1),1);
    vwc_sf(gs_flag~=2,1) = 1;
    vwc_sf(gs_flag==2,1) = 1./(1 + exp(c_hat(2).RE_all_logi(4)-c_hat(2).RE_all_logi(5).*data.SM_a_filled(gs_flag==2,1)));    
    
%%%% Parameterize RE for each year and produce predicted RE for different temperature scenarios:    
temp_diffs = 0.6339.*(-0.5:0.1:0.5)'; % scaled by 0.6339 because Ts scales with Ta by 63.39%.
RE_pred_logi = NaN.*ones(size(data.Year,1),1);
ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).REyear =  find(data.Year == yr & (data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std));
    
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(ctr).RE_logi2, y_hat(ctr).RE_logi2, RE_pred_logi(data.Year==yr), stats(ctr).RE_logi2, sigma(ctr).RE_logi2, err(ctr).RE_logi2, exitflag(ctr).RE_logi2, num_iter(ctr).RE_logi2] = ...
        fitresp([8 0.2 12], 'fitresp_2A_sf', [data.Ts5(ind_param(ctr).REyear) vwc_sf(ind_param(ctr).REyear)], data.NEE(ind_param(ctr).REyear), [data.Ts5(data.Year==yr) vwc_sf(data.Year==yr)], data.NEE_std(ind_param(ctr).REyear), options);
    % columns for RE_sum: -0.3 | -0.2 | -0.1 | 0 | +0.1 | +0.2 | + 0.3
    for j = 1:1:size(temp_diffs,1)
        %     tmp = fitresp_2A_sf(c_hat(ctr).RE_logi2,[data.Ts5(data.Year==yr)+j vwc_sf(data.Year==yr)]);
        RE_sum(ctr,j) = sum(fitresp_2A_sf(c_hat(ctr).RE_logi2,[data.Ts5(data.Year==yr)+temp_diffs(j,1) vwc_sf(data.Year==yr)])).*0.0216;
    end
    %     RE_sum(ctr,1) = sum(RE_pred_logi(data.Year==yr)).*0.0216;
    %     c_hat_toPlot(ctr,:) = c_hat(ctr).RE_logi2;
    ctr = ctr + 1;
end

%%%%%%%%%% GEP
    GEPraw = RE_pred_logi - data.NEE;

    clear options global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(1,4);
    
    temp_diffs = (-0.5:0.1:0.5)';

    GEP_pred_logi = zeros(size(data.Year,1),1);
    ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).GEP_all = find(data.Year==yr & ~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag>0);
%     ind_param(3).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==3);
%     ind_param(4).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==4);

    %%% Spring shoulder
%         X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%    X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%         [c_hat(2).GEP_all, y_hat(2).GEP_all, y_pred(2).GEP_all, stats(2).GEP_all, sigma(2).GEP_all, err(2).GEP_all, exitflag(2).GEP_all, num_iter(2).GEP_all] = ...
%         fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_2L6', X_in,GEPraw(ind_param(2).GEP_all),  X_eval, data.NEE_std(ind_param(2).GEP_all), options);
   X_in = [data.PAR(ind_param(ctr).GEP_all) data.Ta(ind_param(ctr).GEP_all) gs_sf(ind_param(ctr).GEP_all)];
       X_eval = [data.PAR(data.Year==yr) data.Ta(data.Year==yr) gs_sf(data.Year==yr)];    

        [c_hat(ctr).GEP_all, y_hat(ctr).GEP_all, y_pred(ctr).GEP_all, stats(ctr).GEP_all, sigma(ctr).GEP_all, err(ctr).GEP_all, exitflag(ctr).GEP_all, num_iter(ctr).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in,GEPraw(ind_param(ctr).GEP_all),  X_eval, data.NEE_std(ind_param(ctr).GEP_all), options);
        GEP_pred_logi(data.Year==yr & gs_flag>0) = y_pred(ctr).GEP_all(gs_flag(data.Year==yr)>0);
    for j = 1:1:size(temp_diffs,1)
        %     tmp = fitresp_2A_sf(c_hat(ctr).RE_logi2,[data.Ts5(data.Year==yr)+j vwc_sf(data.Year==yr)]);
        tmp = fitGEP_1H1_1L6_pheno(c_hat(ctr).GEP_all,[data.PAR(data.Year==yr) data.Ta(data.Year==yr)+temp_diffs(j,1) gs_sf(data.Year==yr)]);
        tmp(gs_flag==0)=0;
        GEP_sum(ctr,j) = sum(tmp).*0.0216;
    end
ctr = ctr + 1;
end

%%%%%%%%%%%% NEP - plot NEP vs delta T
NEP_pred = GEP_pred_logi - RE_pred_logi;
GEP_sum = GEP_sum';
RE_sum = RE_sum';
NEP_sum = GEP_sum - RE_sum;
% NEP_sum = NEP_sum';

clrs = colormap(jet(7));

f1= figure(1);clf;
ctr = 1;
for yr = begin_year:1:end_year
subplot(3,1,1);
    h(ctr) = plot(RE_sum(:,ctr),'Color',clrs(ctr,:),'LineWidth',2); hold on;
subplot(3,1,2);
    plot(GEP_sum(:,ctr),'Color',clrs(ctr,:),'LineWidth',2); hold on;
subplot(3,1,3);
    plot(NEP_sum(:,ctr),'Color',clrs(ctr,:),'LineWidth',2); hold on;

ctr = ctr + 1;
end
subplot(3,1,1);
legend(h,num2str((begin_year:1:end_year)'),'Location','North','Orientation','horizontal');
ylabel('RE (g C m^{-2} yr^{-1})');
set(gca,'XTick',(1:1:11),'XTickLabel',{'-0.5','-0.4','-0.3','-0.2','-0.1','0','0.1','0.2','0.3','0.4','0.5'});
grid on;
subplot(3,1,2);
ylabel('GEP (g C m^{-2} yr^{-1})');
set(gca,'XTick',(1:1:11),'XTickLabel',{'-0.5','-0.4','-0.3','-0.2','-0.1','0','0.1','0.2','0.3','0.4','0.5'});
grid on;
subplot(3,1,3); 
ylabel('NEP (g C m^{-2} yr^{-1})');
xlabel('\Delta T (\circ C)');
set(gca,'XTick',(1:1:11),'XTickLabel',{'-0.5','-0.4','-0.3','-0.2','-0.1','0','0.1','0.2','0.3','0.4','0.5'});
axis([1 11 0 300]);
grid on;
print([save_path 'TPD-Fluxes-deltaT.png'],'-dpng','-r300');

%%%%% Calculate rates 
RE_diff = RE_sum(end,:)-RE_sum(1,:);
GEP_diff = GEP_sum(end,:)-GEP_sum(1,:);
NEP_diff = NEP_sum(end,:)-NEP_sum(1,:);
disp(['Mean change per 1 degree increase: '])
disp(['RE: ' num2str(mean(RE_diff)) 'g C yr-1']);
disp(['GEP: ' num2str(mean(GEP_diff)) 'g C yr-1']);
disp(['NEP: ' num2str(mean(NEP_diff)) 'g C yr-1']);

%%%%%%%%%%%%% average NEP of 
% daily NEP sums
tmp = reshape(NEP_pred,48,[]);
NEP_pred_d = (sum(tmp,1).*0.0216)';
tmp = reshape(gs_flag,48,[]);
gs_flag_d = mode(tmp,1)';

x = 1:1:size(NEP_pred_d,1);
f2 = figure(2);clf; 
plot(x,NEP_pred_d); hold on;
plot(x(gs_flag_d==2),NEP_pred_d(gs_flag_d==2),'go');
plot(x(gs_flag_d==4),NEP_pred_d(gs_flag_d==4),'ro');

%%% Calculate the mean and median daily NEP values immediately (i.e. 10 days) after the
%%% peak LAI season starts and immediately before fall shoulder (at the end of the peak LAI season). 
ind1 = gs_flag_d; ind2 = [gs_flag_d(2:end); gs_flag_d(1)];
ind3 = find(ind1==2 & ind2==3); %transitions from spring shoulder to peak LAI period. 
ind4 = find(ind1==3 & ind2==4); %transitions from peak LAI period to fall shoulder. 
NEP_ss_all = [];
NEP_fs_all = [];
for i = 1:1:length(ind3)
    NEP_ss_all = [NEP_ss_all; NEP_pred_d(ind3(i)+1:ind3(i)+11)];
    NEP_fs_all = [NEP_fs_all; NEP_pred_d(ind4(i)-11:ind4(i)-1)];
    
    NEP_ss_mean(i,1) = mean(NEP_pred_d(ind3(i)+1:ind3(i)+11)); 
    NEP_ss_med(i,1) = median(NEP_pred_d(ind3(i)+1:ind3(i)+11)); 
    
    NEP_fs_mean(i,1) = mean(NEP_pred_d(ind4(i)-11:ind4(i)-1)); 
    NEP_fs_med(i,1) = median(NEP_pred_d(ind4(i)-11:ind4(i)-1)); 
end


%%%%%% Plot histogram of NEP values for first 10 and last 10 days of max
%%%%%% LAI period
edges = (-4:1:10);
f3 = figure(3);clf;
subplot(2,1,1);
histogram(NEP_ss_all,edges); hold on;
h3(1) = plot([mean(NEP_ss_all) mean(NEP_ss_all)],[0 20],'r--','LineWidth',2);
h3(2) = plot([median(NEP_ss_all) median(NEP_ss_all)],[0 20],'y:','LineWidth',2);
text(-4.5,16,['mean = '  num2str(round(mean(NEP_ss_all),1)) ' g C m^{-2} d^{-1}']);
text(-4.5,12,['median = '  num2str(round(median(NEP_ss_all),1)) ' g C m^{-2} d^{-1}']);
xlabel('NEP (g C m^{-2} d^{-1})');
ylabel('Count')
title('First 10 days of max LAI period')

subplot(2,1,2);
histogram(NEP_fs_all,edges);hold on;
h3(1) = plot([mean(NEP_fs_all) mean(NEP_fs_all)],[0 20],'r--','LineWidth',2);
h3(2) = plot([median(NEP_fs_all) median(NEP_fs_all)],[0 20],'y:','LineWidth',2);
text(-4.5,16,['mean = '  num2str(round(mean(NEP_fs_all),1)) ' g C m^{-2} d^{-1}']);
text(-4.5,12,['median = '  num2str(round(median(NEP_fs_all),1)) ' g C m^{-2} d^{-1}']);
xlabel('NEP (g C m^{-2} d^{-1})');
ylabel('Count')
title('Last 10 days of max LAI period')
legend(h3,{'mean','median'},'Location','NorthEast');
print([save_path site 'daily_NEP.png'],'-dpng','-r300');

%% 2019-09-22: Model RE and GEP for TP39 and TPD parameterizing with everything
% but Soil Moisture 
sites = {'TPD';'TP39'};
begin_year_main = 2012;
end_year_main = 2017;

%%% TPD first: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear data h1 h h3 *_sum
    close all; clear options;
    site = 'TPD';
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year,1);
% tmp_Ts = data.Ts5;

% year | SOS | EOG | BOB | EOS 
% NOTE: using mean values for 2018
gs_dates = ...
    [2012 2013 2014 2015 2016 2017 2018; ... 
    120 116 127 118 126 125 122; ...
    145	155	160	146	154	159 153; ...
    257	249	255	249	262	261 256; ...
    306	314	307	309	328	318 314]';


gs_flag = NaN.*ones(size(data.GEP_flag,1),1);
gs_sf = NaN.*ones(size(data.GEP_flag,1),1);
ctr = 1;
for yr = begin_year:1:end_year
%    data.Year==yr & (data.dt <= gs_dates(i,2) | data.dt >= gs_dates(i,5))
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 1; % off-season
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,3) & data.dt > gs_dates(ctr,2)),1) = 2; % spring shoulder
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 3;% peak uptake
    gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,5) & data.dt > gs_dates(ctr,4)),1) = 4;% fall shoulder

    % scaling factors
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 0; 
    gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 1;% peak uptake
    tmp = gs_sf(data.Year==yr);
    ind_bos = find(isnan(tmp),1,'first');
    ind_eog = find(tmp==1,1,'first')-1;
    
    ind_bob = find(tmp==1,1,'last')+1;
    ind_eos = find(isnan(tmp),1,'last');
    
    greenup = linspace(0,1,ind_eog-ind_bos+3)';
    browndown = linspace(1,0,ind_eos+3 - ind_bob)';
    tmp(ind_bos-1:ind_eog+1,1) = greenup;
    tmp(ind_bob-1:ind_eos+1) = browndown;
    gs_sf(data.Year==yr) = tmp;
    clear tmp greenup browndown
    ctr = ctr + 1;
end

% Respiration: Use 3-parameter logistic model fit to each year
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;

    
%%% RE

%%%% Parameterize RE for each year and produce predicted RE for different temperature scenarios:    
RE_pred_logi = NaN.*ones(size(data.Year,1),1);
ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).REyear =  find(data.Year == yr & (data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std));
    
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(ctr).RE_logi2, y_hat(ctr).RE_logi2, RE_pred_logi(data.Year==yr), stats(ctr).RE_logi2, sigma(ctr).RE_logi2, err(ctr).RE_logi2, exitflag(ctr).RE_logi2, num_iter(ctr).RE_logi2] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(ctr).REyear), data.NEE(ind_param(ctr).REyear), data.Ts5(data.Year==yr), data.NEE_std(ind_param(ctr).REyear), options);
    % columns for RE_sum: -0.3 | -0.2 | -0.1 | 0 | +0.1 | +0.2 | + 0.3
    %     RE_sum(ctr,1) = sum(RE_pred_logi(data.Year==yr)).*0.0216;
    %     c_hat_toPlot(ctr,:) = c_hat(ctr).RE_logi2;
    ctr = ctr + 1;
end
data.RE_pred = RE_pred_logi;

%%%%%%%%%% GEP
    GEPraw = data.RE_pred - data.NEE;

    clear options global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(4,1);
    
    GEP_pred_logi = zeros(size(data.Year,1),1);
    ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).GEP_all = find(data.Year==yr & ~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag>0);
%     ind_param(3).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==3);
%     ind_param(4).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==4);

    %%% Spring shoulder
%         X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%    X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%         [c_hat(2).GEP_all, y_hat(2).GEP_all, y_pred(2).GEP_all, stats(2).GEP_all, sigma(2).GEP_all, err(2).GEP_all, exitflag(2).GEP_all, num_iter(2).GEP_all] = ...
%         fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_2L6', X_in,GEPraw(ind_param(2).GEP_all),  X_eval, data.NEE_std(ind_param(2).GEP_all), options);
   X_in = [data.PAR(ind_param(ctr).GEP_all) data.Ta(ind_param(ctr).GEP_all) gs_sf(ind_param(ctr).GEP_all)];
       X_eval = [data.PAR(data.Year==yr) data.Ta(data.Year==yr) gs_sf(data.Year==yr)];    

        [c_hat(ctr).GEP_all, y_hat(ctr).GEP_all, y_pred(ctr).GEP_all, stats(ctr).GEP_all, sigma(ctr).GEP_all, err(ctr).GEP_all, exitflag(ctr).GEP_all, num_iter(ctr).GEP_all] = ...
        fitGEP([0.1 40 2 0.5], 'fitGEP_1H1_1L6_pheno', X_in,GEPraw(ind_param(ctr).GEP_all),  X_eval, data.NEE_std(ind_param(ctr).GEP_all), options);
        GEP_pred_logi(data.Year==yr & gs_flag>0) = y_pred(ctr).GEP_all(gs_flag(data.Year==yr)>0);

        
ctr = ctr + 1;
end
data.GEP_pred = GEP_pred_logi;
data.NEP_pred = GEP_pred_logi - RE_pred_logi;

%%% Calculate residuals: 
data.GEP_resids = NaN.*ones(size(data.GEP_pred,1),1);
ind_GEP = find(~isnan(GEPraw) & data.PAR > 15 & gs_flag > 0);
data.GEP_resids(ind_GEP) = GEPraw(ind_GEP) - data.GEP_pred(ind_GEP);
data.RE_resids = NaN.*ones(size(data.RE_pred,1),1);
ind_RE = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.NEE));
data.RE_resids(ind_RE) = data.NEE(ind_RE) - data.RE_pred(ind_RE);
data.NEP_resids = NaN.*ones(size(data.NEP_pred,1),1);
data.NEP_resids(ind_RE) = (-1.*data.NEE(ind_RE)) - data.NEP_pred(ind_RE);
data.NEP_resids(ind_GEP) = (-1.*data.NEE(ind_GEP)) - data.NEP_pred(ind_GEP);

%%%% Moving window stats
[RE_resid_mw] = jjb_mov_window_stats(data.REW(ind_RE),data.RE_resids(ind_RE), 0.05, 0.025);
[GEP_resid_mw] = jjb_mov_window_stats(data.REW(ind_GEP),data.GEP_resids(ind_GEP), 0.05, 0.025);

% plots
f1 = figure(1);clf
plot(data.REW(ind_RE),data.RE_resids(ind_RE),'r.'); hold on;
plot(data.REW(ind_GEP),data.GEP_resids(ind_GEP),'g.'); hold on;
plot(RE_resid_mw(:,1),RE_resid_mw(:,2),'r-','Color',[0.5 0 0],'Linewidth',2);
plot(GEP_resid_mw(:,1),GEP_resid_mw(:,2),'-','Color',[0 0.5 0],'Linewidth',2);
xlabel('REW'); ylabel('RE / GEP (hhourly)')
legend('RE','GEP','Location','NorthWest')
TPD.data = data;
save([save_path 'TPD_resids.mat'],'TPD');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TP39: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear data h1 h h3 *_sum
    close all; clear options;
    site = 'TP39';
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year,1);
% tmp_Ts = data.Ts5;

% year | SOS | EOG | BOB | EOS 
% NOTE: using mean values for 2018
% gs_dates = ...
%     [2012 2013 2014 2015 2016 2017 2018; ... 
%     120 116 127 118 126 125 122; ...
%     145	155	160	146	154	159 153; ...
%     257	249	255	249	262	261 256; ...
%     306	314	307	309	328	318 314]';


% gs_flag = NaN.*ones(size(data.GEP_flag,1),1);
% gs_sf = NaN.*ones(size(data.GEP_flag,1),1);
% ctr = 1;
% for yr = begin_year:1:end_year
% %    data.Year==yr & (data.dt <= gs_dates(i,2) | data.dt >= gs_dates(i,5))
%     gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 1; % off-season
%     gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,3) & data.dt > gs_dates(ctr,2)),1) = 2; % spring shoulder
%     gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 3;% peak uptake
%     gs_flag(data.Year==yr & (data.dt <= gs_dates(ctr,5) & data.dt > gs_dates(ctr,4)),1) = 4;% fall shoulder
% 
%     % scaling factors
%     gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,2) | data.dt > gs_dates(ctr,5)),1) = 0; 
%     gs_sf(data.Year==yr & (data.dt <= gs_dates(ctr,4) & data.dt > gs_dates(ctr,3)),1) = 1;% peak uptake
%     tmp = gs_sf(data.Year==yr);
%     ind_bos = find(isnan(tmp),1,'first');
%     ind_eog = find(tmp==1,1,'first')-1;
%     
%     ind_bob = find(tmp==1,1,'last')+1;
%     ind_eos = find(isnan(tmp),1,'last');
%     
%     greenup = linspace(0,1,ind_eog-ind_bos+3)';
%     browndown = linspace(1,0,ind_eos+3 - ind_bob)';
%     tmp(ind_bos-1:ind_eog+1,1) = greenup;
%     tmp(ind_bob-1:ind_eos+1) = browndown;
%     gs_sf(data.Year==yr) = tmp;
%     clear tmp greenup browndown
%     ctr = ctr + 1;
% end

% Respiration: Use 3-parameter logistic model fit to each year

    
%%% RE

%%%% Parameterize RE for each year and produce predicted RE for different temperature scenarios:  
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;
RE_pred_logi = NaN.*ones(size(data.Year,1),1);
ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).REyear =  find(data.Year == yr & (data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std));
    
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(ctr).RE_logi2, y_hat(ctr).RE_logi2, RE_pred_logi(data.Year==yr), stats(ctr).RE_logi2, sigma(ctr).RE_logi2, err(ctr).RE_logi2, exitflag(ctr).RE_logi2, num_iter(ctr).RE_logi2] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(ctr).REyear), data.NEE(ind_param(ctr).REyear), data.Ts5(data.Year==yr), data.NEE_std(ind_param(ctr).REyear), options);
    % columns for RE_sum: -0.3 | -0.2 | -0.1 | 0 | +0.1 | +0.2 | + 0.3
    %     RE_sum(ctr,1) = sum(RE_pred_logi(data.Year==yr)).*0.0216;
    %     c_hat_toPlot(ctr,:) = c_hat(ctr).RE_logi2;
    ctr = ctr + 1;
end
data.RE_pred = RE_pred_logi;

%%%%%%%%%% GEP
    GEPraw = data.RE_pred - data.NEE;

    clear options global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(6,1);
    
    GEP_pred_logi = zeros(size(data.Year,1),1);
    ctr = 1;
for yr = begin_year:1:end_year
    ind_param(ctr).GEP_all = find(data.Year==yr & ~isnan(GEPraw.*data.NEE_std.*data.Ts5.*data.PAR) & data.PAR > 15 & data.VPD > 0 & data.GEP_flag ==2);
%     ind_param(3).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==3);
%     ind_param(4).GEP_all = find(~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR) & data.PAR > 15 & data.VPD > 0 & gs_flag==4);

    %%% Spring shoulder
%         X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%    X_in = [data.PAR(ind_param(2).GEP_all) data.Ts5(ind_param(2).GEP_all) data.VPD(ind_param(2).GEP_all) data.SM_a_filled(ind_param(2).GEP_all)];
%         [c_hat(2).GEP_all, y_hat(2).GEP_all, y_pred(2).GEP_all, stats(2).GEP_all, sigma(2).GEP_all, err(2).GEP_all, exitflag(2).GEP_all, num_iter(2).GEP_all] = ...
%         fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_2L6', X_in,GEPraw(ind_param(2).GEP_all),  X_eval, data.NEE_std(ind_param(2).GEP_all), options);
   X_in = [data.PAR(ind_param(ctr).GEP_all) data.Ts5(ind_param(ctr).GEP_all) data.VPD(ind_param(ctr).GEP_all)];
       X_eval = [data.PAR(data.Year==yr) data.Ts5(data.Year==yr) data.VPD(data.Year==yr)];    

        [c_hat(ctr).GEP_all, y_hat(ctr).GEP_all, y_pred(ctr).GEP_all, stats(ctr).GEP_all, sigma(ctr).GEP_all, err(ctr).GEP_all, exitflag(ctr).GEP_all, num_iter(ctr).GEP_all] = ...
        fitGEP([0.1 40 2 0.5 -2 -0.8], 'fitGEP_1H1_2L6', X_in,GEPraw(ind_param(ctr).GEP_all),  X_eval, data.NEE_std(ind_param(ctr).GEP_all), options);
        GEP_pred_logi(data.Year==yr & data.GEP_flag >=1) = y_pred(ctr).GEP_all(data.GEP_flag(data.Year==yr)>=1);
        
ctr = ctr + 1;
end

data.GEP_pred = GEP_pred_logi;
data.NEP_pred = GEP_pred_logi - RE_pred_logi;

%%% Calculate residuals: 
data.GEP_resids = NaN.*ones(size(data.GEP_pred,1),1);
ind_GEP = find(~isnan(GEPraw) & data.PAR > 15 & data.GEP_flag>=1);
data.GEP_resids(ind_GEP) = GEPraw(ind_GEP) - data.GEP_pred(ind_GEP);
data.RE_resids = NaN.*ones(size(data.RE_pred,1),1);
ind_RE = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.NEE));
data.RE_resids(ind_RE) = data.NEE(ind_RE) - data.RE_pred(ind_RE);
data.NEP_resids = NaN.*ones(size(data.NEP_pred,1),1);
data.NEP_resids(ind_RE) = (-1.*data.NEE(ind_RE)) - data.NEP_pred(ind_RE);
data.NEP_resids(ind_GEP) = (-1.*data.NEE(ind_GEP)) - data.NEP_pred(ind_GEP);

%%%% Moving window stats
[RE_resid_mw] = jjb_mov_window_stats(data.REW(ind_RE),data.RE_resids(ind_RE), 0.05, 0.025);
[GEP_resid_mw] = jjb_mov_window_stats(data.REW(ind_GEP),data.GEP_resids(ind_GEP), 0.05, 0.025);

% plots
f1 = figure(1);clf
plot(data.REW(ind_RE),data.RE_resids(ind_RE),'r.'); hold on;
plot(data.REW(ind_GEP),data.GEP_resids(ind_GEP),'g.'); hold on;
plot(RE_resid_mw(:,1),RE_resid_mw(:,2),'r-','Color',[0.5 0 0],'Linewidth',2);
plot(GEP_resid_mw(:,1),GEP_resid_mw(:,2),'-','Color',[0 0.5 0],'Linewidth',2);
xlabel('REW'); ylabel('RE / GEP (hhourly)')
legend('RE','GEP','Location','NorthWest')

TP39.data = data;
save([save_path 'TP39_resids.mat'],'TP39');

%% 2019-10-26: residual analysis at TP39 and TPD using 
sites = {'TPD';'TP39'};
begin_year_main = 2012;
end_year_main = 2017;
clrs = colormap(jet(7));

%%% 1. TPD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear data h1 h h3 *_sum
    close all; clear options;
    site = 'TPD';
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year,1);

%%%% GS dates: 
gs_dates = ...
    [2012 2013 2014 2015 2016 2017 2018; ... 
    120 116 127 118 126 125 122; ...
    145	155	160	146	154	159 153; ...
    257	249	255	249	262	261 256; ...
    306	314	307	309	328	318 314]';
    
%%%% 1.1 Respiration: Use 3-parameter logistic model fit to each year
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;
data.RE_pred = NaN.*ones(size(data.Year,1),1);

gs_flag = zeros(size(data.Year,1),1);
for yr = begin_year:1:end_year
    gs_start = gs_dates(gs_dates(:,1)==yr,3);
    gs_end = gs_dates(gs_dates(:,1)==yr,4);
    gs_flag(data.Year==yr & data.dt>=gs_start & data.dt<=gs_end) = 1; 
end

% Parameterize all-years at once -- just Ts
ind_param(1).REyear_all_gs = find(gs_flag == 1 & (data.PAR >= 15 | data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(1).RE_logi_gs, y_hat(1).RE_logi_gs, RE_pred_logi_gs, stats(1).RE_logi_gs, sigma(1).RE_logi_gs, err(1).RE_logi_gs, exitflag(1).RE_logi_gs, num_iter(1).RE_logi_gs] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(1).REyear_all_gs), data.NEE(ind_param(1).REyear_all_gs), data.Ts5, data.NEE_std(ind_param(1).REyear_all_gs), options);
% Parameterize all-years at once -- Ts + SM
    ind_param(2).REyear_all_gs = find(gs_flag == 1 & (data.PAR >= 15 | data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));   
    clear global
    options.f_coeff = NaN.*ones(5,1);
    [c_hat(2).RE_logi_gs, y_hat(2).RE_logi_gs, RE_pred_logi_gs2, stats(2).RE_logi_gs, sigma(2).RE_logi_gs, err(2).RE_logi_gs, exitflag(2).RE_logi_gs, num_iter(2).RE_logi_gs] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(2).REyear_all_gs) data.SM_a_filled(ind_param(2).REyear_all_gs)], data.NEE(ind_param(2).REyear_all_gs), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(2).REyear_all_gs), options);
    
% Plotting residual analysis
figure(1);clf;
plot(ind_param(1).REyear_all_gs, data.NEE(ind_param(1).REyear_all_gs),'k.'); 
hold on;
plot(RE_pred_logi_gs,'r-');
plot(RE_pred_logi_gs2,'b-');
% Residuals between the just-Ts 
resid_RE = NaN.*ones(length(RE_pred_logi_gs),1);
resid_RE(ind_param(1).REyear_all_gs) = RE_pred_logi_gs(ind_param(1).REyear_all_gs)-data.NEE(ind_param(1).REyear_all_gs);

figure(2);clf;
plot(data.SM_a_filled(ind_param(1).REyear_all_gs),resid_RE(ind_param(1).REyear_all_gs),'k.')
[mov_avg_RE] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).REyear_all_gs),resid_RE(ind_param(1).REyear_all_gs), 0.005, 0.01);
hold on;
plot(mov_avg_RE(:,1),mov_avg_RE(:,2),'r-', 'LineWidth',2);
    axis([0.025 0.15 -5 5]);
    ylabel('RE_{pred} - RE_{meas}');
    xlabel('VWC (%)');
    set(gca,'FontSize',12);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_RE_resid_VWC'],'-dpng','-r300');

[x_SM, y_SM, f_SM,h_SM] = plot_SMlogi(c_hat(2).RE_logi_gs(4:5), 1);figure(f_SM); axis([0 0.2 0 1]);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_RE-VWC_fn_rel'],'-dpng','-r300');


%{    
THIS IS ALL GARBAGE
% Try 2: parameterize all-at-once, all seasons of data
ind_param(1).REyear_all = find((data.PAR >= 15 | data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(1).RE_logi2, y_hat(1).RE_logi2, RE_pred_logi, stats(1).RE_logi2, sigma(1).RE_logi2, err(1).RE_logi2, exitflag(1).RE_logi2, num_iter(1).RE_logi2] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(1).REyear_all), data.NEE(ind_param(1).REyear_all), data.Ts5(data.Year==yr), data.NEE_std(ind_param(1).REyear_all), options);
plot_TsLogi(c_hat(1).RE_logi2)


% Parameterize each year 
ctr = 1;
for yr = begin_year:1:end_year
 
    ind_param(ctr).REyear =  find(data.Year == yr & (data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));
    
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(ctr).RE_logi2, y_hat(ctr).RE_logi2, RE_pred_logi(data.Year==yr), stats(ctr).RE_logi2, sigma(ctr).RE_logi2, err(ctr).RE_logi2, exitflag(ctr).RE_logi2, num_iter(ctr).RE_logi2] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(ctr).REyear), data.NEE(ind_param(ctr).REyear), data.Ts5(data.Year==yr), data.NEE_std(ind_param(ctr).REyear), options);
    clear global
    options.f_coeff = NaN.*ones(5,1);
    ctr = ctr + 1;
end
data.RE_pred = RE_pred_logi;
%}

%%%% 1.2 GEP
    data.RE_pred = RE_pred_logi_gs;
    GEPraw = data.RE_pred - data.NEE;
    GEP_pred_logi = zeros(length(GEPraw),1);

    % Parameterize all-years at once
ind_param(1).GEP_all_gs = find(gs_flag == 1 & ~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR.*data.SM_a_filled) & data.PAR > 15 & data.VPD > 0);
X_in = [data.PAR(ind_param(1).GEP_all_gs) data.Ta(ind_param(1).GEP_all_gs) data.VPD(ind_param(1).GEP_all_gs) data.SM_a_filled(ind_param(1).GEP_all_gs) ];
X_eval = [data.PAR data.Ta data.VPD data.SM_a_filled];
   
    clear options global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(8,1);

       [c_hat(1).GEP_all_gs, y_hat(1).GEP_all_gs, y_pred(1).GEP_all_gs, stats(1).GEP_all_gs, sigma(1).GEP_all_gs, err(1).GEP_all_gs, exitflag(1).GEP_all_gs, num_iter(1).GEP_all_gs] = ...
        fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
        GEP_pred_logi(gs_flag==1) = y_pred(1).GEP_all_gs(gs_flag==1);
    
% plot functional relationships
[x_Ta, y_Ta, f_Ta, h_Ta] = plot_SMlogi(c_hat(1).GEP_all_gs(3:4), 1); figure(f_Ta); axis([-10 30 0 1]);
xlabel('Ta (C)')
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-Ta_fn_rel'],'-dpng','-r300');

[x_VPD, y_VPD, f_VPD, h_VPD] = plot_SMlogi(c_hat(1).GEP_all_gs(5:6), 1);figure(f_VPD); axis([0 35 0 1]);
xlabel('VPD (hPa?)')
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-VPD_fn_rel'],'-dpng','-r300');

[x_SM, y_SM, f_SM,h_SM] = plot_SMlogi(c_hat(1).GEP_all_gs(7:8), 1);figure(f_SM); axis([0 0.2 0 1]);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-VWC_fn_rel'],'-dpng','-r300');

%%%%%% Fix the Ta effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(3:4) = [-10000 100];
GEP_pred_logi_noTa = zeros(length(GEPraw),1);

[c_hat(2).GEP_all_gs, y_hat(2).GEP_all_gs, y_pred(2).GEP_all_gs, stats(2).GEP_all_gs, sigma(2).GEP_all_gs, err(2).GEP_all_gs, exitflag(2).GEP_all_gs, num_iter(2).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noTa(gs_flag==1) = y_pred(2).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noTa = NaN.*ones(length(GEP_pred_logi_noTa),1);
resid_GEP_noTa(ind_param(1).GEP_all_gs) = GEP_pred_logi_noTa(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noTa = figure;clf(f_noTa);
plot(data.Ta(ind_param(1).GEP_all_gs),resid_GEP_noTa(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noTa] = jjb_mov_window_stats(data.Ta(ind_param(1).GEP_all_gs),resid_GEP_noTa(ind_param(1).GEP_all_gs), 0.5, 0.5);
hold on;
plot(mov_avg_GEP_noTa(:,1),mov_avg_GEP_noTa(:,2),'r-','LineWidth',2);
axis([12 30 -10 10]);
xlabel('Ta (C)')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_Ta'],'-dpng','-r300');


%%%%%% Fix the VPD effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(5:6) = [-10000 100];
GEP_pred_logi_noVPD = zeros(length(GEPraw),1);

[c_hat(3).GEP_all_gs, y_hat(3).GEP_all_gs, y_pred(3).GEP_all_gs, stats(3).GEP_all_gs, sigma(3).GEP_all_gs, err(3).GEP_all_gs, exitflag(3).GEP_all_gs, num_iter(3).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noVPD(gs_flag==1) = y_pred(3).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noVPD = NaN.*ones(length(GEP_pred_logi_noVPD),1);
resid_GEP_noVPD(ind_param(1).GEP_all_gs) = GEP_pred_logi_noVPD(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noVPD = figure;clf(f_noVPD);
plot(data.VPD(ind_param(1).GEP_all_gs),resid_GEP_noVPD(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noVPD] = jjb_mov_window_stats(data.VPD(ind_param(1).GEP_all_gs),resid_GEP_noVPD(ind_param(1).GEP_all_gs), 0.5, 0.5);
hold on;
plot(mov_avg_GEP_noVPD(:,1),mov_avg_GEP_noVPD(:,2),'r-','LineWidth',2);
axis([0 25 -10 10]);
xlabel('VPD')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_VPD'],'-dpng','-r300');


%%%%%% Fix the VWC effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(7:8) = [-10000 100];
GEP_pred_logi_noSM = zeros(length(GEPraw),1);

[c_hat(4).GEP_all_gs, y_hat(4).GEP_all_gs, y_pred(4).GEP_all_gs, stats(4).GEP_all_gs, sigma(4).GEP_all_gs, err(4).GEP_all_gs, exitflag(4).GEP_all_gs, num_iter(4).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noSM(gs_flag==1) = y_pred(4).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noSM = NaN.*ones(length(GEP_pred_logi_noSM),1);
resid_GEP_noSM(ind_param(1).GEP_all_gs) = GEP_pred_logi_noSM(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noSM = figure;clf(f_noSM);
plot(data.SM_a_filled(ind_param(1).GEP_all_gs),resid_GEP_noSM(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noSM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).GEP_all_gs),resid_GEP_noSM(ind_param(1).GEP_all_gs), 0.005, 0.005);
hold on;
plot(mov_avg_GEP_noSM(:,1),mov_avg_GEP_noSM(:,2),'r-','LineWidth',2);
axis([0.025 0.15 -10 10]);
xlabel('VWC %')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_VWC'],'-dpng','-r300');

%%%% Part 3: Can we do some sort of analysis of variability in conditions? 
clear options global;
options.f_coeff = NaN.*ones(8,1);
GEP_PAR_only = zeros(length(GEPraw),1);
c_hat_PAR_only = [c_hat(1).GEP_all_gs(1:2) -10000 100 -10000 100  -10000 100];
tmp = fitGEP_1H1_3L6(c_hat_PAR_only,X_eval);
GEP_PAR_only(gs_flag==1) = tmp(gs_flag==1);

% Mean value of scaling factors during non-zero GEP periods
Ta_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(3)-c_hat(1).GEP_all_gs(4).*X_eval(:,2))));
VPD_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(5)-c_hat(1).GEP_all_gs(6).*X_eval(:,3))));
PAR_sf = ((c_hat(1).GEP_all_gs(1)*c_hat(1).GEP_all_gs(2)*X_eval(:,1))./(c_hat(1).GEP_all_gs(1)*X_eval(:,1) + c_hat(1).GEP_all_gs(2)));
VWC_GEP_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(7)-c_hat(1).GEP_all_gs(8).*X_eval(:,4))));

% Throw in a scaling factor for RE: 
VWC_RE_sf = (1./(1 + exp(c_hat(2).RE_logi_gs(4)-c_hat(2).RE_logi_gs(5).*data.SM_a_filled)));

f_GEP_PAR_only = figure(); 
clf(f_GEP_PAR_only);
ctr = 1;
for yr = begin_year:1:end_year
    ind_sf = find(data.Year==yr & GEP_pred_logi>0);
    GEP_sfs(ctr,1) = yr;
    GEP_sfs(ctr,2) = sum(GEP_pred_logi(data.Year==yr).*0.0216);
    GEP_sfs(ctr,3) = sum(GEP_PAR_only(data.Year==yr).*0.0216); 
    GEP_sfs(ctr,4) = sum(GEP_pred_logi_noTa(data.Year==yr).*0.0216); 
    GEP_sfs(ctr,5) = sum(GEP_pred_logi_noVPD(data.Year==yr).*0.0216); 
    
    GEP_sfs(ctr,6) = mean(Ta_sf(ind_sf));
    GEP_sfs(ctr,7) = mean(VPD_sf(ind_sf));
    GEP_sfs(ctr,8) = mean(PAR_sf(ind_sf));
    GEP_sfs(ctr,9) = mean(VWC_GEP_sf(ind_sf));
    
    GEP_sfs(ctr,11) = sum(RE_pred_logi_gs(data.Year==yr & gs_flag==1).*0.0216); 
    GEP_sfs(ctr,10) = sum(RE_pred_logi_gs2(data.Year==yr & gs_flag==1).*0.0216); 
    GEP_sfs(ctr,12) = mean(VWC_RE_sf(ind_sf)); % This is the sf for RE (VWC)
    
    ind = find(data.Year==yr);
    subplot(4,1,1);
    h_GEP_pred(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
    subplot(4,1,2);
    h_GEP_PAR_only(ctr) = plot(data.dt(ind),cumsum(GEP_PAR_only(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
    subplot(4,1,3);
    h_GEP_noTa(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi_noTa(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;   
    
    subplot(4,1,4);
    h_GEP_noVPD(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi_noVPD(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
%     subplot(3,1,2);
%     h_GEP_PAR_only(ctr) = plot(data.dt(ind),cumsum(GEP_PAR_only(ind)),'-','Color',clrs(ctr,:)); hold on;

   ctr = ctr+1; 
end

legend(h_GEP_pred,num2str((begin_year:1:end_year)'),'Location','NorthWest')

GEP_sfs(:,6) = GEP_sfs(:,6)./max(GEP_sfs(:,6));
GEP_sfs(:,7) = GEP_sfs(:,7)./max(GEP_sfs(:,7));
GEP_sfs(:,8) = GEP_sfs(:,8)./max(GEP_sfs(:,8));
GEP_sfs(:,9) = GEP_sfs(:,9)./max(GEP_sfs(:,9));
GEP_sfs(:,12) = GEP_sfs(:,12)./max(GEP_sfs(:,12));
GEP_sfs(:,13) = GEP_sfs(:,6).*GEP_sfs(:,7).*GEP_sfs(:,8).*GEP_sfs(:,9);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. TP39 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear data h1 h h3 *_sum
    close all; clear options;
    site = 'TP39';
    data = eval([site '.data;']);
    
    if isnan(begin_year_main)==1
        begin_year = min(data.Year);
    else
        begin_year = max(begin_year_main, data.Year(1));
    end
    
    if isnan(end_year_main)==1
        end_year = max(data.Year);
    else
        end_year = min(end_year_main, data.Year(end));
    end
    
    data = trim_data_files(data,begin_year,end_year,1);

%%%% GS dates: 
gs_dates = ...
    [2012 2013 2014 2015 2016 2017 2018; ... 
    70 96 96 91 74 79 79; ...
    147 160 153 140 158 159 159; ...
    271 258 258 257 270 248 248; ...
    314 351 338 345 366 354 354]';
    
%%%% 1.1 Respiration: Use 3-parameter logistic model fit to each year
    clear global;
    options.costfun =data.costfun; options.min_method = data.min_method;
data.RE_pred = NaN.*ones(size(data.Year,1),1);

gs_flag = zeros(size(data.Year,1),1);
for yr = begin_year:1:end_year
    gs_start = gs_dates(gs_dates(:,1)==yr,3);
    gs_end = gs_dates(gs_dates(:,1)==yr,4);
    gs_flag(data.Year==yr & data.dt>=gs_start & data.dt<=gs_end) = 1; 
end

% Parameterize all-years at once -- just Ts
ind_param(1).REyear_all_gs = find(gs_flag == 1 & (data.PAR >= 15 | data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));
    clear global
    options.f_coeff = NaN.*ones(3,1);
    [c_hat(1).RE_logi_gs, y_hat(1).RE_logi_gs, RE_pred_logi_gs, stats(1).RE_logi_gs, sigma(1).RE_logi_gs, err(1).RE_logi_gs, exitflag(1).RE_logi_gs, num_iter(1).RE_logi_gs] = ...
        fitresp([8 0.2 12], 'fitresp_2A', data.Ts5(ind_param(1).REyear_all_gs), data.NEE(ind_param(1).REyear_all_gs), data.Ts5, data.NEE_std(ind_param(1).REyear_all_gs), options);
% Parameterize all-years at once -- Ts + SM
    ind_param(2).REyear_all_gs = find(gs_flag == 1 & (data.PAR >= 15 | data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.Ts5.*data.NEE.*data.NEE_std.*data.SM_a_filled));   
    clear global
    options.f_coeff = NaN.*ones(5,1);
    [c_hat(2).RE_logi_gs, y_hat(2).RE_logi_gs, RE_pred_logi_gs2, stats(2).RE_logi_gs, sigma(2).RE_logi_gs, err(2).RE_logi_gs, exitflag(2).RE_logi_gs, num_iter(2).RE_logi_gs] = ...
        fitresp([8 0.2 12 8 180], 'fitresp_2B', [data.Ts5(ind_param(2).REyear_all_gs) data.SM_a_filled(ind_param(2).REyear_all_gs)], data.NEE(ind_param(2).REyear_all_gs), [data.Ts5 data.SM_a_filled], data.NEE_std(ind_param(2).REyear_all_gs), options);
    
% Plotting residual analysis
figure(1);clf;
plot(ind_param(1).REyear_all_gs, data.NEE(ind_param(1).REyear_all_gs),'k.'); 
hold on;
plot(RE_pred_logi_gs,'r-');
plot(RE_pred_logi_gs2,'b-');
% Residuals between the just-Ts 
resid_RE = NaN.*ones(length(RE_pred_logi_gs),1);
resid_RE(ind_param(1).REyear_all_gs) = RE_pred_logi_gs(ind_param(1).REyear_all_gs)-data.NEE(ind_param(1).REyear_all_gs);

figure(2);clf;
plot(data.SM_a_filled(ind_param(1).REyear_all_gs),resid_RE(ind_param(1).REyear_all_gs),'k.')
[mov_avg_RE] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).REyear_all_gs),resid_RE(ind_param(1).REyear_all_gs), 0.005, 0.01);
hold on;
plot(mov_avg_RE(:,1),mov_avg_RE(:,2),'r-', 'LineWidth',2);
    axis([0.025 0.15 -5 5]);
    ylabel('RE_{pred} - RE_{meas}');
    xlabel('VWC (%)');
    set(gca,'FontSize',12);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_RE_resid_VWC'],'-dpng','-r300');

[x_SM, y_SM, f_SM,h_SM] = plot_SMlogi(c_hat(2).RE_logi_gs(4:5), 1);figure(f_SM); axis([0 0.2 0 1]);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_RE-VWC_fn_rel'],'-dpng','-r300');

%%%% 1.2 GEP
    data.RE_pred = RE_pred_logi_gs;
    GEPraw = data.RE_pred - data.NEE;
    GEP_pred_logi = zeros(length(GEPraw),1);

    % Parameterize all-years at once
ind_param(1).GEP_all_gs = find(gs_flag == 1 & ~isnan(GEPraw.*data.NEE_std.*data.Ta.*data.PAR.*data.SM_a_filled) & data.PAR > 15 & data.VPD > 0);
X_in = [data.PAR(ind_param(1).GEP_all_gs) data.Ta(ind_param(1).GEP_all_gs) data.VPD(ind_param(1).GEP_all_gs) data.SM_a_filled(ind_param(1).GEP_all_gs) ];
X_eval = [data.PAR data.Ta data.VPD data.SM_a_filled];
   
    clear options global;
    options.costfun =data.costfun; options.min_method = data.min_method;
    options.f_coeff = NaN.*ones(8,1);

       [c_hat(1).GEP_all_gs, y_hat(1).GEP_all_gs, y_pred(1).GEP_all_gs, stats(1).GEP_all_gs, sigma(1).GEP_all_gs, err(1).GEP_all_gs, exitflag(1).GEP_all_gs, num_iter(1).GEP_all_gs] = ...
        fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
        GEP_pred_logi(gs_flag==1) = y_pred(1).GEP_all_gs(gs_flag==1);
    
% plot functional relationships
[x_Ta, y_Ta, f_Ta, h_Ta] = plot_SMlogi(c_hat(1).GEP_all_gs(3:4), 1); figure(f_Ta); axis([-10 30 0 1]);
xlabel('Ta (C)')
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-Ta_fn_rel'],'-dpng','-r300');

[x_VPD, y_VPD, f_VPD, h_VPD] = plot_SMlogi(c_hat(1).GEP_all_gs(5:6), 1);figure(f_VPD); axis([0 35 0 1]);
xlabel('VPD (hPa?)')
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-VPD_fn_rel'],'-dpng','-r300');

[x_SM, y_SM, f_SM,h_SM] = plot_SMlogi(c_hat(1).GEP_all_gs(7:8), 1);figure(f_SM); axis([0 0.2 0 1]);
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP-VWC_fn_rel'],'-dpng','-r300');

%%%%%% Fix the Ta effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(3:4) = [-10000 100];
GEP_pred_logi_noTa = zeros(length(GEPraw),1);

[c_hat(2).GEP_all_gs, y_hat(2).GEP_all_gs, y_pred(2).GEP_all_gs, stats(2).GEP_all_gs, sigma(2).GEP_all_gs, err(2).GEP_all_gs, exitflag(2).GEP_all_gs, num_iter(2).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noTa(gs_flag==1) = y_pred(2).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noTa = NaN.*ones(length(GEP_pred_logi_noTa),1);
resid_GEP_noTa(ind_param(1).GEP_all_gs) = GEP_pred_logi_noTa(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noTa = figure;clf(f_noTa);
plot(data.Ta(ind_param(1).GEP_all_gs),resid_GEP_noTa(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noTa] = jjb_mov_window_stats(data.Ta(ind_param(1).GEP_all_gs),resid_GEP_noTa(ind_param(1).GEP_all_gs), 0.5, 0.5);
hold on;
plot(mov_avg_GEP_noTa(:,1),mov_avg_GEP_noTa(:,2),'r-','LineWidth',2);
axis([12 30 -10 10]);
xlabel('Ta (C)')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_Ta'],'-dpng','-r300');


%%%%%% Fix the VPD effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(5:6) = [-10000 100];
GEP_pred_logi_noVPD = zeros(length(GEPraw),1);

[c_hat(3).GEP_all_gs, y_hat(3).GEP_all_gs, y_pred(3).GEP_all_gs, stats(3).GEP_all_gs, sigma(3).GEP_all_gs, err(3).GEP_all_gs, exitflag(3).GEP_all_gs, num_iter(3).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noVPD(gs_flag==1) = y_pred(3).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noVPD = NaN.*ones(length(GEP_pred_logi_noVPD),1);
resid_GEP_noVPD(ind_param(1).GEP_all_gs) = GEP_pred_logi_noVPD(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noVPD = figure;clf(f_noVPD);
plot(data.VPD(ind_param(1).GEP_all_gs),resid_GEP_noVPD(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noVPD] = jjb_mov_window_stats(data.VPD(ind_param(1).GEP_all_gs),resid_GEP_noVPD(ind_param(1).GEP_all_gs), 0.5, 0.5);
hold on;
plot(mov_avg_GEP_noVPD(:,1),mov_avg_GEP_noVPD(:,2),'r-','LineWidth',2);
axis([0 25 -10 10]);
xlabel('VPD')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_VPD'],'-dpng','-r300');


%%%%%% Fix the VWC effect.  
clear options global;
options.costfun =data.costfun; options.min_method = data.min_method;
options.f_coeff = NaN.*ones(8,1);
options.f_coeff(7:8) = [-10000 100];
GEP_pred_logi_noSM = zeros(length(GEPraw),1);

[c_hat(4).GEP_all_gs, y_hat(4).GEP_all_gs, y_pred(4).GEP_all_gs, stats(4).GEP_all_gs, sigma(4).GEP_all_gs, err(4).GEP_all_gs, exitflag(4).GEP_all_gs, num_iter(4).GEP_all_gs] = ...
    fitGEP([0.1 40 2 0.5 -2 -0.8 8 180], 'fitGEP_1H1_3L6', X_in,GEPraw(ind_param(1).GEP_all_gs),  X_eval, data.NEE_std(ind_param(1).GEP_all_gs), options);
GEP_pred_logi_noSM(gs_flag==1) = y_pred(4).GEP_all_gs(gs_flag==1);
% Residuals
resid_GEP_noSM = NaN.*ones(length(GEP_pred_logi_noSM),1);
resid_GEP_noSM(ind_param(1).GEP_all_gs) = GEP_pred_logi_noSM(ind_param(1).GEP_all_gs)-GEPraw(ind_param(1).GEP_all_gs);
f_noSM = figure;clf(f_noSM);
plot(data.SM_a_filled(ind_param(1).GEP_all_gs),resid_GEP_noSM(ind_param(1).GEP_all_gs),'k.')
[mov_avg_GEP_noSM] = jjb_mov_window_stats(data.SM_a_filled(ind_param(1).GEP_all_gs),resid_GEP_noSM(ind_param(1).GEP_all_gs), 0.005, 0.005);
hold on;
plot(mov_avg_GEP_noSM(:,1),mov_avg_GEP_noSM(:,2),'r-','LineWidth',2);
axis([0.025 0.15 -10 10]);
xlabel('VWC %')
ylabel('GEP_{pred} - GEP_{meas} [umol CO2]');
print([ls 'Matlab\Data\Diagnostic\Eric - 20191104 analysis\' site '_GEP_resid_VWC'],'-dpng','-r300');

%%%% Part 3: Can we do some sort of analysis of variability in conditions? 
clear options global;
options.f_coeff = NaN.*ones(8,1);
GEP_PAR_only = zeros(length(GEPraw),1);
c_hat_PAR_only = [c_hat(1).GEP_all_gs(1:2) -10000 100 -10000 100  -10000 100];
tmp = fitGEP_1H1_3L6(c_hat_PAR_only,X_eval);
GEP_PAR_only(gs_flag==1) = tmp(gs_flag==1);

% Mean value of scaling factors during non-zero GEP periods
Ta_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(3)-c_hat(1).GEP_all_gs(4).*X_eval(:,2))));
VPD_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(5)-c_hat(1).GEP_all_gs(6).*X_eval(:,3))));
PAR_sf = ((c_hat(1).GEP_all_gs(1)*c_hat(1).GEP_all_gs(2)*X_eval(:,1))./(c_hat(1).GEP_all_gs(1)*X_eval(:,1) + c_hat(1).GEP_all_gs(2)));
VWC_GEP_sf = (1./(1 + exp(c_hat(1).GEP_all_gs(7)-c_hat(1).GEP_all_gs(8).*X_eval(:,4))));

% Throw in a scaling factor for RE: 
VWC_RE_sf = (1./(1 + exp(c_hat(2).RE_logi_gs(4)-c_hat(2).RE_logi_gs(5).*data.SM_a_filled)));

f_GEP_PAR_only = figure(); 
clf(f_GEP_PAR_only);
ctr = 1;
for yr = begin_year:1:end_year
    ind_sf = find(data.Year==yr & GEP_pred_logi>0);
    GEP_sfs(ctr,1) = yr;
    GEP_sfs(ctr,2) = sum(GEP_pred_logi(data.Year==yr).*0.0216);
    GEP_sfs(ctr,3) = sum(GEP_PAR_only(data.Year==yr).*0.0216); 
    GEP_sfs(ctr,4) = sum(GEP_pred_logi_noTa(data.Year==yr).*0.0216); 
    GEP_sfs(ctr,5) = sum(GEP_pred_logi_noVPD(data.Year==yr).*0.0216); 
    
    GEP_sfs(ctr,6) = mean(Ta_sf(ind_sf));
    GEP_sfs(ctr,7) = mean(VPD_sf(ind_sf));
    GEP_sfs(ctr,8) = mean(PAR_sf(ind_sf));
    GEP_sfs(ctr,9) = mean(VWC_GEP_sf(ind_sf));

    GEP_sfs(ctr,11) = sum(RE_pred_logi_gs(data.Year==yr & gs_flag==1).*0.0216); 
    GEP_sfs(ctr,10) = sum(RE_pred_logi_gs2(data.Year==yr & gs_flag==1).*0.0216); 
    GEP_sfs(ctr,12) = mean(VWC_RE_sf(ind_sf)); % This is the sf for RE (VWC)

    ind = find(data.Year==yr);
    subplot(4,1,1);
    h_GEP_pred(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
    subplot(4,1,2);
    h_GEP_PAR_only(ctr) = plot(data.dt(ind),cumsum(GEP_PAR_only(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
    subplot(4,1,3);
    h_GEP_noTa(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi_noTa(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;   
    
    subplot(4,1,4);
    h_GEP_noVPD(ctr) = plot(data.dt(ind),cumsum(GEP_pred_logi_noVPD(ind).*0.0216),'-','Color',clrs(ctr,:)); hold on;
    
%     subplot(3,1,2);
%     h_GEP_PAR_only(ctr) = plot(data.dt(ind),cumsum(GEP_PAR_only(ind)),'-','Color',clrs(ctr,:)); hold on;

   ctr = ctr+1; 
end

legend(h_GEP_pred,num2str((begin_year:1:end_year)'),'Location','NorthWest')

GEP_sfs(:,6) = GEP_sfs(:,6)./max(GEP_sfs(:,6));
GEP_sfs(:,7) = GEP_sfs(:,7)./max(GEP_sfs(:,7));
GEP_sfs(:,8) = GEP_sfs(:,8)./max(GEP_sfs(:,8));
GEP_sfs(:,9) = GEP_sfs(:,9)./max(GEP_sfs(:,9));
GEP_sfs(:,12) = GEP_sfs(:,12)./max(GEP_sfs(:,12));
GEP_sfs(:,13) = GEP_sfs(:,6).*GEP_sfs(:,7).*GEP_sfs(:,8).*GEP_sfs(:,9);



