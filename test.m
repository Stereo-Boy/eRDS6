
addpath('C:\Users\Adrian\Google Drive\recherches partiel\2019_ASM_Accurate_Stereoacuity_Measure\eRDS6\eRDS_functions')
        psi.xmin= 3; %minimal disparity possible in arcsec (cannot measure thresholds below that value!)
        psi.x1 = 1200;
        psi.x2 = 1400;
        psi.xmax = 3000; %max one (cannot measure thresholds above that value!)
        psi.xstep1 = 0.001; %step size for sampling in log unit 0.05
        psi.xstep2 = 0.001;
        psi.disparities = [log10(psi.xmin):psi.xstep1:log10(psi.x1),log10(psi.x1):psi.xstep2:log10(psi.x2),...
            log10(psi.x2):psi.xstep1:log10(psi.xmax)]; %range of possible values for disparities x, in log10(arcsec)
        
        psi.tmin = 3; % minimal threshold that we parametrized
        psi.t1 = 1000;
        psi.t2 = 1600;
        psi.tmax = 2200; % maximal threshold that we parametrized  
        psi.tstep1 = 0.04; %step size for this parameter in log unit 0.05
        psi.tstep2 = 0.04;
        psi.thresholds = [log10(psi.tmin):psi.tstep1:log10(psi.t1),log10(psi.t1):psi.tstep2:log10(psi.t2),...
            log10(psi.t2):psi.tstep1:log10(psi.tmax),log10(100000)]; %range of possible values for thresholds T, in log10(arcsec)

        psi.slopes = [0.2,0.4,0.8,1.6,3.2]; %range of possible values for slope s

        psi.neg_slopes = [0,0.003,0.006,0.012,0.024,0.056,0.112];
        
        psi.lapse = 0.035/2; % we assumed a fixed lapse (finger error) rate (in %)
        psi.maxAllowerThreshold=1300; % threshold considered stereoblindness
        psi.g = 0.5; %guess rate (we have one chance out of 2 - 2AFC)
        psi.delta = 0.01; %what part of the psychometric function is considered ([delta, 1-delta]
        psi.p = 0.75; %success rate at threshold
        psi.practice = log10([ %if we have practice trials, their disparities will be these ones, in that order
            1300      
            1300    
            1300    
            1300     
            1300    
            1000    
            1000      
            1000    
            1000    
            1000     
            500    
            500   
            500      
            500    
            500    
            250     
            250    
            250    
            250      
            250    
            100    
            100     
            100    
            100    
            100    
            ]);
        psi.sim_threshold = 1000; %simulated threshold whenever we do robotMode
        plotIt=1; 
        everyStep=10;
        expe.inputMode=2;
        expe.nn = 85;
        scr.screenNumber=0;
        expe.practiceTrials = 25; 
        duration=nan(1,expe.nn);
        
        for i=1:expe.nn
            psi.trial=i;
            tic;
            psi = Psi_marg_erds6(psi, expe, scr);
            duration(i) = toc;
            if plotIt==1 && (mod(i,everyStep)==2 || i==expe.nn)
                
                %marginalize distributions for plotting
                marg_thr=squeeze(sum(sum(psi.prior(:,:,:,1),3),2));
                marg_slo=squeeze(sum(sum(psi.prior(:,:,:,1),3),1));
                marg_lap=squeeze(sum(sum(psi.prior(:,:,:,1),2),1));
                
                subplot(2,3,1)
                hold off
                plot(10.^psi.thresholds(1:end-1),marg_thr(1:end-1),'k'); hold on
                text(0.1,max(marg_thr(1:end-1))/2,sprintf('p(stereoblind) = %.2f%%',100*sum(marg_thr((10.^psi.thresholds)>=1300))))
                %plot(10.^disparities,ExpEntropy,'--b')
                plot([10.^psi.current_disp 10.^psi.current_disp],[min(marg_thr), max(marg_thr(1:end-1))],'-g')
                if psi.sim_threshold<2000
                    plot([psi.sim_threshold psi.sim_threshold],[min(marg_thr), max(marg_thr(1:end-1))],'-k')
                end
                %plot([curr_est_sum_thr curr_est_sum_thr],[min(marg_thr), max(marg_thr(1:end-1))],'--r')
                %plot([curr_est_max_thr curr_est_max_thr],[min(marg_thr), max(marg_thr(1:end-1))],'--b')
                xlabel('psi.thresholds (arcsec)')
                title('Posterior for threshold, marginalized')
                ylabel('Probability')
                 
                subplot(2,3,2)
                hold off
                plot(psi.slopes,marg_slo,'k'); hold on
                plot([psi.sim_pos_slope psi.sim_pos_slope],[min(marg_slo), max(marg_slo)],'-k')
               % plot([curr_est_sum_pos_slo curr_est_sum_pos_slo],[min(marg_slo), max(marg_slo)],'--r')
               % plot([curr_est_max_pos_slo curr_est_max_pos_slo],[min(marg_slo), max(marg_slo)],'--b')
                xlabel('pos. slopes')
                title('Posterior for pos. slope, marginalized')
                ylabel('Probability')
                
                subplot(2,3,3)
                hold off
                plot(psi.neg_slopes,marg_lap,'k'); hold on
                plot([psi.sim_neg_slope psi.sim_neg_slope],[min(marg_lap), max(marg_lap)],'-k')
               % plot([curr_est_sum_neg_slo curr_est_sum_neg_slo],[min(marg_lap), max(marg_lap)],'--r')
               % plot([curr_est_max_neg_slo curr_est_max_neg_slo],[min(marg_lap), max(marg_lap)],'--b')
                xlabel('neg. slopes')
                title('Posterior for neg. slope, marginalized')
                ylabel('Probability')
                
                subplot(2,3,4)
                plot(10.^psi.disparities, defineLikelihood_bell(psi.g, psi.sim_neg_slope, psi.sim_pos_slope, psi.delta, psi.p, psi.disparities, log10(psi.sim_threshold), psi.sim_lapse),'k')
                hold on
%                plot(10.^psi.disparities, defineLikelihood_bell(psi.g, curr_est_max_neg_slo, curr_est_max_pos_slo, delta, psi.p, psi.disparities, log10(curr_est_max_thr), psi.lapse),'b')
%                plot(10.^psi.disparities, defineLikelihood_bell(psi.g, curr_est_sum_neg_slo, curr_est_sum_pos_slo, delta, psi.p, psi.disparities, log10(curr_est_sum_thr), psi.lapse),'r')
                plot([psi.sim_threshold psi.sim_threshold],[0 1],'k')
               % plot([thr_max thr_max],[0 1],'b--')
                plot([psi.thr_sum psi.thr_sum],[0 1],'r--')
                %plot(10.^disparities, defineLikelihood_bell(g, neg_slope, current_estimates_sum(2), disparities, log10(current_estimates_sum(1))),'r')
                legend('Actual','Max','Sum','Location','NorthWest')
                axis([10.^min(psi.disparities), 10.^max(psi.disparities), psi.g-0.1, 1])
                xlabel('Log disparity (log arcsec)')
                title('Expected psychometric function')
                ylabel('% CR')
                text(20, 0.7, sprintf('Trial %d',i))
                text(20, 0.75, sprintf('Actual %d"',psi.sim_threshold))
                text(20, 0.8, sprintf('Estimated %d" / %d"',round(0),round(psi.thr_sum)))
                output = makeLevelEqualBoundsMean(psi.history(isnan(psi.history(:,1))==0,[1,2]),ceil(i/15));
                
                scatter(output(:,1),output(:,2),output(:,3).*7,'ok')
                hold off
                set(gca, 'XScale', 'log')
                %         %contourf(disparities,thresholds,posterior)
                %         plot(thresholds, posterior)
                %         xlabel('thresholds (log10 arcsec)')
                %         ylabel('posterior probability')
                
                subplot(2,3,5);
                axis([1 expe.nn psi.xmin psi.xmax])
                hold on
                %plot(1:i,psi.history(1:i,[3,9]),'-^');
                plot(1:i,psi.history(1:i,[3 6]),'--');
                legend('estim. sum','75% sum');
                if psi.history(i,2)==1
                    plot(i,psi.history(i,1),'ok')
                else
                    plot(i,psi.history(i,1),'xr')
                end
                xlabel('Trial')
                ylabel('Disparity threshold')
                plot([1 expe.nn], [psi.sim_threshold psi.sim_threshold])
                
%                 subplot(2,3,6);
%                 hold on;
%                 plot(1:i,storingDisp(1:i,4),'-');
%                 hold on;
%                 plot(1:i,storingDisp(1:i,7),'--');
%                 plot([1 trial_nb], [sim_pos_slope sim_pos_slope])
%                 legend('estim. max',' estim. sum')
%                 ylabel('Slope')
%                 xlabel('Trial')
                
                drawnow
        
                
            end
     
        end
      mean(duration)