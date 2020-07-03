function psi = Psi_marg6_erds6(action, trialID, psi, expe, scr)
% Psi algorithm for working with erds files, following version 003o of Psi_marg6
% 
% This code implements a parametrized Bayesian estimation (Psi, Kontsevich & Tyler, 1999) that can work in spaces of 
% more than one parameter (simultaneously), thanks to entropy minimization. It means that it calculates the stimulus 
% placement that will increase the expected information learned from the next trial, given the current data. 
% The method seems robust to attentional lapses.
%
% This version of Psi implements 3 parameter estimates (threshold / positive slope / negative slope) with marginalization on the
% 2nd and 3d parameters (psi.slopes) following Prins (2013).
% It implements the adaptive searchgrid rescaling from Doire et al. (2017), but only for the threshold estimate.
%
% The psychometric function is a non-monotonic adaptation of the logistic function defined by Serrano-Pedraza 
% et al., 2016 (IOVS) and Garcia-Pérez (1998)
%
% The negative slope translates the fact that performance goes back to chance level for very large disparities
%
%
% It is currently set up for a 2AFC detection task.
% Input variables:
% action
%       'value' - find the next disparity to show
%       'record' - record the result of the trial
%       'simulation' - start and follow a simulation 
%           In that case, you can call Psi_marg6_erds6 as follows:
%               Psi_marg6_erds6('simulate', trialID, psi)
%                   with trialID the number of trials and psi the simulated thresholds in arcsec
%                   e.g. Psi_marg6_erds6('simulate', 85, 100)
% trialID is the ID number (independently of psi.trial)
% psi is the algorithm structure
% expe is a structure that needs to contain at least
%       expe.inputMode (1 - person, 2 robot)
%       expe.nn - the total number of trials (for a near or a far side only)
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
            psi.sim_pos_slope = 0.2+rand(1).*(2-0.2); % random simulated slope
            %pos_slope=1;
            psi.sim_neg_slope = rand(1).*0.112; % random simulated negative slope
            psi.sim_lapse = 0.005+rand(1).*0.03; % random finger rate error
        end

        % STEP 0
        % Any parameter defined below is not varying through the estimation
        % We assume a value for them (actually defined in parametersERDS6)
        psi.history=nan(expe.nn,10);
        psi.labels = {'psi trials','disparity','correct','thres est.','slope est.', 'neg slope est.', 'threshold','trial #'};
        
        % Parameter space
        [psi.tt, psi.ss, psi.ll, psi.xx] = ndgrid(psi.thresholds, psi.slopes, psi.neg_slopes, psi.disparities);

        % psi.prior defining the psi.prior (same space as likelihood, information that we gives at the beginning 
        psi.prior = ones(size(psi.tt))./numel(psi.tt); %start with uniform psi.prior distribution for disparity threshold (a vector of possible threshold and
            % the probability associated with each) -> this is the probability of a threshold
    end
        % Likelihoods - properties defining the likelihoods (a set of psychometric functions for success rate depending on the disparity presented and the threshold)
        % It is the probability of success or failure given a set of parameter and a disparity x
        psi.likelihoodCR = defineLikelihood_bell(psi.g, psi.ll, psi.ss, psi.delta, psi.p, psi.xx, psi.tt, psi.lapse); % psis for success
        psi.likelihoodFail = 1 - psi.likelihoodCR; % psis for failure

       % STEP 1
       % The probability of a response given the disparity shown

       psi.pCR = sum(sum(sum(psi.likelihoodCR.*psi.prior))); % success
       psi.pFail = sum(sum(sum(psi.likelihoodFail.*psi.prior))); % failure

       % STEP 2
       % The posterior, which is the probability of parameters given a response at a potential disparity x
       psi.postCR = psi.likelihoodCR.*psi.prior./psi.pCR; %here?
       psi.postFail = psi.likelihoodFail.*psi.prior./psi.pFail;

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
       ExpEntropy = EntropyCR.*squeeze(psi.pCR) + EntropyFail.*squeeze(psi.pFail);

       % STEP 5
       % Find disparity with minimum expected entropy
       if psi.trial<=expe.practiceTrials % in practice trials, we do not choose next disparity but just take the closest to the one is given to us
            [~, psi.idx] = min(abs(psi.disparities-psi.practice(psi.trial)));
            psi.current_disp = psi.disparities(psi.idx);
            psi.practice_trial = 1;
        else
           [~,psi.idx] = min(ExpEntropy);
           candidate_disp = psi.disparities(psi.idx);
           if candidate_disp>log10(psi.xmax) % cannot present above that disparity
               [~, psi.idx2] =  min(abs(candidate_disp-log10(psi.xmax)));
               psi.current_disp = psi.disparities(psi.idx2);
           else
               psi.current_disp = candidate_disp;
           end
           psi.practice_trial = 0;
       end

       % ----------------------------------
       psi.trialID = trialID;
elseif strcmp(action,'record') % and update
    
      % STEP 6 response (for simulation only)
       if psi.sim==1
            pCorrect = defineLikelihood_bell(psi.g, psi.sim_neg_slope, psi.sim_pos_slope, psi.delta, psi.p,psi.current_disp, log10(psi.sim_threshold), psi.sim_lapse); % non-monotonic psychometric function
            psi.correct=rand(1)<=pCorrect; 
       end
       
       % ------------  UPDATE PSI depending ON CORRECT RESPONSE OR NOT ---------------%
       % STEP 7 update psi.prior depending of whether previous trial was psi.correct (1) or not (0) - similar to updating with the posterior
        if psi.correct
            psi.prior = psi.postCR(:,:,:,psi.idx); % probabilities of each parameter
        else
            psi.prior = psi.postFail(:,:,:,psi.idx); % probabilities of each parameter
        end

        % STEP 8 find best estimates - here we take the posterior weighted sum as best estimate
           % [~,idx2] = max(psi.prior(:));
           % curr_est_max_thr = 10.^psi.tt(idx2);
           % curr_est_max_pos_slo = 10.^psi.ss(idx2);
           % curr_est_max_neg_slo = psi.ll(idx2);
           % psi.thr_max = curr_est_max_thr;
        
            thresTmp = psi.tt(:,:,:,psi.idx);
            weightedThres = thresTmp.*psi.prior;    
            weightedSlope= psi.ss(:,:,:,psi.idx).*psi.prior;   
            weightedNegSlo= psi.ll(:,:,:,psi.idx).*psi.prior;
            sumWeightThres = sum(weightedThres(:));
            curr_est_sum_thr = 10.^sumWeightThres;
            curr_est_sum_pos_slo = sum(weightedSlope(:));
            curr_est_sum_neg_slo = sum(weightedNegSlo(:));
            psi.thr_sum = curr_est_sum_thr;
            
       % STEP 9 update mean and dispersion of the most likely parameters
            var_thr = sum(((thresTmp(:)-sumWeightThres).^2).*psi.prior(:));
            factor = 4;
            range = [max(log10(psi.tmin2),sumWeightThres - factor*sqrt(var_thr)), min(log10(psi.tmax2),sumWeightThres + factor*sqrt(var_thr))];

        psi.history(psi.trial,1:10) = [psi.trial, 10.^psi.current_disp, psi.correct, ...
            curr_est_sum_thr, curr_est_sum_pos_slo, curr_est_sum_neg_slo, psi.thr_sum, ...
            psi.trialID,range(1),range(2)];
            %   1       current psi trial
            %   2       current disparity shown in "
            %   3       psi.correct or not
            %   4-6     current estimates for thres / slope / neg_slope using sum method
            %   7       final estimate using sum parameters
            %   8       trial # (different from psi.trial)
            %   9-10    ranges for threshold search grid (in log10)
            
            
         % STEP 10 - rescale the search grid if necessary
          psi.new_thresholds = unique([log10([1,10,100,1000,2000,100000]),linspace(max(log10(psi.tmin2),range(1)),min(log10(psi.tmax2),range(2)),round(psi.gridSizeT))]);
          psi.new_disparities = unique([log10([1,10,100,1000,2000,3000]),linspace(max(log10(psi.xmin2),range(1)),min(log10(psi.xmax),range(2)),round(psi.gridSizeX))]);
          new_range = range;
          if psi.trial>1 %not during first trial
             psi.min_cha = 0.10; % minimal change that triggers recomputation in %
             old_range=psi.history(psi.trial-1,9:10); 
             if abs(10.^new_range(1)-10.^old_range(1))<psi.min_cha*10.^old_range(1) && abs(10.^new_range(2)-10.^old_range(2))<psi.min_cha*10.^old_range(2)
                % new grid different from old one by less 10% -> do nothing
                  psi.donothing_counter =  psi.donothing_counter +1;
             else               
               %let's recompute everything if last practice trial or if limit change is more than 10%
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
                psi.disparities =  psi.new_disparities;
                psi.thresholds =  psi.new_thresholds;  
              end   
          end
          psi.prior = repmat(psi.prior,[1,1,1,numel(psi.disparities)]); 

      % ------------- LAST TRIAL ---------------------
        if psi.trial==expe.nn
            % threshold capping at 1300"                                     
            %psi.threshold=min(psi.maxAllowerThreshold,psi.thr_sum);
            psi.threshold=psi.thr_sum;
            %marginalize distributions for stereoblindness calculation
            psi.marg_thr=squeeze(sum(sum(psi.prior(:,:,:,1),3),2));
            psi.stereoblind_prob = 100*sum(psi.marg_thr((10.^psi.thresholds)>=psi.maxAllowerThreshold));
%             if  psi.stereoblind_prob>50
%                  psi.threshold=psi.maxAllowerThreshold;
%             end
            psi.end = 1;
        else
            % update trial number
            psi.trial = psi.trial + 1;
        end
elseif strcmp(action,'simulate') 
    % start and follow a simulation with trialID trials
    
    % initialization
        expe.nn = trialID;
        sim_threshold = psi;
        psi = struct();
        [expe.eRDSpath,~]=fileparts(fileparts(mfilename('fullpath'))); %path to erds folder
        expe.datapath = fullfile(expe.eRDSpath,'dataFiles'); % path to the datafile folder
        addpath(fullfile(expe.eRDSpath,'analysis'));
        expe.name = 'robot_sim';
        expe.inputMode = 0;
        expe.menu = 0;
        expe.practiceTrials = 12; 
        expe.duration = 0;
    %--------------------------------------------------------------------------
    %   PSI algorithm parameters
    %----------------------------------------------------------------------------
        psi.sign = 'undefined (sim.)';
        psi.xmin= 1; %minimal disparity possible in arcsec (cannot measure thresholds below that value!) % adding 0.5, 1, 1.5, 2 and 2.5 though
        psi.xmin2 = 0.1; %after rescaling
        psi.xmax = 3000; %max one (cannot measure thresholds above that value!)
        psi.gridSizeX = 50;
        psi.disparities = unique([log10([1,10,100,1000,2000,3000]),linspace(log10(psi.xmin),log10(psi.xmax),psi.gridSizeX)]); %starting search grid of possible values for disparities x, in log10(arcsec)
        
        psi.tmin = 1; % minimal threshold that we parametrized before rescaling
        psi.tmin2 = 0.1; %and after rescaling
        psi.tmax1 = 2200; % maximal threshold that we parametrized before rescaling
        psi.tmax2 = 3000; % maximal threshold that we parametrized after rescaling
        psi.gridSizeT = 100;
        psi.thresholds = unique([log10([1,10,100,1000,2000,100000]),linspace(log10(psi.tmin),log10(psi.tmax1),psi.gridSizeT)]); %range of possible values for thresholds T, in log10(arcsec)
        
        psi.slopes = [0.2,0.3,0.4,0.6,0.8,1.2,1.6,2.4]; %range of possible values for slope s
        psi.neg_slopes = [0,0.003,0.006,0.012,0.024,0.056,0.112];

        psi.lapse = 0.035/2; % we assumed a fixed lapse (finger error) rate (in %)
        psi.maxAllowerThreshold=1300; % threshold considered stereoblindness
        psi.g = 0.5; %guess rate (we have one chance out of 2 - 2AFC)
        psi.delta = 0.01; %what part of the psychometric function is considered ([delta, 1-delta]
        psi.p = 0.75; %success rate at threshold
        psi.practice = log10([ %if we have practice trials, their disparities will be these ones, in that order
            2500      
            2000    
            1500   
            1300      
            1000     
            800     
            500     
            300      
            200       
            100          
            50       
            20   
            ]);
        psi.sim_threshold = sim_threshold; %simulated threshold whenever we do robotMode
        psi.end = 0;  % end signal for algorithm
        psi.trial = 1;
        psi.donothing_counter = 0;
        
    for trial = 1:expe.nn
       % find out what is the next disparity
       psi = Psi_marg6_erds6('value',trial, psi, expe, []); 
       % update and record psi data
       psi = Psi_marg6_erds6('record',trial, psi, expe, []);       
    end
    psi1 = psi; psi2 = psi;
    save(fullfile(expe.datapath, [expe.name,'_menu',num2str(expe.menu)]))
    close all;
    stereoAcuity(fullfile(expe.datapath,[expe.name,'_menu',num2str(expe.menu),'.mat']))
end

catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    disp(err)
    %save(fullfile(pathExp,'log',[expe.file,'-crashlog']))
    %saveAll(fullfile(pathExp,'log',[expe.file,'-crashlog.mat']),fullfile(pathExp,'log',[expe.file,'-crashlog.txt']))
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    rethrow(err);
end



