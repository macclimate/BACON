function [CSAT,LICOR_7000,LICOR_7500]= fr_plt_new(dateIn,pth,ext1)
    if ~exist('pth') | isempty(pth)
        pth = 'd:\met-data\data\';
    end
    if ~exist('ext1') | isempty(ext1)
        ext1(1,1:3) = 'dh4';
        ext1(2,1:3) = 'dh5';
        ext1(3,1:3) = 'dh9';
    end
    fileNameX = fr_datetofilename(dateIn);
    YearX = datevec(dateIn);
    YearX = YearX(1);
%    dirX = [num2str(YearX) fileNameX(3:6)];
    dirX = [ fileNameX(1:6)];

    if exist(fullfile(pth,dirX)) == 7
        fullPthX = fullfile(pth,dirX);
    else
        fullPthX = pth;
    end
disp(fileNameX);
    Licor7500FileName = fullfile(fullPthX,[fileNameX '.' ext1(1,:)]);
    CSATFileName = fullfile(fullPthX,[fileNameX '.' ext1(2,:)]);
    Licor7000FileName = fullfile(fullPthX,[fileNameX '.' ext1(3,:)]);
    CSAT = fr_read_digital2_file(CSATFileName);
%try
    LICOR_7500 = fr_read_digital2_file(Licor7500FileName);
if length(LICOR_7500) < 10
        LICOR_7500 = NaN * ones(35000,8);
end
%catch
%    LICOR_7500 = NaN * ones(35000,8);
%end
    LICOR_7000 = fr_read_digital2_file(Licor7000FileName);

    tCSAT = [1:length(CSAT)]/20;
    tLICOR_7500 = [1:length(LICOR_7500)]/20;
    tLICOR_7000 = [1:length(LICOR_7000)]/20.345;

    figure(1)
    plot(tCSAT,CSAT(:,1:3))
    zoom on
    title('Wind Speeds CSAT')
    xlabel('Seconds')
    ylabel('m/s')

    figure(gcf+1)
    plot(tCSAT,sqrt(sum(CSAT(:,1:3)'.^2))')
    zoom on
    title('Cup wind speed CSAT')
    xlabel('Seconds')
    ylabel('m/s')

    figure(gcf+1)
    plot(tCSAT,CSAT(:,4))
    zoom on
    title('Air Temperature CSAT')
    xlabel('Seconds')
    ylabel('deg C')

    figure(gcf+1)
    plot(LICOR_7500(:,1))
    zoom on
    title('CO2')
    xlabel('Seconds')
    ylabel('mmol/m^3')

    figure(gcf+1)
    plot(LICOR_7500(:,2))
    zoom on
    title('H_2O')
    xlabel('Seconds')
    ylabel('mmol/m^3')

    figure(gcf+1)
    tMinInd = 1:min(length(tLICOR_7500),length(tCSAT));
    tMix = tLICOR_7500(tMinInd);
    plot(tMix,[CSAT(tMinInd,3) LICOR_7500(tMinInd,3)])
    zoom on
    title('Uz synchronization')
    xlabel('Seconds')
    ylabel('m/s')
    legend('Licor_7500_Aux','Uz')
    
    [del_1, del_2] = fr_find_delay(CSAT',LICOR_7500',[3 3],5000,[-50 50])
    [CSAT1,LICOR1_7500,N] = fr_remove_delay(CSAT', LICOR_7500',del_1,del_2);
    CSAT1 = CSAT1';
    LICOR1_7500 = LICOR1_7500';

    figure(gcf+1)
    tMix1 = [1:N]/20;
    plot(tMix1,[CSAT1(:,3) LICOR1_7500(:,3)])
    zoom on
    title('Uz Aligned')
    xlabel('Seconds')
    ylabel('m/s')
    legend('LicorAux','Uz')
    
    figure(gcf+1)
    plot(tLICOR_7000,LICOR_7000(:,1))
    zoom on
    title('CO_2')
    xlabel('Seconds')
    ylabel('ppm')

    figure(gcf+1)
    plot(tLICOR_7000,LICOR_7000(:,2))
    zoom on
    title('H_2O')
    xlabel('Seconds')
    ylabel('mmol/mol')

    figure(gcf+1)
    plot(tLICOR_7000,LICOR_7000(:,3))
    zoom on
    title('Tbench')
    xlabel('Seconds')
    ylabel('degC')

    figure(gcf+1)
    plot(tLICOR_7000,LICOR_7000(:,4))
    zoom on
    title('Plicor')
    xlabel('Seconds')
    ylabel('kPa')

if nargout == 0
    clear CSAT LICOR_7000 LICOR_7500
end

    