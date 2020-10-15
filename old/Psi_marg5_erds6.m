function psi = Psi_marg6_erds6(action, trialID, psi, expe, scr)
% Psi algorithm for working with erds files
% 
% This version of Psi implements 3 parameter estimates (threshold / positive slope / negative slope) with marginalization on the
% 2nd and 3d parameters (psi.slopes) following Prins (2013)
% The psychometric function is a non-monotonic adaptation of the logistic
% function defined by Serrano-Pedraza et al., 2016 (IOVS) and Garc?a-Pérez (1998)
%
% The negative slope translates the fact that performance goes back to
% chance level for very large psi.disparities
%
% This code implements a parametrized Bayesian estimation that can work in spaces of more than one parameter (simultaneously), 
% thanks to entropy minimization. It means that it calculates the sampling that will increase the expected information learned from the next trial,
% given the current data, in approximately 30 trials. The method seems robust to attentional lapses.
% It follows: Kontsevich & Tyler, 1999
%
% It is currently set up for a 2AFC detection task 
% action
%       'value' - find the next disparity to show
%       'record' - record the result of the trial
% trialID is the ID number (independently of psi.trial)
% psi is the algorithm structure
% expe is a structure that needs to contain at least
%       expe.inputMode (1 - person, 2 robot)
%       expe.nn - the number of non-practice trials (for a near or a far side only)
%       expe.practiceTrials - the number of practice trials (for a near or a far side only)
%
% Adrien Chopin - 2020


try
    
% ------------------------------
% INITIALIZATION if first trial
% ------------------------------
if strcmp(action,'value')
    if psi.trial==1
        % Limit values and parameters 
        if expe.inputMode==1
            psi.sim=0; 
        else
            psi.sim=1;
            % PARAM for simulated psychometric function
            psi.sim_pos_slope = 0.4+rand(1).*(3-0.4); % random simulated slope
            %pos_slope=1;
            psi.sim_neg_slope = rand(1).*0.112; % random simulated negative slope
            psi.sim_lapse = 0.005+rand(1).*0.03; % random finger rate error
        end

        % STEP 0
        % Any parameter defined below is not varying through the estimation
        % We assume a value for them (actually defined in parametersERDS6
        psi.history=nan(expe.nn,8);
        psi.labels = {'psi trials','disparity','correct','thres est.','slope est.', 'neg slope est.', 'threshold','trial #'};
        
        % Parameter space
        [psi.tt, psi.ss, psi.ll, psi.xx] = ndgrid(psi.thresholds, psi.slopes, psi.neg_slopes, psi.disparities);

        % psi.prior defining the psi.prior (same space as likelihood, information that we gives at the beginning 
        psi.prior = ones(size(psi.tt))./numel(psi.tt); %start with uniform psi.prior distribution for disparity threshold (a vector of possible threshold and
            % the probability associated with each) -> this is the probability of a threshold

        % Likelihoods - properties defining the likelihoods (a set of psychometric functions for success rate depending on the disparity presented and the threshold)
        % It is the probability of success or failure given a set of parameter and a disparity x
        psi.likelihoodCR = defineLikelihood_bell(psi.g, psi.ll, psi.ss, psi.delta, psi.p, psi.xx, psi.tt, psi.lapse); % psis for success
        psi.likelihoodFail = 1 - psi.likelihoodCR; % psis for failure
    end

       % STEP 1
       % The probability of a response given the disparity shown

       pCR = sum(sum(sum(psi.likelihoodCR.*psi.prior))); % success
       pFail = sum(sum(sum(psi.likelihoodFail.*psi.prior))); % failure

       % STEP 2
       % The posterior, which is the probability of parameters given a response at a potential disparity x
       psi.postCR = psi.likelihoodCR.*psi.prior./pCR; %here?
       psi.postFail = psi.likelihoodFail.*psi.prior./pFail;

       % STEP 2-b
       % Marginalization on slope and neg_slope parameters
       marg_postCR = squeeze(sum(sum(psi.postCR,3),2));
       marg_postFail = squeeze(sum(sum(psi.postFail,3),2));

       % STEP 3
       % Entropy of the marginalized parameter space for a given response at a potential disparity x
       EntropyCR = -sum(marg_postCR.*log(marg_postCR))';
       EntropyFail = -sum(marg_postFail.*log(marg_postFail))';

       % STEP 4
       % Expected entropy for each disparity x, whatever the response
       ExpEntropy = EntropyCR.*squeeze(pCR) + EntropyFail.*squeeze(pFail);

       % STEP 5
       % Find disparity with minimum expected entropy
       if psi.trial<=expe.practiceTrials % in practice trials, we do not choose next disparity but just take the closest to the one is given to us
            [~, psi.idx] = min(abs(psi.disparities-psi.practice(psi.trial)));
            psi.current_disp = psi.disparities(psi.idx);
            psi.practice_trial = 1;
        else
           [~,psi.idx] = min(ExpEntropy);
           psi.current_disp = psi.disparities(psi.idx);
           psi.practice_trial = 0;
       end

       % ----------------------------------
       psi.trialID = trialID;
elseif strcmp(action,'record') % and update
    
      % STEP 6 response (for simulation only)
       if psi.sim==1
            pCorrect = defineLikelihood_bell(psi.g, psi.sim_neg_slope, psi.sim_pos_slope, psi.delta, psi.p,psi.current_disp, log10(psi.sim_threshold), psi.sim_lapse); % monotonic psychometric function
           %pCorrect = defineLikelihood_bell(psi.g, neg_slope, pos_slope, psi.current_disp, log10(sim_threshold)); % monotonic psychometric function
            %  [~, pCorrect] = halfBellProbit([sim_threshold,0,neg_slope,0.00025],0, 10^psi.current_disp, [], 1); % non-monotonic psychometric function
            %  [~, pCorrect] = probitSimple([sim_threshold,0,neg_slope,neg_slope],0, 10^psi.current_disp);
            psi.correct=rand(1)<=pCorrect; 
       end
       
       % ------------  UPDATE PSI depending ON CORRECT RESPONSE OR NOT ---------------%
       % STEP 7 update psi.prior depending of whether previous trial was psi.correct (1) or not (0) - similar to updating with the posterior
        if psi.correct
            psi.prior = psi.postCR(:,:,:,psi.idx); % probabilities of each parameter
        else
            psi.prior = psi.postFail(:,:,:,psi.idx); % probabilities of each parameter
        end

        % STEP 8 find best estimates
        %[~,idx2] = max(psi.prior(:));  % ttt=psi.tt(:,:,:,idx); sss = psi.ss(:,:,:,idx); lll = psi.ll(:,:,:,idx);
        %curr_est_max_thr=nan; curr_est_max_neg_slo=nan;curr_est_max_pos_slo=nan;thr_max=nan;

        weightedThres = psi.tt(:,:,:,psi.idx).*psi.prior; 
        weightedSlope= psi.ss(:,:,:,psi.idx).*psi.prior;   
        weightedNegSlo= psi.ll(:,:,:,psi.idx).*psi.prior;

        curr_est_sum_thr = 10.^sum(weightedThres(:));
        curr_est_sum_pos_slo = sum(weightedSlope(:));
        curr_est_sum_neg_slo = sum(weightedNegSlo(:));

        %current_estimates_sum = [10.^sum(weightedThres(:)),sum(weightedSlope(:)),sum(weightedLapse(:))]; % weighted probability sum based estimates
        %[thr_sum,err]=equSolve('likelihoodValues',[psi.g current_estimates_sum(3) current_estimates_sum(2) psi.delta psi.p log10(current_estimates_sum(1))],log10(current_estimates_sum(1)),psi.p-current_estimates_sum(3));
           yySum=defineLikelihood_bell(psi.g, curr_est_sum_neg_slo, curr_est_sum_pos_slo, psi.delta, psi.p, psi.disparities, log10(curr_est_sum_thr), psi.lapse);
           increasingXs=psi.disparities(diff(yySum)>0); if numel(increasingXs)==0; increasingXs=psi.disparities; end
           %find 75%-psi.lapse value for the increasing part
           [thr_sum,psi.err_sum] = equSolve2('likelihood_bell_Values',[psi.g curr_est_sum_neg_slo curr_est_sum_pos_slo psi.delta psi.p log10(curr_est_sum_thr) psi.lapse],increasingXs(1), increasingXs(end),psi.p-psi.lapse);
           psi.thr_sum=10.^thr_sum;

        %if thr_sum>maxAllowerThreshold; thr_sum=maxAllowerThreshold; end
        %if curr_est_sum_thr>maxAllowerThreshold; curr_est_sum_thr=maxAllowerThreshold; end
        psi.history(psi.trial,1:8) = [psi.trial,10.^psi.current_disp,psi.correct,curr_est_sum_thr,curr_est_sum_pos_slo,curr_est_sum_neg_slo,psi.thr_sum,psi.trialID];
            %   1       current psi trial
            %   2       current disparity shown
            %   3       psi.correct or not
            %   4-6     current estimates for thres / slope / neg_slope using sum method
            %   7      final 75% threshold estimate using sum parameters
            %   8       trial # (different from psi.trial)
            
        psi.prior = repmat(psi.prior,[1,1,1,numel(psi.disparities)]);

        % ------------- LAST TRIAL ---------------------
        if psi.trial==expe.nn
            % threshold capping at 1300"                                     
            psi.threshold=min(psi.maxAllowerThreshold,psi.thr_sum);

            % we can't find the 0.75 point, probably because it is never reached -
            % therefore we should assume stereoblindness (err_sum>0.05)
            if abs(psi.err_sum)>0.05
                 psi.threshold=psi.maxAllowerThreshold;
            end
            psi.end = 1;
        else
            % update trial number
            psi.trial = psi.trial + 1;
        end
end

catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    keyboard
    disp(err)
    %save(fullfile(pathExp,'log',[expe.file,'-crashlog']))
    %saveAll(fullfile(pathExp,'log',[expe.file,'-crashlog.mat']),fullfile(pathExp,'log',[expe.file,'-crashlog.txt']))
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    keyboard
    rethrow(err);
end



