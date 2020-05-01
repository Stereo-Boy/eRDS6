function eRDS6
%------------------------------------------------------------------------
% eRDS (version 6) is a program to precisely measure stereoscopic vision performance using recommendations from 
% Chopin et al., 2019, OPO & Scientific Reports. Indeed, it uses a dynamic RDS to prevent monocular cues and a
% depth ordering task rather than an oddball to avoid binocular non-stereo cues. It is a depth detection task, 
% and it issues a threshold separately for crossed (close) and uncrossed (far) disparities.
% Short presentations (200ms) allows to separate for these two measures (otherwise eye movements can inverse the 
% sign of disparities). Long presentations (2 sec) allows for a better threshold using vergence and eye movements. 
% Stimulus are three identical rectangular surface-RDS (stripes) with a frame around and a fixation cross in the 
% center. Dots are white and black or blue and black.
% Either the central or the outer stripes are in front of the others and the task is to indicate whether the blue 
% dots surface is closer or further (2AFC).
% Instead of a constant stimuli paradigm, we use an adaptation of Psi (Kontsevich & Tyler, 1999) bayesian algorithm
% adapted to non-monotonic psychometric functions. Indeed, we also use marginalization of nuisance parameters following
% Prins (2013) and implement the adaptive searchgrid rescaling from Doire et al. (2017) for threshold parameter.
% Prior is uniform but estimated from 12 practice trials, and we recommend to first run 10 additionnal practice trials 
% (that will be discarded).
% The program involves to first run the DST test to calibrate the stereoscope appropriately and ensure fusion.
%
% Changes in version 6
%   - now a central-outer stipes task on the blue dots to avoid strategies
%   - no eye tracking mode anymore
%   - super-imposition of dots is not allowed anymore following Read & Cumming (2018) 
% and 10 arcmin of minimal distance is enforced to avoid stereo crowding
%   - drawDots is used for the anti-aliasing
%   - does not support pedestals 
%   - use of Psi for non-monotonic functions rather than constant stimuli
%   with adaptive grid and marginalization of nuisance parameters
%   - larger possible disparities
%   - use of sharp dots rather than Gaussian, different sizes
%   - cannot load a previously started or crashed session anymore
%   - load a screen calibration file with screen parameters located in screen folder
%
% Properties:
%   - only 24 practice trials (12 crossed, 12 uncrossed), embedded in the test
%   - 10 additionnal practice trials recommended to run first
%   - menu options with 200ms or 2000 ms test without eyetracking
%
% Stimulus sequence: 
%   -nonius + fixation frame
%   -RDS [+fixation frame] - stays for 200ms or 2000ms
%   -response
%   -ISI
%
%   - most parameters are controled in the parametersERDS6 file
%   - screen parameters in the screen folder
%------------------------------------------------------------------------
% Controls: 
%       up arrow (blue dots surface is further away)
%       down arrow  (blue dots surface is closer)
%       Backspace key (exit)
%=======================================================================

try
  clc
  disp(' ------------    eRDS ------------------')  
  %add path to functions and define some folder paths, check that they exist, start a log file
    [expe.eRDSpath,~]=fileparts(mfilename('fullpath')); %path to erds folder
    expe.funpath = fullfile(expe.eRDSpath,'eRDS_functions'); %path to common functions
    if exist(expe.funpath,'dir')==7; addpath(expe.funpath); else; disp('Function folder does not exist:'); disp(expe.funpath); end %add that path to use these functions
    expe.rootpath = fileparts(expe.eRDSpath); % path where both eRDS and DST folders should be present
    expe.DSTpath = fullfile(expe.rootpath,'DST8','dataFiles'); % dst datafile path
    expe.logpath = fullfile(expe.eRDSpath,'log'); % log file path
    expe.datapath = fullfile(expe.eRDSpath,'dataFiles'); % path to the datafile folder
    expe.screenpath = fullfile(expe.eRDSpath,'screen'); % path to the screen folder 
    expe.soundpath = fullfile(expe.eRDSpath,'sound'); % path to the sound folder 
    check_folder(expe.logpath,1,'verboseON');
    diary(fullfile(expe.logpath,[sprintf('%02.f_',fix(clock)),'eRDS.txt']));
    diary ON
    check_folder(expe.rootpath,1,'verboseON');
    check_folder(expe.DSTpath,1,'verboseON');
    check_folder(expe.datapath,1,'verboseON');
    check_folder(expe.screenpath,1,'verboseON');
    check_folder(expe.soundpath,1,'verboseON');
    addpath(expe.screenpath); % so that we can load the screen parameters from there
    addpath(fullfile(expe.eRDSpath,'analysis'));
    expe.dateTime = dateTime;
    disp(dateTime)
    
    %=================      MENU     ===========================================
    disp('------------------------------------')
    disp('Experimental Menu (choose an option)')
    disp('====================================')
    disp('1: Quick Mode')                               %defines quickMode - 1: ON / 2: OFF / The quick mode allows to skip all the input part at the beginning of the experiment to test faster for what the experiment is.
    disp('2: Manual Mode (not implemented yet)')
    disp('3: Practice 2000 ms - 2 x 5 trials') % large disparities
    disp('4: Test 2000 ms - 2 x 12 practice + 73 trials')
    disp('5: Test 200 ms - 2 x 12 practice + 73 trials')
    disp('6: Debug mode (not implemented yet)')         %defines debugMode - 1: ON  ; 2: OFF / In debug mode, some chosen variables are displayed on the screen
    disp('7: Robot mode')         %defines inputMode - 1: User  ; 2: Robot / The robot mode allows to test the experiment with no user awaitings or long graphical outputs, just to test for obvious bugs
    disp('8: Checking mode')      % some checks 
    disp('9: Exit')
    disp('====================================')
    expe.menu=str2double(input('Your option? ','s'));
    
    if expe.menu == 9 % QUIT
            disp('Exiting')
            diary OFF
            return
    end
    %=================== DEFINE ALL MANUALLY INPUT PARAMETERS ================
        if expe.menu~=1 && expe.menu~=3 && expe.menu~=7 && expe.menu~=8      
            expe.name=nameInput(expe);  %erds datafile name
            %expe.DE=str2double(input('Dominant (non-amblyopic) eye (1 for Left; 2 for Right):  ', 's')); %dominant eye
        end
        if expe.menu~=1 && expe.menu~=7 && expe.menu~=8    
            expe.nameDST=input('Enter name given during last DST: ','s');    %dst name
        end
        
    %==========================================================================
    %                           DEFAULT PARAMETERS
    %==========================================================================
    [expe,scr,stim,sounds,psi]=parametersERDS6(expe);   
    
    % Changes default values depending on menu
    switch expe.menu
        case 1
            dispi('Quick mode uses some default values')
            expe.quickMode = 1; 
            expe.feedback = 1;
            expe.practiceTrials = 10; 
            expe.name = 'default';
            expe.nameDST = 'default';
        case 3
            expe.feedback = 1;
            expe.nbTrials = 0;
            expe.practiceTrials = 5;
            expe.name = 'practice';
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
            expe.feedback = 0;
        case 8
            dispi('Check mode uses some default values')
            expe.quickMode = 1; 
            expe.feedback = 1;
            expe.practiceTrials = 10; 
            expe.name = 'default';
            expe.nameDST = 'default';
    end 
    expe.nn = expe.nbTrials+expe.practiceTrials; % number of trials in total (for either the near or the far disparities)
        % the actual total number of trials is two times expe.nn because we adds near and far trials.
    expe.results = nan(size(2*expe.nn,1),13);
    expe.timings = nan(size(2*expe.nn,1),7);
    
    %--------------------------------------------------------------------------
    % load contrast and position information from the DST calibration
    %--------------------------------------------------------------------------
      check_files(expe.DSTpath, [expe.nameDST,'.mat'], 1, 1, expe.verbose)
      dispi('Loading DST file ',expe.nameDST)
      load(fullfile(expe.DSTpath, [expe.nameDST,'.mat']),'DE','leftContr','rightContr', 'leftUpShift', 'rightUpShift', 'leftLeftShift', 'rightLeftShift')
      expe.leftContr = leftContr; expe.rightContr =rightContr; expe.leftUpShift =leftUpShift; expe.rightUpShift =rightUpShift;
      expe.leftLeftShift=leftLeftShift; expe.rightLeftShift=rightLeftShift; expe.DE = DE;
    
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
         expe.date ={dateTime};
         expe.goalCounter=2.*expe.nn;    % for robot mode  

     %---------- UPDATE OTHER PARAMETERS THAT ARE CONTRAST OR LOCATION DEPENDENT-----% 
     %------------  POLARITY --------------%
     %1 : standard with grey background, 2: white on black background, 3: black on white background, 4:
     %Gray background, half of the dots blue light, half of the dots dark,
     %%5: grey background, half of the dots black, the other either white or blueish 
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
            stim.dotColor1 = stim.minLum; stim.dotColor2 = stim.maxLum;
            stim.targDotColor1 = [stim.dotColor1 , stim.dotColor1, stim.dotColor1];
            stim.targDotColor2 = [0 , 0, stim.dotColor2]; %blue dots
          % stim.targDotColor2 = [stim.dotColor2 , stim.dotColor2,stim.dotColor2] %white dots
         case {5}
            [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye (frames)
            [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye (frames)
            scr.fontColor = stim.minLum;
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
            stim.dotColor1 = stim.minLum; %black dots 
            stim.dotColor2 = stim.maxLum; %white dots
            stim.dotColor3 = [stim.maxLum/2, stim.maxLum, stim.maxLum]; %blueish dots
     end
     if stim.config == 3 % WORKS ONLY WITH POLARITY 5 - please keep it that way
         stim.white = stim.dotColor2;
         stim.blue = stim.dotColor3;
     end
     
     % outer frames (for fusion) space
            stim.leftFrameLum = stim.LminL;
            stim.rightFrameLum = stim.LminR;
            stim.frameL = [scr.LcenterXLine-stim.frameWidth/2,scr.LcenterYLine-stim.frameHeight/2,scr.LcenterXLine+stim.frameWidth/2,scr.LcenterYLine+stim.frameHeight/2];
            stim.frameR = [scr.RcenterXLine-stim.frameWidth/2,scr.RcenterYLine-stim.frameHeight/2,scr.RcenterXLine+stim.frameWidth/2,scr.RcenterYLine+stim.frameHeight/2];
     
     %---- RDS SPACE    
     if stim.config == 1 % LEFT - RIGHT RDS
        %defines space to be drawn inside with dots (left and right panels)
            stim.leftrdsL = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight); %left eye
            stim.leftrdsR = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);  %right eye
            stim.rightrdsL = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight);
            stim.rightrdsR = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);
        % split the working area in two areas vertically, that will show the same dots (for speed)
            stim.leftrdsL1 = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2); %left eye
            stim.leftrdsR1 = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2); %right eye
            stim.rightrdsL1 = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
            stim.rightrdsR1 = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
            stim.leftrdsL2 = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
            stim.leftrdsR2 = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
            stim.rightrdsL2 = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
            stim.rightrdsR2 = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
     elseif stim.config == 2 %CENTER - SURROUND RDS
         %defines space to be drawn inside with dots (left and right panels)
            stim.centerrdsL = centerSizedAreaOnPx(scr.LcenterXDot, scr.LcenterYDot, stim.rdsCenterSize, stim.rdsCenterSize); %left eye
            stim.centerrdsR = centerSizedAreaOnPx(scr.RcenterXDot, scr.RcenterYDot, stim.rdsCenterSize, stim.rdsCenterSize);  %right eye
            stim.outerrdsL = centerSizedAreaOnPx(scr.LcenterXDot, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight);
            stim.outerrdsR = centerSizedAreaOnPx(scr.RcenterXDot, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);
%         % split the working area in two areas vertically, that will show the same dots (for speed)
%             stim.leftrdsL1 = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2); %left eye
%             stim.leftrdsR1 = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2); %right eye
%             stim.rightrdsL1 = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
%             stim.rightrdsR1 = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot-stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
%             stim.leftrdsL2 = centerSizedAreaOnPx(scr.LcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
%             stim.leftrdsR2 = centerSizedAreaOnPx(scr.RcenterXDot-(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
%             stim.rightrdsL2 = centerSizedAreaOnPx(scr.LcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.LcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);
%             stim.rightrdsR2 = centerSizedAreaOnPx(scr.RcenterXDot+(stim.rdsWidth+stim.rdsInterspace)/2, scr.RcenterYDot+stim.rdsHeight/4, stim.rdsWidth, stim.rdsHeight/2);   
     elseif stim.config == 3 % CENTRAL STRIP - OUTER STRIPS
         %defines space to be drawn inside with dots (central and outer strips)
            stim.centerrdsL = centerSizedAreaOnPx(scr.LcenterXDot, scr.LcenterYDot, stim.rdsWidth, stim.rdsHeight); %left eye
            stim.centerrdsR = centerSizedAreaOnPx(scr.RcenterXDot, scr.RcenterYDot, stim.rdsWidth, stim.rdsHeight);  %right eye
            stim.outerrdsL1 = centerSizedAreaOnPx(scr.LcenterXDot, scr.LcenterYDot - stim.rdsHeight, stim.rdsWidth, stim.rdsHeight);
            stim.outerrdsR1 = centerSizedAreaOnPx(scr.RcenterXDot, scr.RcenterYDot - stim.rdsHeight, stim.rdsWidth, stim.rdsHeight);
            stim.outerrdsL2 = centerSizedAreaOnPx(scr.LcenterXDot, scr.LcenterYDot + stim.rdsHeight, stim.rdsWidth, stim.rdsHeight);
            stim.outerrdsR2 = centerSizedAreaOnPx(scr.RcenterXDot, scr.RcenterYDot + stim.rdsHeight, stim.rdsWidth, stim.rdsHeight);
     end
     
         disp('Expe structure: ');disp(expe);
         disp('Scr structure: ');disp(scr);
         disp('stim structure: ');disp(stim);
         disp('Sounds structure: ');disp(sounds);
         disp('Psi structure: ');disp(psi);
         
     %=====================================================================
     %               START THE STIMULUS PRESENTATION
     %=====================================================================
       expe.beginInterTrial=GetSecs;
       %we build two psi structures, one for far disparities (2) and one for
       %near disparities (1)
       psi1 = psi; psi1.sign = 'near'; % near disparities
       psi2 = psi; psi2.sign = 'far';  % far disparities
       clear psi;
       stopSignal = 0;
       if expe.menu==8 % CHECKS
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           step1 = ['Step 1 = Luminance checks. Check that next window (background) luminance is ',num2str(scr.backgr),' cd.-m2, that the two after (white and blueish) are ',...
               num2str(stim.maxLum),'. Press a key to start.'];
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step1,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           Screen('FillRect',scr.w, sc(stim.dotColor2,scr));
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           Screen('FillRect',scr.w, sc(stim.dotColor3,scr));
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           step2 = ['Step 2 = Size checks. On next window, check that the dots are ',num2str(round(stim.dotSize(1)./scr.ppBymm)),...
               ' mm and ',num2str(round(stim.dotSize(2)./scr.ppBymm)),' mm. Smaller dot should be ',num2str(min(stim.dotSize)),' pixels. Press a key to start.'];
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step2,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           Screen('DrawDots', scr.w, [scr.LcenterXDot; scr.LcenterYDot-50], stim.dotSize(1), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
           Screen('DrawDots', scr.w, [scr.LcenterXDot; scr.LcenterYDot+50], stim.dotSize(2), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           step3 = ['Step 3 = anti-aliasing checks. On next window, check that the dots are smoothly shifting from a location to another (no large step). Press a key to start.'];
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step3,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           for i=0:10
                Screen('DrawLine', scr.w, sc(stim.dotColor1,scr),scr.LcenterXLine+stim.dotSize(1)/2+2,1,scr.LcenterXLine+stim.dotSize(1)/2+2,scr.res(4), 1);
                Screen('DrawLine', scr.w, sc(stim.dotColor1,scr),scr.LcenterXLine-stim.dotSize(1)/2-2,1,scr.LcenterXLine-stim.dotSize(1)/2-2,scr.res(4), 1);
                Screen('DrawDots', scr.w, [scr.LcenterXDot+i/10; scr.LcenterYDot/2+i*stim.dotSize(1)], stim.dotSize(1), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);

                Screen('DrawLine', scr.w, sc(stim.dotColor1,scr),2*stim.dotSize(1)+scr.LcenterXLine+stim.dotSize(2)/2+2,1,2*stim.dotSize(1)+scr.LcenterXLine+stim.dotSize(2)/2+2,scr.res(4), 1);
                Screen('DrawLine', scr.w, sc(stim.dotColor1,scr),2*stim.dotSize(1)+scr.LcenterXLine-stim.dotSize(2)/2-2,1,2*stim.dotSize(1)+scr.LcenterXLine-stim.dotSize(2)/2-2,scr.res(4), 1);
                Screen('DrawDots', scr.w, [2*stim.dotSize(1)+scr.LcenterXDot+i/10; scr.LcenterYDot/2+i*stim.dotSize(1)], stim.dotSize(2), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
           end
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           step4 = ['Step 4 = stereoDeviation check. On next window, check that frames do not cross over. Press a key to start.'];
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step4,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           Screen('FrameRect', scr.w, sc(stim.fixL,scr),stim.frameL, stim.frameLineWidth/2);
           Screen('FrameRect', scr.w, sc(stim.fixR,scr),stim.frameR, stim.frameLineWidth/2); 
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           step5 = ['Step 5 = Trial check. On next window, check that the long trial seems OK. You should hear sound. Press a key to start.'];
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step5,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           [expe, psi1, stopSignal]=trialeRDS6(1,stim,scr,expe,sounds,psi1);
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           stim.itemDuration = 200;
           step6 = ['Step 6 = Timing check. On next window, check that the short trial is ',num2str(stim.itemDuration),' ms. Press a key to start.'];
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,step6,1);
           Screen('Flip',scr.w);
           waitForKey(scr.keyboardNum,expe.inputMode);
           [expe, psi1, stopSignal]=trialeRDS6(1,stim,scr,expe,sounds,psi1);    
       else %ACTUAL TEST
           sign_list = Shuffle([ones(1,expe.nn),zeros(1,expe.nn)]);
           for trial=1:(2*expe.nn) % 2x because we have far and close disparities, each being nn trials 
                   if sign_list(trial) == 0
                        [expe, psi1, stopSignal]=trialeRDS6(trial,stim,scr,expe,sounds,psi1);
                   else
                        [expe, psi2, stopSignal]=trialeRDS6(trial,stim,scr,expe,sounds,psi2);
                   end
               if stopSignal==1; break; end
           end         
       end                        
    %--------------------------------------------------------------------------
    %   SAVE AND QUIT
    %--------------------------------------------------------------------------
            %===== THANKS ===%
            Screen('FillRect',scr.w, sc(scr.backgr,scr));
            displaystereotext3(scr,sc(scr.fontColor,scr),[0,500,500,400],expe.thx.(expe.language),1);
            flip2(expe.inputMode, scr.w);
            
            %===== SAVE ===%
            expe.duration = (GetSecs-expe.startTime)/60;
            if isfield(psi1,'tt')
                psi1=rmfield(psi1,'tt'); psi1=rmfield(psi1,'ss'); psi1=rmfield(psi1,'ll'); psi1=rmfield(psi1,'xx');
                psi1=rmfield(psi1,'likelihoodCR'); psi1=rmfield(psi1,'likelihoodFail'); psi1=rmfield(psi1,'postFail'); psi1=rmfield(psi1,'postCR');
            end
            if isfield(psi2,'tt')
                psi2=rmfield(psi2,'tt'); psi2=rmfield(psi2,'ss'); psi2=rmfield(psi2,'ll'); psi2=rmfield(psi2,'xx');
                psi2=rmfield(psi2,'likelihoodCR'); psi2=rmfield(psi2,'likelihoodFail'); psi2=rmfield(psi2,'postFail'); psi2=rmfield(psi2,'postCR');
            end
            clear psi
            expe.resultsLabels = {'trial ID', 'central strip disparity (")', 'lateral strip disparity (")','expected response', 'response',...
                'presentation duration','RT','correct', 'central strip disparity (pp)', 'lateral strip disparity (pp)','practice?','blue dots'};
            expe.timingsLabels={'calculation','fixation','frame duration','flash duration','stimulus duration','RT','ISI'}; %HERE
            if stopSignal==1
                save(fullfile(expe.logpath,[expe.name,'_menu',num2str(expe.menu),'_crashlog']))
            else
                save(fullfile(expe.datapath, [expe.name,'_menu',num2str(expe.menu)]))
            end

        %===== QUIT =====%
            waitForKey(scr.keyboardNum,expe.inputMode);
            precautions(scr.w, 'off');
            changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz);    
           
            disp('==========================================')
            disp('         Results')
            dispi('Duration:',round(expe.duration,1));
            if isfield(psi1, 'threshold')
                stereoAcuity(fullfile(expe.datapath,[expe.name,'_menu',num2str(expe.menu),'.mat']))
            else
                disp('No threshold detected in psi structure.')
            end
            diary OFF 
catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    if exist('sounds','var'); PsychPortAudio('Close', sounds.handle1); end
    if exist('sounds','var'); PsychPortAudio('Close', sounds.handle2); end
    disp(err)
    if exist('psi1','var') && isfield(psi1,'tt')
                psi1=rmfield(psi1,'tt'); psi1=rmfield(psi1,'ss'); psi1=rmfield(psi1,'ll'); psi1=rmfield(psi1,'xx');
                psi1=rmfield(psi1,'likelihoodCR'); psi1=rmfield(psi1,'likelihoodFail'); psi1=rmfield(psi1,'postFail'); psi1=rmfield(psi1,'postCR');
    end
    if exist('psi1','var') && isfield(psi2,'tt')
        psi2=rmfield(psi2,'tt'); psi2=rmfield(psi2,'ss'); psi2=rmfield(psi2,'ll'); psi2=rmfield(psi2,'xx');
        psi2=rmfield(psi2,'likelihoodCR'); psi2=rmfield(psi2,'likelihoodFail'); psi2=rmfield(psi2,'postFail'); psi2=rmfield(psi2,'postCR');
    end
    %keyboard
    if exist('scr','var'); save(fullfile(expe.logpath,[expe.name,'_menu',num2str(expe.menu),'_crashlog'])); end
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    rethrow(err)
end

