function [daily_avg daily_med daily_sum daily_max daily_min daily_std nans_per_day] = daily_stats(data, pts_per_day)
%% daily_stats.m 
%%% This function calculates all sorts of fun stats on the daily timestep,
%%% provided that you tell it how many points make up a day.

%%% Make sure the timeseries is the right length
if rem(length(data),pts_per_day) ~= 0
    disp('The inputted points per day does not divide evenly into the length of data -- please recheck,');
    disp('Or pad the timeseries with an appropriate number of NaNs')
end

%%% Reshape the data to be in columns that each represent a day
rs = reshape(data,pts_per_day,[]);

%%% Cycle through each day
[r c] = size(rs);
for i = 1:1:c
%     disp(i);
    oks = find(~isnan(rs(:,i)));
    % number of nans in each day
    nans_per_day(i,1) = pts_per_day - length(oks);
    % nan mean
    if length(oks) >= pts_per_day/2
        
    daily_avg(i,1) = mean(rs(oks,i));
    daily_med(i,1) = median(rs(oks,i));
    daily_sum(i,1) = daily_avg(i,1).*48;
    daily_max(i,1) = max(rs(oks,i));
    daily_min(i,1) = min(rs(oks,i));
    daily_std(i,1) = std(rs(oks,i));
    else
      daily_avg(i,1) = NaN;
    daily_med(i,1) = NaN;
    daily_sum(i,1) = NaN;
    daily_max(i,1) = NaN;
    daily_min(i,1) = NaN;
    daily_std(i,1) = NaN;  
    end
end
    
