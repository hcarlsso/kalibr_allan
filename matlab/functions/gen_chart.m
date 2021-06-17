function [fh1] = gen_chart(tau,sig,titlestr,name,unit,white_n, rw_n)

tau = reshape(tau,[],1);

% =======================================================================
% Plot the results on a figure
fh1 = figure;
ls = ["-", "-", "-"];
dirs = ["x","y","z"];
for i = 1:3
    label = strcat(dirs(i),'-',name);
    loglog(tau, sig(:,i), ls(i), "DisplayName",label); hold on;
end
grid on;
title([titlestr,' ',name]);
xlabel('\tau [sec]');
ylabel(['Normal Allan Deviation [',unit,']']);
cOrder = get(gca,'colororder');

% =======================================================================
% Estimate N2

mask_min = tau > white_n.taumin;
mask_max = tau < white_n.taumax;
mask = logical(mask_min .* mask_max);
A = 1./tau;
sig2 = sig.^2;
A_eff = A(mask,:);
% Should weight with standard error of sig2
N2 = (A_eff'*A_eff)\(A_eff'*sig2(mask,:));
sig2_hat = A*N2;

sig_hat = sqrt(sig2_hat);
N = sqrt(N2);
for i = 1:3
    label = sprintf("N=%.2e", N(i));
    loglog(tau, sig_hat(:,i),"--", 'Color', cOrder(i,:), "DisplayName", label); hold on;
end


% =======================================================================
% Estimate K2

mask_min = tau > rw_n.taumin;
mask_max = tau < rw_n.taumax;
mask = logical(mask_min .* mask_max);
A = tau/3;
sig2 = sig.^2;
A_eff = A(mask,:);
% Should weight with standard error of sig2
K2 = (A_eff'*A_eff)\(A_eff'*sig2(mask,:));
sig2_hat = A*K2;

sig_hat = sqrt(sig2_hat);
K = sqrt(K2);
for i = 1:3
    label = sprintf("K=%.2e", K(i));
    loglog(tau, sig_hat(:,i),"--", 'Color', cOrder(i,:), "DisplayName", label); hold on;
end


legend('Location','southwest', "AutoUpdate","off");

yLim = get(gca, "YLim");

patch([white_n.taumin white_n.taumin white_n.taumax white_n.taumax],...
    [yLim(2) yLim(1) yLim(1) yLim(2)],ones(1,4),...
    'FaceColor','b','facealpha',0.2);

patch([rw_n.taumin rw_n.taumin rw_n.taumax rw_n.taumax],...
    [yLim(2) yLim(1) yLim(1) yLim(2)],ones(1,4),...
    'FaceColor','r','facealpha',0.2);

end

