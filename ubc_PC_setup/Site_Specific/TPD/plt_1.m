k = min([length(data_Aux) length(data_uz)]);

figure(1)
plot([1:k]/20,[data_Aux(1:k) data_uz(1:k)])
zoom on
title('Synchronization channel (Uz)')
legend('Licor AUX','CSAT Uz')
xlabel('Seconds')
ylabel('m/s')

figure(2)
plot([1:k]/20,[data_ux(1:k) data_uy(1:k) data_uz(1:k)])
zoom on
title('Wind speeds')
legend('Ux','Uy','Uz')
xlabel('Seconds')
ylabel('m/s')

figure(3)
plot([1:k]/20,((data_ux(1:k).^2+data_uy(1:k).^2+data_uz(1:k).^2).^0.5))
zoom on
title('Cup wind speed (3D)')
xlabel('Seconds')
ylabel('m/s')

figure(4)
plot([1:k]/20,[data_t(1:k)])
zoom on
title('Sonic Temperature')
xlabel('Seconds')
ylabel('deg C')

figure(5)
plot([1:k]/20,[data_temp(1:k)])
zoom on
title('LI-7500 Temperature')
xlabel('Seconds')
ylabel('deg C')

figure(6)
plot([1:k]/20,[data_CO2(1:k)])
zoom on
title('LI-7500 CO_2')
xlabel('Seconds')
ylabel('ppm')

figure(7)
plot([1:k]/20,[data_H2O(1:k)])
zoom on
title('LI-7500 H_2O')
xlabel('Seconds')
ylabel('mmol/mol')

figure(8)
plot([1:k]/20,[data_pressure(1:k)])
zoom on
title('LI-7500 Pressure')
xlabel('Seconds')
ylabel('kPa')


