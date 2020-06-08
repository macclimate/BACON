function[loadstart, gdrive_loc] = addpath_loadstart(disp_flag)
gdrive_loc = '';
if ispc ~= 1
    if exist('/home/brodeujj/1/fielddata/Matlab/','dir') ==7
    loadstart = '/home/brodeujj/1/fielddata/';
    elseif exist('/work/brodeujj/1/fielddata/Matlab/','dir')==7
    loadstart = '/work/brodeujj/1/fielddata/';
    else
        loadstart = '/1/fielddata/';
    end
else
     if exist('Y:\Matlab\','dir') ==7
        loadstart = 'Y:\';
     elseif exist('D:\Matlab','dir') == 7
         loadstart = 'D:\';
         gdrive_loc = 'D:\Google Drive\Mac Climate - Shared Data\';
     else
        disp('This function is not currently setup for operation on this machine');
     end
end

assignin('base', 'loadstart', loadstart)
assignin('base', 'gdrive_loc', gdrive_loc)

% end
if nargin == 0 || strcmp(disp_flag,'off') == 1
else
disp(['loadstart = ' loadstart]);
disp(['Google Drive location  = ' gdrive_loc]);

end

