function psi = recomputeFromData(psi1, psi2)
%let's recompute everything from all data
psi=psi1;
psi.thresholdsIni = unique([log10([1,10,100,1000,2000,100000]),linspace(log10(psi.tmin),log10(psi.tmax1),psi.gridSizeT)]); %range of possible values for thresholds T, in log10(arcsec)              
psi.history = [psi1.history; psi2.history];
psi.trial = size(psi.history,1);
psi.new_thresholds = unique([psi1.new_thresholds,psi2.new_thresholds,psi.thresholdsIni]);
psi.new_disparities = [1 2];
               [psi.tt, psi.ss, psi.ll, psi.xx] = ndgrid(psi.new_thresholds, psi.slopes, psi.neg_slopes, psi.new_disparities);
                psi.prior = ones(size(psi.tt(:,:,:,1)))./numel(psi.tt); % reinitialize a flat prior
                   for j=1:psi.trial % and update with the history of data
                      disp_j = psi.history(j,2); resp_j = psi.history(j,3);
                      psi.likelihoodCR = defineLikelihood_bell(psi.g, psi.ll(:,:,:,1), psi.ss(:,:,:,1), psi.delta, psi.p, log10(disp_j), psi.tt(:,:,:,1), psi.lapse); % psis for success
                      if resp_j == 1
                        % The probability of a response given the disparity shown
                        psi.pCR = sum(psi.likelihoodCR(:).*psi.prior(:)); % success
                        % The posterior, which is the probability of parameters given a response at a potential disparity x
                        psi.prior = psi.likelihoodCR.*psi.prior./psi.pCR; %here?
                      else
                        psi.likelihoodFail = 1 - psi.likelihoodCR; % psis for failure
                        psi.pFail = sum(psi.likelihoodFail(:).*psi.prior(:)); % failure
                        psi.prior = psi.likelihoodFail.*psi.prior./psi.pFail;
                      end
                   end
                   
            weightedThres = psi.tt(:,:,:,1).*psi.prior;    
            sumWeightThres = sum(weightedThres(:));
            psi.threshold = 10.^sumWeightThres;
            
            weightedSlope= psi.ss(:,:,:,1).*psi.prior;   
            weightedNegSlo= psi.ll(:,:,:,1).*psi.prior;
            psi.curr_est_sum_pos_slo = sum(weightedSlope(:));
            psi.curr_est_sum_neg_slo = sum(weightedNegSlo(:));
        %marginalize distributions for stereoblindness calculation
            psi.marg_thr=squeeze(sum(sum(psi.prior(:,:,:,1),3),2));
            psi.stereoblind_prob = 100*sum(psi.marg_thr((10.^psi.new_thresholds)>=psi.maxAllowerThreshold));
            
end