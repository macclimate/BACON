%footprint_hsieh.m: Estimates the footprint (or source weight function)
%                   along the upwind distance (x=0 is measuring point)
%
%Authors:           Gaby Katul and Cheng-I Hsieh
%
%Reference:         Hsieh, C.I., G.G. Katul, and T.W. Chi, 2000,
%                   "An approximate analytical model for footprint estimation of scalar fluxes
%                   in thermally stratified atmospheric flows",
%                   Advances in Water Resources, 23, 765-772.
%
%Usage: [Fc, Fp, L,xp,x]=footprint_hsieh(ustar,H,Ta,zm,zo)
%
%Fc = Cumulative source contribution with distance (fraction)
%fp = Source-weight function (with distance)
%L  = Obukhov length (m)
%xp = Peak distance from measuring point to the maximum contributing source area (m)
%x  = Distance vector used in the computation of Fc, fp (m)
%F2H=Fetch to Height ratio (for 90% of flux recovery, i.e. 100:1 or 20:1)
%
%ustar = friction velocity (m/s)
%H     = Sensible heat (W/m2)
%Ta    = Mean air temperature (oC)
%z    = Instrument height (m)
%h    = Height of roughness elements (forest height, m)
%---------------------------------------------------------------------------------------------------------
% function [Fc, Fp, x,L,xp,F2H]=mcm_footprint_hsieh(ustar,H,Ta,zm,zo)
function [Fc,L,xp,F2H,zL]=mcm_footprint_hsieh(ustar,H,Ta,z,h)
Fc = NaN.*ones(length(Ta),10);
xp = NaN.*ones(length(Ta),1);

%%% Specify Parameter Values:
z0 = 0.1*h;
d = (2.*h)/3;
zm = z - d;
k=0.4;                              %Von karman constant
Cp=1005;                            %Specific heat capacity of dry air at constant pressure (J/kg K)
g=9.81;                             % Gravitational constant
Ta_K=Ta+273.15;                     % Convert oC to K
rho=1.3079-0.0045*Ta;               % Density of air (kg/m3)
%%% Calculate Obukhov Length
L=(-rho.*((ustar+eps).^3).*Cp.*Ta_K)./(k.*g.*((H+eps))); % Obukhov Length (m)

% Equations (15)-(17) from Hsieh et al. (2000)
zu=zm*(log(zm/z0)-1+z0/zm);
P=[0.59 1 1.33];
D=[0.28 0.97 2.44];
Mu=[100 500 2000];
zL=zu./L;
thresh=0.04;

D1 = NaN.*ones(length(zL),1);
P1 = NaN.*ones(length(zL),1);
Mu1 = NaN.*ones(length(zL),1);

D1(zL < (-1.*thresh),1) = D(1); P1(zL < (-1.*thresh),1) = P(1); Mu1(zL < (-1.*thresh),1) = Mu(1);
D1(abs(zL) <= thresh,1) = D(2); P1(abs(zL) <= thresh,1) = P(2); Mu1(abs(zL) <= thresh,1) = Mu(2);
D1(zL > thresh,1) = D(3); P1(zL > thresh,1) = P(3); Mu1(zL > thresh,1) = Mu(3);

min_x=(Mu1./100)*z0;
max_x=Mu1.*zm;
x_bin=(max_x-min_x)./1000;

%%% Cycle through all data points and estimate the fetch distance for
%%% different % flux contours:
for j = 1:1:length(zL)
    x=(min_x(j):x_bin(j):max_x(j))';
    
    temp_Fc = NaN.*ones(length(x),1);
    temp_Fp = NaN.*ones(length(x),1);
    
    c1=(-1/k/k)*(D1(j,1)*zu^P1(j,1)*abs(L(j,1))^(1-P1(j,1)))./x;
    
    temp_Fc(:,1)=exp(c1);
    temp_Fp(:,1)=-(c1./x).*temp_Fc(:,1);
    xp(j,1)=(1/2/k/k)*(D1(j,1)*zu^P1(j,1)*abs(L(j,1))^(1-P1(j,1)));
    F2H=(D1(j,1)/0.105/k/k)*(zm^(-1)*abs(L(j,1))^(1-P1(j,1))*zu^(P1(j,1)));
    
    ctr = 1;
%     if j >= 70;
%         disp(j);
%     else
%     end
    for flux_pct = 0.5:0.05:0.95
        try
        ind = find(temp_Fc > flux_pct,1,'first');
        Fc(j,ctr) = x(ind,1);
        catch
            if temp_Fc(end) < flux_pct
                Fc(j,ctr) = x(end);
            else
         Fc(j,ctr) = NaN;   
            end
        end
        clear ind
        ctr = ctr+1;
    end
end