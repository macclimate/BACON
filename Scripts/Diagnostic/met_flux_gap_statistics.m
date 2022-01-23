%%% This function calculates the footprint & ustar data coverage
%%% Variables
% site = 'TP02';
% site = 'TP02';
% columns in sites variable
%%% 1. site name
%%% 2. Year start for analysis
%%% 3. Year end for analysis
%%% 4. Master file column numbers for Ta, WS, PAR, Ts5
sites = {'TP39', 2003,2020,[50,56,47,61];'TP74', 2008,2020,[42 44 39 48];'TP02', 2008,2020,[42 44 39 49];'TPD', 2012,2020,[48 50 39 56]};
load_path = 'D:\Matlab\Data\';
% load_path = '\\130.113.210.243\fielddata\Matlab\Data\';
% load_path = '/1/fielddata/Matlab/Data/'; On data PC
% begin_year = 2012;
% end_year = 2020;

for j = 1:1:size(sites,1)
    site = sites{j,1};
    begin_year = sites{j,2}; 
    end_year = sites{j,3};
    
%% Extract the ustar thresholds for the site by year:
gf = load([load_path 'Flux\Gapfilling\' site '\NEE_GEP_RE\Default\' site '_Gapfill_NEE_default.mat']); %% Load gapfilling model outputs
right_branch = 3; % 3 = SiteSpec_region approach
% gf.master(right_branch).tag
[years,ia] = unique(gf.master(right_branch).Year,'rows');
Ustar_th = [years gf.master(right_branch).Ustar_th(ia)]; % table of [year | Ustar_th]

%% Load Master File:

load([load_path 'Master_Files/' site '/' site '_data_master.mat']);
gf_input = load([load_path 'Master_Files/' site '/' site '_gapfill_data_in.mat']);
[gf_input.data] = trim_data_files(gf_input.data,begin_year,end_year, 1);

NEE_filled_col = find(strcmp('GapFilledPIPref_NEE',master.labels(:,1))==1);
NEE_meas_col = find(strncmp('NetEcosystemExchange_AbvCnpy',master.labels(:,1),length('NetEcosystemExchange_AbvCnpy'))==1);

ctr = 1;
for i = begin_year:1:end_year
    %%% FLUX DATA
    ind = find(gf_input.data.Year==i);
    ind2 = find(master.data(:,1)==i);
    prop_meas(ctr,1) = sum(~isnan(gf_input.data.NEE(ind,1)))./length(ind);
    prop_fp_pass(ctr,1) = sum(~isnan( gf_input.data.NEE(ind,1).*gf_input.data.Kljun_Regional_90flag(ind,1) )) ./length(ind);
%     ind3 = find(master.data(ind2,111) == gf_input.data.NEE(ind,1));
    prop_ustar_pass(ctr,1) = length(find(master.data(ind2,NEE_filled_col) == gf_input.data.NEE(ind,1))) ./length(ind);
%     mcm_GEP_RE_flag
    table_out(ctr,1:4) = [i prop_meas(ctr,1) prop_fp_pass(ctr,1) prop_ustar_pass(ctr,1)];
    
    %%% MET DATA
    % Take the average availability of Ta, WS, PAR, Ts
    Ta = master.data(ind2,sites{1,4}(1));
    WS = master.data(ind2,sites{j,4}(2));
    PAR = master.data(ind2,sites{j,4}(3));
    Ts = master.data(ind2,sites{j,4}(4));
%     all_met = [Ta;WS;PAR;Ts];
    table_out(ctr,5:8) = [length(find(~isnan(Ta)))./length(Ta) length(find(~isnan(WS)))./length(WS) length(find(~isnan(PAR)))./length(PAR) length(find(~isnan(Ts)))./length(Ts) ];
    
    clear all_met
    ctr = ctr + 1;
end

%%% 
variable_names = {'year' 'flux_pMeasured' 'flux_pFPpassing' 'flux_pUstarThpassing' 'Ta_pPassing'  'WS_pPassing'  'PAR_pPassing' 'Ts_pPassing'};
T = array2table(table_out,'VariableNames',variable_names);
clear table_out prop_meas prop_fp_pass prop_ustar_pass ind ind2;
writetable(T,[load_path 'Diagnostic/gap_analysis/' site '.csv']);
end

% ind2 = find(master.data(:,1)>=begin_year & master.data(:,1)<=end_year);
% plot(master.data(ind2,NEE_filled_col),'b');hold on;
% plot(gf_input.data.NEE,'r'); hold on;
% 
% figure(2);clf;
% plot(master.data(ind2,NEE_meas_col),'b');hold on;
% plot(gf_input.data.NEE,'r'); hold on;
