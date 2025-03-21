%% Idealized processing for 2024
%%% Assumes that all cleaning (met, flux, PPT) has been taken care of. 
%%% This can be run by successively highlighting sections and hitting F9,
%%% or by running the entire block (Ctrl+Enter).

site_met = {'TP39', 2002:2023;'TP74', 2003:2023;'TP02', 2003:2023;'TPD', 2012:2023; 'TP_PPT',2012:2023; 'TPAg',2020:2023; 'TP_PPT',2008:2023};
site_CPEC_met = {'TP39', 2002:2023;'TP74', 2003:2023;'TP02', 2003:2023;'TPD', 2012:2023; 'TPAg',2020:2023};
site_CPEC = {'TP39', 2003:2023;'TP74', 2008:2023;'TP02', 2008:2023;'TPD', 2012:2023; 'TPAg',2020:2023};
site_output = {'TP39',2002:2023;'TP74', 2002:2023;'TP02', 2002:2023;'TPD', 2012:2023; 'TPAg',2020:2023}; %; 'TP_VDT',2020};
progress = 0;

%%%% Fill met and ppt data:
mcm_PPTfill(2024)
mcm_metfill(2023,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
progress = 1;

%%% SHF Calculation %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_CPEC_met)-1
    mcm_SHF(2024,site_CPEC_met{i,1});
end
progress = 2;

%%% Storage and NEE calc %%%%%%%%%%%%%%%%%%
% be sure to update params.m before running for the first time in the year.
for i = 1:1:length(site_CPEC)
    mcm_CPEC_storage(2013:2023,site_CPEC{i,1},1,1);
end
progress = 3;

%%% First compile %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
mcm_data_compiler(2008:2024,'TP_PPT','met',-2); % Recompile TP_PPT.
progress = 4;

%%% Run Footprints %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end
progress = 5;

%%% LE,H Gapfilling %%%%%%%%%%%%%%%%%%
% ** Before running gapfilling, need to update dates in files at: D:\Matlab\Config\Flux\Gapfilling\Defaults
for i = 1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%%% NEE Gapfilling %%%%%%%%%%%%%%%%%%
% ** Before running, need to update NEE Gapfilling (after editing defaults in D:\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 3%1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off
try
    fid = fopen(diary_filename,'r');
    
    fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
    eof = 0;
    while eof==0
        tline = fgetl(fid);
        if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
            fprintf(fid2,'%s\n',tline);
        end
        eof = feof(fid);
    end
    fclose(fid);fclose(fid2);
    progress = 7;
catch
    disp('encountered an error writing to diary');
end

%%% Aggregate sums (OUTPUTS to D:\Matlab\Data\Flux\Gapfilling)
try
mcm_make_Gapfill_sums({[ts_now(1:4) '-' ts_now(5:6) '-' ts_now(7:8)]}); 
catch
   disp('Something went wrong trying to compile sums'); 
end

%%% Final Compile %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

%%% Running ameriflux output for all years. %%%%%%%%%%%%%%%%%%
for i = 1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;

%% 2024-March-May Reprocessing 2022 and 2023 data
site_met = {'TP39', 2002:2023;'TP74', 2003:2023;'TP02', 2003:2023;'TPD', 2012:2023; 'TP_PPT',2012:2023; 'TPAg',2020:2023; 'TP_PPT',2008:2023};
site_CPEC_met = {'TP39', 2002:2023;'TP74', 2003:2023;'TP02', 2003:2023;'TPD', 2012:2023; 'TPAg',2020:2023};
site_CPEC = {'TP39', 2003:2023;'TP74', 2008:2023;'TP02', 2008:2023;'TPD', 2012:2023; 'TPAg',2020:2023};
site_output = {'TP39',2002:2023;'TP74', 2002:2023;'TP02', 2002:2023;'TPD', 2012:2023; 'TPAg',2020:2023}; %; 'TP_VDT',2020};
progress = 0;

% Metfixing
for i = 5%1:1:length(site_CPEC_met)
mcm_metfixer(2021:2023,site_CPEC_met{i,1},'met',1); 
end

%%% ONE TIME ONLY: Rerun threshold cleaning and fixing for 2020-2023, all main sites: 
for i = 1:1:length(site_CPEC)-1
mcm_fluxclean(2020:2023,site_CPEC{i,1},1); 
mcm_fluxfixer(2020:2023,site_CPEC{i,1},1);
end

%%% Metfilling %%%%%%%%%%%%%%%%%%
mcm_metfill(2019,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
mcm_metfill(2020,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
mcm_metfill(2021,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
mcm_metfill(2022,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
mcm_metfill(2023,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
progress = 1;

%%% SHF Calculation %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_CPEC_met)-1
    mcm_SHF(2022,site_CPEC_met{i,1});
end
for i = 1:1:length(site_CPEC_met)-1
    mcm_SHF(2023,site_CPEC_met{i,1});
end
progress = 2; 




%%% Storage and NEE calc %%%%%%%%%%%%%%%%%%
% be sure to update params.m before running for the first time in the year.
for i = 5%1:1:length(site_CPEC)
    mcm_CPEC_storage(2020:2023,site_CPEC{i,1},1,1);
end
progress = 3;

%%% First compile %%%%%%%%%%%%%%%%%%
for i =5% 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
mcm_data_compiler(2008:2023,'TP_PPT','met',-2); % Recompile TP_PPT.
progress = 4;

%%% Footprints %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end
progress = 5;

%%% LE,H Gapfilling %%%%%%%%%%%%%%%%%%
% ** Before running gapfilling, need to update dates in files at: D:\Matlab\Config\Flux\Gapfilling\Defaults
for i = 5%:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%%% NEE Gapfilling %%%%%%%%%%%%%%%%%%
% ** Before running, need to update NEE Gapfilling (after editing defaults in D:\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 5%:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off
try
    fid = fopen(diary_filename,'r');
    
    fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
    eof = 0;
    while eof==0
        tline = fgetl(fid);
        if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
            fprintf(fid2,'%s\n',tline);
        end
        eof = feof(fid);
    end
    fclose(fid);fclose(fid2);
    progress = 7;
catch
    disp('encountered an error writing to diary');
end

%%% Aggregate sums (OUTPUTS to D:\Matlab\Data\Flux\Gapfilling)
mcm_make_Gapfill_sums({'2024-07-08';'2024-07-09';'2024-07-21'}); 

%%% Final Compile %%%%%%%%%%%%%%%%%%
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

%%% Running ameriflux output for all years. %%%%%%%%%%%%%%%%%%
for i = 1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;



%% 2022-05-07 Run cleaning and calcs for 2022
site_met = {'TP39', 2002:2022;'TP74', 2003:2022;'TP02', 2003:2022;'TPD', 2012:2022; 'TP_PPT',2012:2022; 'TPAg',2020:2022};
site_CPEC_met = {'TP39', 2002:2022;'TP74', 2003:2022;'TP02', 2003:2022;'TPD', 2012:2022; 'TPAg',2020:2022};
site_CPEC = {'TP39', 2003:2022;'TP74', 2008:2022;'TP02', 2008:2022;'TPD', 2012:2022; 'TPAg',2020:2022};
site_output = {'TP39',2002:2022;'TP74', 2002:2022;'TP02', 2002:2022;'TPD', 2012:2022; 'TPAg',2020:2022}; %; 'TP_VDT',2020};
progress = 0;

% Metfixing
for i = 1:1:length(site_CPEC_met)
mcm_metfixer(2022,site_CPEC_met{i,1},'met',1); 
end

%%% SHF Calculation
for i = 1:1:length(site_CPEC_met)-1
    mcm_SHF(2022,site_CPEC_met{i,1});
end

%%% First compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%%% Footprints
for i = 1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end
progress = 5;

% Before running gapfilling, need to update dates in files at: D:\Matlab\Config\Flux\Gapfilling\Defaults
% LE,H Gapfilling (after editing defaults in \Matlab\Config\Flux\Gapfilling\Defaults)
for i = site_to_run %1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%NEE Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = site_to_run %1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off
try
    fid = fopen(diary_filename,'r');
    
    fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
    eof = 0;
    while eof==0
        tline = fgetl(fid);
        if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
            fprintf(fid2,'%s\n',tline);
        end
        eof = feof(fid);
    end
    fclose(fid);fclose(fid2);
    progress = 7;
catch
    disp('encountered an error writing to diary');
end
% Final Compile
for i = site_to_run %1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

% Running ameriflux output for all years.
for i = site_to_run %1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;
%% 2022-06-26 Run cleaning and calcs for 2021
site_met = {'TP39', 2002:2021;'TP74', 2003:2021;'TP02', 2003:2021;'TPD', 2012:2021; 'TP_PPT',2012:2021; 'TPAg',2020:2021};
site_CPEC_met = {'TP39', 2002:2021;'TP74', 2003:2021;'TP02', 2003:2021;'TPD', 2012:2021; 'TPAg',2020:2021};
site_CPEC = {'TP39', 2003:2021;'TP74', 2008:2021;'TP02', 2008:2021;'TPD', 2012:2021; 'TPAg',2020:2021};
site_output = {'TP39',2002:2021;'TP74', 2002:2021;'TP02', 2002:2021;'TPD', 2012:2021; 'TPAg',2020:2021}; %; 'TP_VDT',2020};
progress = 0;
site_to_run = 3;
% % Metfixing
% for i = 1:1:length(site_CPEC_met)
% mcm_metfixer(2020,site_CPEC_met{i,1},'met',1); 
% end
% % %%% Metfilling
% mcm_metfill(2020,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
% % progress = 1;

% %%% SHF Calculation
% for i = 1:1:length(site_CPEC_met)-1
%     mcm_SHF(2021,site_CPEC_met{i,1});
% end

for i = site_to_run %:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

% % %%% Footprints
for i = site_to_run %1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end
progress = 5;


% Before running gapfilling, need to update dates in files at: D:\Matlab\Config\Flux\Gapfilling\Defaults
% LE,H Gapfilling (after editing defaults in \Matlab\Config\Flux\Gapfilling\Defaults)
for i = site_to_run %1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%NEE Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = site_to_run %1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off
try
    fid = fopen(diary_filename,'r');
    
    fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
    eof = 0;
    while eof==0
        tline = fgetl(fid);
        if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
            fprintf(fid2,'%s\n',tline);
        end
        eof = feof(fid);
    end
    fclose(fid);fclose(fid2);
    progress = 7;
catch
    disp('encountered an error writing to diary');
end
% Final Compile
for i = site_to_run %1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

% Running ameriflux output for all years.
for i = site_to_run %1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;

%% 2022-06-26 Run cleaning for 2021
site = 'TP39';
mcm_metclean(2021,site,'met');
mcm_metfixer(2021,'TPAg','met',1);

mcm_fluxclean(2021,site);
mcm_fluxfixer(2021,'TP39');

%% Recalc flxues for TP39
mcm_calc_fluxes('TP39', 'CPEC',{'2021,01,01', '2022,01,01'});
mcm_CPEC_mat2annual(2021, 'TP39', -1);


%% 20210310 - Run all calculations for 2020
site_met = {'TP39', 2002:2020;'TP74', 2003:2020;'TP02', 2003:2020;'TPD', 2012:2020; 'TP_PPT',2012:2020; 'TPAg',2020};
site_CPEC_met = {'TP39', 2002:2020;'TP74', 2003:2020;'TP02', 2003:2020;'TPD', 2012:2020; 'TPAg',2020};
site_CPEC = {'TP39', 2003:2020;'TP74', 2008:2020;'TP02', 2008:2020;'TPD', 2012:2020; 'TPAg',2020};
site_output = {'TP39',2002:2020;'TP74', 2002:2020;'TP02', 2002:2020;'TPD', 2012:2020; 'TPAg',2020; 'TP_VDT',2020};
progress = 0;

% Metfixing
for i = 1:1:length(site_CPEC_met)
mcm_metfixer(2020,site_CPEC_met{i,1},'met',1); 
end
% %%% Metfilling
mcm_metfill(2020,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
% progress = 1;


%%% SHF Calculation
for i = 1:1:length(site_CPEC_met)-1
    mcm_SHF(2020,site_CPEC_met{i,1});
end
% progress = 2;
%%% Storage and NEE calc:
for i = 1:1:length(site_CPEC)
    mcm_CPEC_storage(2020,site_CPEC{i,1},1,1);
end
progress = 3;

%%%% Put fluxes into annual files
% mcm_CPEC_mat2annual(year, site,quickflag)

%%% First compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-1) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 4;
% % %%% Footprints
% for i = 1:1:length(site_CPEC)
% run_mcm_footprint(site_CPEC{i,1},[],0);
% end
% progress = 5;
% LE,H Gapfilling (after editing defaults in \Matlab\Config\Flux\Gapfilling\Defaults)
for i = 1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%NEE Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off
fid = fopen(diary_filename,'r');

fid = fopen('D:\Matlab\Data\Flux\Gapfilling\gapfilling_diary_20210330T160914.txt','r');
fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
eof = 0;
while eof==0
tline = fgetl(fid);
if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
    fprintf(fid2,'%s\n',tline);
end
eof = feof(fid);
end
fclose(fid);fclose(fid2);
progress = 7;

% Final Compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

% Running ameriflux output for all years.
for i = 1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;
%% 20210102 - Run cleaning for all 2020 met data so that I can test filling
site_met = {'TP39', 2002:2020;'TP74', 2003:2020;'TP02', 2003:2020;'TPD', 2012:2020; 'TP_PPT',2012:2020; 'TPAg', 2020};
site_CPEC_met = {'TP39', 2002:2020;'TP74', 2003:2020;'TP02', 2003:2020;'TPD', 2012:2020; 'TPAg', 2020};
site_CPEC = {'TP39', 2003:2020;'TP74', 2008:2020;'TP02', 2008:2020;'TPD', 2012:2020; 'TPAg', 2020};
site_output = {'TP39',2002:2020;'TP74', 2002:2020;'TP02', 2002:2020;'TPD', 2012:2020; 'TPAg', 2020};

for i = 5:1:length(site_met)
    mcm_metfixer(2020,site_met{i,1},'met',1)
end


%% 20200607 - Run all calculations for 2019
site_met = {'TP39', 2002:2019;'TP74', 2003:2019;'TP02', 2003:2019;'TPD', 2012:2019; 'TP_PPT',2012:2019};
site_CPEC_met = {'TP39', 2002:2019;'TP74', 2003:2019;'TP02', 2003:2019;'TPD', 2012:2019};
site_CPEC = {'TP39', 2003:2019;'TP74', 2008:2019;'TP02', 2008:2019;'TPD', 2012:2019};
site_output = {'TP39',2002:2019;'TP74', 2002:2019;'TP02', 2002:2019;'TPD', 2012:2019};
progess = 0;
% %%% Metfilling
mcm_metfill(2019,1); % 2nd argument is quickflag - use if soil averaging flags have been set.
% progress = 1;
% %%% SHF Calculation
% for i = 1:1:length(site_CPEC_met)
%     mcm_SHF(2019,site_CPEC_met{i,1});
% end
% progress = 2;
%%% Storage and NEE calc:
% for i = 1:1:length(site_CPEC)
%     mcm_CPEC_storage(2019,site_CPEC{i,1},1,1);
% end
progress = 3;
%%% First compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-1) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 4;
% %%% Footprints
% for i = 1:1:length(site_CPEC)
% run_mcm_footprint(site_CPEC{i,1},[],0);
% end
% progress = 5;
% LE,H Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
for i = 1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end
progress = 6;

%NEE Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end

% diary off
% fid = fopen(diary_filename,'r');
% fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
% eof = 0;
% while eof==0
% tline = fgetl(fid);
% if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
%     fprintf(fid2,'%s\n',tline);
% end
% eof = feof(fid);
% end
% fclose(fid);fclose(fid2);
% progress = 7;

% Final Compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end
progress = 8;

% Running ameriflux output for all years.
for i = 1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
progress = 9;

%% 20200211 - Regenerate all Ameriflux data
mcm_fluxnet_output(2002:2018, 'TP39', 'main');
mcm_fluxnet_output(2002:2018, 'TP39', 'sapflow');
mcm_fluxnet_output(2002:2018, 'TP74', 'main');
% mcm_fluxnet_output(2002:2018, 'TP74', 'sapflow');
mcm_fluxnet_output(2002:2018, 'TP02', 'main');
mcm_fluxnet_output(2012:2018, 'TPD', 'main');




%% 20190403 - Rerun all calculations 
site_met = {'TP39', 2002:2018;'TP74', 2003:2018;'TP02', 2003:2018;'TPD', 2012:2018; 'TP_PPT',2012:2018};
site_CPEC_met = {'TP39', 2002:2018;'TP74', 2003:2018;'TP02', 2003:2018;'TPD', 2012:2018};
site_CPEC = {'TP39', 2003:2018;'TP74', 2008:2018;'TP02', 2008:2018;'TPD', 2012:2018};
site_output = {'TP39',2002:2018;'TP74', 2002:2018;'TP02', 2002:2018;'TPD', 2012:2018};

%%% Metfilling
mcm_metfill(2018,1); % 2nd argument is quickflag - use if soil averaging flags have been set.

%%% SHF Calculation
for i = 1:1:length(site_CPEC_met)
    mcm_SHF(2018,site_CPEC_met{i,1});
end

%%% Storage and NEE calc:
for i = 1:1:length(site_CPEC)
    mcm_CPEC_storage(2018,site_CPEC{i,1},1,1);
end

%%% First compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-1) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

% %%% Footprints
for i = 1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end

% LE,H Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
for i = 1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end

%NEE Gapfilling
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end

diary off
fid = fopen(diary_filename,'r');
fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
eof = 0;
while eof==0
tline = fgetl(fid);
if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
    fprintf(fid2,'%s\n',tline);
end
eof = feof(fid);
end
fclose(fid);fclose(fid2);


% Final Compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end

% Running ameriflux output for all years.
for i = 1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% 20190405 - Rerunning for TP02:
site_CPEC = {'TP02', 2008:2018};
site_output = {'TP02', 2002:2018};

%%% Storage and NEE calc:
for i = 1:1:length(site_CPEC)
    mcm_CPEC_storage(site_CPEC{i,2},site_CPEC{i,1},1,1);
end

%%% First compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-1) % first compile. Create from scratch.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%%% Footprints
for i = 1:1:length(site_CPEC)
run_mcm_footprint(site_CPEC{i,1},[],0);
end

% LE,H Gapfilling (after editing defaults in \fielddata\Matlab\Config\Flux\Gapfilling\Defaults)
for i = 1:1:length(site_CPEC)
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end

%NEE Gapfilling
loadstart = addpath_loadstart;
ts_now = datestr(now,30);
diary_filename = [loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '.txt'];
diary(diary_filename);
for i = 1:1:length(site_CPEC)
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end

diary off
fid = fopen(diary_filename,'r');
fid2 = fopen([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' ts_now '_sums.txt'],'w');
eof = 0;
while eof==0
tline = fgetl(fid);
if strcmp(tline(1),' ')==1 || strcmp(tline(1),'=')==1
    fprintf(fid2,'%s\n',tline);
end
eof = feof(fid);
end
fclose(fid);fclose(fid2);


% Final Compile
for i = 1:1:length(site_output)
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end

% Running ameriflux output for all years.
for i = 1:1:length(site_output)
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% 20180905 - rerunning SW_down gapfilling for TPD
for i = 2012:1:2017
mcm_metfill(i,1);
end
mcm_data_compiler(2012:2017,'TPD','all',-2)
mcm_fluxnet_output(2012:2017, 'TPD', 'main',3);

%% 20180316 - Sapflow recalc and compile:

mcm_sapflow_calc(2014:2017,'TP39',1);
mcm_sapflow_calc(2011:2017,'TP74',1);
mcm_data_compiler(2009:2017,'TP39','sapflow',-9);
mcm_data_compiler(2011:2017,'TP74','sapflow',-9);

mcm_fluxnet_output(2002:2017,'TP39','sapflow')
mcm_fluxnet_output(2011:2017,'TP74','sapflow')

mcm_data_compiler(2002:2017, 'TP74', 'all',-2); % full compile. No prompts.
mcm_fluxnet_output(2002:2017, 'TP74', 'main',3);
mcm_data_compiler(2002:2017, 'TP39', 'all',-2); % full compile. No prompts.
mcm_fluxnet_output(2002:2017, 'TP39', 'main',3);

mcm_metfill(2002);
mcm_metfill(2012);
%% 20180316 - Running mcm_metfill for all years, all sites
% for yr = 2003:1:2017
% mcm_metfill(yr,1);
% end
% mcm_SHF(2008,'TP89');
% site_output = {'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017};
site_output = {'TP39', 2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017; 'TP89', 2002:2008};

% site_output = {'TP39', 2002:2017;'TP89', 2002:2008};

for i = 1:1:length(site_output);
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % full compile. No prompts.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

for i = 1:1:length(site_output);
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main',3)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
%% 20180318 - Rerunning all compiles for all years.
site_output = {'TP39', 2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017;'TP_PPT', 2007:2017; 'TP89', 2002:2008};

for i = 1:1:length(site_output)-1;
% mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % recreates from scratch.
% mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-1) % first compile. No prompts.
mcm_data_compiler(2013:2017, site_output{i,1}, 'all',-1) % first compile. No prompts.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% 20180318 - Running ameriflux output for all years.
site_output = {'TP39', 2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017; 'TP89', 2002:2007};
for i = 1:1:length(site_output);
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
%% 20180324 - Recalculating ALL fluxes:
%%% 20180327 - flux clean and fixing 
site_CPEC_met = {'TP39', 2002:2017;'TP74', 2003:2017;'TP02', 2003:2017;'TPD', 2012:2017};
site_CPEC = {'TP39', 2003:2017;'TP74', 2008:2017;'TP02', 2008:2017;'TPD', 2012:2017};
% for i = 1:1:length(site_CPEC2)
% mcm_calc_fluxes(site_CPEC2{i,1},'CPEC',{'2016,01,01', '2018,01,01'});
% mcm_CPEC_mat2annual(2016:2017, site_CPEC2{i,1}, -1);
% % mcm_fluxclean(2015, site_CPEC2{i,1},1);
% mcm_fluxfixer(2015,site_CPEC2{i,1},1);
% end
for i = 2%1:1:length(site_CPEC)
    start_year = site_CPEC{i,2}(1);
    end_year = site_CPEC{i,2}(end);
% mcm_calc_fluxes(site_CPEC{i,1},'CPEC',{[num2str(start_year) ',01,01'], [num2str(end_year) ',12,31']});
% mcm_CPEC_mat2annual(start_year:end_year, site_CPEC{i,1}, -1);
mcm_fluxclean(site_CPEC{i,2}, site_CPEC{i,1},1);
mcm_fluxfixer(site_CPEC{i,2}, site_CPEC{i,1},1);
end

%%% Rerun SHF Calculation
for i = 1:1:length(site_CPEC_met);
for yr = site_CPEC_met{i,2}(1):1:site_CPEC_met{i,2}(end)    
    mcm_SHF(yr,site_CPEC_met{i,1});
end
end

%%% Storage and NEE calc:
for i = 2:1:length(site_CPEC);
for yr = site_CPEC{i,2}(1):1:site_CPEC{i,2}(end)    
    mcm_CPEC_storage(yr,site_CPEC{i,1},1,1);
end
end

% for yr = yr_start:1:yr_end
%     for i = 1:1:length(site_CPEC);
%         mcm_CPEC_storage(yr,site_CPEC{i,1},1,1)
%     end
% end

%% 20180327 - Rerunning footprints and gap-filling
site_CPEC = {'TP39', 2003:2017;'TP74', 2008:2017;'TP02', 2008:2017;'TPD', 2012:2017};

% Footprints
% for i = 1:1:length(site_CPEC)
% run_mcm_footprint(site_CPEC{i,1},[],0);
% end

% LE,H Gapfilling
for i = 1:1:length(site_CPEC);
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end

loadstart = addpath_loadstart;
diary([loadstart 'Matlab/Data/Flux/Gapfilling/gapfilling_diary_' datestr(now,30) '.txt']);
%NEE Gapfilling
for i = 1:1:length(site_CPEC);
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end
diary off

% Final Compile
site_output = {'TP39',2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017};
for i = 1:1:length(site_output);
% mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-9) % recreates from scratch.
mcm_data_compiler(site_output{i,2}, site_output{i,1}, 'all',-2) % final compile. No prompts.
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

% Ameriflux output:
site_output = {'TP39', 2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017; 'TP89', 2002:2007};
for i = 1:1:length(site_output)-1
mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% CCP Output:
site_output = {'TP39', 2002:2017;'TP74', 2002:2017;'TP02', 2002:2017;'TPD', 2012:2017; 'TP89', 2002:2007};
for i = 1:1:length(site_output)-1
% mcm_fluxnet_output(site_output{i,2}, site_output{i,1}, 'main')
 mcm_CCP_output(site_output{i,2}, site_output{i,1},[],[]);
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
   
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% first compile:
site_all = {'TP39';'TP74';'TP89';'TP02';'TPD';'TP_PPT'};
site_CPEC = {'TP39', 2002:2015;'TP74', 2008:2015;'TP02', 2008:2015;'TPD', 2012:2015};
site_CCP_output = {'TP39', 2002:2015;'TP74', 2008:2015;'TP02', 2008:2015;'TPD', 2012:2015;'TP_PPT', 2007:2015};

% site_short = {'TP39', 2003:2013;'TP74', 2003:2013;'TP02', 2003:2013;'TPD', 2012:2013};
site_short = {'TP39', 2002:2015, 'all';'TP74', 2002:2015, 'all';'TP02', 2002:2015, 'all'; ...
                'TPD', 2012:2015, 'all';'TP89',2002:2008, 'all';'TP_PPT', 2007:2015, 'all'; ...
                'TP39',2007:2015, 'sapflow'; 'MCM_WX', 2007:2015, 'all'};

%% 20161203 - Running first processing run for 2016
site_CPEC = {'TP39', 2002:2015;'TP74', 2008:2015;'TP02', 2008:2015;'TPD', 2012:2015};
site_short = {'TP39', 2002:2015, 'all';'TP74', 2002:2015, 'all';'TP02', 2002:2015, 'all'; ...
                'TPD', 2012:2015, 'all';'TP89',2002:2008, 'all';'TP_PPT', 2007:2015, 'all'; ...
                'TP39',2007:2015, 'sapflow'; 'MCM_WX', 2007:2015, 'all'};
site_output = {'TP39', 2002:2016;'TP74', 2002:2016;'TP02', 2002:2016;'TPD', 2012:2016;'TP_PPT', 2007:2016; 'TP89', 2002:2007};
yr_start = 2016;
yr_end = 2016;
%%% fill met variables
for yr = yr_start:1:yr_end
mcm_metfill(yr,1);
end
         
%%% SHF Calculation
for yr = yr_start:1:yr_end
for i = 1:1:length(site_CPEC);
    mcm_SHF(yr,site_CPEC{i,1});
end
end     

%%% Storage and NEE calc:
for yr = yr_start:1:yr_end
    for i = 1:1:length(site_CPEC);
        mcm_CPEC_storage(yr,site_CPEC{i,1},1,1)
    end
end

%%% First compile
for i = 1:1:length(site_short);
mcm_data_compiler(2016, site_short{i,1}, site_short{i,3},-1)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% 20170206 - footprint, gapfilling
ind = 1:4;
site_CPEC = {'TP39', 2003:2016;'TP74', 2008:2016;'TP02', 2008:2016;'TPD', 2012:2016};

for i = 1:1:length(ind)
tic;
% run_mcm_footprint(site_CPEC{ind(i),1},[],0); % run footprint
%     t(i,1) = toc;
% try mcm_Gapfill_LE_H_default(site_CPEC{ind(i),1},site_CPEC{ind(i),2},0); % LE, H Gapfilling
% catch; disp(['LE,H Gapfill failed for ' site_CPEC{ind(i),1}]); end
    
try mcm_Gapfill_NEE_default(site_CPEC{ind(i),1},[],0); % NEE Gapfilling
catch; disp(['NEE Gapfill failed for ' site_CPEC{ind(i),1}]); end
mcm_data_compiler(site_CPEC{ind(i),2}, site_CPEC{ind(i),1}, 'all',-2)
t(i,2) = toc;
end

sendmail('jason.brodeur@gmail.com','Done','Done.');


%% 20170213 - Regenerating CCP and Fluxnet output data:

site_output = {'TP39', 2002:2016;'TP74', 2002:2016;'TP02', 2002:2016;'TPD', 2012:2016;'TP_PPT', 2007:2016; 'TP89', 2002:2007};

tic;
for i = 1:1:length(site_output);
    try
    mcm_CCP_output(site_output{i,2}, site_output{i,1},[],[]);
    catch
         disp(['Couldn''t do mcm_CCP_output for ' site_output{i,1}]);
    end
    disp(['Completed CCP output for ' site_output{i,1}]);
    
    try
        mcm_fluxnet_output(site_output{i,2}, site_output{i,1});
    catch
        disp(['Couldn''t do mcm_fluxnet_output for ' site_output{i,1}]);
    end
    disp(['Completed output for ' site_output{i,1}]);
end
t = toc;
sendmail({'jason.brodeur@gmail.com'; 'arainm@mcmaster.ca'},'Fluxnet data prepared.',['Done in ' num2str(t) 'seconds. Wait a few minutes for upload to Google Drive.']);


%% 20150130 - recalculations
site_CPEC = {'TP39', 2002:2016;'TP74', 2008:2016;'TP02', 2008:2016;'TPD', 2012:2016};
site_short = {'TP39', 2002:2016, 'all';'TP74', 2002:2016, 'all';'TP02', 2002:2016, 'all'; ...
                'TPD', 2012:2016, 'all';'TP89',2002:2008, 'all';'TP_PPT', 2007:2016, 'all'; ...
                'TP39',2007:2016, 'sapflow'; 'MCM_WX', 2007:2016, 'all'};
site_output = {'TP39', 2002:2016;'TP74', 2002:2016;'TP02', 2002:2016;'TPD', 2012:2016;'TP_PPT', 2007:2016; 'TP89', 2002:2007};

%%% fill met variables
for yr = 2003:1:2016
mcm_metfill(yr,1);
end
% 

% %%% SHF Calculation
% for yr = 2003:1:2015
% for i = 1:1:length(site_CPEC);
%     mcm_SHF(2015,site_CPEC{i,1});
% end
% end
%%% SHF Calculation
% for yr = 2003:1:2015
% for i = 1%:1:length(site_CPEC);
%     mcm_SHF(2015,site_CPEC{i,1});
% end
% end

%%% Storage and NEE calc:
% for yr = 2013:1:2015 
%     for i = 1:1:length(site_CPEC);
%         mcm_CPEC_storage(yr,site_CPEC{i,1},1,1)
%     end
% end
% % Storage and NEE calc:
% for yr = 2002:1:2015 
    for i = 1:1:length(site_CPEC);
        for j = min(site_CPEC{i,2}):1:max(site_CPEC{i,2})
        mcm_CPEC_storage(j,site_CPEC{i,1},1,1)
        end
    end
% end

% % First compile, no prompts, CPEC sites - 2013-2015 only:            
for i = 1:1:length(site_CPEC);
mcm_data_compiler(site_output{i,2}, site_CPEC{i,1}, 'all',-1)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
% try

% LE,H Gapfilling
% for i = 4:1:length(site_CPEC);
% mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
% end
% LE,H Gapfilling
for i = 1:1:length(site_CPEC);
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end

% NEE Gapfilling
% for j = 1:1:length(site_CPEC);
% mcm_Gapfill_NEE_default(site_CPEC{j,1},[],0);
% end

%NEE Gapfilling
for j = 1%:1:length(site_CPEC);
mcm_Gapfill_NEE_default(site_CPEC{j,1},[],0);
end

% 
%%% Full compile, no prompts, all sites:            
for k = 1:1:length(site_short);
mcm_data_compiler(site_short{k,2}, site_short{k,1}, site_short{k,3},-2)
end
try
sendmail('jason.brodeur@gmail.com','Done','Done');
catch
end
% %%% CCP Output
% mcm_fluxnet_output(site_output{3,2}, site_output{3,1});
tic;
for i = 1:1:length(site_output);
    try
    mcm_CCP_output(site_output{i,2}, site_output{i,1},[],[]);
    catch
         disp(['Couldn''t do mcm_CCP_output for ' site_output{i,1}]);
    end
    disp(['Completed CCP output for ' site_output{i,1}]);
    
%     try
%         mcm_fluxnet_output(site_output{i,2}, site_output{i,1});
%     catch
%         disp(['Couldn''t do mcm_fluxnet_output for ' site_output{i,1}]);
%     end
%     disp(['Completed output for ' site_output{i,1}]);
end
t = toc;
sendmail({'jason.brodeur@gmail.com'; 'arainm@mcmaster.ca'},'Fluxnet data prepared.',['Done in ' num2str(t) 'seconds. Wait a few minutes for upload to Google Drive.']);


% mcm_CCP_output(year,site,CCP_out_path, master,ftypes_torun)

% sendmail('jason.brodeur@gmail.com','Error.','Error.');
% end
%%

%%% Storage and NEE calc:
for i = 1:1:length(site_CPEC);
    mcm_CPEC_storage(2015,site_CPEC{i,1},1)
end

%%% First compile, no prompts, all sites - 2015 only:            
for i = 1:1:length(site_short);
mcm_data_compiler(2015, site_short{i,1}, site_short{i,3},-1)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%%% Full compile, no prompts, all sites:            
for i = 1:1:length(site_short);
mcm_data_compiler(site_short{i,2}, site_short{i,1}, site_short{i,3},-2)
end
%%% Full compile, no prompts, all sites - 2015 only:            
for i = 1:1:length(site_short);
mcm_data_compiler(2015, site_short{i,1}, site_short{i,3},-2)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
% %%% FROM SCRATCH Full compile, no prompts, all sites:            
% for i = 1:1:length(site_short);
% mcm_data_compiler(site_short{i,2}, site_short{i,1}, site_short{i,3},-9)
% end

%%% Full compile, no prompts, CPEC sites:            
for i = 1:1:length(site_CPEC);
mcm_data_compiler(site_CPEC{i,2}, site_CPEC{i,1}, 'all',-2)
end

%%% CCP Output
for i = 1:1:length(site_CCP_output);
mcm_CCP_output(site_CCP_output{i,2}, site_CCP_output{i,1},[],[])
end


%%%
mcm_CCP_output(2015, 'TP39',[],[]);
mcm_CCP_output(2015, 'TPD',[],[]);



%%%

%%% CCP Output
for i = 1:1:length(site_CCP_output);
mcm_CCP_output(site_CCP_output{i,2}, site_CCP_output{i,1},[],[])
end


%%% LE Gap-filling:
for i = 4:1:length(site_short);
mcm_Gapfill_LE_H_default(site_short{i,1},site_short{i,2},0);
end

for i = 1:1:length(site_CPEC);
mcm_Gapfill_LE_H_default(site_CPEC{i,1},site_CPEC{i,2},0);
end

for i = 1:1:length(site_CPEC);
mcm_Gapfill_NEE_default(site_CPEC{i,1},[],0);
end

% mcm_CCP_output(2002:2013,'TP39',[],[]);
% mcm_CCP_output(2002:2013,'TP74',[],[]);
% mcm_CCP_output(2002:2013,'TP02',[],[]);
% mcm_CCP_output(2002:2008,'TP89',[],[]);
mcm_CCP_output(2012:2013,'TPD',[],[]);
mcm_CCP_output(2008:2013,'TP_PPT',[],[]);

mcm_CPEC_storage(2015,'TP39',1)
mcm_CPEC_storage(2015,'TP74')
mcm_CPEC_storage(2015,'TPD')

ind = [1,4]




% sendmail('jason.brodeur@gmail.com','Done','Done');
%% Flux recalc - 20171104 (JJB)

%% %%%%%%%%%%%%%%% Matlab 1
mcm_calc_fluxes('TP02', 'CPEC',{'2008,01,01', '2017,11,05'});
for i = 2008:1:2017
mcm_CPEC_mat2annual(i, 'TP02', -1);
end

mcm_calc_fluxes('TP74', 'CPEC',{'2008,01,01', '2017,11,05'});
for i = 2008:1:2017
mcm_CPEC_mat2annual(i, 'TP74', -1);
end

auto_flag = 1;

mcm_fluxclean((2008:1:2017), 'TP02', auto_flag);
mcm_fluxfixer((2008:1:2017), 'TP02', auto_flag);

mcm_fluxclean((2008:1:2017), 'TP74', auto_flag);
mcm_fluxfixer((2008:1:2017), 'TP74', auto_flag);
%% %%%%%%%%%%%%%%% Matlab 2

mcm_calc_fluxes('TP39', 'CPEC',{'2002,01,01', '2017,11,05'});
for i = 2002:1:2017
mcm_CPEC_mat2annual(i, 'TP39', -1);
end

mcm_calc_fluxes('TPD', 'CPEC',{'2012,01,01', '2017,11,05'});
for i = 2012:1:2017
mcm_CPEC_mat2annual(i, 'TPD', -1);
end

auto_flag = 1;

mcm_fluxclean((2002:1:2017), 'TP39', auto_flag);
mcm_fluxfixer((2002:1:2017), 'TP39', auto_flag);

mcm_fluxclean((2012:1:2017), 'TPD', auto_flag);
mcm_fluxfixer((2012:1:2017), 'TPD', auto_flag);

%% 201711 - Rerunning storage calculation and first compile.
site_CPEC = {'TP39', 2003:2016;'TP74', 2008:2016;'TP02', 2008:2016;'TPD', 2012:2016};

%%% Storage calc:
for i = 1:1:length(site_CPEC);
    mcm_CPEC_storage(site_CPEC{i,2},site_CPEC{i,1},1,1)
end

%%% First compile, no prompts, all sites & years:            
for i = 1:1:length(site_CPEC);
mcm_data_compiler(site_CPEC{i,2}, site_CPEC{i,1}, 'all',-1)
end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

%% 20190829 - Run footprints, gapfilling for TP02 after incresing Ztree
site_CPEC = {'TP39', 2003:2016;'TP74', 2008:2016;'TP02', 2008:2016;'TPD', 2012:2016};

run_mcm_footprint('TP02',[],0);

% Full compile 
mcm_data_compiler(site_CPEC{3,2}, site_CPEC{3,1}, 'all',-2)

mcm_Gapfill_LE_H_default(site_CPEC{3,1},site_CPEC{3,2},0);

mcm_Gapfill_NEE_default(site_CPEC{3,1},[],0);

% Final Compile
mcm_data_compiler(site_CPEC{3,2}, site_CPEC{3,1}, 'all',-2)

