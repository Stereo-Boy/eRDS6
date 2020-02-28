function eRDS6
%------------------------------------------------------------------------
% eRDS (version 6) is a program to precisely measure stereoscopic vision performance
% using recommendations from Chopin et al., 2019, OPO & Scientific Reports
% Indeed, it uses a dynamic RDS to prevent monocular cues and a depth
% ordering task rather than an oddball to avoid binocular non-stereo cues.
% It is a depth detection task, and it issues a threshold separately for
% crossed (close) and uncrossed (far) disparities.
% Short presentations (200ms) allows to separate for these two measures
% (otherwise eye movements can inverse the sign of disparities).
% Long presentations (2 sec) allows for a better threshold using vergence
% and eye movements. 
% Stimulus are two identical rectangular surface-RDS with a frame around
% and a fixation cross in the center. Dots are white and black.
% Either the left or the right surface is in front of the other and the task 
% is to indicate which one (2AFC).
% Instead of a constant stimuli paradigm, we use an adaptation of Psi (Kontsevich & Tyler, 1999)
% bayesian algorithm to non-monotonic psychometric functions. Indeed, we
% also use marginalization of nuisance parameters following Prins (2013)
% Prior is estimated from 25 practice trials, and 10 additionnal practice
% trials are run (and discarded) simply to learn the task.
% The program involves to first run the DST test to calibrate the
% stereoscope appropriately and ensure fusion.
%
% Changes in version 6
%   - now a left-right task to prevent strategies
%   - no eye tracking mode anymore
%   - super-imposition of dots is not allowed anymore following Read &
%   Cumming (2018)
%   - drawCircle is used rather than drawDots to avoid limitation on dot size
%   - does not support pedestals anymore
%   - use of Psi for non-monotonic functions rather than constant stimuli
%   - larger possible disparities
%   - use of sharp dots rather than Gaussian, different sizes
%   - cannot load a previously started or crashed session anymore
%   - load a screen calibration file with screen parameters located in screen folder
%
% Properties:
%   - only 25 practice trials, always embedded in the test
%   - 10 additionnal practice trials possible, to run first
%   - menu options with 200ms or 2000 ms test without eyetracking
%
% Stimulus sequence: 
%   -nonius + fixation frame
%   -RDS [+fixation frame] - stays for 200ms or 2000ms
%   -response (left or right array key)
%   -ISI
%
%   - most parameters are controled in the globalParameters file except for
%   the ones in the default section below
%   
%------------------------------------------------------------------------
% Controls: 
%       Left arrow (closer surface is on the left)
%       Right arrow  (close surface is on the right)
%       Backspace key (exit)
%------------------------------------------------------------------------
% Analysis: the correct file to analyse individual results is:
%
%=======================================================================

try
  clc
  disp(' ------------    eRDS ------------------')  
  %add path to functions and define some folder paths, check that they exist, start a log file
    [eRDSpath,~]=fileparts(mfilename('fullpath')); %path to erds folder
    funpath = fullfile(eRDSpath,'eRDS_functions'); %path to common functions
    if exist(funpath,'dir')==7; addpath(funpath); else; disp('Function folder does not exist:'); disp(funpath); end %add that path to use these functions
    rootpath = fileparts(eRDSpath); % path where both eRDS and DST folders should be present
    DSTpath = fullfile(rootpath,'DST8','dataFiles'); % dst datafile path
    logpath = fullfile(eRDSpath,'log'); % log file path
    datapath = fullfile(eRDSpath,'dataFiles'); % path to the datafile folder
    screenpath = fullfile(eRDSpath,'screen'); % path to the screen folder 
    expe.soundpath = fullfile(eRDSpath,'sound'); % path to the sound folder 
    check_folder(logpath,1,'verboseON');
    diary(fullfile(logpath,[sprintf('%02.f_',fix(clock)),'eRDS.txt']));
    diary ON
    check_folder(rootpath,1,'verboseON');
    check_folder(DSTpath,1,'verboseON');
    check_folder(datapath,1,'verboseON');
    check_folder(screenpath,1,'verboseON');
    check_folder(expe.soundpath,1,'verboseON');
    addpath(screenpath); % so that we can load the screen parameters from there
    disp(dateTime)
    
    %=================      MENU     ===========================================
    disp('------------------------------------')
    disp('Experimental Menu (choose an option)')
    disp('====================================')
    disp('1: Quick Mode')                               %defines quickMode - 1: ON / 2: OFF / The quick mode allows to skip all the input part at the beginning of the experiment to test faster for what the experiment is.
    disp('2: Manual Mode (not implemented yet)')
    disp('3: Practice 2000 ms - 10 trials')
    disp('4: Test 2000 ms - 25 practice + 60 trials')
    disp('5: Test 200 ms - 25 practice + 60 trials')
    disp('6: Debug mode (not implemented yet)')         %defines debugMode - 1: ON  ; 2: OFF / In debug mode, some chosen variables are displayed on the screen
    disp('7: Robot mode')         %defines inputMode - 1: User  ; 2: Robot / The robot mode allows to test the experiment with no user awaitings or long graphical outputs, just to test for obvious bugs
    disp('====================================')
    expe.menu=str2double(input('Your option? ','s'));
    
    %=================== DEFINE ALL MANUALLY INPUT PARAMETERS ================
        if expe.menu~=1 && expe.menu~=3 && expe.menu~=7           
            expe.name=nameInput(datapath);  %erds datafile name
            expe.DE=str2double(input('Dominant (non-amblyopic) eye (1 for Left; 2 for Right):  ', 's')); %dominant eye
            expe.nameDST=input('Enter name given during last DST: ','s');    %dst name
        end
        
    %==========================================================================
    %                           DEFAULT PARAMETERS
    %==========================================================================
    [expe,scr,stim,sounds,psi]=parametersERDS6(expe)   
    
    % Changes default values depending on menu
    switch expe.menu
        case 1
            dispi('Quick mode uses default values')
            expe.quickMode=1; 
            expe.feedback = 1;
            expe.practiceTrials = 2; 
            expe.name = 'default';
            %HERE
            %if check_files(datapath, [expe.name,'.mat'],1,0,'verboseOFF'); delete(fullfile(datapath, [expe.name,'.mat'])); end % remove existing default erds file
            expe.nameDST = 'default';
        case 2
        case 3
            expe.feedback = 1;
            expe.nbTrials = 0;
            expe.practiceTrials = 10;
            expe.name = 'practice';
        case 4
        case 5
            stim.itemDuration = 200;
        case 6
            expe.practiceTrials = 0;
            expe.feedback = 1;
            expe.debugMode = 1;
        case 7
            stim.itemDuration = 0;
            stim.flashDuration = 0.000001;
            expe.name = 'robot';
            expe.nameDST = 'default';
            expe.verbose = 'verboseOFF';
            expe.inputMode = 2;
            stim.itemDuration = 0.00001;
            stim.interTrial = 0.00001;   
    end 

    %HERE COULD DO A LAST CHECK WITH SCREEN
    
    %--------------------------------------------------------------------------
    % load contrast and position information from the DST calibration
    %--------------------------------------------------------------------------
      check_files(DSTpath, [expe.nameDST,'.mat'], 1, 1, expe.verbose)
      dispi('Loading DST file ',expe.nameDST)
      load(fullfile(DSTpath, [expe.nameDST,'.mat']),'leftContr','rightContr', 'leftUpShift', 'rightUpShift', 'leftLeftShift', 'rightLeftShift', 'flickering')
      expe.leftContr = leftContr; expe.rightContr =rightContr; expe.leftUpShift =leftUpShift; expe.rightUpShift =rightUpShift;
      expe.leftLeftShift=leftLeftShift; expe.rightLeftShift=rightLeftShift; expe.flickering=flickering;
    
     %----------------------------------------------------------------------------
     %   UPDATE LEFT AND RIGHT EYE COORDINATES AND CONTRAST from DST / initialize
     %----------------------------------------------------------------------------
         scr.LcenterXLine= scr.LcenterXLine - expe.leftLeftShift;
         scr.LcenterXDot = scr.LcenterXDot - expe.leftLeftShift;
         scr.RcenterXLine= scr.RcenterXLine - expe.rightLeftShift;
         scr.RcenterXDot = scr.RcenterXDot - expe.rightLeftShift;
         scr.LcenterYLine = scr.centerYLine - expe.leftUpShift;
         scr.RcenterYLine = scr.centerYLine - expe.rightUpShift;
         scr.LcenterYDot = scr.centerYDot - expe.leftUpShift;
         scr.RcenterYDot = scr.centerYDot - expe.rightUpShift;
         expe.startTime=GetSecs;
         expe.lastBreakTime=GetSecs; %time from the last break
         expe.date ={dateTime};
         expe.goalCounter=2.*expe.nn;    % for robot mode  

     %---------- UPDATE OTHER PARAMETERS THAT ARE CONTRAST OR LOCATION DEPENDENT-----% 
     %------------  POLARITY --------------%
     %1 : standard with grey background, 2: white on black background, 3: black on white background, 4:
     %Gray background, half of the dots blue light, half of the dots dark,
     %%5: grey background, half of the dots white, the other black
     switch stim.polarity 
        case {1}
            [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye
            [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye
            scr.fontColor = stim.minLum;
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
            stim.dotColor1 = stim.minLum; stim.dotColor2 = stim.minLum;
            stim.targDotColor1 = [stim.dotColor1 , stim.dotColor1, stim.dotColor1];
            stim.targDotColor2 = [stim.dotColor2 , stim.dotColor2, stim.dotColor2];
        case {2}
            stim.LmaxL = stim.minLum + expe.leftContr*(stim.maxLum - stim.minLum);
            stim.LminL = stim.minLum;
            stim.LmaxR = stim.minLum + expe.rightContr*(stim.maxLum - stim.minLum);
            stim.LminR = stim.minLum;
            stim.fixL = stim.LmaxL;
            stim.fixR = stim.LmaxR;
            scr.fontColor = stim.maxLum;
            stim.dotColor1 = stim.maxLum;   stim.dotColor2 = stim.maxLum;
            stim.targDotColor1 = [0 , 0, stim.dotColor1];
            stim.targDotColor2 = [0 , 0, stim.dotColor2];
            scr.backgr = stim.minLum;
        case {3}
            stim.LmaxL = stim.maxLum;
            stim.LminL = stim.maxLum - expe.leftContr*(stim.maxLum - stim.minLum);
            stim.LmaxR = stim.maxLum;
            stim.LminR = stim.maxLum - expe.rightContr*(stim.maxLum - stim.minLum);
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
            scr.fontColor = stim.minLum;
            stim.dotColor1 = stim.minLum;   stim.dotColor2 = stim.minLum;
            stim.targDotColor1 = [stim.dotColor1 , stim.dotColor1, stim.dotColor1];
            stim.targDotColor2 = [stim.dotColor2 , stim.dotColor2, stim.dotColor2];
            scr.backgr = stim.maxLum;
        case {4}
            [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye
            [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye
            scr.fontColor = stim.minLum;
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
            stim.dotColor1 = stim.minLum; stim.dotColor2 = stim.maxLum;%BACKGROUND
            stim.targDotColor1 = [stim.dotColor1 , stim.dotColor1, stim.dotColor1];
            stim.targDotColor2 = [0 , 0, stim.dotColor2]; %blue dots
          % stim.targDotColor2 = [stim.dotColor2 , stim.dotColor2,stim.dotColor2] %white dots
         case {5}
            [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye
            [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye
            scr.fontColor = stim.minLum;
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
            stim.dotColor1 = stim.minLum; stim.dotColor2 = stim.maxLum;
            stim.targDotColor1 = stim.dotColor1; %white dots
            stim.targDotColor2 = stim.dotColor2; %black dots
     end
     
     % outer frames (for fusion) space
            stim.leftFrameLum = stim.LminL;
            stim.rightFrameLum = stim.LminR;
            stim.frameL = [scr.LcenterXLine-stim.frameWidth/2,scr.LcenterYLine-stim.frameHeight/2,scr.LcenterXLine+stim.frameWidth/2,scr.LcenterYLine+stim.frameHeight/2];
            stim.frameR = [scr.RcenterXLine-stim.frameWidth/2,scr.RcenterYLine-stim.frameHeight/2,scr.RcenterXLine+stim.frameWidth/2,scr.RcenterYLine+stim.frameHeight/2];
     
     %---- RDS SPACE             
        %defines space to be drawn inside with dots
            %stim.bgRectL = centerSizedAreaOnPx(scr.LcenterXLine, scr.LcenterYLine, 2*stim.rdsWidth+stim.rdsInterspace, stim.rdsHeight);
            %stim.bgRectR = centerSizedAreaOnPx(scr.RcenterXLine,scr.RcenterYLine,stim.rdsWidth,stim.rdsHeight);
            stim.leftrdsL = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight);
            stim.leftrdsR = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);
            stim.rightrdsL = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight);
            stim.rightrdsR = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);
            
     %=====================================================================
     %               START THE STIMULUS PRESENTATION
     %=====================================================================
     
       expe.beginInterTrial=GetSecs;
       %we build two psi structures, one for far disparities (2) and one for
       %near disparities (1)
       psi1 = psi; psi1.sign = 'near'; % near disparities
       psi2 = psi; psi2.sign = 'far';  % far disparities
       sign_list = Shuffle([ones(1,expe.nn),zeros(1,expe.nn)]);
           for trial=1:(2*expe.nn)
                   if sign_list(trial) == 0
                        [expe, psi1, stopSignal]=trialeRDS6(trial,stim,scr,expe,sounds,psi1);
                   else
                        [expe, psi2, stopSignal]=trialeRDS6(trial,stim,scr,expe,sounds,psi2);
                   end
               %save('temp.mat') % just in case something goes really wrong
               if stopSignal==1; break; end
           end         
                                   
    %--------------------------------------------------------------------------
    %   SAVE AND QUIT
    %--------------------------------------------------------------------------
            %===== THANKS ===%
            Screen('FillRect',scr.w, sc(scr.backgr,scr));
            displaystereotext3(scr,sc(scr.fontColor,scr),[0,500,500,400],expe.thx.(expe.language),1);
            flip2(expe.inputMode, scr.w);
            waitForKey(scr.keyboardNum,expe.inputMode);
            
            %===== SAVE ===%
            disp(['Duration:',num2str((GetSecs-expe.startTime)/60)]);
            expe.time = (GetSecs-expe.startTime)/60;
            if isfield(psi1,'tt')
                psi1=rmfield(psi1,'tt'); psi1=rmfield(psi1,'ss'); psi1=rmfield(psi1,'ll'); psi1=rmfield(psi1,'xx');
                psi1=rmfield(psi1,'likelihoodCR'); psi1=rmfield(psi1,'likelihoodFail'); psi1=rmfield(psi1,'postFail'); psi1=rmfield(psi1,'postCR');
            end
            if isfield(psi2,'tt')
                psi2=rmfield(psi2,'tt'); psi2=rmfield(psi2,'ss'); psi2=rmfield(psi2,'ll'); psi2=rmfield(psi2,'xx');
                psi2=rmfield(psi2,'likelihoodCR'); psi2=rmfield(psi2,'likelihoodFail'); psi2=rmfield(psi2,'postFail'); psi2=rmfield(psi2,'postCR');
            end
            clear psi
            expe.resultsLabels = {'trial ID', 'left disparity (")', 'right disparity (")','expected response', 'response','presentation duration','RT','correct',...
                'left disparity (pp)', 'right disparity (pp)','practice?'};
            if stopSignal==1
                save(fullfile(logpath,[expe.name,'-crashlog']))
            else
                save(fullfile(datapath,expe.name))
            end
            %saveAll(fullfile(datapath,[expe.name,'.mat']),fullfile(datapath,[expe.name,'.txt']))

        %===== QUIT =====%
            precautions(scr.w, 'off');
            changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz);
            diary OFF
              
              
catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    keyboard
    if exist('sounds','var'); PsychPortAudio('Close', sounds.handle1); end
    if exist('sounds','var'); PsychPortAudio('Close', sounds.handle2); end
    disp(err)
    if exist('scr','var'); save(fullfile(logpath,[expe.name,'-crashlog'])); end
    if exist('psi1','var') && isfield(psi1,'tt')
                psi1=rmfield(psi1,'tt'); psi1=rmfield(psi1,'ss'); psi1=rmfield(psi1,'ll'); psi1=rmfield(psi1,'xx');
                psi1=rmfield(psi1,'likelihoodCR'); psi1=rmfield(psi1,'likelihoodFail'); psi1=rmfield(psi1,'postFail'); psi1=rmfield(psi1,'postCR');
    end
    if exist('psi1','var') && isfield(psi2,'tt')
        psi2=rmfield(psi2,'tt'); psi2=rmfield(psi2,'ss'); psi2=rmfield(psi2,'ll'); psi2=rmfield(psi2,'xx');
        psi2=rmfield(psi2,'likelihoodCR'); psi2=rmfield(psi2,'likelihoodFail'); psi2=rmfield(psi2,'postFail'); psi2=rmfield(psi2,'postCR');
    end
    if exist('psi','var');    clear psi; end
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
end

