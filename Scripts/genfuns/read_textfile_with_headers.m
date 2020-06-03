function [H, C] = read_textfile_with_headers(file_in,delimiter,nHeaderLines)

%%% Loading the raw spreadsheet; reforming data: %%%%
fid = fopen(file_in,'r');
tline = fgets(fid);

%%% Figure out how many columns there are in the file:
startIndex = regexp(tline,delimiter); numcols = size(startIndex,2)+1;
fmt = repmat('%s',1,numcols); %create the format string for reading:
frewind(fid); %rewind the pointer to the start of the file:

%%% Load the file using textscan. Reform it until it's in a first-level
%%% cell structure
tmp = textscan(fid,fmt,'Delimiter',delimiter,'TreatAsEmpty',{'NA','na','NAN'});
C = {};

%%% Fix a problem with Google Sheet export where the final column has one
%%% less element in it than the others.
% if length(tmp{1,1}) - length(tmp{1,end}) == 1
%     tmp{1,end}{length(tmp{1,end})+1,1} = '';
% end

% Remove quotations (removed as of 08-Aug-2016); Collect header information
% replace '&' with '&amp;' (added 08-Aug-2016):
for i = 1:1:size(tmp,2)
    C(:,i) = tmp{1,i}(:,1); % remove all quotation marks from tmp and assign it a column in C
%     H{i,1} = C{1,i};    H{i,2} = C{2,i};    H{i,3} = C{3,i};
end

for j = 1:1:nHeaderLines
   H(:,j) = C(j,:); 
end

clear tmp;
fclose(fid);

% Remove the first x rows of C
C(1:nHeaderLines,:) = [];
end