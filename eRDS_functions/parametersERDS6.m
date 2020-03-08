function [expe,scr,stim,sounds, psi]=parametersERDS6(expe)
%======================================================================
%  Goal: control panel for the experiment parameters for eRDS6
%======================================================================
    
    %set the randomness random
    try rng('shuffle'); catch; rand('twister', sum(100*clock)); end
    Screen('Preference', 'SkipSyncTests', 0); % HERE CHANGE TO 0!!!
    %warning('change line 8 to 0')
    AssertOpenGL; %?

    %--------------------------------------------------------------------------
    %         EXPERIENCE PARAMETERS
    %--------------------------------------------------------------------------
        %general
        expe.feedback = 2;               % 0 = never; 1 = always; 2 = yes for practice, no for test
        expe.nbTrials = 73;              % number of trials HERE (for a near or a far side only)73
        expe.practiceTrials = 12;        % HERE 12 number of practice trials before task (used for prior estimation) (for either the near or the far disparities)   
        %expe.nn = expe.nbTrials+expe.practiceTrials; % number of trials in total (for either the near or the far disparities)
        % the actual total number of trials is two times expe.nn because we adds near and far trials.
        expe.version = 'eRDS6';
        expe.time = [];                    % duration of the sessions in min
        expe.date = {};                    % date of the sessions
        expe.breaks = [];                  % for each break, trial and duration of the break in sec
        expe.breakNb = 0;                  % current break number
        expe.breakTime = 10;               % time after which there is a small break, in min
        expe.escapeTimeLimit = 10;         % nb of min after which escape key is deactivated
        expe.quickMode = 2;                % 1: ON / 2: OFF / The quick mode allows to skip all the input part at the beginning of the experiment to test faster for what the experiment is.
        expe.inputMode = 1;                % 1: User  ; 2: Robot / The robot mode allows to test the experiment with no user awaitings or long graphical outputs, just to test for obvious bugs
        expe.debugMode = 2;                % 1: ON  ; 2: OFF / In debug mode, some chosen variables are displayed on the screen
        expe.breakInstructions.fr = strcat('Vous pouvez prendre une pause. Appuyez sur une touche à la fin de la pause.');
        expe.breakInstructions.en = strcat('You can have a break if you wish. Press a key after the break.');
        expe.thx.fr = '====  MERCI  =====';
        expe.thx.en = '=====  THANK YOU  =====';
        expe.verbose = 'verboseON';      % verbose or not (verboseON or verboseOFF)
        expe.language = 'fr';
        %       Response Code Table:
        %               0: no keypress before time limit
        %               1: left 
        %               2: right 
        %               3: space
        %               4: escape
        %               5: up
        %               6: down
        %               8: backspace
        %              52: enter (numpad)
    %======================================================================
    %              WINDOW-SCREEN PARAMETERS 
    %====================================================================== 
        scr = screen_parameters;
        screens=Screen('Screens');
        scr.screenNumber=max(screens);            % will certainly not function correctly in multiple screen though

    %check that we have the appropriate resolution
%        scr.oldResolution=Screen('Resolution',scr.screenNumber);
%         if scr.oldResolution.width==scr.goalWidthRes && scr.oldResolution.height==scr.goalHeightRes && scr.oldResolution.hz==scr.goalRefreshRate
%             disp('Resolution and refresh are correct')
%             scr.pixelSize = scr.oldResolution.pixelSize;
%         else
        [success, scr.oldResolution, scr.newResolution]  = changeResolution(scr.screenNumber, scr.goalWidthRes, scr.goalHeightRes, scr.goalRefreshRate);
        if success==0; error('See warning - resolution could not be changed appropriately');end
        scr.pixelSize = scr.newResolution.pixelSize;
        scr.res=Screen('rect', scr.screenNumber); % screen size in pixel, format: [0 0 maxHoriz maxVert]
        
     %check if vertical and horizontal pixel sizes are the same
        scr.ppBymm= scr.res(3)/scr.W;
        if abs((scr.res(3)/scr.W)-(scr.res(4)/scr.H))>0.05; warning('Ratio error >5%: change the screen resolution to have equal pixel sizes.');end
        scr.VA2pxConstant=scr.ppBymm *10*VA2cm(1,scr.distFromScreen); %constant by which we multiply a value in VA to get a value in px ?
        scr.dispByPx = 3600./scr.VA2pxConstant; %disparity (arcsec) by pixel when in one eye
        %careful: if you have 1px of disparity for each eye (not just one), the above disparity by pixel should be multiplied by two
        
     %now defines centers of screen and centers of stereo screens
     %Caution has to be taken because the screen origin for DrawLine and DrawDots are different, and are also dependent on the screen
     %On some viewPixx, screen originates at [1,0] for DrawLine and [0,1]
       %for DrawDots
        scr.centerX = scr.res(3)/2;
        scr.centerY = scr.res(4)/2;
        scr.frameSep = scr.W/4;
        scr.stereoDeviation = scr.ppBymm.*scr.frameSep; %nb of px necessary to add from screen center in order to put a stim at zero disparity
        % This above value is calibrated during DST (red-green lines)           
        scr.LcenterX=round(scr.centerX-scr.stereoDeviation);
        scr.RcenterX=round(scr.centerX+scr.stereoDeviation);
        scr.centerY=round(scr.centerY);
           
       %Centers for Drawline
        scr.LcenterXLine=ceil(scr.centerX-scr.stereoDeviation); %stereo position of left eye center
        scr.RcenterXLine=ceil(scr.centerX+scr.stereoDeviation); %stereo position of right eye center
        scr.centerYLine=ceil(scr.centerY); %stereo position of left eye center
       %Centers for Drawdots
        scr.LcenterXDot=ceil(scr.centerX-scr.stereoDeviation); %stereo position of left eye center
        scr.RcenterXDot=ceil(scr.centerX+scr.stereoDeviation); %stereo position of right eye center
        scr.centerYDot=ceil(scr.centerY); %stereo position of left eye center
            
        scr.backgr=15; %in cd/m2
        scr.keyboardNum=-1; % all available keyboards
        scr.fontSize  = 30; % font size for text drawings
        
        scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr), [], [], 2, [], scr.pixelSize);      %32 multisamples for anti-aliasing but then system will downgrade to the max supported
        Screen('BlendFunction', scr.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %for multisampling anti-aliasing and transparency    
           
     %    scr.frameTime =Screen('GetFlipInterval', scr.w, 2);
     %   scr.frameTime = 1/60; %CHANGE HERE
    %     scr.monitorRefreshRate=1/scr.frameTime;
        scr.monitorRefreshRate = Screen('NominalFrameRate', scr.w);
        scr.frameTime = 1/scr.monitorRefreshRate;
        
        [~, maxSmoothPointSize, ~, ~] = Screen('DrawDots',scr.w);
        scr.maxSmoothPointSize = maxSmoothPointSize;       
        scr.antialliasingMode = 2;  % 2 is best, 3 is OK HERE
        scr.lenient = 1; % enforce (0) or not (1) the abortion of the program in case the detected max dot size is below what we need HERE
        
    %======================================================================
    %              STIMULUS PARAMETERS 
    %======================================================================
         stim.maxLum = 50;   %maximum white to display
         stim.minLum = 0;    %maximum dark to display
         stim.flash = 1;     %0 no dyRDS - 1: dyRDS - 0 is not implemented yet
                
        %Fixation nonius cross / circle + fixation dot
         stim.fixationLengthMin = 25; % half size in arcmin
         stim.fixationLineWidthMin = 6; %in arcmin 8
         stim.fixationOffsetMin = 10; %offset between central fixation and nonius in arcmin
         stim.fixationDotSizeMin = 11; %in arcmin
             
         % RDS dots        
         stim.config = 3;                 % orientation of rds stimuli: 1: left - right panels / 2: NOT OPERATIONAL center - surround  / 3 : outer-strip vs central strip
         stim.dotSizeVA = [0.5, 0.1];    % needs two sizes here 0.5 0.1
         % size for a dot in visual angle (can be a list of dot sizes)
         % Ideally it would be:
         % 0.5 VA, which is optimal according to Ding & Levi, 2011, Fig. 3B for participants with strabismus
         % 0.03 VA, which is is optimal for participant without strabismus
         % However, drawDots does not support the large size
         %stim.densityXsize = 1800; % constant size (in arcsec) x density (in dots by VA2)
         %stim.dotDensity_VA2 = stim.densityXsize./mean(stim.dotSizeVA.*3600); % in dots per squared VA
         stim.dotDensity = [12/100, 2/100]; % in % of area occupied by dots for each dot size, so that size in arcsec x nb dots by degree = 2175/2  
         stim.distBetwDots_min = 10; % minimal distance between dots in arcmin - 10 arcmin prevents crowding
         stim.overlap = 0; % can dots overlap each other or not? 0 no, 1 yes (if they can overlap, distBetwDots_min does not matter)
         stim.maxLoadingTime = 10; %in sec, maximum calculation time allowed to find dot coordinates %HERE
         stim.coherence = 0/100; % share of dots (in %) that have a coherent motion - careful, coherent motion decreases stereoacuity: Hadani & Vardi, 1987
         stim.speedVA_sec = 0.5; % in VA by sec
          %to be converted in arcsec ?
         stim.polarity = 5; %1 : standard with grey background, 2: white on black background, 3: black on white background, 4: half white+blue/half white+black, %5: grey background, half white, half black
          %  if mod(stim.dotSize,2)~=1; disp('dotsize should be odd');  sca; xx; end
          %  if stim.dotSize<3; disp('dotsize should be greater than 3');  sca; xx; end
          
         % Large box properties 1 (outer frame for fusion)
         stim.frameLineWidthVA = 0.3; %line width of the frames in VA
         stim.spaceFrameRdsVA = 0.1;    %size of the space between the rds and the outer frame in VA 0.2
         
        % RDS width and height / be sure to adapt that so that it is compatible with your screen size and distance
        
        if stim.config == 1 % LEFT - RIGHT RDS
            % THIS IS THE SIZE OF ONLY ONE RDS space (we have one on the left, one the right)
             stim.rdsWidthVA = 3.3; %6.5 
             stim.rdsInterspaceVA = 0; %space size between RDS in VA
             stim.rdsHeightVA = 8; %6.5
             
            % Large box properties 2 (outer frame for fusion)         
             stim.frameWidthVA = 2*stim.rdsWidthVA + 2*stim.spaceFrameRdsVA + stim.rdsInterspaceVA + stim.frameLineWidthVA; % witdth of the outside frame in deg 10.65
             stim.frameHeightVA = stim.rdsHeightVA + 2*stim.spaceFrameRdsVA + stim.frameLineWidthVA; %in deg 18.65        
             stim.patterning = 1; % 0: no patterning; 1: we split the area in two and just copy the dots from top area to bottom area; 2: mirror them vertically
        elseif stim.config == 2 %CENTER - SURROUND RDS
             stim.rdsWidthVA = 6.6;    % width of surround rds (its height is stim.rdsHeightVA)
             stim.rdsCenterSizeVA = 3; % width and height for central rds
             stim.rdsHeightVA = 8; %6.5
            % Large box properties 2 (outer frame for fusion)     
             stim.frameWidthVA = stim.rdsWidthVA + 2*stim.spaceFrameRdsVA + stim.frameLineWidthVA; % witdth of the outside frame in deg 10.65
             stim.frameHeightVA = stim.rdsHeightVA + 2*stim.spaceFrameRdsVA + stim.frameLineWidthVA; %in deg 18.65             
             stim.patterning = 2; % 0: no patterning; 1: we split the area in two and just copy the dots from top area to bottom area; 2: mirror them vertically
        elseif stim.config == 3 % CENTRAL STRIP - OUTER STRIPS
             stim.rdsWidthVA = 6.6;    % width of surround rds 
             stim.rdsHeightVA = 2.7; %6.5 % THIS IS FOR ONE STRIP (out of 3)
             %stim.rdsInterspaceVA = 0; %space size between RDS in VA
             
             % Large box properties 2 (outer frame for fusion)     
             stim.frameWidthVA = stim.rdsWidthVA + stim.frameLineWidthVA; % witdth of the outside frame in deg 10.65
             stim.frameHeightVA = 3*stim.rdsHeightVA + 2*stim.spaceFrameRdsVA + stim.frameLineWidthVA; %in deg 18.65      + 2*stim.rdsInterspaceVA       
             stim.patterning = 1; % 0: no patterning; 1: we split the area in two and just copy the dots from top area to bottom area; 2: mirror them vertically
        end
        
        if stim.config == 1
            expe.allowed_key = [8, 1, 2]; %the escape key is not esc but backspace 
            expe.allowed_key_locked = [1, 2]; % after escapeTimeLimit, escape key is locked to avoid quitting by mistake
        else
            expe.allowed_key = [8, 5, 6]; %the escape key is not esc but backspace 
            expe.allowed_key_locked = [5, 6]; % after escapeTimeLimit, escape key is locked to avoid quitting by mistake
        end
        expe.current_allowed = expe.allowed_key; 
        
    %--------------------------------------------------------------------------
    % TIMING (All times are in MILLISECONDS)
    %--------------------------------------------------------------------------
         stim.itemDuration = 2000;        % RDS total presentation time in ms HERE
         if stim.flash==0 && mod(stim.itemDuration,(1000*scr.frameTime))~=0; warni('Stimulus duration is not a factor of the frame duration. For precision, it could be...')
             warni('...wise (but we will round anyway) to adjust stim.itemDuration by ',mod(stim.itemDuration,(1000*scr.frameTime)),'ms'); end
         stim.flashDuration  = 400;       % duration of a flash in ms (a dyRDS is a series of flash presentations)
         if mod(stim.itemDuration,stim.flashDuration)~=0; warni('Stimulus duration is not a factor of flash duration. For precision, it could be...')
             warni('...wise to adjust stim.itemDuration by ',mod(stim.itemDuration,stim.flashDuration),'ms'); end
         stim.interTrial   = 0;           % Minimal ISI in ms - entirely determined by calculation time
    %--------------------------------------------------------------------------   

% ============================================
%           Conversions in pixels
% ============================================
        stim.fixationLength=round(convertVA2px(stim.fixationLengthMin/60));
        stim.fixationLineWidth=round(convertVA2px(stim.fixationLineWidthMin/60));
        stim.fixationOffset=round(convertVA2px(stim.fixationOffsetMin/60));
        stim.fixationDotSize=round(convertVA2px(stim.fixationDotSizeMin/60));
        stim.frameLineWidth = round(convertVA2px(stim.frameLineWidthVA));
        stim.rdsWidth=round(convertVA2px(stim.rdsWidthVA));
        stim.rdsHeight=round(convertVA2px(stim.rdsHeightVA));
        stim.frameWidth = round(convertVA2px(stim.frameWidthVA));
        stim.frameHeight = round(convertVA2px(stim.frameHeightVA));
        if stim.config == 1; stim.rdsInterspace = round(convertVA2px(stim.rdsInterspaceVA)); end
        stim.speed = convertVA2px(stim.speedVA_sec); % in pp by sec
        stim.ppByFlash = ((stim.speed./1000).*stim.flashDuration); % in pp by flash 
        stim.distBetwDots = round(convertVA2px(stim.distBetwDots_min/60));
        stim.dotSize = round(convertVA2px(stim.dotSizeVA)); % in pp
        if stim.config == 2
            stim.rdsCenterSize = round(convertVA2px(stim.rdsCenterSizeVA)); 
            if mod(stim.rdsCenterSize,2)~=0; disp('Correcting: stim.rdsCenterSize should be even - removing 1pp');  stim.rdsCenterSize=stim.rdsCenterSize-1; end
        end
        if mod(stim.rdsHeight,2)~=0; disp('Correcting: stim.rdsHeight should be even - removing 1pp');  stim.rdsHeight=stim.rdsHeight-1; end
        if mod(stim.rdsWidth,2)~=0; disp('Correcting: stim.rdsWidth should be even - removing 1pp');  stim.rdsWidth=stim.rdsWidth-1; end
        if mod(stim.frameWidth,2)~=0; disp('Correcting: stim.frameWidth should be even - adding 1pp');  stim.frameWidth=stim.frameWidth+1; end
        if mod(stim.frameHeight,2)~=0; disp('Correcting: stim.frameHeight should be even - adding 1pp');  stim.frameHeight=stim.frameHeight+1; end
        
        %Text properties
         stim.instrPosition = [0,scr.centerY,stim.frameWidth,stim.frameHeight];   % where to show instructions on screen 
         if ((scr.lenient==0) && any(stim.dotSize>scr.maxSmoothPointSize)); erri('Your system does not support the requested dot size(',stim.dotSize,' vs. a max of ',scr.maxSmoothPointSize,')'); end

    %--------------------------------------------------------------------------
    %         sounds PARAMETERS
    %--------------------------------------------------------------------------
        sounds = struct();
        [wave1, sounds.freq1] = psychwavread(fullfile(expe.soundpath,'success.wav'));
        sounds.success = wave1';
        [wave2, sounds.freq2] = psychwavread(fullfile(expe.soundpath,'fail.wav'));
        sounds.fail = wave2';
        InitializePsychSound;
        sounds.handle1 = PsychPortAudio('Open', [], [], 0, sounds.freq1, 2);
        sounds.handle2 = PsychPortAudio('Open', [], [], 0, sounds.freq2, 2);
        PsychPortAudio('FillBuffer', sounds.handle1, sounds.success);
        PsychPortAudio('FillBuffer', sounds.handle2, sounds.fail);
        
    %--------------------------------------------------------------------------
    %   PSI algorithm parameters
    %----------------------------------------------------------------------------
        psi.xmin= 3; %minimal disparity possible in arcsec (cannot measure thresholds below that value!) % adding 0.5, 1, 1.5, 2 and 2.5 though
        psi.x1 = 1200;
        psi.x2 = 1400;
        psi.xmax = 3000; %max one (cannot measure thresholds above that value!)
        psi.xstep1 = 0.001; %step size for sampling in log unit 0.05
        psi.xstep2 = 0.001;
        psi.disparities = [log10(0.5:0.5:2.5),log10(psi.xmin):psi.xstep1:log10(psi.x1),log10(psi.x1):psi.xstep2:log10(psi.x2),...
            log10(psi.x2):psi.xstep1:log10(psi.xmax)]; %range of possible values for disparities x, in log10(arcsec)
        
        psi.tmin = 3; % minimal threshold that we parametrized % adding 0.5, 1, 1.5, 2 and 2.5 though
        psi.t1 = 1000;
        psi.t2 = 1600;
        psi.tmax = 2200; % maximal threshold that we parametrized  
        psi.tstep1 = 0.04; %step size for this parameter in log unit 0.05
        psi.tstep2 = 0.04;
        psi.thresholds = [log10(0.5:0.5:2.5),log10(psi.tmin):psi.tstep1:log10(psi.t1),log10(psi.t1):psi.tstep2:log10(psi.t2),...
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
            1000    
            1000   
            1000
            500    
            500    
            250     
            250       
            100    
            100    
            ]);
        psi.sim_threshold = 1000; %simulated threshold whenever we do robotMode
        psi.end = 0;  % end signal for algorithm
        psi.trial = 1;
        
        precautions(scr.w, 'on');
 
%     SPECIAL for VIEWPIXX - this needs the usb cable to be plugged
    if scr.viewpixx==1
        Datapixx('Open');
        Datapixx('EnableVideoScanningBacklight');
        Datapixx('RegWrRd');
        status = Datapixx('GetVideoStatus');
        fprintf('Scanning Backlight mode on = %d\n', status.scanningBacklight);
        Datapixx('Close');
    end

    function px=convertVA2px(VA)
        px=scr.ppBymm.*10.*VA2cm(VA,scr.distFromScreen); 
    end
end
