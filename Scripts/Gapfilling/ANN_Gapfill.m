function [nnet] = ANN_Gapfill(inputs, target, year_list, method_flag, num_nodes, disp_flag)
%%% Typically, inputs will be a matrix of input column vectors of
%%% environmental (or supplementary) data.
%%% target is the observed (and cleaned: fp, u* filtered) NEE values
%%% year_list is a column vector of the year of the measurement
%%% corresponding to the row elements in both input and target.  If using
%%% method_flag=1 (all years), then year_list may be made empty ([]).
%%%
%%% This function should work for both NEE and LE
%%% Index of method_flag:
% 1 - all years:
% 2 - individual years:

%%% Revision History:
%%% March 30, 2011:
% - Modified function so that any input for disp_flag (other than [] or '') disables the NN
% progress screen

if nargin == 3
    method_flag = 2; % default method is to fit each year separately.
    num_nodes = 30;  % default number of nodes is set to 30.
    disp_flag = '';
elseif nargin ==4
    num_nodes = 30;  % default number of nodes is set to 30.
    disp_flag = '';
end
year_start = min(year_list);
year_end = max(year_list);

%%% Prepare filled dataset:
NEE_sim = NaN.*ones(size(inputs,1),1);

if ~isempty(disp_flag)==1
    disp(['Working on NNET: ' disp_flag])
end

switch method_flag
    case 1 % Where we are fitting the data to all-years
        %%% Run training:
        ind_use_all = find(~isnan(prod(inputs,2)) & ~isnan(target));
        training_inputs = inputs(ind_use_all,:);
        training_target = target(ind_use_all,:);
        nnet.net = newfit(training_inputs',training_target',num_nodes);
        if ~isempty(disp_flag)==1
            nnet.net.trainParam.showWindow = false;
        end
        nnet.net =train(nnet.net,training_inputs',training_target');
        %%% Prediction:
        %%% Index for prediction -- find where no NaNs in met data:
        ind_sim_all = find(~isnan(prod(inputs,2)));
        sim_inputs = inputs(ind_sim_all,:);
        %%% Run NN to predict
        [Y,Pf,Af,E,perf] = sim(nnet.net,sim_inputs');
        Y = Y';
        % Assign predicted data to proper row in ouput
        NEE_sim(ind_sim_all) = Y;
    case 2 % Where we are fitting the data to individual years:
        ctr = 1;
        for yr = year_start:1:year_end
            disp(num2str(yr));
            %%% Run training: %%%%%%%%%%%
            ind_use(ctr).net = find(~isnan(prod(inputs,2)) & ~isnan(target) & year_list == yr);% & (data.PAR > 15 | (data.PAR<=15 & data.Ustar >= Ustar_th)) & data.Year ==  );
            training_inputs = inputs(ind_use(ctr).net,:);
            training_target = target(ind_use(ctr).net,:);
            nnet(ctr).net = newfit(training_inputs',training_target',num_nodes);
            if ~isempty(disp_flag)==1
                nnet(ctr).net.trainParam.showWindow = false;
            end
            
            nnet(ctr).net=train(nnet(ctr).net,training_inputs',training_target');
            clear training_inputs training_target;
            %%% Prediction:
            %%% Index for prediction -- find where no NaNs in met data:
            ind_sim = find(~isnan(prod(inputs,2)) & year_list == yr);
            sim_inputs = inputs(ind_sim,:);
            %%% Run NN to predict
            [Y,Pf,Af,E,perf] = sim(nnet(ctr).net,sim_inputs');
            Y = Y';
            % Assign predicted data to proper row in ouput (makes rows of predicted
            % variable match the rows of the input LE file:
            NEE_sim(ind_sim) = Y;
            clear Y Pf Af E perf ind_sim sim_inputs
            ctr = ctr+1;
        end
end

nnet(1).NEE_sim = NEE_sim;
% Do stats and calculate sums:
nnet(1).sumstats = NEE_sums_stats(nnet(1).NEE_sim, target, year_list);
