function [x_out, y_out, fplot, h] = plot_SMhyp2(coeff_in, plot_flag)
%%% plot_SMlogi.m
%%% usage: [x_out, y_out] = plot_SMlogi(coeff_in, plot_flag)
%%% This function takes in pairs of coefficient values for the logistic,
%%% scaling SM function, and outputs predicted x and y values, and plots
%%% these all on the same graph (if plot_flag is not set to zero).
%%% Created Aug 6, 2010 by JJB

if nargin == 1
plot_flag = 1;
end

xneg = (-0.3:0.01:0)';
x = (0:0.001:0.5)';
num_reps = size(coeff_in,1);
% clrs = colormap(lines(num_reps));
S = (lines(num_reps) + gray(num_reps))/2;
clrs = colormap(S);
% hp = coeff_in(:,1)./coeff_in(:,2);
if plot_flag ==1 
fplot = figure('Name','SM_coeff_test');clf;
end
SM_pred = NaN.*ones(length(x),num_reps);
SM_pred_neg = NaN.*ones(length(xneg),num_reps);
x_out = [];
for i = 1:1:num_reps
% SM_pred(:,i) = 1./(1 + exp(coeff_in(i,1)-coeff_in(i,2).*x(:,1)));
% SM_pred_neg(:,i) = 1./(1 + exp(coeff_in(i,1)-coeff_in(i,2).*xneg(:,1)));
SM_pred(:,i) = (((coeff_in(i,1).*x(:,1).*(1-coeff_in(i,2)))./(coeff_in(i,1).*x(:,1) + (1-coeff_in(i,2)))) + coeff_in(i,2));
SM_pred_neg(:,i) = (((coeff_in(i,1).*xneg(:,1).*(1-coeff_in(i,2)))./(coeff_in(i,1).*xneg(:,1) + (1-coeff_in(i,2)))) + coeff_in(i,2));
x_out = [x_out [xneg;x]];
if plot_flag==1
plot(xneg,SM_pred_neg(:,i),'--','Color',clrs(i,:)); hold on;
h(i) = plot(x,SM_pred(:,i),'.-','Color',clrs(i,:)); hold on;
% plot([hp(i,1) hp(i,1) ],[0 0.5],':','Color',clrs(i,:));
% text(hp(i,1)-0.025, 1-(i/10),num2str(hp(i,1)),'Color',clrs(i,:))
text(0.505,SM_pred(end,i),num2str(i),'Color',clrs(i,:));
end
legend_title{i,1} = num2str(i);
end
axis([-0.3 0.5 0 1]);
if plot_flag==1
xlabel('SWC (%)');
ylabel('Scaling Factor');
legend(h,legend_title)
end
grid on;
% x_out = [xneg.*ones(length(xneg),num_reps); x.*ones(length(x),num_reps)];
y_out = [SM_pred_neg; SM_pred];
