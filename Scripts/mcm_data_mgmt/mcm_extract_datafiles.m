function mcm_extract_datafiles(source_path, dest_path, site)
% mcm_extract_datafiles.m
% This function is called by mcm_extract_CPEC (called from mcm_start_mgmt),
% and sorts incoming downloaded HF data, checks for their existence in the
% master directory (/SiteData/), and either copies the file over, or does
% nothing, depending on the file status in the master file.
% What this program does:
% Checks downloaded data for:
% 1. That they have the proper data tags (means from the proper site)
% 2. That the data exists already in the master /SiteData/data directory --
%       -- if the file doesn't exist, it is copied in the master directory.
%       -- If the file exists in the master directory, it only moves it if
%       the new file is larger than the current file in /SiteData/
% Created May, 2009 by JJB
% Revision History:
%
%
%
%
%
%

%% Create List of Necessary Data Tags to Look for:
% switch site
%     case 'TP39'
%         tag(1) = cellstr('.DMCM4');
%         tag(2) = cellstr('.DMCM5');
%     case 'TP74'
%         tag(1) = cellstr('.DMCM21');
%         tag(2) = cellstr('.DMCM22');
%         tag(3) = cellstr('.DMCM23');
%     case 'TP02'
%         tag(1) = cellstr('.DMCM31');
%         tag(2) = cellstr('.DMCM32');
%         tag(3) = cellstr('.DMCM33');
%     case 'TP39_chamber'
%         tag(1) = cellstr('.DACS16');
% end
tag = mcm_get_fluxsystem_info(site, 'data_extensions');

%%% Step 1 -- Load the source /data folder and look inside:
d = dir(source_path);
if length(d) > 2 % If d is larger than 2, we know there is data in the folder
    
    %%% Step 2: Look inside each folder inside of /data:
    for i = 3:1:length(d)
        move_flag = []; tag_flag = []; final_flag = [];
        clear d2 d_dest junk* file_list;
        clear *_sizes *_fullname;
        
        if d(i).isdir == 1
            d2 = dir([source_path d(i).name]); 
        else
        continue;
        end % make sure that we are opening a folder
        
        if ~isempty(d2) && length(d2) > 2
            
            %%% Step 3: Load the destination folder
            if exist([dest_path d(i).name])==7
            else
                mkdir([dest_path d(i).name]);
                disp(['Directory ' d(i).name ' does not exist; creating.']);
            end
            d_dest = dir([dest_path d(i).name]);
            
            if length(d_dest) <= 2
                dest_fullname = [];
                %                     move_flag(3:length(d2),1) = 1;
            else
                for k = 3:1:length(d_dest)
                    dest_sizes(k,1) = d_dest(k).bytes;
                    dest_fullname(k,:) = cellstr(d_dest(k).name);
                end
            end
            
            for j = 3:1:length(d2)
                [junk1, junk3, file_list(j).ext] = fileparts(d2(j).name); % get tag
                source_sizes(j,1) = d2(j).bytes;
                source_fullname(j,1) = cellstr(d2(j).name);
                
                %%% Step 4: Make flags for data tags:
                if sum(strcmp(file_list(j).ext,tag)) > 0
                    tag_flag(j,1) = 1;
                else
                    tag_flag(j,1) = 0;
                    disp(['There is a problem with tags in the ' d(i).name ' directory.']);
                end
                
                ind_copy = find(strcmp(source_fullname(j,1),dest_fullname)==1);
                
                if isempty(ind_copy)  % if no copy of the file is found in destination:
                    if source_sizes(j,1) == 0;
                        move_flag(j,1) = 0;
                        disp(['One or more files in the ' d(i).name ' directory are empty.  Not Copied.']);
                    else
                        move_flag(j,1) = 1;
                    end
                else
                    if source_sizes(j,1) == 0;
                        move_flag(j,1) = 0;
                        disp(['One or more files in the ' d(i).name ' directory are empty.  Not Copied.']);
                        
                    elseif source_sizes(j,1) > dest_sizes(ind_copy,1)
                        move_flag(j,1) = 1; % if source file is larger than dest file -- we move it.
                    else
                        move_flag(j,1) = 0; % if same file is already in destination:
                    end
                end
            end
            
            %%% Pad the length of tag_flag
            
            final_flag = move_flag.*tag_flag; % if final_flag is 1, then we can move it over:
            
            %%% Move data (if needed);
            if sum(final_flag) > 0;
                ind_move = find(final_flag == 1); % gives list of files to move
                
                for k = 1:1:length(ind_move)
                    try
                        
                        if ispc == 1;
                            [s,mess,messid] = copyfile([source_path d(i).name '\' d2(ind_move(k)).name], [dest_path d(i).name '\' d2(ind_move(k)).name]);
                            %                             [status,result] = dos(['copy ' source_path d(i).name '\' d2(ind_move(k)).name ' ' dest_path d(i).name '\' d2(ind_move(k)).name ' /y'],'-echo');
                            
                        else
                            [status,result] = unix(['cp ' source_path d(i).name '/' d2(ind_move(k)).name ' ' dest_path d(i).name '/' d2(ind_move(k)).name],'-echo');
                        end
                        
                        %         [s(k),mess(k),messid(k)] = copyfile([source_path d(i).name '/' d2(ind_move).name], [dest_path d(i).name '/' d2(ind_move).name])
                        %         [status,result] = unix(['cp ' source_path d(i).name '/' d2(ind_move(k)).name ' ' dest_path d(i).name '/' d2(ind_move(k)).name],'-echo');
                        
                    catch
                        disp(['failed copy for file ' source_path d(i).name '/' d2(ind_move(k)).name]);
                    end
                end
                disp(['total of ' num2str(length(ind_move)) ' files copied for ' d(i).name])
            else
                disp(['Data already exists for ' d(i).name '. No Data Copied.']);
            end
            
        else
            disp(['The folder ' d(i).name ' seems to be empty']);
        end
    end
else
    disp('data folder seems to be empty')
end
