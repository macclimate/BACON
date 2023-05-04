load('D:\Matlab\Data\Master_Files\TP02\TP02_data_master.mat')

ust = master.data(:,11);
NEE = master.data(:,7);
year = master.data(:,1);
fp_flag = master.data(:,129);
NEE_filled = master.data(:,111);
PAR = master.data(:,74);
NEE_filled_FCRN = master.data(:,117);

ind  = find(year==2021);

ust_2021 = ust(ind);
NEE_2021 = NEE(ind);
fp_flag_2021 = fp_flag(ind);
NEE_f_2021 = NEE_filled(ind);
PAR_2021 = PAR(ind);
NEE_f_FCRN_2021 = NEE_filled_FCRN(ind);


% FP and ustar passing
NEE_filt_2021 = NEE_f_2021;
NEE_filt_2021(ust_2021 < 0.05 | isnan(fp_flag_2021)==1) = NaN;

figure(1);clf;
plot(PAR_2021./100); hold on;
plot(NEE_f_2021); 
plot(NEE_f_FCRN_2021);
plot(NEE_2021);
plot(NEE_filt_2021);

legend('PAR/100','NEE-filled','NEE-filled-FCRN','NEE-raw','NEE-filtered');

figure(2); clf;
plot(cumsum(NEE_f_2021).*0.0216); hold on;
plot(cumsum(NEE_f_FCRN_2021).*0.0216); 
legend('SiteSpec','FCRN');

gf_TP02 = load('D:\Matlab\Data\Flux\Gapfilling\TP02\NEE_GEP_RE\Default\TP02_Gapfill_NEE_default.mat');

gf_TP39 = load('D:\Matlab\Data\Flux\Gapfilling\TP39\NEE_GEP_RE\Default\TP39_Gapfill_NEE_default.mat');
