%% Loading Met2 CPEC data:
clear all
year = 2008;
%% List of files it will want to load
%%% for 2008:
days_in_mos = [31 28 31 30 31 30 31 31 30 31 30 31];
if find_leapyr(year) == 1;
days_in_mos(1,2) = days_in_mos(1,2)+1;
else  
end

yr_str = num2str(year);
part1 = yr_str(1,3:4);
ctr = 1;
for mth = 1:1:12
    if mth < 10
        part2 = ['0' num2str(mth)];
    else
        part2 = num2str(mth);
    end
    for days = 1:1:days_in_mos(mth)
        if days <10
        part3 = ['0' num2str(days)];
        else
            part3 = num2str(days);
        end
datalist(ctr,:) = [part1 part2 part3];
        
        ctr = ctr+1;
        clear  part3;
    end
    clear part2;
end
        
%%
path = ['C:\HOME\MATLAB\Data\Flux\CPEC\Met4\HH_Fluxes\' num2str(year) '\large\'];

out.FC = NaN.*ones(48,length(datalist)); out.WD = NaN.*ones(48,length(datalist)); out.LE = NaN.*ones(48,length(datalist)); 
out.WS = NaN.*ones(48,length(datalist)); out.HS = NaN.*ones(48,length(datalist)); 

D = dir(path);
ctr = 1;
for i = 3:length(D)
    try
    data(i).full = load([path D(i).name]);
    filen = D(i).name(1,1:6);
    loc = strmatch(filen,datalist);
   
   
    for j = 1:48
    try
        out.FC(j,loc) = data(i).full.Stats(j).MainEddy.Three_Rotations.AvgDtr.Fluxes.Fc;
        out.WD(j,loc) = data(i).full.Stats(j).Instrument(4).MiscVariables.WindDirection;
        out.WS(j,loc) = data(i).full.Stats(j).Instrument(4).MiscVariables.CupWindSpeed;
        out.LE(j,loc) = data(i).full.Stats(j).MainEddy.Three_Rotations.AvgDtr.Fluxes.LE_L;
        out.HS(j,loc) = data(i).full.Stats(j).MainEddy.Three_Rotations.AvgDtr.Fluxes.Hs;

    catch
    out.FC(j,loc) = NaN;
        out.WD(j,loc) = NaN;
        out.WS(j,loc) = NaN;
        out.LE(j,loc) = NaN;
        out.HS(j,loc) = NaN;
        
    end
    
    end
    catch
        disp(['file ' D(i).name(1,1:6) ' may be corrupted.']);
    end
end

FC = out.FC; WD = out.WD; WS = out.WS; LE = out.LE; HS = out.HS; 




save('C:\HOME\MATLAB\Data\Flux_comp\CP_FC.dat','FC','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_WD.dat','WD','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_WS.dat','WS','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_LE.dat','LE','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_HS.dat','HS','-ASCII')

figure(1); clf
ann_FC = reshape(FC,[],1);
ann_WD = reshape(WD,[],1);
ann_WS = reshape(WS,[],1);
ann_HS = reshape(HS,[],1);
ann_LE = reshape(LE,[],1);
plot(ann_FC, 'b.-')
plot(ann_LE,'r-.')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_FC1.dat','ann_FC','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_WD1.dat','ann_WD','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_WS1.dat','ann_WS','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_LE1.dat','ann_LE','-ASCII')
save('C:\HOME\MATLAB\Data\Flux_comp\CP_HS1.dat','ann_HS','-ASCII')


