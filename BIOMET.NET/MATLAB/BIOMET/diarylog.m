% diarylog.m  
% 
% Last edit: Oct 29, 2008
%
% Comments: 
%           This script does create a log file in the \matlab\ subdirectory. The file name
%       is in the form: YYMMDD.LOG  . This file will contain all the input/outputs during
%       all the Matlab sessions for that day.
%
%   Zoran Nesic, BIOMET, UBC
%



x = clock;
Year = num2str(x(1));Year = Year(3:4);
Month = num2str(x(2));
Day  = num2str(x(3));
%Hour = num2str(x(4));
%Minutes = num2str(x(5));
if length(Month) < 2
    Month = ['0' Month];
end
if length(Day) < 2
    Day = [ '0' Day];
end
verMat = ver;
if verMat(1).Version(1)< '6'
    eval(['diary d:\met-data\log\' Year Month Day '.log']);
else
    diary(fullfile('d:\met-data\log',[datestr(now,30) '.log']))
end
ver
disp('********************************************************************************');
disp(sprintf('Start at: %s', datestr(now)));
disp('********************************************************************************');

% Auto-save diary file every minute
t = timer('timerfcn',@fr_updatediary,...
'period',60,...
'ExecutionMode','fixedRate');

t = timerfind;
start(t)

% Keep the timer handle under UserData
UserData = get(0,'UserData');
UserData = setfield(UserData,'DiaryTimer',t); %#ok<SFLD>
set(0,'UserData',UserData);

clear x Year Month Day Minutes Hour UserData t


