function [final_out f_out] = mcm_Gapfill_HOWLAND(data, Ustar_th, plot_flag)
f_out = [];
%%%%%%%%
warning off all
%%%%%%%%

year_start = data.year_start;
year_end = data.year_end;

%% Ustar Threshold -- default is simple fixed threshold 
%%% Enforced if data.Ustar_th does not exist:
if isfield(data,'Ustar_th')
    if plot_flag ~=-9
        disp('u*_{TH} already established -- not calculated.');
    end
else
    data.Ustar_th = Ustar_th.*ones(length(data.Year),1);
end

%%% Standard Deviation Estimates:
%%% If the field exists, then we'll assume we want to use WSS.
%%% 1. If NEE_std does not exist, use OLS:
if isfield(data,'NEE_std')==0
    data.costfun = 'OLS';
    data.NEE_std = ones(length(data.Year),1); 
else
    % If it does exist, check if data.costfun exists:
    if isfield(data,'costfun')==1
        % If data.costfun exists, do nothing - we're all set
        if strcmp(data.costfun,'OLS')
        data.NEE_std = ones(length(data.Year),1); 
        end
    else
        % If it doesn't, assume we want WSS, since there is std data:
        data.costfun = 'WSS';
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Part 1: Respiration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate Rraw:
Rraw(1:length(data.NEE),1) = NaN;
RE_model(1:length(data.NEE),1) = NaN;

% ind_Rraw = find((data.Ustar >= data.Ustar_th & ~isnan(data.NEE) & data.PAR < 15) |... % growing season
%     (data.Ustar >= data.Ustar_th & ~isnan(data.NEE) & ((data.dt < 85 | data.dt > 335) & data.Ts5 < 0.2)) );                             % non-growing season
%  ind_Rraw = find((data.Ustar >= data.Ustar_th & ~isnan(data.NEE.*data.NEE_std) & data.PAR < 15 ) |... % growing season
%         (data.Ustar >= data.Ustar_th & ~isnan(data.NEE.*data.NEE_std) &  ((data.Ts2<0.5 & data.Ta < 2)|(data.Ts2<2 & data.Ta < 0)) ) );% non-growing season
% ind_Rraw = find(data.Ustar >= data.Ustar_th & data.GEP_flag == 0 & ~isnan(data.NEE)); 
ind_Rraw = find((data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.GEP_flag == 0 & ~isnan(data.NEE)); % all-seasons

Rraw(ind_Rraw) = data.NEE(ind_Rraw);

%%% Run through Ts_RE_logistic function:
ctr = 1;
ind_param = struct;

for year = year_start:1:year_end
%     ind_param(ctr).RE = find((data.Year == year & data.Ustar >= data.Ustar_th & ~isnan(data.Ts5) & ~isnan(data.NEE.*data.NEE_std) & data.PAR < 15) |... % growing season
%         (data.Year == year & data.Ustar >= data.Ustar_th & ~isnan(data.NEE.*data.NEE_std) & data.Ts5 < -1  ) );
%           ind_param(ctr).RE = find((data.Year == year & data.Ustar >= data.Ustar_th & ~isnan(data.Ts5.*data.SM_a_filled.*data.NEE.*data.NEE_std) & data.PAR < 15 ) |... % growing season
%             (data.Year == year & data.Ustar >= data.Ustar_th & ~isnan(data.NEE.*data.NEE_std.*data.SM_a_filled) & ((data.Ts2<0.5 & data.Ta < 2)|(data.Ts2<2 & data.Ta < 0))  ) );                                   % non-growing season
% ind_param(ctr).RE = find(data.Year == year & data.Ustar >= data.Ustar_th & data.RE_flag == 2 & ~isnan(data.NEE));
ind_param(ctr).RE = find(data.Year == year & (data.PAR >= 15 |data.Ustar >= data.Ustar_th) & data.RE_flag == 2 & ~isnan(data.NEE));

    %%%%% ******* Add in line here to filter out OPEC-measured flux data???? **
    
    %%% Set up fourier parameters
    e = 2.*pi().*data.dt(ind_param(ctr).RE,1)./365;
    cos_e = cos(e);
    sin_e = sin(e);
    cos_2e = cos(2.*e);
    sin_2e = sin(2.*e);
    
    %%% Run regression:
    X = [ones(length(cos_e),1) cos_e sin_e cos_2e sin_2e];
    [b,bint,r,rint,stats] = regress_analysis(data.NEE(ind_param(ctr).RE),X,0.05);
    %%% Predict Respiration:
    e_dt = 2.*pi().*data.dt(data.Year == year)./365;
    RE_model(data.Year == year,1) = b(1) + b(2).*cos(e_dt) + b(3).*sin(e_dt) + b(4).*cos(2.*e_dt) + b(5).*sin(2.*e_dt);
end
clear stats;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% PHOTOSYNTHESIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options.costfun = data.costfun; options.min_method ='NM';
GEPraw = RE_model - data.NEE;
% GEPraw(data.PAR < 15) = NaN;
%%% Updated May 19, 2011 by JJB: %%%%%%%%%%%
GEPraw(data.PAR < 15 | (data.PAR <= 150 & data.Ustar < data.Ustar_th) ) = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GEP_model = zeros(length(GEPraw),1);
GEP_pred = NaN.*ones(length(GEPraw),1);
%%% For this approach, we need to separate each year into periods of equal
%%% length (could technically do all years together at once, providing we
%%% use the same sized periods all the way through, and can keep track of
%%% where we are in the data).
% starts =
% ends =
% dtime = [];
yr_ctr = 1;
for year = year_start:1:year_end
    [st_en] = sel_st_ends(year);
%     dtime = [dtime; (1:1:st_en(end,2))'];
    ctr = 1;
    for j = 1:1:12
%         ind_param = find(data.Ts2 > 1 & data.Ta > 2 & data.PAR > 15 & ~isnan(GEPraw) & data.Year == year & ~isnan(data.NEE_std) & data.recnum >= st_en(j,1) & data.recnum <= st_en(j,2));
  ind_param_GEP = find(data.Year == year & ~isnan(GEPraw.*data.NEE_std.*data.PAR) & data.GEP_flag==2 & data.recnum >= st_en(j,1) & data.recnum <= st_en(j,2));
%   ind_param_GEP = find(data.Year == year & ~isnan(GEPraw.*data.NEE_std.*data.PAR) & data.GEP_flag==2 & ...
%       data.recnum >= st_en(j,1) & data.recnum <= st_en(j,2) & ( (data.PAR >= 15 & data.PAR <200 & data.Ustar >= data.Ustar_th) | data.PAR >= 200 ));
    
        if isempty(ind_param_GEP)==1
            % Set GEP to zero if there are no favourable periods for GEP:
        GEP_pred(data.Year == year & data.recnum >= st_en(j,1) & data.recnum <= st_en(j,2)) = 0;    
        else
            % Use M-M relationship btw GEP and PAR to predict for the
            % entire period:
        clear global;
        [c_hat(yr_ctr,ctr).GEP, y_hat(yr_ctr,ctr).GEP, y_pred(yr_ctr,ctr).GEP, stats(yr_ctr,ctr).GEP, sigma(yr_ctr,ctr).GEP, err(yr_ctr,ctr).GEP, exitflag(yr_ctr,ctr).GEP, num_iter(yr_ctr,ctr).GEP] = ...
            fitGEP([0.1 40], 'fitGEP_1H1', data.PAR(ind_param_GEP),GEPraw(ind_param_GEP),  data.PAR(data.Year == year), data.NEE_std(ind_param_GEP), options);
        GEP_pred(data.Year == year & data.recnum >= st_en(j,1) & data.recnum <= st_en(j,2)) = ...
            y_pred(yr_ctr,ctr).GEP(data.recnum(data.Year == year) >= st_en(j,1) & data.recnum(data.Year == year) <= st_en(j,2));
        end
        ctr = ctr+1;
    end
    yr_ctr = yr_ctr+1;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%  Final Filling & Output  %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Clean NEE (ustar filtering):
NEE_raw = data.NEE;
NEE_clean = NEE_raw;
% NEE_clean(data.PAR < 15 & data.Ustar < data.Ustar_th,1) = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% The following was changed to 150 on May 19, 2011 by JJB
% This change was implemented to reduce the GEP < 0 events that occur at 
% sundown/sunup that get included into NEE, but get excluded from GEP (set
% to zero).  This change will make things more consistent between NEE and
%  (RE_filled - GEP_filled).
NEE_clean((data.PAR < 15 & data.Ustar < data.Ustar_th) | ...
    (data.PAR < 150 & data.GEP_flag>=1 & data.Ustar< data.Ustar_th),1) = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Fill RE - Use raw data when Ustar > threshold; otherwise, use model+tvp
RE_filled(1:length(Rraw),1) = RE_model;
RE_filled(~isnan(Rraw) & data.Ustar > data.Ustar_th,1) = Rraw(~isnan(Rraw) & data.Ustar > data.Ustar_th,1);

%%% Fill GEP:
GEP_filled = zeros(length(GEPraw),1);
% ind_GEP = find(data.PAR >= 15 & ((data.dt > 85 & data.dt < 330 & (data.GDD > 8 | data.Ts5 >= 1 & data.Ta > 2)) ...
%                 | data.dt > 330 & data.Ts5 >= 1.25 & data.Ta > 2));
% ind_GEP = find(data.PAR >= 15 & ((data.dt > 85 & data.dt < 330 & (data.Ts2 >= 1 & data.Ta > 2)) ...
%     | (data.dt > 330 | data.dt < 85) & data.Ts2 >= 2 & data.Ta > 2));
ind_GEP = find(data.GEP_flag>=1);
GEP_model(ind_GEP,1) = GEP_pred(ind_GEP,1);
% fill any nans in GEPraw with GEP_model:
GEPraw(isnan(GEPraw) | GEPraw < 0,1) = GEP_model(isnan(GEPraw) | GEPraw < 0,1);
% Now, substitute GEPraw into GEP_filled when applicable (set by ind_GEP)
GEP_filled(ind_GEP) = GEPraw(ind_GEP);

%%% Fill NEE:
NEE_filled = NEE_clean;
NEE_filled(isnan(NEE_filled),1) = RE_filled(isnan(NEE_filled),1) - GEP_filled(isnan(NEE_filled),1);

%% Plot the final output:
if plot_flag ~=-9
    f_out = figure('Name', 'Final Filled Data');clf
    subplot(2,1,1); title('NEE');
    plot(NEE_filled); hold on;
    plot(NEE_clean,'k.')
    legend('filled','measured');
    subplot(2,1,2);
    hold on;
    plot(RE_filled,'r')
    plot(-1.*GEP_filled,'g')
    legend('RE','GEE');
end
%% The final loop to calculate annual sums and check for holes remaining in data:
final_out = struct;
sum_labels = {'Year';'NEE_filled';'NEE_pred'; 'GEP_filled';'GEP_pred';'RE_filled';'RE_pred'};

    %%% Assign data to master file:
    master.Year = data.Year;
    master.NEE_clean = NEE_clean;
    master.NEE_filled = NEE_filled;
    master.NEE_pred = RE_model-GEP_model;
    master.RE_filled = RE_filled;
    master.GEP_filled = GEP_filled;
    master.GEP_pred = GEP_model;
    master.RE_pred = RE_model;
    master.c_hat = c_hat;

    %%% Do Sums:
    ctr = 1;
    for year = year_start:1:year_end
        if year == 2002;
            NEE_filled(1:8,1) = NEE_filled(9,1);
            RE_filled(1:8,1) = RE_filled(9,1);
            GEP_filled(1:8,1) = GEP_filled(9,1);
        end
        master.sums(ctr,1) = year;
        master.sums(ctr,2) = sum(master.NEE_filled(data.Year==year)).*0.0216;
        master.sums(ctr,3) = sum(master.NEE_pred(data.Year==year)).*0.0216;
        master.sums(ctr,4) = sum(master.GEP_filled(data.Year==year)).*0.0216;
        master.sums(ctr,5) = sum(master.GEP_pred(data.Year==year)).*0.0216;
        master.sums(ctr,6) = sum(master.RE_filled(data.Year==year)).*0.0216;
        master.sums(ctr,7) = sum(master.RE_pred(data.Year==year)).*0.0216;
        ctr = ctr + 1;
    end
final_out.master = master;
final_out.master.sum_labels = sum_labels;
final_out.tag = 'HOWLAND';   

if plot_flag ~=-9
disp('mcm_Gapfill_HOWLAND done!');
end
end

%% %%%%%%%% END OF MAIN FUNCTION: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [st_en] = sel_st_ends(year)
yr_len = yr_length(year,30);
b = linspace(1,yr_len,13);
st_en(:,1) =(floor(b(1:12)))';
st_en(:,2) =(floor(b(2:13)))+1';
st_en(end,2) = st_en(end,2) - 1;
end


% ctr = 1;
% for yr_ctr = year_start:1:year_end
%     holes(ctr,1) = yr_ctr;
%     try
%         %%% Special fix for 2002 -- we lost 8 datapoints due to UTC timeshift:
%         if yr_ctr == 2002;
%             NEE_filled(1:8,1) = NEE_filled(9,1);
%             RE_filled(1:8,1) = RE_filled(9,1);
%             GEP_filled(1:8,1) = GEP_filled(9,1);
%         end
% 
%         NEE_sum(ctr,1) = sum(NEE_filled(data.Year== yr_ctr,1)).*0.0216  ; % sums is annual sum
%         GEP_sum(ctr,1) = sum(GEP_filled(data.Year== yr_ctr,1)).*0.0216  ;
%         RE_sum(ctr,1) = sum(RE_filled(data.Year== yr_ctr,1)).*0.0216  ;       
%         holes(ctr,2:4) = [length(find(isnan(NEE_filled(data.Year == yr_ctr,1)))) ...
%                         length(find(isnan(RE_filled(data.Year == yr_ctr,1)))) ... 
%                         length(find(isnan(GEP_filled(data.Year == yr_ctr,1))))] ;
%     catch
%         disp(['something went wrong calculating sums, year: ' num2str(yr_ctr)]);
%         NEE_sum(ctr,1) = NaN;
%         GEP_sum(ctr,1) =  NaN;
%         RE_sum(ctr,1) =  NaN;
%         holes(ctr,1:3) = NaN;
%     end
% 
% ctr = ctr+1;
% end
% if plot_flag == 1;
% sums = [holes(:,1) NEE_sum(:,1) RE_sum(:,1) GEP_sum(:,1)];
% disp('Number of NaNs outstanding in data: Year | NEE | RE | GEP ');
% disp(holes);
% disp('Annual Totals: Year | NEE | RE | GEP ');
% disp(sums)
% end
% %% Compile data and save:
% master.data = [data.Year NEE_raw NEE_clean NEE_filled GEP_filled RE_filled RE_model GEP_pred];
% master.sums = sums;
% master.labels = {'Year'; 'NEE_raw'; 'NEE_clean'; 'NEE_filled'; 'GEP_filled'; 'RE_filled'; 'RE_model'; 'GEP_model'};
% 
% % 
% % master.data.Year = data.Year(:,1);
% % master.data.NEE_raw = NEE_raw(:,1);
% % master.data.NEE_clean = NEE_clean(:,1);
% % master.data.NEE_filled = NEE_filled(:,1);
% % master.data.GEP_filled = GEP_filled(:,1);
% % master.data.RE_filled = RE_filled(:,1);
% % 
% % master.data.RE_model = RE_tvp_adj;  
% % master.data.GEP_model = GEP_tvp_adj;  
% % master.data.sums = sums;
% 
% 
% 
% % save([save_path site '_FCRN_GapFilled_' num2str(year_start) '_' num2str(year_end) '_ust_th = ' num2str(Ustar_th)  fp_options.addtoname '.mat'],'master');
% disp('mcm_Gapfill_HOWLAND done!');
% end


