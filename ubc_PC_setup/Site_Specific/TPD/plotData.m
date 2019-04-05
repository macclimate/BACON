function status = plotData(dataVar)

for countChan = 1:1:dataVar.header.NumOfChans
    figure(countChan)        
    clf
    plot([1:length(dataVar.data(:,countChan))]/20,dataVar.data(:,countChan))
    xlabel('Seconds (assuming 20 Hz)')
    ylabel(dataVar.header.chanInfo(countChan).units)
    title(dataVar.header.chanInfo(countChan).name)
    set(gcf, 'Name', dataVar.header.chanInfo(countChan).name)
    zoom on
end


    
