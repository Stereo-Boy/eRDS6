function stereoAcuity(filepath)
% This function analyze the results of eRDS6 psi algorithm to visualize the
% data and the threshold
%
% data structure is (in psi.history)
%   1       current psi trial
%   2       current disparity shown
%   3       psi.correct or not
%   4-6     current estimates for thres / slope / neg_slope using sum method
%   7      final 75% threshold estimate using sum parameters
%   8       trial # (different from psi.trial)
load(filepath,'psi1','psi2')

pStereoblind1 = plotIt(1,psi1);
disp('-------------------------------------------------------')
dispi('    ',psi1.sign,' disparities')
disp('-------------------------------------------------------')
dispi('Final threshold: ',round(psi1.threshold,1),' arcsec')
dispi('Probability to be ',psi1.sign,'-stereoblind: ',sprintf('%.0f%%',pStereoblind1))
disp(' ')
pStereoblind2 = plotIt(2,psi2);
disp('-------------------------------------------------------')
dispi('    ',psi2.sign,' disparities')
disp('-------------------------------------------------------')
dispi('Final threshold: ',round(psi2.threshold,1),' arcsec')
dispi('Probability to be ',psi2.sign,'-stereoblind: ',sprintf('%.0f%%',pStereoblind2))    
disp(' ')
end

function pStereoblind = plotIt(fig,psi)
        curr_est_sum_thr = psi.history(end,4);
        curr_est_sum_pos_slo = psi.history(end,5);
        curr_est_sum_neg_slo = psi.history(end,6);
        shown_disp = psi.history(:,2);
        correct_resp = psi.history(:,3);
        thres_history = psi.history(:,7);
        slope_history = psi.history(:,5);
        
        figure(fig)
        %marginalize distributions for plotting
        marg_thr=squeeze(sum(sum(psi.prior(:,:,:,1),3),2));
        marg_slo=squeeze(sum(sum(psi.prior(:,:,:,1),3),1));
        marg_lap=squeeze(sum(sum(psi.prior(:,:,:,1),2),1));

        subplot(2,3,1) % threshold estimate distribution
        hold off
         plot(10.^psi.thresholds(1:end-1),marg_thr(1:end-1),'k'); hold on
         pStereoblind = 100*sum(marg_thr((10.^psi.thresholds)>=1300));
         text(0.1,max(marg_thr(1:end-1))/2,sprintf('  p(stereoblind) = %.2f%%',pStereoblind))
         %plot(10.^disparities,ExpEntropy,'--b')
         %plot([10.^current_disp 10.^current_disp],[min(marg_thr), max(marg_thr(1:end-1))],'-g')
         plot([curr_est_sum_thr curr_est_sum_thr],[min(marg_thr), max(marg_thr(1:end-1))],'--r')
         %plot([curr_est_max_thr curr_est_max_thr],[min(marg_thr), max(marg_thr(1:end-1))],'--b')
         xlabel('Thresholds (")')
         title('Posterior for threshold')
         ylabel('Marginalized probability')
         
        subplot(2,3,2) % positive slope estimate distribution
        hold off
         plot(psi.slopes,marg_slo,'k'); hold on
         plot([curr_est_sum_pos_slo curr_est_sum_pos_slo],[min(marg_slo), max(marg_slo)],'--r')
         % plot([curr_est_max_pos_slo curr_est_max_pos_slo],[min(marg_slo), max(marg_slo)],'--b')
         xlabel('Positive slopes')
        title('Posterior for pos. slope')
        ylabel('Marginalized probability')
        
        subplot(2,3,3) % negative slope estimate distribution
        hold off
         plot(psi.neg_slopes,marg_lap,'k'); hold on
         plot([curr_est_sum_neg_slo curr_est_sum_neg_slo],[min(marg_lap), max(marg_lap)],'--r')
         % plot([curr_est_max_neg_slo curr_est_max_neg_slo],[min(marg_lap), max(marg_lap)],'--b')
         xlabel('Negative slopes')
        title('Posterior for neg. slope')
        ylabel('Marginalized probability')
        
        subplot(2,3,4) % estimated psychometric function
         hold on
         %plot(10.^disparities, defineLikelihood_bell(g, curr_est_max_neg_slo, curr_est_max_pos_slo, delta, p, disparities, log10(curr_est_max_thr), lapse),'b')
         plot(10.^psi.disparities, defineLikelihood_bell(psi.g, curr_est_sum_neg_slo, curr_est_sum_pos_slo, psi.delta, psi.p, psi.disparities, log10(curr_est_sum_thr), psi.lapse),'-k')
         %plot([thr_max thr_max],[0 1],'b--')
         plot([psi.thr_sum psi.thr_sum],[0 1],'r--')
        %plot(10.^disparities, defineLikelihood_bell(g, neg_slope, current_estimates_sum(2), disparities, log10(current_estimates_sum(1))),'r')
         axis([10.^min(psi.disparities), 10.^max(psi.disparities), psi.g-0.1, 1])
         xlabel('Disparity (arcsec)')
        title(['Psychometric function: ',psi.sign, ' disparities'])
        ylabel('% CR')
        output = makeLevelEqualBoundsMean([shown_disp,correct_resp],ceil(psi.trial/17));
        
        scatter(output(:,1),output(:,2),output(:,3).*7,'ok')
        hold off
        set(gca, 'XScale', 'log')
        xticks([1 10 20 50 100 200 500 1000 2000])
        xticklabels({'1' '10' '20' '50' '100' '200' '500' '1000' '2000'})
%         %contourf(disparities,psi.thresholds,posterior)
%         plot(psi.thresholds, posterior)
%         xlabel('psi.thresholds (log10 arcsec)')
%         ylabel('posterior probability')
        
       subplot(2,3,5); % history of threshold estimate
      axis([1 psi.trial psi.xmin psi.xmax])
      hold on
       plot(psi.history(correct_resp==1,1),psi.history(correct_resp==1,2),'ok')
       plot(psi.history(correct_resp==0,1),psi.history(correct_resp==0,2),'xr')
       plot(1:psi.trial,thres_history,'-b');
       plot([1,psi.trial], [psi.thr_sum psi.thr_sum], '--r')
       xlabel('Trial')
       ylabel('Threshold')
       title('History of threshold estimate')
       text(20, 1000, sprintf('Trials: %d',psi.trial))
       text(20, 700, sprintf('Estimate: %d" (%d")',round(psi.thr_sum),round(psi.threshold)))
       set(gca, 'YScale', 'log')
       yticks([1 10 50 100 500 1000 2000])
       yticklabels({'1' '10' '50' '100' '500' '1000' '2000'})
        
       subplot(2,3,6); % history of slope estimate
       hold on;
       plot(1:psi.trial,slope_history,'-k');
       plot([1,psi.trial], [curr_est_sum_pos_slo curr_est_sum_pos_slo], '--r')
        hold on;
       ylabel('Positive slope')
       xlabel('Trial')
       title('History of slope estimate')
       axis([1 psi.trial min(psi.slopes) max(psi.slopes)])
       
%         contourf(psi.disparities,psi.thresholds,psi.prior)
%         %plot(psi.disparities,psi.prior);
%         %line([current_disp current_disp], [min(likelihood) max(likelihood)]) %chosen disparity for this trial
%         xlabel('Thresholds (log10 arcsec)')
%         ylabel('Posterior likelihood')

       
end