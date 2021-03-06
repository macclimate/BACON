function [y_filled y_model] = jjb_WLR_gapfill(x, y, win_size, bin_avg_flag, x_range, y_range)
%% jjb_WLR_gapfill.m
%%% Fills gaps in data using a linear regression and window of specified
%%% size
%%% x: independent variable
%%% y: dependent variable to be gap-filled
%%% win_size: size of window (in data points) to be used to make
%%% regressions

if nargin == 3
    bin_avg_flag = 'off';
end

if nargin == 4;
    x_range = [min(x) max(x)];
    y_range = [min(y) max(y)];
end
    
y_model(1:length(y),1) = NaN;
y_filled(1:length(y),1) = y;

%%% Calculate the number of expected windows to make across the data
num_loops = floor(length(y)/win_size);
%%% Span is half the window size -- number of datapoints to consider on
%%% each side of the middlepoint of the window
span = win_size/2;
%%% Specify the rows in the data that will be the mid-points of the data
loop_int = (span:win_size:length(y))';
loop_int(1,1) = span+1;  %% Add one to avoid sampling 0th point at start

%%% If the window size does not fit perfectly into the vector, adjust the
%%% size of the last window to accomodate
if rem(length(y),win_size) ~= 0 %span
    num_loops = num_loops +1;
    loop_int(num_loops,1) = length(y)-span;
end


%% Run loop to find regression
for ctr = 1:1:length(loop_int)
    %%% proper rows to be considered inside window
    y_rows(:,1) = (loop_int(ctr) - span : loop_int(ctr) + span);
%     %%% section of actual data in selected rows
%     y_sec(:,1) = y(y_rows);
    %%% find good data inside of selected rows
    y_rows_good(:,1) = y_rows(~isnan(y(y_rows)) & ~isnan(x(y_rows)));
    %%% Calculate linear regression between x and y
    
    if strcmp(bin_avg_flag,'on') == 1
        b_avg = jjb_blockavg(x(y_rows_good), y(y_rows_good), 25, max(y_range), min(y_range));
        good_b_avg = find(~isnan(b_avg(:,1)) & ~isnan(b_avg(:,2)));
        p_x = polyfit(b_avg(good_b_avg,1),b_avg(good_b_avg,2),1);
     else
    p_x = polyfit(x(y_rows_good), y(y_rows_good),1);
    end

    %%% If entire window is empty, make entries NaN
    if isequal(p_x(1,1),0) == 1 && isequal(p_x(1,2),0) == 1;
        p_x(:,:) = NaN;
    end
    
    %%% Modeled values for y for entire period;
    y_model(y_rows,1) = polyval(p_x,x(y_rows,1));
    
%     %%% Evaluate regression to fill gaps in window
%     y_sec(isnan(y_sec)) = polyval(p_x,x(isnan(y_sec)));
%     %%% Fill modelled data into the original data
%     y_new(y_rows,1) = y_sec(:,1);
   
%% FOR TESTING ONLY ************
%     figure(1) 
%     clf
%     plot(x(y_rows_good),y(y_rows_good),'.');
%     hold on
%     x_test = (min(x_range):(max(x_range)-min(x_range))/20:max(x_range))';
%     y_test = polyval(p_x,x_test);
%     plot(x_test,y_test,'r-');
%     plot(b_avg(:,1),b_avg(:,2),'go');
%% ***********************


% %% FOR TESTING ONLY ************   
%  y_test2 = polyval(p_x,x(y_rows,1));
%     %% FOR TESTING ONLY ************
%     figure(2) 
%     clf
%     plot(y_sec,'b')    
%     hold on
%     plot(y_test2,'r')
%     plot(x(y_rows,1),'k')
% %     
%% ***********************
    
    
    
    clear y_rows_good  y_rows p_x;
end


y_filled(isnan(y_filled),1)  = y_model(isnan(y_filled),1);

