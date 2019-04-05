function status = plotDataMCM_EC(dataVar)

for countChan = 1:dataVar.header.NumOfChans
    figure(countChan)    
    plot([1:length(dataVar.data)]/dataVar.header.SampleFreq,dataVar.data(:,countChan))
    zoom on
    xlabel('Seconds')
    ylabel(dataVar.header.chanInfo(countChan).units)
    title(dataVar.header.chanInfo(countChan).name)
    set(countChan, 'Name', dataVar.header.chanInfo(countChan).name)
end


    
