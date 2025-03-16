function [final] = params(year, site, program,options)
%% OPEC_params.m
%%% This function serves as a central source of parameters for use in all
%%% scripts operating on OPEC data
% program specifies which program this script is being run from (see
% bottom)
%%
if ischar(year)==1
else
    year = num2str(year);
end


%%%%% Added 22-Jan-2014 by JJB %%%%%%%%%%%%%
%%%% The purpose of 'options' argument is to allow for additional changes
%%%% to run parameters.
%%% For instance the fetch_type variable can be used to control the size of
%%% the 'forest' fetch used in footprint filtering.
%%% In this case, 'tight' refers to boundaries that include only the direct
%%% study forest, while 'all' refers to inclusion of all forest land uses
%%% in the surrounding area.

if nargin==3
    options.fetch_type = 'tight';
    options.time_int = 30;
else
    if isfield(options,'fetch_type')==1
        
        if isempty(options.fetch_type)==1
            options.fetch_type = 'tight';
        end
    else
        options.fetch_type = 'tight';
    end
    if isfield(options,'time_int')==1
        if isempty(options.time_int)==1
            options.time_int = 30;
        end
    else
        options.time_int = 30;
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_remove = []; % This is used to if we need to keep only a section of a site's data during a year (e.g. TP_VDT and TPAg)

switch site
    
    %% TP39 PARAMETERS
    case 'TP39'
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        lat = dms2dec(42, 42, 35.20);
        long = dms2dec(80, 21, 26.64);
        elev = 184;
        wdir_keep = [0 360]; % exclude angles less than first number, exclude greater than second
        %           42, 39', 39.37'' N
        %           80, 33', 34.27'' W
        
        %%% 'fetch' defines the dimensions of the measurement site.%%%%%%%%%%%%%
        %%% Columns (shown here as rows) 1 and 2 specify the starting and
        %%% ending mathematical direction from the tower for each sector (0 = North,
        %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
        %%% rows 3 & 4 here), specify the distance from the tower at each
        %%% bearing.  This data is structured to create quadrants that may
        %%% be redrawn to represent the dimensions of the field site, and
        %%% for work in footprint filtering.
        
        switch options.fetch_type
            case 'tight'
                fetch = [[0  30  60  80  90 117 120 140 148 150 170 180 194 210 234 240 270 300 330 352]'...
                    [30  60  80  90 117 120 140 148 150 170 180 194 210 234 240 270 300 330 352 360]' ...
                    [360 306 340 434 757 492 487 530 390 397 540 481 325 307 225 155  97 258 282 398]' ...
                    [306 340 434 757 587 487 530 390 397 540 481 434 307 343 155  97  82 282 398 360]'];
            case 'all'
                %%% Below are the "no-agriculture" fetches; this includes all types of 'forest', but removes from the fetch any area that is
                %%% agricultural or newly-planted forest or grassland
                fetch = [[0  17   42   54   56       157 175 184  232  258  273  284  355]'...
                    [17  42   54   56   157      175 184 232  258  273  284  355  360]' ...
                    [504 1753 1891 1812 1520     842 592 823 1872 2525 1125 1678  439]' ...
                    [1080 1720 1812 1520 842     592 823 795 2525 1932 1041  439  504]'];
        end
        %%%%%%%%%%%%%%%%%%%%
        
        switch year
            case '2002'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 88; gsend = 329; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 19.14;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 20.97; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2003'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 81; gsend = 334; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 19.67;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 21.43; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2004'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 86; gsend = 336; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 20.2;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 21.9; % Actual Measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2005'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 94; gsend = 317; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 20.73;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 22.37; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2006'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 86; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 21.26;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 22.83; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2007'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 21.8;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 23.30; % Actual Measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2008'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 22.34;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 23.60; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2009'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 22.87;
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 23.90; % Interpolated
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2010'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 24.2; % Actual Measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2011'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                z_meas = 28; z_tree = 23.9; % Actual Measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2012'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 28; z_tree = 23.7; % Actual measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            case '2013'
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 28; z_tree = 23.7; % Actual measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2014' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2013!!
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 28; z_tree = 24.5; % Actual measurement
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2015' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2013/2014!!
                % CO2 Storage
                z = 28; ztop = 14; zcpy = 14; col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 28; z_tree = 24.5; % COPIED FROM 2014 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2016' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2015!
                % CO2 Storage
                z = 28;
                z(1:5933,1)=28; z(5934:17568,1)=34;
                ztop = z-14; zcpy = 14.*ones(17568,1); col_flag = 2;
                % Respiration
                gsstart = 84; gsend = 331; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas(1:5933,1) = 28; z_meas(5934:17568,1)=34;
                z_tree = 24.5; % COPIED FROM 2015 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2017' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2016!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 24.5; % COPIED FROM 2016 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2018' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2017!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 24.5; % COPIED FROM 2016 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2019' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2018!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 24.5; % COPIED FROM 2016 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2020' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2018!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 24.5; % COPIED FROM 2016 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2021' %%
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 26.0; % Updated for 2021
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2022' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2020!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 26; % COPIED FROM 2021 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case '2023' %% ALL VALUES HAVE BEEN STRAIGHT-UP COPIED FROM 2020!
                % CO2 Storage
                z = 34;
                ztop = z-14; zcpy = 14.*ones(yr_length(str2num(year),30),1); col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.325;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                %                 z_meas = 28; z_tree = 23.4; % z_tree is estimate only!!!!
                %%%%% Updated information - Jan 4, 2011 by JJB: %%%%%%%%%%
                %%% Tree height information was changed to reflect average
                %%% height of co-dominant and dominant trees only (not
                %%% including non-dominant trees, as was done before).
                %%% This stand was selectively thinning in Winter 2012. The
                %%% average tree height thus decreased slightly due to
                %%% more, larger trees being removed.
                z_meas = 34; z_tree = 26; % COPIED FROM 2021 - REPLACE!
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        %%%%%%%%%%%% TP74 PARAMETERS
    case 'TP74'
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        lat = dms2dec(42, 42, 24.52);
        long = dms2dec(80, 20, 53.93);
        elev = 184;
        wdir_keep = [180 360]; % exclude angles less than first number, exclude greater than second
        %%% 'fetch' defines the dimensions of the measurement site.
        %%% Columns (shown here as rows) 1 and 2 specify the starting and
        %%% ending mathematical direction from the tower for each sector (0 = North,
        %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
        %%% rows 3 & 4 here), specify the distance from the tower at each
        %%% bearing.  This data is structured to create quadrants that may
        %%% be redrawn to represent the dimensions of the field site, and
        %%% for work in footprint filtering.
        switch options.fetch_type
            case 'tight'
                fetch = [[ 0 30 60  90 113 120 150 162 180 210 220 240 270 300 330 343]' ...
                    [30 60 90 113 120 150 162 180 210 220 240 270 300 330 343 360]' ...
                    [48 38 44  78 247 244 279 324 245 215 220  96 150 139  55  57]' ...
                    [38 44 78 247 244 279 324 245 215 220  96 150 139  72  57  48]' ];
            case 'all'
                fetch = [[ 0  10 78  110 128 147 177  192  206  244  292 325]' ...
                    [10 78 110 128 147 177 192  206  244  292  325 360]' ...
                    [1321 1070 1543 847 843  274 995  1368 1023 1308 934 1341]' ...
                    [1070 1543 1166 843 274  452 1368 1023 1308 934  519 1321]' ];
        end
        
        
        switch year
            
            case '2002'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 88; gsend = 329; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 10.4;
                
            case '2003'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 81; gsend = 334; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 10.8;
                
            case '2004'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 11.2;
                
            case '2005'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 94; gsend = 317; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 11.6;
                
            case '2006'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 86; gsend = 331; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 12;
                
            case '2007'
                % CO2 Storage
                z = 14; ztop = 8.2; zcpy = 5.8; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 15; z_tree = 12.4;
                
            case '2008'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 12.8;
                
            case '2009'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 13.2;
                
            case '2010'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 13.6; % z_tree is estimate only!!!!
                
            case '2011'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 13.4;
                
            case '2012'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 13.5; % Actual measurement
                
            case '2013'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 13.5; % Actual measurement
                
                %%% SOME 2014 VALUES ARE STRAIGHT UP COPIED FROM 2013
            case '2014'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1;  % Actual measurement
                
                %%% ALL 2015 VALUES STRAIGHT UP COPIED FROM 2013/2014 -
                %%% REPLACE!!
            case '2015'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2014 -- REPLACE!!
                
                %%% ALL 2016 VALUES STRAIGHT UP COPIED FROM 2015 - REPLACE!!
            case '2016'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2015 -- REPLACE!!
                
                %%% ALL 2017 VALUES STRAIGHT UP COPIED FROM 2016 - REPLACE!!
            case '2017'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2015 -- REPLACE!!
                
                %%% ALL 2018 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2018'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2017 -- REPLACE!!
                
                %%% ALL 2019 VALUES STRAIGHT UP COPIED FROM 2018 - REPLACE!!
            case '2019'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2018 -- REPLACE!!
                
                
                %%% ALL 2020 VALUES STRAIGHT UP COPIED FROM 2018 - REPLACE!!
            case '2020'
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 14.1; % COPIED FROM 2018 -- REPLACE!!
            case '2021' %
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 17; % Updated for 2021
            case '2022' % COPIED FROM 2021 - UPDATE NEEDED!
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 17; % COPIED FROM 2021 -- REPLACE!!
            case '2023' % COPIED FROM 2020 - UPDATE NEEDED!
                % CO2 Storage
                z = 20; ztop = 10; zcpy = 10; col_flag = 2;
                % Respiration
                gsstart = 85; gsend = 338; NEE_cap = 7; ustar_crit = 0.25;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 20; z_tree = 17; % COPIED FROM 2021 -- REPLACE!!
        end
        %%%%%%%%%%%% TP89 PARAMETERS
    case 'TP89'
        theta_w  = 0.20;     % 20% water
        theta_m	= 0.01;
        theta_o  = 160/1300;
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        lat = dms2dec(42, 46, 27.91);
        long = dms2dec(80, 27, 31.59);
        elev = NaN;
        wdir_keep = [0 360]; % exclude angles less than first number, exclude greater than second
        %%% 'fetch' defines the dimensions of the measurement site.
        %%% Columns (shown here as rows) 1 and 2 specify the starting and
        %%% ending mathematical direction from the tower for each sector (0 = North,
        %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
        %%% rows 3 & 4 here), specify the distance from the tower at each
        %%% bearing.  This data is structured to create quadrants that may
        %%% be redrawn to represent the dimensions of the field site, and
        %%% for work in footprint filtering.
        
        switch options.fetch_type
            case 'tight'
                fetch = [[0 30  60  83  90 120 150 180 185 194 210 240 270 287 300 325 330]' ...
                    [30 60  83  90 120 150 180 185 194 210 240 270 287 300 325 330 360]' ...
                    [94 83  98 142 138 117 135 231 268 242 202 158 118 188 184 174 154]' ...
                    [83 98 142 138 117 135 231 268 242 202 158 118 188 184 174 154  94]' ];
            case 'all'
                fetch = [[0 30  60  83  90 120 150 180 185 194 210 240 270 287 300 325 330]' ...
                    [30 60  83  90 120 150 180 185 194 210 240 270 287 300 325 330 360]' ...
                    [94 83  98 142 138 117 135 231 268 242 202 158 118 188 184 174 154]' ...
                    [83 98 142 138 117 135 231 268 242 202 158 118 188 184 174 154  94]' ];
        end
        
        switch year
            case '2002'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 88; gsend = 329; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 7.5;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2003'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 81; gsend = 334; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 8.3;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2004'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 9.1;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2005'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 94; gsend = 317; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 9.9;
                
                % gsend in this program set as 334 instead of 304 as in Resp..
            case '2006'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 86; gsend = 331; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10.5; z_tree = 10.7;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2007'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10.8; z_tree = 11.5;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2008'
                % CO2 Storage
                z = 12; ztop = 6; zcpy = 6; col_flag = 2;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10.8; z_tree = 11.5;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
        end
        
        %%%%%%%%%%%% TP02 PARAMETERS
        
    case 'TP02'
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        lat = dms2dec(42,39,39.37);
        long = dms2dec(80,33,34.27);
        elev = 265;
        wdir_keep = [135 360]; % exclude angles less than first number, exclude greater than second
        %%% 'fetch' defines the dimensions of the measurement site.
        %%% Columns (shown here as rows) 1 and 2 specify the starting and
        %%% ending mathematical direction from the tower for each sector (0 = North,
        %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
        %%% rows 3 & 4 here), specify the distance from the tower at each
        %%% bearing.  This data is structured to create quadrants that may
        %%% be redrawn to represent the dimensions of the field site, and
        %%% for work in footprint filtering.
        
        switch options.fetch_type
            case 'tight'
                fetch = [[0 30  60  90  97 116 120 150 171 180 210 223 240 270 300 330 349]' ...
                    [30 60  90  97 116 120 150 171 180 210 223 240 270 300 330 349 360]' ...
                    [57 50  57 101 130 220 222 235 264 221 207 220  94  55  45  52  61]' ...
                    [50 57 101 130 220 222 235 264 221 207 220  94  55  45  52  61  57]' ];
            case 'all'
                fetch = [	[0   7  85  117  145  184	 204  207 216]' ...
                    [7  85  117 145  184  204  207  216 360]' ...
                    [85 96 159  680  546  1127 1031 861 655]' ...
                    [96 159 244 546  1127 1031 861  655 85]' ];
        end
        
        switch year
            % A NOTE ABOUT MEASUREMENT HEIGHTS
            % This site is a bit tricky in that the tower sits atop a small
            % hill that is about 2 m higher than the surrounding landscape.
            % We generally try to accommodate this by adding to the
            % measurement height.
            % We need to have more information about how TP02 height
            % changed over time. Here's what we know:
            % 2002-2005: EC Sensor at 2 m (as per Natalia's Thesis)
            % sometime in between - moved to 3 m
            % 09-Sept-2009 (Data Point ~): Moved from 3 m to 4 m
            % 24/25-July (Data Point ~9827): Moved to 8 m
            case '2002'
                % CO2 storage
                z = 2; ztop = 3; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 88; gsend = 329; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 4; z_tree = 0.4;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2003'
                % CO2 storage
                z = 2; ztop = 2; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 81; gsend = 334; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 4; z_tree = 0.6;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2004'
                % CO2 storage
                z = 2; ztop = 2; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 4; z_tree = 0.95;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2005'
                % CO2 storage
                z = 2; ztop = 2; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 94; gsend = 317; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 4; z_tree = 1.35;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2006'
                % CO2 storage
                z = 2; ztop = 2; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 86; gsend = 331; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 4; z_tree = 2; % measurement height is actually 3 m (meas height) + 1 m for offset between tower and
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2007'
                % CO2 storage
                z = 3; ztop = 3; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 5; z_tree = 2.8;
                
                % gsend in this program set as 334 instead of 304 as in
                % Resp..
            case '2008'
                % CO2 storage
                z = 3; ztop = 3; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 5; z_tree = 3.55; % Note that measurement is actually
                % taking place at 3 m from the base of the tower, but the
                % hill where the tower is placed is about 2 metres
                
            case '2009'
                % CO2 storage
                z(1:12070,1)=3; z(12071:17520,1)=4;
                ztop = z;
                %                 z = 5; ztop = 5;
                zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 6; z_tree = 4.2;
                
            case '2010'  % Update this:::::
                % CO2 storage
                z = 4; ztop = 4; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 6; z_tree = 4.9; % z_tree is estimate only!!!!
                
            case '2011'
                % CO2 storage
                z = 4; ztop = 4; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 6; z_tree = 5.1;
                
            case '2012'
                % CO2 storage
                z = 4; ztop = 4; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 6; z_tree = 5.8; % Actual measurement
            case '2013'
                % CO2 storage
                z = 4; ztop = 4; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 6; z_tree = 6.03; % Actual measurement
                !
            case '2014'
                % CO2 storage
                z(1:9827,1) = 4; z(9828:17520,1) = 8;
                ztop=z;
                %                 z = 5; ztop = 5;
                zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                % In
                z_meas = NaN.*ones(yr_length(str2num(year),30),1);
                z_meas(1:9827,1)=6;z_meas(9828:end)=10;
                z_tree = 6.26.*ones(yr_length(str2num(year),30),1); %  % Actual measurement
                
                %%% ALL 2015 VALUES STRAIGHT UP COPIED FROM 2013/2014 -
                %%% REPLACE!!
            case '2015'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                
                z_meas = 10; z_tree = 6.5;
                %                 z_meas = 10; z_tree = 8.5; % JUST A TEST - PUT BACK!!!
                
                %%% ALL 2016 VALUES STRAIGHT UP COPIED FROM 2015 - REPLACE!!
            case '2016'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 90; gsend = 304; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 6.85;
                %                 z_meas = 10; z_tree = 8.85;% JUST A TEST - PUT BACK!!!
                
                %%% ALL 2017 VALUES STRAIGHT UP COPIED FROM 2016 - REPLACE!!
            case '2017'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 7.13; %
                %                 z_meas = 10; z_tree = 9.13;% JUST A TEST - PUT BACK!!!
                
                %%% ALL 2018 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2018'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 7.28;
                %                 z_meas = 10; z_tree = 9.28;% JUST A TEST - PUT BACK!!!
                
                %%% ALL 2019 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2019'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 7.85; % Linearly interpolated between 2018 and 2021
                
                %%% ALL 2020 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2020'
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 10; z_tree = 8.42; % Linearly interpolated between 2018 and 2021
            case '2021'         
                % CO2 storage
                z(1:7509,1) = 8; z(7510:17520,1) = 11.1;
                ztop = z; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas(1:7509,1) = 10; z_meas(7510:17520,1) = 13.1;
                z_tree = 9.0; % Updated for 2021
            case '2022'         % COPIED FROM 2020 - UPDATE NEEDED!
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 13.1; z_tree = 9.6; % Assumed based on +0.6 annual increment trend
            case '2023'         % COPIED FROM 2020 - UPDATE NEEDED!
                % CO2 storage
                z = 8; ztop = 8; zcpy = 0; col_flag = 1;
                % Respiration
                gsstart = 78; gsend = 338; NEE_cap = 7; ustar_crit = 0.1;
                % Photosynthesis
                Qthresh = 10; Awa = 0.62; ka = 0.540; kh = 0.756; alpha = 0.03;
                % Final Flux Calculation (OPEC_Fluxes)
                GEPcutstart = 151; GEPcutend = 273; corr_1 = 1; corr_2 = 0;
                % Footprint Information (measurement and tree height)
                z_meas = 13.1; z_tree = 10.2; % Assumed based on +0.6 annual increment trend
        end
        
        
    case 'TPD'
        %% TPD
        % #################################################################
        % TPD
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        %           lat = dms2dec(42,38,7.124);
        %           long = dms2dec(80,33,27.222);
        lat = 42.635312;
        long = 80.557562;
        elev = 265;
        %
        %         wdir_keep = [135 360]; % exclude angles less than first number, exclude greater than second
        %         %%% 'fetch' defines the dimensions of the measurement site.
        %         %%% Columns (shown here as rows) 1 and 2 specify the starting and
        %         %%% ending mathematical direction from the tower for each sector (0 = North,
        %         %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
        %         %%% rows 3 & 4 here), specify the distance from the tower at each
        %         %%% bearing.  This data is structured to create quadrants that may
        %         %%% be redrawn to represent the dimensions of the field site, and
        %         %%% for work in footprint filtering.
        switch options.fetch_type
            case 'tight'
                fetch = [   [0 4 16 19 21 34 43 75 81 100 113 120 121.3 165 172 177 231 241 262 275 295 311 321 330 345 349]'...
                    [4 16 19 21 34 43 75 81 100 113 120 121.3 165 172 177 231 241 262 275 295 311 321 330 345 349 360]'...
                    [629 1232 1400 1405 1746 1710 1768 596 1072 1472 1804 1784 913 1666 1487 1667 950 844 554 331 344 343 293 852 743 637]'...
                    [647 1230 1405 1746 1710 1768 596 789 1472 1409 1784 913 1371 1487 1667 1492 844 1184 331 304 343 293 411 743 637 629]' ];
            case 'all'
                fetch = [   [0 4 16 19 21 34 43 75 81 100 113 120 121.3 165 172 177 231 241 262 275 295 311 321 330 345 349]'...
                    [4 16 19 21 34 43 75 81 100 113 120 121.3 165 172 177 231 241 262 275 295 311 321 330 345 349 360]'...
                    [629 1232 1400 1405 1746 1710 1768 596 1072 1472 1804 1784 913 1666 1487 1667 950 844 554 331 344 343 293 852 743 637]'...
                    [647 1230 1405 1746 1710 1768 596 789 1472 1409 1784 913 1371 1487 1667 1492 844 1184 331 304 343 293 411 743 637 629]' ];
                
        end
        
        switch year
            case '2012'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7;
                
                % Growing Season Start and End Dates:
                gs_start = 105;
                gs_end = 300;
                
            case '2013'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7;
                
                % Growing Season Start and End Dates:
                gs_start = 117;
                gs_end = 308;
                
                %%% ALL 2014 VALUES STRAIGHT UP COPIED FROM 2013 - REPLACE!!
            case '2014'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %%  % Actual measurement
                
                % Growing Season Start and End Dates:
                gs_start = 120;
                gs_end = 302;
                
                %%% ALL 2015 VALUES STRAIGHT UP COPIED FROM 2013 - REPLACE!!
            case '2015'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 119;
                gs_end = 302;
                
                %%% ALL 2016 VALUES STRAIGHT UP COPIED FROM 2015 - REPLACE!!
            case '2016'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 120;
                gs_end = 313;
                
                %%% ALL 2017 VALUES STRAIGHT UP COPIED FROM 2016 - REPLACE!!
            case '2017'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 120;
                gs_end = 313;
                
                %%% ALL 2018 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2018'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 121;
                gs_end = 304;
                
                %%% ALL 2019 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2019'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 121;
                gs_end = 304;
                
                %%% ALL 2020 VALUES STRAIGHT UP COPIED FROM 2017 - REPLACE!!
            case '2020'
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 25.7; %% REPLACE!!
                
                % Growing Season Start and End Dates:
                gs_start = 120;
                gs_end = 313;
            case '2021' %
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 26.5; %% Updated for 2021!!
                
                % Growing Season Start and End Dates:
                gs_start = 121;
                gs_end = 304;
            case '2022' % COPIED FROM 2020 -- UPDATE!!
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 26.5; % Copied from 2021
                
                % Growing Season Start and End Dates:
                gs_start = 121;
                gs_end = 304;
            case '2023' % COPIED FROM 2020 -- UPDATE!!
                % CO2 storage
                z = 31; ztop = 20; zcpy = 11; col_flag = 2;
                
                % Footprint Information (measurement and tree height)
                z_meas = 36.6; z_tree = 26.5; % Copied from 2021
                
                % Growing Season Start and End Dates:
                gs_start = 121;
                gs_end = 304;
            otherwise
        end
        
    case 'TP_VDT'
        %% TP_VDT
        
        % These are all just copied from TPAg
        
        %%% Soil parameters THESE PROBABLY ARE OK TO KEEP
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% Soil heat flux sensor/calculation details
        z_shf = 0.03; % soil heat sensor depth (in m)
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        
        %%% Lat/Long/Elev
        
        % ORIGINAL VALUES
        % lat = dms2dec(42, 42, 24.52); % latitude of the site UPDATE
        % long = dms2dec(80, 20, 53.93);  % longitude of the site UPDATE
        % elev = 184; % elevation of the site UPDATE
        
        %%% UPDATED BY ALANNA - MARCH 25 2021
        lat = dms2dec(42, 42, 18.96); % latitude of the site
        long = dms2dec(80, 21, 13.63);  % longitude of the site
        elev = 236; % elevation of the site
        
        switch year
            case '2019' %%% Copied from TPAg -- need to be update
                z_meas = 5; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z_tree = 15; % Mean tree height from ground [JJB modified 2021-03-31; think this makes more sense from a footprint perspective]
                z = 5;
                ztop = 5; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                gs_start = 125; % This is inferred from the Fc plot; should be revisited
                gs_end = 300; % This is inferred from the Fc plot; should be revisited
                
            case '2020' %%% Copied from TPAg -- need to be update
                z_meas = 5; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z_tree = 15; % Mean tree height from ground [JJB modified 2021-03-31; think this makes more sense from a footprint perspective]
                z = 5;
                ztop = 5; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                
                % Set this parameter to keep only a certain portion of the
                % timeseries--this will be applied at the 'final compile'
                % step.
                data_remove = [8401 17568]; % remove half hours 8401 to 17568
            case '2021' %%% Copied from TPAg -- need to be update
                z_meas = 5; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z_tree = 15; % Mean tree height from ground [JJB modified 2021-03-31; think this makes more sense from a footprint perspective]
                z = 5;
                ztop = 5; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                
        end
        
        
    case 'TPAg'
        %% TPAg
        % Address: 1811, Front Road, Charlottesville, Norfolk County, N0E 1P0
        % Site start Date: 29 June 2020
        % The instruments were installed at the exact same height as before in the forest below canopy setting. The EC system is at:
        % o	4.96 m height to centre of CSAT path
        % o	Centre of LI7500 path is offset 25 cm below centre of CSAT path, and 12cm south
        %
        % Heights of Ta/RH and Radiations sensors are same as used for VDT below canopy flux measurements.
        %
        % 4.20 m  LI190SB ("quantum" PAR sensor, LICOR S/N = 32166)
        % 4.20 m  SN-500 (Net Radiation sensors, Apogee, S/N 1200)
        % 4.30 m  HC2S3 (air temp and humidity probe)
        %
        % Ts – Soil Temperate CSI, model 107b
        % 2cm (new, installed on 28 Oct 2020)
        % 5cm (installed)
        % 10cm (installed)
        % 50 cm (new, installed on 28 Oct 2020)
        %
        % SM – Soil Moisture, CSI, model CS616
        % 5cm (installed)
        % 10-40cm (installed vertically, starting at 10 cm depth)
        % 50 cm (new, in future)
        % 100 cm (new, in future)
        %
        % G – Soil heat flux – CSI, model HFT3
        % 8 cm (from 29 June to 28 Oct, 2020)
        % 3 cm (move to 3cm on installed on 28 Oct 2020)
        %
        % Plant height was 0.3 m on 29 June (Altaf)
        % Plnat height was about 2.5 to 3.0 m by July 2020 (Keegan)
        % Plant height is between 2.5 and 3 m tall on 21 Oct (Shawn)
        % The plants in their rows are about 12 to 15 cm apart
        % The rows are 50 cm apart
        % There are between 12 to 15 plants per square meter in the field
        theta_w = 0.13;
        theta_m = 0.01;
        theta_o = 160/1300;
        z_shf = 0.03;
        Ts_to_use = 2; % Use 2 cm sensor to calculate dT/dt
        
        switch year
            case '2020'
                % Coordinates updated by JJB 2021-01-01 | original (commented) by EB 9/17
                % In UTM: 17N 553367 4727120
                lat = 42.69444; %42.694670;
                long = 80.34833; %80.348748;
                elev = 175; % Elevation in masl
                
                %         %%% 'fetch' defines the dimensions of the measurement site.
                %         %%% Columns (shown here as rows) 1 and 2 specify the starting and
                %         %%% ending mathematical direction from the tower for each sector (0 = North,
                %         %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
                %         %%% rows 3 & 4 here), specify the distance from the tower at each
                %         %%% bearing.  This data is structured to create quadrants that may
                %         %%% be redrawn to represent the dimensions of the field site, and
                %         %%% for work in footprint filtering.
                switch options.fetch_type
                    case 'tight'
                        fetch = [   [0 27 45 57 78 113 135 140 145 158 169 198 257 265 283 349]'... % sector start bearing
                            [27 45 57 78 113 135 140 145 158 169 198 257 265 283 349 360]'...         % sector end bearing
                            [195 187 192 175 238 181 197 282 289 211 249 136 124 119 139 207]'...  % sector start distance (m)
                            [187 192 175 221 181 154 209 289 211 249 136 124 119 139 207 195]' ]; % sector end distance (m)
                    case 'all'
                        % For the time being, the fetches have been made
                        % equal--it's uncear whether we would want to define a
                        % broader representative area when the cover type will
                        % change from year to year.
                        fetch = [   [0 27 45 57 78 113 135 140 145 158 169 198 257 265 283 349]'... % sector start bearing
                            [27 45 57 78 113 135 140 145 158 169 198 257 265 283 349 360]'...         % sector end bearing
                            [195 187 192 175 238 181 197 282 289 211 249 136 124 119 139 207]'...  % sector start distance (m)
                            [187 192 175 221 181 154 209 289 211 249 136 124 119 139 207 195]' ]; % sector end distance (m)
                        
                end
                
                z_meas = 5; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z = 5;
                ztop = 5; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                gs_start = 154; % emerged from the ground ~02 June
                gs_end = 317; % Harvested on 12-Nov. May need to adjust this to consider that corn may have stopped photosynthesizing well before that
                %%%% Need to calculate z_tree (crop height) as a variable quantity:
                % Corn came out of the ground and were ~5 cm tall on 02 June 2020
                % Corn was 0.15 to 0.5 cm (~6-20 inch) high and well grown on 14 June 2020
                % Plant height was 0.9 to 1.2m (~3-4 ft) m on 29 June (Altaf)
                % Plant height was about 2.5 to 3.0 m by 14 July 2020 (Keegan)
                % Plant height is between 2.5 and 3.0 m tall on 21 Oct (Shawn)
                
                %                 z_tree = zeroes(yr_length(str2num(year),options.time_int),1);
                spot_heights = [7345, 0.05; 7921, 0.325; 8641, 1.05; 9361, 2.75; 15169, 0];
                % Need to fill in linearly between these points (and
                % extrapolate backwards to zero)
                p = polyfit(spot_heights(1:end-1,1), spot_heights(1:end-1,2), 1);
                z_tree(:,1) = polyval(p,(1:1:yr_length(str2num(year),options.time_int))');
                z_tree(9362:15168,1) = z_tree(9361,1); % consistent height
                z_tree(z_tree<0,1) = 0; % Before emergence
                z_tree(15169:end,1) = 0; % After harvest
                
                % Set this parameter to keep only a certain portion of the
                % timeseries--this will be applied at the 'final compile'
                % step.
                data_remove = [1 8400]; % remove half hours 1 to 8400
                
                
            case '2021' %% NEEDS TO BE UPDATED
                % Coordinates updated by JJB 2021-01-01 | original (commented) by EB 9/17
                % In UTM: 17N 553367 4727120
                lat = 42.696126;
                long = 80.348781;
                elev = 215; % Elevation in masl
                
                %         %%% 'fetch' defines the dimensions of the measurement site.
                %         %%% Columns (shown here as rows) 1 and 2 specify the starting and
                %         %%% ending mathematical direction from the tower for each sector (0 = North,
                %         %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
                %         %%% rows 3 & 4 here), specify the distance from the tower at each
                %         %%% bearing.  This data is structured to create quadrants that may
                %         %%% be redrawn to represent the dimensions of the field site, and
                %         %%% for work in footprint filtering.
                switch options.fetch_type
                    case 'tight'
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                    case 'all'
                        % For the time being, the fetches have been made
                        % equal--it's uncear whether we would want to define a
                        % broader representative area when the cover type will
                        % change from year to year.
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                end
                
                
                z_meas = 4.71; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z = 4.71;
                ztop = 4.71; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                gs_start = 154; % emerged from the ground ~02 June
                gs_end = 317; % Harvested on 12-Nov. May need to adjust this to consider that corn may have stopped photosynthesizing well before that
                %                 z_tree = 0;
                %%%% Need to calculate z_tree (crop height) as a variable quantity:
                % Corn was  30 cm (~12 inch) high on 12 June 2021.
                %
                % Corn was  2.5 m (~7 to 8 ft ) high on 23 July 2021.
                %
                % Yes, it is ok to assume same heights and time periods.
                %
                % Production - 182 bushel per ac of corm in 2021

                
                %                 z_tree = zeroes(yr_length(str2num(year),options.time_int),1);
                spot_heights = [7345, 0.05; 7921, 0.325; 8641, 1.05; 9361, 2.75; 15169, 0];
                % Need to fill in linearly between these points (and
                % extrapolate backwards to zero)
                p = polyfit(spot_heights(1:end-1,1), spot_heights(1:end-1,2), 1);
                z_tree(:,1) = polyval(p,(1:1:yr_length(str2num(year),options.time_int))');
                z_tree(9362:15168,1) = z_tree(9361,1); % consistent height
                z_tree(z_tree<0,1) = 0; % Before emergence
                z_tree(15169:end,1) = 0; % After harvest
                
                
                case '2022' %% NEEDS TO BE UPDATED
                % Coordinates updated by JJB 2021-01-01 | original (commented) by EB 9/17
                % In UTM: 17N 553367 4727120
                lat = 42.696126;
                long = 80.348781;
                elev = 215; % Elevation in masl
                
                %         %%% 'fetch' defines the dimensions of the measurement site.
                %         %%% Columns (shown here as rows) 1 and 2 specify the starting and
                %         %%% ending mathematical direction from the tower for each sector (0 = North,
                %         %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
                %         %%% rows 3 & 4 here), specify the distance from the tower at each
                %         %%% bearing.  This data is structured to create quadrants that may
                %         %%% be redrawn to represent the dimensions of the field site, and
                %         %%% for work in footprint filtering.
                switch options.fetch_type
                    case 'tight'
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                    case 'all'
                        % For the time being, the fetches have been made
                        % equal--it's uncear whether we would want to define a
                        % broader representative area when the cover type will
                        % change from year to year.
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                end
                
                
                z_meas = 4.71; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z = 4.71;
                ztop = 4.71; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                gs_start = 173; % emerged from the ground ~22 June
                gs_end = 285; % Fully senesced on 12-Oct
                %                 z_tree = 0;
                %%%% Need to calculate z_tree (crop height) as a variable quantity:
                % Planting date = There was no crop planted as of 15 June. It may have been planted on 16 June, 2022.
                %
                % Emergence date = Approximately 22 June.  Plants were about 10 cm high as of 2 July 2022 as noted on a site trip.
                %
                % Plant were about 15 cm on 27 July 2022. 75% field covered with crop and rest bare ground.
                %
                % Plants fully covered 100% ground on 9 August 2020. Height about 20 cm.
                %
                % Plants were well grown and about 20 cm high on 16-17 August site trip.
                %
                % Plants were harvested on 12 October 2022. Half the field cleared.
                %
                % Date when crop fully senesced (no more photosynthesis) = 12 October, 2022. Plants were still green when harvested
                %
                % Full Harvesting date = 14 or 15 October 2022.
                %
                % Production - 3200 Ibs per acre in 2022 sweet potatoes
                %
                % Field plowed and winter grass planted on 22 October 2023.
                %
                % By the start of winter grass as 6-7 cm tall and covered 5% of ground.
                
                %                 z_tree = zeroes(yr_length(str2num(year),options.time_int),1);
                spot_heights = [8737, 0.1; 9937, 0.15; 10561, 0.2; 13753, 0.2; 13754, 0];
                % Need to fill in linearly between these points (and
                % extrapolate backwards to zero)
                p = polyfit(spot_heights(1:3,1), spot_heights(1:3,2), 1);
                z_tree(:,1) = polyval(p,(1:1:yr_length(str2num(year),options.time_int))');
                z_tree(10561:13753,1) = 0.2; % consistent height
                z_tree(z_tree>0.2) = 0.2; 
                z_tree(z_tree<0,1) = 0; % Before emergence
                z_tree(13754:end,1) = 0; % After harvest

                case '2023' %% NEEDS TO BE UPDATED
                % Coordinates updated by JJB 2021-01-01 | original (commented) by EB 9/17
                % In UTM: 17N 553367 4727120
                lat = 42.696126;
                long = 80.348781;
                elev = 215; % Elevation in masl
                
                %         %%% 'fetch' defines the dimensions of the measurement site.
                %         %%% Columns (shown here as rows) 1 and 2 specify the starting and
                %         %%% ending mathematical direction from the tower for each sector (0 = North,
                %         %%% increasing counter-clockwise), while Columns 3 and 4 (shown as
                %         %%% rows 3 & 4 here), specify the distance from the tower at each
                %         %%% bearing.  This data is structured to create quadrants that may
                %         %%% be redrawn to represent the dimensions of the field site, and
                %         %%% for work in footprint filtering.
                switch options.fetch_type
                    case 'tight'
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                    case 'all'
                        % For the time being, the fetches have been made
                        % equal--it's uncear whether we would want to define a
                        % broader representative area when the cover type will
                        % change from year to year.
                        fetch = [[0 14 64 67 80 85 114 117 130 130 154 167 167 178 217 228]'... % sector start bearing
                            [14 64 67 80 85 114 117 130 130 154 167 167 178 217 228 360]'...         % sector end bearing
                            [157 301 350 640 523 611 516 146 152 239 286 304 411 432 262 232]'...  % sector start distance (m)
                            [301 350 640 523 611 516 146 152 239 286 304 411 432 262 232 157]' ]; % sector end distance (m)
                end
                
                
                z_meas = 4.71; % Height of EC system from ground
                %                 z_tree = 3; % Mean tree height from ground
                z = 4.71;
                ztop = 4.71; % Height of the column that is represented by the top CO2 sensor (ztop = z if only one sensor)
                zcpy = 0; % Height of the column that is represented by the bottom CO2 sensor (zcpy + ztop = z if two sensors are used)
                col_flag = 1; % =1 for one-height CO2 storage measurement, =2 for two-height
                gs_start = 154; % ***NEEDS UPDATING*** emerged from the ground
                gs_end = 274; % Harvested by 101-Oct. 
                %                 z_tree = 0;
                %%%% Need to calculate z_tree (crop height) as a variable quantity:
                % Winter grass was planted at site. It was about 10 cm tall when mowed back in the soil in late April, 2022.
                %
                % Tobacco on July 1, 2023. Plants were 0.3 m high.
                %
                % Tobacco on 31 August 2023. Plant were 1.5 to 1.75 m tall. 2nd harvest was being conducted.
                %
                % Tobacco on 16 Sept 2023. Plant were 2 to 2.5 m tall.
                %
                % Tobacco was fully harvested by 1-2 October. Only stem about 0.3 m tall standing on the ground as on 3 October 2023.
                %
                % Field plowed on 22 Oct 2023 and seems seeded with grass.

                
                %                 z_tree = zeroes(yr_length(str2num(year),options.time_int),1);
                spot_heights = [8689, 0.3; 11617, 1.625; 12385, 2.25; 13465, 2.25; 13466, 0.3; 14136, 0.3; 14137, 0];
                % Need to fill in linearly between these points (and
                % extrapolate backwards to zero)
                p = polyfit(spot_heights(1:3,1), spot_heights(1:3,2), 1);
                z_tree(:,1) = polyval(p,(1:1:yr_length(str2num(year),options.time_int))');
                z_tree(12385:13466,1) = 2.25; % consistent height
                z_tree(13466:14136,1) = 0.3;
                z_tree(14137:end,1) = 0;% After harvest
                z_tree(z_tree>2.25) = 2.25;
                z_tree(z_tree<0,1) = 0; % Before emergence
            otherwise
        end
        % #################################################################
    case 'TP_PPT'
        z_meas = 2;
        z_tree = 0;
        ztop = 0;
        zcpy = 0;
        z = 2;
        col_flag = 0;
end

%% Modifications to height variables associated with Footprint and CO2_storage calculations,
%%% to make them half-hourly values instead of a single value for a year
%%% Added 30-Jan-2015 by JJB
if exist('z_meas','var')==1
    if numel(z_meas)==1; z_meas = repmat(z_meas,yr_length(str2num(year),options.time_int),1); end
else 
end

if exist('z_tree','var')==1
    if numel(z_tree)==1
        z_tree = repmat(z_tree,yr_length(str2num(year),options.time_int),1);
    end
else
end

if exist('z','var')==1
    if numel(z)==1
        z = repmat(z,yr_length(str2num(year),options.time_int),1);
    end
else
end

if exist('ztop','var')==1
    if numel(ztop)==1
        ztop = repmat(ztop,yr_length(str2num(year),options.time_int),1);
    end
else
end

if exist('zcpy','var')==1
    if numel(zcpy)==1
        zcpy = repmat(zcpy,yr_length(str2num(year),options.time_int),1);
    end
else
end

if exist('col_flag','var')==1
    if numel(col_flag)==1
        col_flag = repmat(col_flag,yr_length(str2num(year),options.time_int),1);
    end
else
end

%% This Section controls the parameters outputted, based on which program calls it
switch program
    case 'Resp'
        final = [gsstart gsend NEE_cap ustar_crit];
    case 'Met'
        final = [];
    case 'CO2_storage'
        final = [z ztop zcpy col_flag];
    case 'Photosynth'
        final = [Qthresh Awa ka kh alpha gsstart gsend];
    case 'Fluxes'
        final = [gsstart gsend GEPcutstart GEPcutend corr_1 corr_2 ustar_crit];
    case 'SHF'
        final = [theta_w theta_m theta_o z_shf Ts_to_use];
    case 'Sun'
        final = [lat long];
    case 'WDir'
        final = wdir_keep;
    case 'Heights'
        final = [z_meas z_tree];
    case 'Fetch'
        final = fetch;
    case 'GS_Dates'
        final = [gs_start gs_end];
    case 'Location'
        final = [lat long elev];
    case 'Trim'
        final = data_remove;
end
