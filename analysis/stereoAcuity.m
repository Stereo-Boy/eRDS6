function stereoAcuity(file)
% This function analyze the results of eRDS6 psi algorithm to visualize the
% data and the threshold
%
% data structure is (in psi.history)
%   1       current psi trial
%   2       current disparity shown in "
%   3       psi.correct or not
%   4-6     current estimates for thres / slope / neg_slope using sum method
%   7      final 75% threshold estimate using sum parameters
%   8       trial # (different from psi.trial)

close all;
[eRDSpath,~]=fileparts(fileparts(mfilename('fullpath'))); %path to erds folder
[~,filename,ext] = fileparts(file); 
if isempty(ext); ext='.mat'; end
load(fullfile(eRDSpath,'dataFiles',[filename,ext]),'psi1','psi2','expe');
addpath(fullfile(eRDSpath,'eRDS_functions'));
expe.eRDSpath = eRDSpath; expe.filename = filename;
dispi('Data file: ',filename);
dispi('Duration: ',round(expe.duration,1),' min');
disp('-------------------------------------------------------');
dispi('    ',psi1.sign,' disparities');
disp('-------------------------------------------------------');
plotIt(psi1,expe);
dispi('Raw threshold: ',round(psi1.threshold,1),' arcsec');
psi1.final_threshold=round(min(psi1.maxAllowerThreshold,psi1.threshold),1);
% if  psi1.stereoblind_prob>50
%     psi1.final_threshold=psi1.maxAllowerThreshold;
% end
dispi('Final threshold: ',psi1.final_threshold,' arcsec');
if psi1.final_threshold>=psi1.maxAllowerThreshold; dispi('Participant is ',psi1.sign,'-stereoblind'); end
dispi('Marginal probability to be ',psi1.sign,'-stereoblind: ',sprintf('%.0f%%',psi1.stereoblind_prob));
if  round(psi1.threshold,1)>1348 && round(psi1.threshold,1)<1413
    dispi('NB: threshold is in uncertainty area: [1348" - 1413"] - we cannot be sure whether participant is stereoblind or not.');
end

disp(' ');
disp('-------------------------------------------------------');
dispi('    ',psi2.sign,' disparities');
disp('-------------------------------------------------------');
plotIt(psi2,expe);
dispi('Raw threshold: ',round(psi2.threshold,1),' arcsec');
psi2.final_threshold=round(min(psi2.maxAllowerThreshold,psi2.threshold),1);
% if  psi2.stereoblind_prob>50
%     psi2.final_threshold=psi2.maxAllowerThreshold;
% end
dispi('Final threshold: ',psi2.final_threshold,' arcsec');
if psi2.final_threshold>=psi2.maxAllowerThreshold; dispi('Participant is ',psi2.sign,'-stereoblind'); end
dispi('Marginal probability to be ',psi2.sign,'-stereoblind: ',sprintf('%.0f%%',psi2.stereoblind_prob))   ; 
if  round(psi2.threshold,1)>1348 && round(psi2.threshold,1)<1413
    dispi('NB: threshold is in uncertainty area: [1348" - 1413"] - we cannot be sure whether participant is stereoblind or not.');
end
disp(' ')

disp('-------------------------------------------------------');
dispi('    composite threshold');
disp('-------------------------------------------------------');
psi = recomputeFromData(psi1, psi2);
psi.final_threshold=round(min(psi.maxAllowerThreshold,psi.threshold),1);
dispi('Final threshold: ',psi.final_threshold,' arcsec');
if psi.final_threshold>=psi.maxAllowerThreshold; dispi('Participant is likely stereoblind'); end
dispi('Marginal probability to be stereoblind: ',sprintf('%.0f%%',psi.stereoblind_prob))   ; 
figure('Color', 'w','OuterPosition',[0 0 6000 6000])
        hold on
        psi1.curr_est_sum_thr = psi1.history(end,4);
        psi1.curr_est_sum_pos_slo = psi1.history(end,5);
        psi1.curr_est_sum_neg_slo = psi1.history(end,6);
        psi1.shown_disp = psi1.history(:,2);
        psi1.correct_resp = psi1.history(:,3);
        plot(10.^psi1.disparities, defineLikelihood_bell(psi1.g, psi1.curr_est_sum_neg_slo, psi1.curr_est_sum_pos_slo, psi1.delta, psi1.p, psi1.disparities, log10(psi1.threshold), psi1.lapse),'-b')
        plot([psi1.threshold psi1.threshold],[0 1],'b--')
        axis([10.^min(psi.disparities), 10.^max(psi.disparities(1:end-1)), psi.g-0.1, 1])
        xlabel('Disparity (arcsec)')
        title('Psychometric function: near, far disparities and composite')
        ylabel('% CR')
        output = makeLevelEqualBoundsMean([psi1.shown_disp,psi1.correct_resp],ceil(psi1.trial/15));    
        scatter(output(:,1),output(:,2),output(:,3).*7,'ob');
        xticks([1 10 20 50 100 200 500 1000 2000]);
        xticklabels({'1' '10' '20' '50' '100' '200' '500' '1000' '2000'});
        set(gca, 'XScale', 'log');
        psi2.curr_est_sum_thr = psi2.history(end,4);
        psi2.curr_est_sum_pos_slo = psi2.history(end,5);
        psi2.curr_est_sum_neg_slo = psi2.history(end,6);
        psi2.shown_disp = psi2.history(:,2);
        psi2.correct_resp = psi2.history(:,3);
        plot(10.^psi2.disparities, defineLikelihood_bell(psi2.g, psi2.curr_est_sum_neg_slo, psi2.curr_est_sum_pos_slo, psi2.delta, psi2.p, psi2.disparities, log10(psi2.threshold), psi2.lapse),'-r')
        plot([psi2.threshold psi2.threshold],[0 1],'r--')
        output = makeLevelEqualBoundsMean([psi2.shown_disp,psi2.correct_resp],ceil(psi2.trial/15));    
        scatter(output(:,1),output(:,2),output(:,3).*7,'or');
        psi.shown_disp = psi.history(:,2);
        psi.correct_resp = psi.history(:,3);
        plot(10.^psi.disparities, defineLikelihood_bell(psi.g, psi.curr_est_sum_neg_slo, psi.curr_est_sum_pos_slo, psi.delta, psi.p, psi.disparities, log10(psi.threshold), psi.lapse),'-k')
        plot([psi.threshold psi.threshold],[0 1],'k--')
        output = makeLevelEqualBoundsMean([psi.shown_disp,psi.correct_resp],ceil(psi.trial/15));    
        scatter(output(:,1),output(:,2),output(:,3).*7,'ok');
end

function plotIt(psi,expe)
        curr_est_sum_thr = psi.history(end,4);
        curr_est_sum_pos_slo = psi.history(end,5);
        curr_est_sum_neg_slo = psi.history(end,6);
        shown_disp = psi.history(:,2);
        correct_resp = psi.history(:,3);
        thres_history = psi.history(:,7);
        slope_history = psi.history(:,5);
        range1_history = psi.history(:,9);
        range2_history = psi.history(:,10);
        dispi('Proportion of rescaling: ',round(100*(1-psi.donothing_counter/size(psi.history,1))),'%')
        figure('OuterPosition',[0 0 6000 6000],'Color', 'w');
        %marginalize distributions for plotting
        marg_thr=squeeze(sum(sum(psi.prior(:,:,:,1),3),2));
        marg_slo=squeeze(sum(sum(psi.prior(:,:,:,1),3),1));
        marg_lap=squeeze(sum(sum(psi.prior(:,:,:,1),2),1));

        subplot(2,3,1) % threshold estimate distribution
        hold off
        plot(10.^psi.thresholds(1:end-1),marg_thr(1:end-1),'k'); hold on
        text(max(psi.thresholds(1:end-1))/2,max(marg_thr(1:end-1))/3,sprintf('p(stereoblind) = %.2f%%',psi.stereoblind_prob))
        text(max(psi.thresholds(1:end-1))/2,max(marg_thr(1:end-1))/2,['ID: ',expe.name])

        plot([curr_est_sum_thr curr_est_sum_thr],[min(marg_thr), max(marg_thr(1:end-1))],'--r')
        xlabel('Thresholds (")')
        title('Posterior for threshold')
        ylabel('Marginalized probability')
        set(gca, 'XScale', 'log');
        xticks([1 10 100 500 1000]);
        xticklabels({'1' '10' '100' '500' '1000'});
        
        subplot(2,3,2) % positive slope estimate distribution
        hold off
        plot(psi.slopes,marg_slo,'k'); hold on
        plot([curr_est_sum_pos_slo curr_est_sum_pos_slo],[min(marg_slo), max(marg_slo)],'--r')
        xlabel('Positive slopes')
        title('Posterior for positive slope')
        ylabel('Marginalized probability')
         
        subplot(2,3,3) % negative slope estimate distribution
        hold off
        plot(psi.neg_slopes,marg_lap,'k'); hold on
        plot([curr_est_sum_neg_slo curr_est_sum_neg_slo],[min(marg_lap), max(marg_lap)],'--r')
        xlabel('Negative slopes')
        title('Posterior for negative slope')
        ylabel('Marginalized probability')
        
         
        subplot(2,3,4) % estimated psychometric function
        hold on
        plot(10.^psi.disparities, defineLikelihood_bell(psi.g, curr_est_sum_neg_slo, curr_est_sum_pos_slo, psi.delta, psi.p, psi.disparities, log10(curr_est_sum_thr), psi.lapse),'-k')
        plot([psi.thr_sum psi.thr_sum],[0 1],'r--')
        axis([10.^min(psi.disparities), 10.^max(psi.disparities), psi.g-0.1, 1])
        xlabel('Disparity (arcsec)')
        title(['Psychometric function: ',psi.sign, ' disparities'])
        ylabel('% CR')
        output = makeLevelEqualBoundsMean([shown_disp,correct_resp],ceil(psi.trial/15));    
        scatter(output(:,1),output(:,2),output(:,3).*7,'ok');
        hold off
        set(gca, 'XScale', 'log');
        xticks([1 10 20 50 100 200 500 1000 2000]);
        xticklabels({'1' '10' '20' '50' '100' '200' '500' '1000' '2000'});
             
       subplot(2,3,5); % history of threshold estimate
      axis([1 psi.trial psi.xmin2 psi.xmax]);
      hold on
       plot(psi.history(correct_resp==1,1),psi.history(correct_resp==1,2),'og')
       plot(psi.history(correct_resp==0,1),psi.history(correct_resp==0,2),'xr')
       plot(1:psi.trial,thres_history,'-b');
       plot([1,psi.trial], [psi.thr_sum psi.thr_sum], '--r')
       plot(1:psi.trial,10.^range1_history,'r')
       plot(1:psi.trial,10.^range2_history,'r')
       xlabel('Trial')
       ylabel('Threshold estimate')
       title('History of threshold estimate')
       text(20, 1000, sprintf('Total trials: %d',psi.trial))
       text(20, 500, sprintf('Estimate: %d" (%d")',round(psi.thr_sum),round(psi.threshold)))
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
       saveas(gcf,fullfile(expe.eRDSpath,'figures', [expe.filename,'_',psi.sign,'.fig']));
       saveas(gcf,fullfile(expe.eRDSpath,'figures', [expe.filename,'_',psi.sign,'.png']));

end
















