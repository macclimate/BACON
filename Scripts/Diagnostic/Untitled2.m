ls = addpath_loadstart;
% save_path = [ls 'Matlab/Data/Flux/Gapfilling/' site '/'];
footprint_path = [ls 'Matlab/Data/Flux/Footprint/'];
save_path = [ls 'Matlab/Data/Diagnostic/'];
% if exist([ls 'Matlab/Data/Diagnostic/EB_MK_Paper.mat'],'file')~=2
    
    %%% Load TPD Data:
    site = 'TPD';
    year_start = 2012;
    year_end = 2018;
    
    load_path = [ls 'Matlab/Data/Master_Files/' site '/'];
    load([load_path site '_gapfill_data_in.mat']);
    
    data = trim_data_files(data,year_start, year_end,1);
    Ta = master.data(:,95);
    clrs = colormap(lines(10));

%%    
    CDD = nan*ones(size(Ta,1),1);
    
    f1 = figure(1);clf;
        f2 = figure(2);clf;
  f3 = figure(3);clf;
  f5 = figure(5);clf;  
    ctr = 1;
    for year = 2012:1:2018
        ind = find(master.data(:,1)==year);
        figure(f1);
        h1(ctr) = plot(master.data(ind,6),Ta(ind),'Color',clrs(ctr,:)); hold on;
        %calculate CDD
        Ta_reshape = reshape(Ta(ind),48,[]);
        CDD_tmp = repmat((((max(Ta_reshape,[],1)+min(Ta_reshape,[],1))./2)-20),48,1);
        CDD_tmp = CDD_tmp(:);
        CDD(ind) = CDD_tmp;
        CDD_cum_tmp = cumsum(CDD_tmp);
        CDD_cum_tmp = CDD_cum_tmp - CDD_cum_tmp(131*48);
        CDD_cum_tmp(1:131*48) = 0;
        figure(f2);
        h2(ctr) = plot(master.data(ind,6),CDD_cum_tmp,'Color',clrs(ctr,:),'LineWidth',2); hold on;
        [GDD_tmp GDD_hh_tmp] = GDD_calc(Ta(ind),10,48,1);
        GDD_tmp = GDD_tmp - GDD_tmp(118);
        GDD_tmp(1:117) = 0;
        GDD_tmp = repmat(GDD_tmp',48,1);
        
        GDD(ind) = GDD_tmp(:);
        
        figure(f3);
        h3(ctr) = plot(master.data(ind,6),GDD_tmp(:),'Color',clrs(ctr,:),'LineWidth',2); hold on;
        figure(f5);
        h5(ctr) = plot(master.data(ind,6),master.data(ind,97),'Color',clrs(ctr,:),'LineWidth',2); hold on;
        
        
        ctr = ctr + 1;
        
    end
    
    legend(h1, num2str((2012:1:2018)'));
        legend(h2, num2str((2012:1:2018)'));
            legend(h3, num2str((2012:1:2018)'));
             legend(h5, num2str((2012:1:2018)'));
           
            
            %%
            GEP = master.data(:,132);
            year = master.data(:,1);
            year_daily = reshape(year,48,[]);
            year_daily = year_daily(1,:)';
            doy = master.data(:,6);
            doy_daily = reshape(doy,48,[]);
            doy_daily = doy_daily(1,:)';
            
            GEP_tmp = reshape(GEP,48,[]);
            GEP_daily = mean(GEP_tmp,1)';
            f4 = figure;clf
            plot(year_daily + doy_daily/366,GEP_daily,'b-');
            hold on;
            plot(year_daily + doy_daily/366, doy_daily/10,'r');
            
%% 
GEP_filled = master.data(:,132);
GEP_pred = 

