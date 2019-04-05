function [R3,CSAT,TC,Licor1,Licor2] = pa_test(dateIn)

% modified from pa_test used at OY

% nick, Nov 11, 2006


if ~exist('dateIn')
    dateIn = now;
end

[Stats_New,HF_Data] = yf_calc_module_main(dateIn,'yf',1);
LI_7000 = HF_Data.Instrument(2).EngUnits; % instrument numbers from yf_init_all
Gill = HF_Data.Instrument(1).EngUnits;
t = [1:length(LI_7000)]/20;
figure(1)
subplot(4,1,1)
plot(t,LI_7000(:,1))
zoom on
ylabel('CO_2')
xlabel('T (sec)')

subplot(4,1,2)
plot(t,LI_7000(:,2))
zoom on
ylabel('H_2O')
xlabel('T (sec)')

subplot(4,1,3)
plot(t,LI_7000(:,3))
zoom on
ylabel('Tbench')
xlabel('T (sec)')

subplot(4,1,4)
plot(t,LI_7000(:,4))
zoom on
ylabel('Plicor')
xlabel('T (sec)')

figure(2)
t_sonic = [1:length(Gill)]/20;
subplot(2,1,1)
plot(t_sonic,Gill(:,1:3))
zoom on
ylabel('Wind')
xlabel('T(sec)')

subplot(2,1,2)
plot(t_sonic,Gill(:,4))
zoom on
ylabel('Temp')
xlabel('T(sec)')
