function traces_out = CR_lowlevel_structure(traces)
% traces_out = CR_lowlevel_structure(traces)
%
% Takes requested traces from structure and copies them to the output structure
% and renames them.
%
%	kai* 	Created:			17 Sep, 2001

out_names = {...
   'Air_Temperature_AbvCnpy_43m',...
   'Relative_Humidity_AbvCnpy_43m',...
   'Downwelling_Shortwave_Rad_AbvCnpy_45m',...
   'Downwelling_Longwave_Rad_AbvCnpy_45m',...
   'Upwelling_Shortwave_Rad_AbvCnpy_45m',...
   'Upwelling_Longwave_Rad_AbvCnpy_45m',...   
   'PPFD_downwelling_AbvCnpy_45m',...
   'PPFD_upwelling_AbvCnpy_45m',...
   'Wind_Speed_AbvCnpy_45m',...
   'Wind_Direction_AbvCnpy_45m',...
   'Barometric_Pressure',...
   'Precipitation',...
};

in_names = {...
   'air_temperature_main',...
   'relative_humidity_main',...
   'global_radiation_main',...
   'radiation_longwave_downwelling_main',...
   'radiation_shortwave_upwelling_main',...
   'radiation_longwave_upwelling_main',...   
   'ppfd_downwelling_main',...
   'ppfd_upwelling_main',...
   'wind_speed_main',...
   'wind_direction_main',...
   'barometric_pressure_main',...
   'precipitation_main',...
};

[dummy,ind_in,ind_trc] = intersect(in_names,{traces(:).variableName});
[dum,ind_s] = sort(ind_in);
ind_trc = ind_trc(ind_s);

for i = 1:length(ind_trc)
   traces_out(i) = traces(ind_trc(i));
   traces_out(i).variableName = char(out_names(i));
end

traces_out(1).ini.measurementType = 'CL';