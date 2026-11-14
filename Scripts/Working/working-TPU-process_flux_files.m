%%% Prep
cd('C:\Local\TPUrban-IP')
clearvars;

% flux_path = 'C:\Local\TPUrban-IP\flux-summaries';

% We need to expand 1 year in each direction because we need to shift the
% timestamp by 1 row.
% Files are titled with the starting half hour, but date is the ending half hour: 2025-08-15T000000_smart3-01469.ghg	2025-08-15	00:30:00

start_year = 2025;
end_year = 2026;
flux_data_template = [];
for i = start_year-1:1:end_year+1
    [Year, JD, HHMM, dt] = jjb_makedate(num2str(i), 30,2);
    [Mon, Day] = make_Mon_Day(num2str(i), 30, 2);
    [HH, MM] = make_HH_MM(num2str(i), 30,2);

    flux_data_template = [flux_data_template; [Year, JD, dt,Mon,Day,HHMM,HH,MM]];
end
dateTimeString = strcat(num2str(flux_data_template(:,1)), '-', num2str(flux_data_template(:,4),'%02d'), '-', num2str(flux_data_template(:,5),'%02d'), 'T', num2str(flux_data_template(:,7),'%02d'), num2str(flux_data_template(:,8),'%02d'));
dateTimeString(2:end,:) = dateTimeString(1:end-1,:);
dateTimeString(1,:)='               ';

row_start = find(flux_data_template(:,1)==start_year,1,'first');
row_end = find(flux_data_template(:,1)==end_year,1,'last');

flux_data_trimmed = flux_data_template(row_start:row_end,:);
dateTimeString_trimmed = dateTimeString(row_start:row_end,:);

%%% Read the flux-file-headers file, which controls the strcuture of the
%%% output file.
opts = detectImportOptions("flux-file-headers.csv", 'FileType', 'text', 'Delimiter', '\t');
opts.DataLines = [1 Inf];
opts.VariableNamesLine = 0;
headers_raw = readcell("flux-file-headers.csv",opts);

% Append the generated date variables to the front of the header files
headers = ['YYYY';'JD';'dt';'MM';'DD';'hhmm';'hh';'mm';'timestamp';headers_raw];
% flux_data_cell = {};
clear flux_data_cell;
flux_data_cell = cell(size(flux_data_trimmed, 1), size(headers,1));
flux_data_cell(:, 1:8) = num2cell(flux_data_trimmed);
% flux_data_cell(:, 9) = dateTimeString_trimmed; % Add timestamp to the cell array
flux_data_cell(:,9) = cellstr(dateTimeString_trimmed);

%% Cycle through all files in flux_path, pull out data and paste to the
% correct spots in main template file:
flux_path = 'C:\Local\TPUrban-IP\flux-summaries';
d = dir(flux_path);

for i = 3:1:length(d)
    filename = [flux_path '\' d(i).name];
    disp(['Processing file: ' d(i).name]);
    % Setup Import Options
    opts = detectImportOptions(filename, 'FileType', 'text', 'Delimiter', '\t');
    opts.VariableNamesLine = 1; % Headers are on row 1
    opts.DataLines = [3, Inf]; % Data starts on row 3 (skipping the units on row 2)
    opts.VariableNamingRule = 'preserve';

    data = readtable(filename, opts);
    data_cell = readcell(filename, opts);
    %%% Let's compare the variable names to see if the station data matches the
    %%% main template

    vn1 = headers_raw';
    vn2 = data.Properties.VariableNames;
    vn2 = vn2(1,3:end);
    sameOrder = isequal(vn1, vn2);

    if sameOrder==1
        disp(['Columns match for file ' filename '. Proceeding'])
    else
        disp(['columns don not match for file ' filename '. Skipping' ])
        continue
    end

    for j = 1:1:size(data,1)
        %%% Pull out timestamp
        ts_tmp = data.filename(j);
        ts = ts_tmp{1}(1:15);

        %%% find matching row in flux_data_cell
        right_row = find(strcmp(ts,flux_data_cell(:,9))==1);
        if isempty(right_row)
            disp(['Skipping row ' ts '. No data to extract.'])
        else
            flux_data_cell(right_row,10:end) = data_cell(j,3:end);
        end
    end
end

% Save the updated cell array to a new Excel file after processing all files
% varnames = T.Properties.VariableNames;

T_out = cell2table(flux_data_cell, 'VariableNames',headers');
writetable(T_out, 'main_fluxfile.xlsx');


%% Can we do the same with met data ?

%%% Do some cleanup on met data files
% 1. Load each file
% 2. Condense headers into a single line
% 3. Write headers into a single lookup file (for comparison)
% 4. Identify the date format; create from it a YYYY-MM-DDThhmm string
met_path = 'C:\Local\TPUrban-IP\met-data';

%%% Read the flux-file-headers file, which controls the strcuture of the
%%% output file.
opts = detectImportOptions("met-file-headers.csv", 'FileType', 'text', 'Delimiter', '\t');
opts.DataLines = [1 Inf];
opts.VariableNamesLine = 0;
met_headers_raw = readcell("met-file-headers.csv",opts);

met_headers = ['YYYY';'JD';'dt';'MM';'DD';'hhmm';'hh';'mm';'timestamp';met_headers_raw];
% Comprehensive file: Start with flux_data_trimmed
met_data_cell = cell(size(flux_data_trimmed,1),size(met_headers,1));
met_data_cell(:, 1:8) = num2cell(flux_data_trimmed);
% flux_data_cell(:, 9) = dateTimeString_trimmed; % Add timestamp to the cell array
met_data_cell(:,9) = cellstr(dateTimeString_trimmed);
%%%% Create a string in the format yyyy-mm-ddTHHMM
dateTimeString2 = strcat(num2str(flux_data_template(:,1)), '-', num2str(flux_data_template(:,4),'%02d'), '-', num2str(flux_data_template(:,5),'%02d'), 'T', num2str(flux_data_template(:,7),'%02d'), num2str(flux_data_template(:,8),'%02d'));
dateTimeString2_trimmed = cellstr(dateTimeString2(row_start:row_end,:));

%%% Load the dateformat list (will help
opts = detectImportOptions('metfile-dateformat-list.csv', 'FileType', 'text');
opts = setvartype(opts, [1 2], 'char');    % or 'char'
T = readtable('metfile-dateformat-list.csv', opts);
dateformat_list = table2cell(T);

d2 = dir(met_path);
% All that is needed to load: 20250624, 20251017

for k = 3:1:length(d2)
    % tmp = readcell([met_path '\' d2(k).name]);
    [~,tmp_filename,~] = fileparts(d2(k).name);
    opts = detectImportOptions([met_path '\' d2(k).name],'FileType','text');    % detect based on file
    opts = setvartype(opts, 'Date', 'string');   % or 'char'
    opts = setvartype(opts, 'Time', 'string');
    opts.Delimiter = {'\t'};
    tmp_T = readtable([met_path '\' d2(k).name],opts);
    tmp_C = readcell([met_path '\' d2(k).name]);

    %%% Merge the top two header rows (and then delete the headers altogether
    header_revised = cell(1,size(tmp_C,2));
    for n = 1:1:size(tmp_C,2)
        switch sum(ismissing(tmp_C{1,n}))
            case 1
                header_revised{1,n} = tmp_C{2,n};
            case 0
                header_revised{1,n} = [tmp_C{1,n} '_' tmp_C{2,n}];
        end
    end
    tmp_C(1:2,:) = [];
    %%% Let's compare the variable names to see if the station data matches the
    %%% main template

    mvn1 = met_headers_raw;
    mvn2 = header_revised';
    sameOrder = isequal(mvn1, mvn2);

    if sameOrder==1
        disp(['Columns match for file ' tmp_filename '. Proceeding'])
    else
        disp(['columns don not match for file ' tmp_filename '. Skipping' ])
        continue
    end

    %%%%%%%% Confirm date format
    date_format = dateformat_list{strcmp(tmp_filename,dateformat_list(:,1))==1,2}
    switch date_format
        case 'YY-MM-DD'
            input_dateformat_string = 'yy-MM-dd';
        case 'DD-MM-YY'
            input_dateformat_string = 'dd-MM-yy';
    end

    for m = 1:1:size(tmp_T,1)
        % Reformat date
        reformattedDate = datetime(tmp_T{m,1}, 'InputFormat', input_dateformat_string);
        reformattedDate.Format = "yyyy-MM-dd";
        tmp_C{m,1} = char(reformattedDate);
        % Reformat time
        % reformatted_time = tmp_T{m,2};
        tstr = strrep(tmp_T{m,2},' p',' PM');
        tstr = strrep(tstr,' a',' AM');
        s = regexprep(tstr, '\s*([ap])\b', ' $1M', 'ignorecase');   % "3:00 PM"
        reformattedTime = datetime(s, 'InputFormat', 'h:mm a');               % parse
        reformattedTime.Format = "HHmm";                                     % 24-hour display
        tmp_C{m,2} = char(reformattedTime);

        % Make datetime string
        timedate_out = [char(reformattedDate) 'T' char(reformattedTime)];

        %%% Find the right row to insert data:
        rrow = find(strcmp(timedate_out,dateTimeString2_trimmed)==1);

        switch isempty(rrow)
            case 1
            otherwise
                met_data_cell(rrow,10:end) = tmp_C(m,1:end);
        end

    end

end


% Save the updated cell array to a new Excel file after processing all files

T_out_met = cell2table(met_data_cell, 'VariableNames',met_headers');
writetable(T_out_met, 'main_metfile.xlsx');
