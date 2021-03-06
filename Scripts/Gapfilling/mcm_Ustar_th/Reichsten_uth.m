function [out] = Reichsten_uth(Fc, T, Ustar, RE_flag)
%%% Reichsten_uth.m
%%% usage: [u_th_est final_u_th] = Reichsten_uth(Fc, T, Ustar, RE_flag)
%%% This function performs the u* threshold determination scheme proposed
%%% by Reichstein (2005).  This function works in the following manner:
%%% 1. Data is used only for periods when respiration is the only exchange
%%% occuring (nighttime or daytime non-growing-season)
%%% 2. Data is sorted into 6 Temperature quantiles
%%% 3. Data in each T quantile is sorted into 20 u* classes
%%% 4. Mean Fc in each u* class is calculated.
%%% 5. u*_th is determined as the lowest u* class where the Mean Fc value
%%% is equal to 99% (or 95%) of the mean of the higher classes' Fc.
%%% 6. Provided that the correlation between T and u* are low for the given
%%% T class, the suggested u*_th is accepted.
%%% 7. The final u*_th estimate is the median of all accepted u*_th for the
%%% T classes.
%%%

T = T(RE_flag ==1);
Fc = Fc(RE_flag ==1);
Ustar = Ustar(RE_flag ==1);

%% Step 1: Sort data into T Quantiles and then u* quantiles
[T_sort1 ind_sort1] = sort(T, 'ascend');
Fc_sort1 = Fc(ind_sort1); Ustar_sort1 = Ustar(ind_sort1);

%%% Separate data into 6 quantiles:
[quant_index1] = jjb_quantile_index(length(T_sort1), 6);

%%% Cycle through the T quantiles
for q1 = 1:1:length(quant_index1)
    ind_st = quant_index1(q1,1);
    ind_end = quant_index1(q1,2);
    
    Ustar_sort1_tmp = Ustar_sort1(ind_st:ind_end,1);
    Ustar_sort1_use = Ustar_sort1_tmp(~isnan(Ustar_sort1_tmp),1);
    T_sort1_tmp = T_sort1(ind_st:ind_end,1);
    T_sort1_use = T_sort1_tmp(~isnan(Ustar_sort1_tmp),1);
    Fc_sort1_tmp = Fc_sort1(ind_st:ind_end,1);
    Fc_sort1_use = Fc_sort1_tmp(~isnan(Ustar_sort1_tmp),1);
    
    
    %%% Correlation coefficient for T and u* (Use later):
    try
        T_ust_corr(q1,1) = corr(T_sort1_use,Ustar_sort1_use);
    catch
        T_ust_corr(q1,1) = NaN;
    end
    
    %%% Sort Ustar within each Temperature quantile
    [Ustar_sort2 ind_sort2] = sort(Ustar_sort1_use, 'ascend');
    [quant_index2] = jjb_quantile_index(length(Ustar_sort2), 20);
    
    T_sort2 = T_sort1_use(ind_sort2);
    Fc_sort2 = Fc_sort1_use(ind_sort2);
    
    %%% Cycle through the u* quantiles for each T quantile
    for q2 = 1:1:length(quant_index2)
        ind_st2 = quant_index2(q2,1);
        ind_end2 = quant_index2(q2,2);
        %%%% Average Tempature:
        if isempty(T_sort2(ind_st2:ind_end2,1))== 1; T_mean(q1,q2) = NaN;
        else T_mean(q1,q2) = nanmedian(T_sort2(ind_st2:ind_end2,1)); end
        %%%% Average u*
        if isempty(Ustar_sort2(ind_st2:ind_end2,1))== 1; Ustar_mean(q1,q2) = NaN;
        else Ustar_mean(q1,q2) = nanmedian(Ustar_sort2(ind_st2:ind_end2,1)); end
        %%%% Average Fc
        if isempty(Fc_sort2(ind_st2:ind_end2,1))== 1; Fc_mean(q1,q2) = NaN;
        else Fc_mean(q1,q2) = nanmedian(Fc_sort2(ind_st2:ind_end2,1)); end
    end
end

%% Step 2: Criteria for selecting appropriate u*_th:

good_rows = zeros(size(Fc_mean,1),1);
for tclass = 1:1:size(Fc_mean,1)
    
    for uclass = 1:1:size(Fc_mean,2)-1
        Fc_ratio(tclass,uclass) = Fc_mean(tclass,uclass)./(mean(Fc_mean(tclass, uclass+1:end)));
    end
    
    right_col = find(Fc_ratio(tclass,:)>=0.99, 1,'first');
    if isempty(right_col)
        u_th_est(tclass,1) = inf; %Ustar_mean(tclass,size(Fc_mean,2));
        good_rows(tclass,1) = -1;
    elseif T_ust_corr(tclass,1) > 0.4 || isnan(T_ust_corr(tclass,1))==1
        u_th_est(tclass,1) = NaN;
        good_rows(tclass,1) = 0;
    else
        u_th_est(tclass,1) = Ustar_mean(tclass, right_col);
        good_rows(tclass,1) = 1;
    end
end

final_u_th = median(u_th_est(good_rows==1,1));
if length(find(good_rows==1)) < 2
    disp(['Reichstein_uth.m --> Warning: u*_{TH} estimated from ' num2str(length(find(good_rows==1))) ' of a possible ' num2str(size(Fc_mean,1)) ' T classes.']);
end
out.u_th_est = u_th_est;
% out.final_u_th =  final_u_th;

% if nargout == 1;
%     varargout = out;
% elseif nargout ==2;
%     varargout{1} = u_th_est; 
%         varargout{2} = final_u_th;
% end
end