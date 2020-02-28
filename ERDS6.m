function ERDS6
%------------------------------------------------------------------------
% ERDS v6 is a program to measure precisely stereoscopic vision performance
% using eyetracking (part 2) on a central fixation with a given RDS or
% short/long presentation (part 1) without eyetracking
% Stimulus is a blue/black dot RDS in a square shape in the center (target) with a 
% white/black dot bacground at a different disparity. RDS is dynamic.
% It should present no monocular or binocular non-stereoscopic cues and
% triggers good stereoacuity.
% Changes in version 6
%   - fixed target (but dynamic background) - no fixation cross during
%   stimulation
%   - In 200 ms mode, measure amplitude of percept (mouse click) in some
%   trials to catch potential partial stereoblindness strategy
%   - does not support pedestals anymore
% Properties:
%   - dots at -2200 and 2200" to better estimate large thresholds
%   - 20 repetitions
%   - menu options with 200ms or 2000 ms test without eyetracking
%   - pseudo-randomization of trials
%   - menu manual mode can control dot size and dyRDS flashed
%   duration, among other things
%   - pedestal is always 0
%   - 3 different precisions (menu)


%-----------------------------------------------------------------------
%   Core paradigm is a 2AFC (discrimination) within constant stimuli method
%-----------------------------------------------------------------------
% Stimuli: dynamic RDS in 2 squares (one inside each other fixation) with zero disparity. We use Gaussian dots for
% subpixel precision, but the further away in distance, the better
%
% Stimulus sequence: 
%   -nonius + fixation squares
%   -RDS [+fixation] - stays for 2000ms or large eye movement (we use eye tracking)
%   -response (up or down arroy key)
%   -ISI
%
% Conditions: [constant stim of 13 stimuli]
%   - pedestals: 0 arcmin
%   - most parameters are controled in the globalParameters file except for
%   the ones in the default section below
%   
% Task: is the background further or closer than central surface?
%------------------------------------------------------------------------
% Controls: 
%       Down arrow (closer)
%       Up arrow  (further)
%       Backspace key (exit)
%------------------------------------------------------------------------
% Analysis: the correct file to analyse individual results is:
%       indivAnalysisERDS_multi_model
%
%=======================================================================
try
    
    clc
    Box=19;
    clc
    [pathExp,~]=fileparts(mfilename('fullpath'));
    addpath(fullfile(pathExp,'fonctions_ERDS'))
    rootpath=fileparts(pathExp);
    cd(pathExp)
    diary(fullfile(pathExp,'log',[sprintf('%02.f_',fix(clock)),'ERDS.txt']));
    diary ON
    disp(' ------------    ERDS version 5  ------------------')  

    
    %==========================================================================
    %                           QUICK PARAMETERS
    %==========================================================================
    
           %===================== INPUT MODE ==============================
            %1: User  ; 2: Robot 
            %The robot mode allows to test the experiment with no user awaitings
            %or long graphical outputs, just to test for obvious bugs
            inputMode=1; 
            %==================== DISPLAY MODE ==============================
            %1: ON  ; 2: OFF
            %In Display mode, some chosen variables are displayed on the screen
            displayMode=2;

            
    %=================      MENU     ===========================================
    %
    disp('------------------------------------')
    disp('Experimental Menu (choose an option)')
    disp('====================================')
    disp('1: Quick Mode')
    disp('2: Manual Mode')
    disp('3: Practice 2000 ms - no eyeTracker (NoE) - easy') 
    disp('4: Practice 1000 ms - NoE - easy')
    disp('5: Practice 1000 ms - NoE')
    disp('6: Practice 200 ms - NoE')
    disp('7: Test 200 ms - NoE - precision 20"')
    disp('8: Test 200 ms - NoE - precision 2"')
    disp('9: Practice 2000 ms - eyeTracker')
    disp('10: Test 2000 ms - eyeTracker')
    disp('11: Test 200 ms - NoE - precision 0.25" - sz 0.25VA') %sz 0.25VA is the size of the random dots
    disp('12: Test 2000 ms - NoE - precision 0.25" - sz 0.25VA')
    disp('13: Test 2000 ms - NoE - precision 0.25" - sz 0.14VA')
    disp('14: Test 2000 ms - NoE - precision 20"')
    disp('15: Test 2000 ms - NoE - precision 2"')
    disp('====================================')
    menu=str2double(input('Your option? ','s'));
    
            %==================== QUICK MODE ==============================
            %1: ON  ; 2: OFF 
            %The quick mode allows to skip all the input part at the beginning of
            %the experiment to test faster for what the experiment is.
            if menu == 1
                quickMode=1; %load parameters
            else
                 quickMode=2; 
            end        
            
            %===========================================
            %   HERE ARE THE DEFAULT VALUES
            %===========================================
                %==================== EYE TRACKER MODE ==============================
                %1: ON  ; 2: OFF 
                %In Display mode, some chosen variables are displayed on the screen
                eyeTrackerMode=2; 
                %==================== EYE TRACKER NO-SHOW MODE ==============================
                %1: NO SHOW  ; 2: SHOW 
                %Show or not the exact gaze position on screen with a colored dot
                noShowMode=1; 
                %===============================================================
                feedback = 1; %default
                stimDuration = 2000; %in ms %default 2000
                DE=2; %default
                nbRep = 2; %default
                nbRepAmp=1;%default
                practice = 1; %'Practice? 0 = no; 1 = stereo practice; 2 = eyetracker practice
                distFromScreen = 150; %cm defaut 150
                dotsizeVA = 0.25; %apparent size for a dot in visual angle %default
                flashduration = 250; %duration of a flash in ms (a dyRDS is a series of flash) %default
            %===========================================
            
            if quickMode==1 %just use the defaut values 
                name='default';
                nameDST='default';
                dispi('Quick mode uses default values')
            else
                
                distFromScreen = str2double(input('Viewing distance in cm? (enter a value or 1 for 150cm): ', 's'));
                if distFromScreen==1; distFromScreen=150; end
                
                if menu==2
                    %================   MANUAL MODE    ==========================================================
                    %   in manual mode, the following parameters can be changed
                    %       -practice
                    %       -feedback
                    %       -eyeTrackerMode
                    %       -nbRep
                    %       -noShowMode
                    %       -DE
                    %       -name + name DST
                    %       -stim duration
                    %       -distance from screen
                    %==========================================================================
                    dispi('Manual mode let you choose all values for each parameter')
                    eyeTrackerMode = str2double(input('eyeTracker Mode? (1: ON  ; 2: OFF): ', 's'));
                    noShowMode = str2double(input('no Show Mode? (1: no show  ; 2: show): ', 's'));
                    practice = str2double(input('Practice? (0 = no; 1 = stereo practice; 2 = eyetracker practice): ', 's'));
                    feedback = str2double(input('Feedback? (0 = no; 1 = yes): ', 's'));
                    nbRep = str2double(input('Nb of repetitions? (usually 2 for practice, 20 for test): ', 's'));
                    stimDuration = str2double(input('Stimulus duration? (in ms): ', 's'));
                    dotsizeVA = str2double(input('Dot size in VA? (0.14, 0.25 or 0.7): ', 's'));
                    flashduration = str2double(input('Flash duration? (250 or 2000): ', 's'));
                    name=nameInput;
                    DE=str2double(input('Dominant (non-amblyopic) Eye (1 for Left; 2 for Right): ', 's'));
                    nameDST=input('Enter name given for last DST: ','s');  
                    % dotSize=str2double(input('Dot Size? (11 or 21):  ', 's'));
                else
                    switch menu
                        case{3} %Practice 2000 ms - no eyeTracker
                            %default values)
                            dispi('Practice mode with long presentations, large disparities (easy), no eyetracking and default values')
                        case{4, 5} %Practice 1000 ms - no eyeTracker
                            stimDuration = 1000; %in ms
                            dispi('Practice mode with short presentations, no eyetracking')
                        case{6}  %Practice 200 ms - no eyeTracker
                             stimDuration = 200; %in ms
                             dispi('Practice mode with flashed presentations, small disparities (hard), no eyetracking')
                        case{7}  %Test 200 ms - no eyeTracker
                            dispi('Test mode with flashed presentations, threshold >20", no eyetracking')
                            stimDuration = 200; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;
                            nbRepAmp=10; %nb of repeats for amplitude estimates
                        case{8} %Test 200 ms - no eyeTracker - very hard
                            dispi('Test mode with flashed presentations, threshold 2-20", no eyetracking')
                            stimDuration = 200; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;
                            nbRepAmp=10;
                        case{9}  % Practice 2000 ms - eyeTracker
                            dispi('Practice mode with long presentations, threshold >20", eyetracking and visual fixation feedback')
                            practice = 2;
                            %==================== EYE TRACKER MODE ==============================
                            %1: ON  ; 2: OFF 
                            %In Display mode, some chosen variables are displayed on the screen
                            eyeTrackerMode=1;
                            %==================== EYE TRACKER NO-SHOW MODE ==============================
                            %1: NO SHOW  ; 2: SHOW 
                            %Show or not the exact gaze position on screen with a colored dot
                            noShowMode=2; 
                         case{10}  % Test 2000 ms - eyeTracker
                            dispi('Test mode with long presentations, threshold >20", eyetracking and no visual fixation feedback')
                            practice = 0; 
                            feedback = 0; 
                            nbRep = 20;
                            %==================== EYE TRACKER MODE ==============================
                            %1: ON  ; 2: OFF 
                            %In Display mode, some chosen variables are displayed on the screen
                            eyeTrackerMode=1;
                         case{11} 
                            dispi('Test mode with flashed presentations, threshold <2", no eyetracking')
                            stimDuration = 200; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;  
                            nbRepAmp=10;
                        case{12} 
                            dispi('Test mode with long presentations, threshold <2", no eyetracking')
                            stimDuration = 2000; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;  
                        case{13} 
                            dispi('Test mode with long presentations, threshold <2", small dots')
                            stimDuration = 2000; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;  
                            dotsizeVA=0.14;
                        case{14}  %Test 2000 ms - no eyeTracker
                            dispi('Test mode with long presentations, threshold >20", no eyetracking')
                            stimDuration = 2000; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;
                        case{15} %Test 2000 ms - no eyeTracker - very hard
                            dispi('Test mode with long presentations, threshold 2-20", no eyetracking')
                            stimDuration = 2000; %in ms
                            practice = 0;
                            feedback = 0; 
                            nbRep = 20;
                    end
                end

                if menu~=2
                    %==================  NAME  =============================================
                    if practice == 0
                        name=nameInput;
                    else
                        name = 'practice';
                    end
                    %==================  AMBLYOPIC EYE  =============================================
                   if eyeTrackerMode==1
                        DE=str2double(input('Dominant (non-amblyopic) Eye (1 for Left; 2 for Right):  ', 's'));
                   end
                   %==================  DST NAME  =============================================
                        nameDST=input('Enter name given for last DST: ','s');    
                end
            end
            flash = 1;
            file=[name,'_ERDS'];
            
            if practice == 0
                disp('----------------------------------------------------------------------------------------------')
                disp('Last review - are the following parameters correct for the REAL experiment?')
                disp('----------------------------------------------------------------------------------------------')
                disp(['File name: ',file])
                disp(['DST name: ',nameDST])
                disp(['Dominant Eye: ', num2str(DE)])
                disp(['Practice: ', num2str(practice)])
                disp(['Accordingly, feedback is ', num2str(feedback), ', EyeTracking mode is ',num2str(eyeTrackerMode),' and noShowMode parameter is ', num2str(noShowMode)])
                disp(['Distance to screen: ', num2str(distFromScreen),' cm'])
                dispi('Duration of a flash in a series of dyRDS: ',flashduration,'ms')
                dispi('Total stimulus duration: ',stimDuration,'ms')
                dispi('Size of a dot: ',dotsizeVA,'VA')
                dispi('Nb of repetitions by disparity: ',nbRep)
                disp('----------------------------------------------------------------------------------------------')
                disp('Press a key twice to continue or CTRL+C to exit...')
                WaitSecs(1);
                KbWait;
                WaitSecs(1);
                KbWait;
            end
            %=========  STARTERS =================================================== %
    %Initialize and load experiment settings (window and stimulus)
    
        %first check is file exists for that name
            alreadyStarted=exist(fullfile(pathExp,'dataFiles',[file,'.mat']))==2;
            
            %if file exist but its default, delete and start afresh
            if (quickMode==1 && alreadyStarted==1) || practice>0; delete(['dataFiles',filesep,file,'.mat']); delete(['dataFiles',filesep,file,'.txt']); alreadyStarted=0; end 
            
            if alreadyStarted==0 %intialize                 
                %=============   LOAD ALL PARAMETERS =================%
                [expe,scr,stim,sounds]=globalParametersERDS3(0,Box,distFromScreen,dotsizeVA,flashduration); 
                expe.nbRepeat=nbRep; %for non-zero disp pedestal MULTIPLE OF 2
                if mod(expe.nbRepeat,2)~=0; disp('Nb of repeats should be a multiple of 2!'); sca; xx; end
                if (menu==6) || (menu==7) || (menu==8) || (menu==11) || (menu==1)
                    expe.nbRepeatAmp=nbRepAmp; %repeat numbers for amplitude estimates
                else
                    expe.nbRepeatAmp=0;
                end
                expe.timings = nan(expe.nbRepeat*expe.nbValues,6);
                % ---------- ADAPT DIFFICULTY ---------------%
                %default disparity values:
                    expe.valueList = [-32 -16 -8 -4 -2 -1 0 1 2 4 8 16 32].*scr.distFromScreen/75; %or [-64 -32 -16 -8 -4 -2 0 2 4 8 16 32 64] at 150cm
                    expe.valueListSec = expe.valueList.*scr.dispByPx;
                    expe.nbValues = numel(expe.valueList);                      
                  switch menu
                      case{1, 3, 4}                    
                         expe.valueList = [-16 -8 -6 -4 -2 -1 1 2 4 6 8 16].*scr.distFromScreen/75;
                         expe.valueListSec = expe.valueList.*scr.dispByPx;
                         expe.nbValues = numel(expe.valueList);
                      case{8,15} %test with hard disparities
                         expe.valueList = [-1.5 -0.75 -0.375 -0.1875 -0.0938 0 0.0938 0.1875 0.375 0.75 1.5].*scr.distFromScreen/75; 
                         %it gives at 150: [-3 -1.5 -0.75 -0.375 -0.1875 0 0.1875 0.375 0.75 1.5 3]
                         expe.valueListSec = expe.valueList.*scr.dispByPx;
                         expe.nbValues = numel(expe.valueList);
                      case{11,12,13} %even smaller disparities <1"
                          expe.valueList = ([-0.2188 -0.1094 -0.0547 -0.0273 -0.0137 0 0.0137 0.0273 0.0547 0.1094 0.2188]).*scr.distFromScreen/75; %at 150cm,
                         %it gives: [-0.4375 -0.2188 -0.1094 -0.0547 -0.0273 0 0.0273 0.0547 0.1094 0.2188 0.4375]
                          expe.valueListSec = expe.valueList.*scr.dispByPx;
                         expe.nbValues = numel(expe.valueList);
                  end
                expe.menu=menu;
                expe.name='ERDS5';
                %=============   Do the stimulus table =================%                
                [expe.ShuffledTable]=initializeExp(expe);
       
                expe.DE = DE;
                expe.results = nan(size(expe.ShuffledTable,1),14);
                expe.block=0;
                expe.breakNb=0;
                expe.file=file;
                
                expe.nn=size(expe.ShuffledTable,1);
                                          
             else
                %if the file exists, just load it
                disp('Name exists: load previous data and parameters: IS THAT CORRECT? Quit now if it is not correct.')
                WaitSecs(1);
                KbWait;
                load([filesep,'dataFiles',filesep,file,'.mat'])
                Screen('Preference', 'SkipSyncTests', 0);
                scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr.box), [], 32, 2, [], 16); %multisampling to 16 for nice antialiasing
                Screen('BlendFunction', scr.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                precautions(scr.w, 'on');
                  
            end
         
      %--------------------------------------------------------------------------
      % load contrast and position information from the DST calibration
      %--------------------------------------------------------------------------
      if exist(fullfile(rootpath,'DSTv7','dataFiles', [nameDST,'.mat']),'file')==0; error('DST file name does not exist: we exist the program');end
          load(fullfile(rootpath,'DSTv7','dataFiles', [nameDST,'.mat']),'leftContr','rightContr', 'leftUpShift', 'rightUpShift', 'leftLeftShift', 'rightLeftShift', 'flickering')
          expe.leftContr = leftContr; expe.rightContr =rightContr; expe.leftUpShift =leftUpShift; expe.rightUpShift =rightUpShift;
          expe.leftLeftShift=leftLeftShift; expe.rightLeftShift=rightLeftShift; expe.flickering=flickering;

       %--------------------------------------------------------------------------
       %   UPDATE LEFT AND RIGHT EYE COORDINATES AND CONTRAST 
       %--------------------------------------------------------------------------
                        scr.LcenterXLine= scr.LcenterXLine - expe.leftLeftShift;
                        scr.LcenterXDot = scr.LcenterXDot - expe.leftLeftShift;
                        scr.RcenterXLine= scr.RcenterXLine - expe.rightLeftShift;
                        scr.RcenterXDot = scr.RcenterXDot - expe.rightLeftShift;
                        scr.LcenterYLine = scr.centerYLine - expe.leftUpShift;
                        scr.RcenterYLine = scr.centerYLine - expe.rightUpShift;
                        scr.LcenterYDot = scr.centerYDot - expe.leftUpShift;
                        scr.RcenterYDot = scr.centerYDot - expe.rightUpShift;
                       % [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye
                       % [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye
            
            disp(expe.name)
            expe.startTime=GetSecs;
            expe.lastBreakTime=GetSecs; %time from the last break
            expe.date(end+1)={dateTime};
            expe.goalCounter=expe.nn;      
            stim.flash = flash;
            expe.feedback = feedback;
           % expe.instrPosition=[0,scr.centerY,300,1000];
            
            %------------  POLARITY --------------%
     polarity = stim.polarity; %1 : standard with grey background, 2: white on black background, 3: black on white background, 4:
     %Gray background, half of the dots blue light, half of the dots dark
     switch polarity 
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
     end
    
     stim.itemDuration =  stimDuration  ;
     
      %----- ROBOT MODE ------%
        %when in robot mode, make all timings very short
        if inputMode==2
            stim.itemDuration                  = 0.0001;
            stim.interTrial                    = 0.0001;   
            displayMode=2;
            eyeTrackerMode=2;
        end
        
      
      %----- INITIALIZE EYE TRACKER ------%
      if eyeTrackerMode == 1
          if ~EyelinkInit(0)
                fprintf('Eyelink Init aborted.\n');
              %  cleanup;  % cleanup function 
              sca
                return; 
          end
            el=EyelinkInitDefaults(scr.w);
            
          % make sure that we get gaze data from the Eyelink
            Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA'); %binocular
            
          % open file to record data to
            Eyelink('openfile', 'temp.edf');

            % Calibrate the eye tracker
           % EyelinkDoTrackerSetup2(el, el.ENTER_KEY, scr);
          % round(scr.RcenterXDot-0.75*scr.res(3))/(scr.res(3)/2)
%            switch expe.DE
%                case  {1} %left eye
%                    outshift = 0.25*scr.res(3) - scr.LcenterXDot;
%                case {2} %right eye
%                    outshift = scr.RcenterXDot - 0.75*scr.res(3);
%            end
           
            expe.eyeTrackCalibration = 1;
            expe.driftCorrectionFlag = 1;
            % do a final check of calibration using driftcorrection
          %  EyelinkDoDriftCorrection(el);
      else
           el=[];
      end
      
      expe.language='en';
   %   %----- BLOCK LOOP --------%
   %   for ii=1:blockToDo
   %       expe.block=expe.block+1;
   %       disp(['BLOCK ',num2str(expe.block)])
                  
%             %--------------------------------------------------------------------------
%             %   DISPLAY INSTRUCTIONS 
%             %--------------------------------------------------------------------------
%                 displaystereotext3(scr,sc(scr.fontColor,scr.box),expe.instrPosition,expe.instructions3.(language),1);
%                 flip2(inputMode, scr.w,[],0);
%                 waitForKey(scr.keyboardNum,inputMode);
%             %--------------------- WAIT  --------------------------------

%             %--------------------------------------------------------------------------
%             %   Display block #
%             %--------------------------------------------------------------------------
%                 displaystereotext3(scr,sc(scr.fontColor,scr.box),expe.instrPosition,['Block ', num2str(block),' ---- ', additionalInstruction],1);
%                 flip2(inputMode, scr.w,[],0);
%                 waitForKey(scr.keyboardNum,inputMode);
%             %--------------------- WAIT  --------------------------------


            %THIS IS HERE ONLY FOR COMPATIBILITY WITH DICHOPTIC EYETRACKInG                
             %---- BIG BOXES (outer frame)
                  stim.horiz.contrast=expe.leftContr;
                  stim.vert.contrast=expe.leftContr;
                   horizframeMatL=ultimateGabor(scr.VA2pxConstant, stim.horiz); 
                   vertframeMatL=ultimateGabor(scr.VA2pxConstant, stim.vert); 
                  stim.horiz.contrast=expe.rightContr;
                  stim.vert.contrast=expe.rightContr;
                  horizframeMatR=ultimateGabor(scr.VA2pxConstant, stim.horiz); 
                   vertframeMatR=ultimateGabor(scr.VA2pxConstant, stim.vert);
                   
                  fr.topFrameCoordL=[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.horiz.height/2-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2+1,scr.LcenterYLine+stim.horiz.height/2-stim.vert.height/2+1];
                  fr.topFrameCoordR=[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.horiz.height/2-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2+1,scr.RcenterYLine+stim.horiz.height/2-stim.vert.height/2+1];
                  fr.bottomFrameCoordL=[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.horiz.height/2+stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2+1,scr.LcenterYLine+stim.horiz.height/2+stim.vert.height/2+1];
                  fr.bottomFrameCoordR=[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.horiz.height/2+stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2+1,scr.RcenterYLine+stim.horiz.height/2+stim.vert.height/2+1];
                  fr.leftFrameL=[scr.LcenterXLine-stim.vert.width/2-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2-stim.horiz.height/2-1,scr.LcenterXLine-stim.horiz.width/2+stim.vert.width/2+1,scr.LcenterYLine+stim.vert.height/2+stim.horiz.height/2+1];
                  fr.leftFrameR=[scr.RcenterXLine-stim.vert.width/2-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2-stim.horiz.height/2-1,scr.RcenterXLine-stim.horiz.width/2+stim.vert.width/2+1,scr.RcenterYLine+stim.vert.height/2+stim.horiz.height/2+1];
                  fr.rightFrameL=[scr.LcenterXLine-stim.vert.width/2+stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2-stim.horiz.height/2-1,scr.LcenterXLine+stim.horiz.width/2+stim.vert.width/2+1,scr.LcenterYLine+stim.vert.height/2+stim.horiz.height/2+1];
                  fr.rightFrameR=[scr.RcenterXLine-stim.vert.width/2+stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2-stim.horiz.height/2-1,scr.RcenterXLine+stim.horiz.width/2+stim.vert.width/2+1,scr.RcenterYLine+stim.vert.height/2+stim.horiz.height/2+1];

                  fr.horizframeL=Screen('MakeTexture',scr.w,sc(horizframeMatL,scr.box));
                  fr.vertframeL=Screen('MakeTexture',scr.w,sc(vertframeMatL,scr.box));
                  fr.horizframeR=Screen('MakeTexture',scr.w,sc(horizframeMatR,scr.box));
                  fr.vertframeR=Screen('MakeTexture',scr.w,sc(vertframeMatR,scr.box));
                  

         expe.beginInterTrial=GetSecs;
           abortedTrialNb = 1;
           startTrial = find(isnan(expe.results)==1,1,'first'); %find the first nan (not done) trial
           for trial=startTrial:expe.nn
               abortedTrial = 1;
               while abortedTrial == 1
                    [trialLine, expe, abortedTrial,stopSignal, timingsTrial]=trialERDS(trial, stim,scr,expe, sounds, el,inputMode, displayMode, eyeTrackerMode, noShowMode,fr);
                    expe.results(trial,:)= trialLine;
                    expe.timings(trial,:)= timingsTrial;
                    if abortedTrial == 1
                       expe.abortedTrials(abortedTrialNb, :) = trialLine; 
                       abortedTrialNb = abortedTrialNb + 1; 
                       thisTrial = expe.ShuffledTable(trial,:);
                       expe.ShuffledTable(trial,:)=[];
                       expe.ShuffledTable(end+1,:)=thisTrial;
                    end
                    save('temp2.mat')
                    
                   if stopSignal==1
                       break 
                    end 
               end
               
               if stopSignal==1
                   %expe.timings
                       break 
               end
            end
                        

                                   % ----- response TABLE --------------------------------
                                   %    1:  trial
                                   %    2:  Does the trial includes amplitude estimate? (1 - yes, 0 - no)
                                   %    3:  pedestal value in pp (always 0)
                                   %    4:  repetition
                                   %    5:  value (disparity) # (background)
                                   %    6:  estimate response (distance in mm)
                                   %    7:  is the target closer or not ? (correct answer) - 1: yes - 2: no
                                   %    8:  disparity of Center stim in pp
                                   %    9:  disparity of background stim in pp
                                   %    10:  disparity value in arcsec
                                   %    11  responseKey - target stim is closer(6) or not (5)
                                   %    12  fixation duration
                                   %    13  RT = stimulus duration
                                   %    14  Gaze outside of area or not? (1 yes, 0 no)
                                                                      
        %--------------------------------------------------------------------------
        %   SAVE AND QUIT
        %--------------------------------------------------------------------------
             %===== SAVE ===%
                 disp(['Duration:',num2str((GetSecs-expe.startTime)/60)]);
                 expe.time(end+1)=(GetSecs-expe.startTime)/60;
                 tmp=inputMode; 
                 if eyeTrackerMode==1; 
                    % stop eyelink
                    Eyelink('StopRecording');
                    Eyelink('ShutDown');
                 end
                 clear quickMode inputMode displayMode eyeTrackerMode noShowMode nameDST
                 save(fullfile(pathExp,'dataFiles',expe.file))
                 saveAll(fullfile(pathExp,'dataFiles',[expe.file,'.mat']),fullfile(pathExp,'dataFiles',[expe.file,'.txt']))

             %===== THANKS ===%
                Screen('FillRect',scr.w, sc(scr.backgr,scr.box));
                displaystereotext3(scr,sc(scr.fontColor,scr.box),[0,500,500,400],expe.thx.(expe.language),1);
                %displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/2-250,500,500,400],thx.(expe.language))
                flip2(tmp, scr.w);   
                waitForKey(scr.keyboardNum,tmp); 

             %===== QUIT =====%
                 warnings 
                 precautions(scr.w, 'off');
            
                 %display some result
              CR=sum(((7-expe.results(:,11))==expe.results(:,7) | expe.results(:,9) == 0))./size(expe.results,1);
              disp(['Correct response rate = ',num2str(100*CR),'%'])
              changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz);
              diary OFF

catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    disp(err)
    rethrow(err);
    save(fullfile(pathExp,'log',[expe.file,'-crashlog']))
    saveAll(fullfile(pathExp,'log',[expe.file,'-crashlog.mat']),fullfile(pathExp,'log',[expe.file,'-crashlog.txt']))
    warnings
    changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz);
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
        if eyeTrackerMode==1; Eyelink('ShutDown');end
end
%============================================================================
end

function [ShuffledTable]=initializeExp(expe)
                                   % -----  TABLE --------------------------------
                                   %    1:  Does the trial includes amplitude estimate? (1 - yes, 0 - no)
                                   %    2:  pedestal value in pp (always 0)
                                   %    3:  repetition
                                   %    4:  value (disparity) # (background)
                                   %    5:  estimate response (nan initially)
                                   %    6:  is the background closer or not ? (correct answer) - 1: yes - 2: no
                                   %    7:  disparity of Center stim in pp(positive is uncrossed)
                                   %    8:  disparity of background stim in pp (positive is uncrossed)
                                   %    9:  disparity value in arcsec(positive is uncrossed)
                                   % ---------------------------------------------
                                   
ShuffledTable=[];
    %pseudorandomisation
     for r=1:(expe.nbRepeat)
        table=[];
             for v=1:expe.nbValues
                 %if r<=expe.nbRepeatAmp; amplitudeTrial=1; else; amplitudeTrial=0;end
                 dispCenter = 0 ; %disparity in pp for the upper stimulus
                 dispBg = 0 + expe.valueList(1,v);  %disparity in pp for (background)
                 [dummy, t] = min([dispCenter,dispBg]) ; % is the target closer or not (correct answer)  (yes 1 or no 2)
                 table=[table;nan,0,r,v,nan,t,dispCenter, dispBg, expe.valueListSec(1,v)];            
             end   
        nn=size(table,1);
        idx=randsample(nn,nn,0);
        ShuffledTable=[ShuffledTable;table(idx,:)];
     end
     
     %add amplitude measures
     for v=1:expe.nbValues
         idxAmp=randsample(expe.nbRepeat,expe.nbRepeatAmp,0);
         idx=find(ShuffledTable(:,4)==v);
         ShuffledTable(idx(idxAmp),1)=1;
     end

end
