function [expe, psi, stopSignal]=trialeRDS6(trial,stim,scr,expe,sounds,psi)
%------------------------------------------------------------------------
%
%================== Trial function in a 2AFC constant stim method ====================================   
%   Called by ERDS main experiment function
%   This function does:
%           - display instructions and stimuli, get response for 1 trial
%           - choose next stimulus depending on psi algorithm
%=======================================================================

try
%--------------------------------------------------------------------------
%   STIM - RESP LOOP
%--------------------------------------------------------------------------  
    startTrialTime = GetSecs;
    stopSignal = 0;
    stim.trial = trial;
    
    % find out what is the next disparity
    psi = Psi_marg_erds6('value',trial, psi, expe, scr);
                                   
%im2=nan(50,50,3,11); %subpixel
%for jjj=1:10 %subpixel
   expected_side = round(rand(1)); % 0: left/center side closer - 1: right/outer side closer
   if strcmp(psi.sign, 'near')
        signed_disp = -10.^psi.current_disp;
        if expected_side == 0
            L_R_disp = [signed_disp 0];
        else
            L_R_disp = [0 signed_disp];
        end
   else
        signed_disp = 10.^psi.current_disp;
        if expected_side == 0
            L_R_disp = [0 signed_disp];
        else
            L_R_disp = [signed_disp 0];
        end
   end
   L_R_disp_pp = L_R_disp./scr.dispByPx; % this is actually center - surround disparities if in stim.config 2/3

   if stim.config == 3
        % for that configuration, decide whether central dots are blue or white
        blueDots = round(rand(1)); %0 centre, 1: outer strips
        if blueDots == 0
            stim.dotColor2 = stim.white;
            stim.dotColor3 = stim.blue;
        else
            stim.dotColor2 = stim.blue;
            stim.dotColor3 = stim.white;
        end
   else
       blueDots = 2; %always right - useless
   end
   
       % dispCenter=(jjj-1)/5; %subpixel
      %dispBg=(jjj-1)/10; %subpixel
      %--------------------------------------------------------------------------
      %=====  Check BREAK TIME  ====================
      %--------------------------------------------------------------------------
       if (GetSecs-expe.lastBreakTime)/60>=expe.breakTime
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           beginbreak=GetSecs;
           countdown(30,scr,stim)
           displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,expe.breakInstructions.(expe.language),1);
           flip2(expe.inputMode, scr.w);  
           waitForKey(scr.keyboardNum,expe.inputMode);
           %-------------------- WAIT ------------------------------------------
           expe.breakNb=expe.breakNb+1;
           expe.breaks(expe.breakNb,:)=[expe.breakNb, (beginbreak-expe.startTime)/60 ,trial, (GetSecs-beginbreak)/60]; %block, trial and duration of the break
           expe.lastBreakTime=GetSecs;
           startTrialTime = GetSecs;
       end

        if ((GetSecs-expe.startTime)/60)>expe.escapeTimeLimit %the first ~10 min, allows for esc button but not after
            expe.current_allowed = expe.allowed_key_locked;
        end
        responseKey = 0;
              
              
        %--------------------------------------------------------------------------
        %   PRELOADING OF COORDINATES DURING INTERTRIAL 
        %--------------------------------------------------------------------------

             %generates every frames of RDS stimulus
             %backgound
             expe.nbFrames =  round(stim.itemDuration / stim.flashDuration);   % +20?
             
             % obtain the number of dots to generate for that area size, dot density, and possible dot sizes (assuming equal number of each possible size)
             if stim.config == 1 % LEFT - RIGHT RDS
                 % left rds
                 stim.areaSizeppLeft = (stim.leftrdsL1(4)-stim.leftrdsL1(2)).*(stim.leftrdsL1(3)-stim.leftrdsL1(1)-abs(L_R_disp_pp(2))); % in squared pp
                 stim.nbDotsLeft(1) = round(stim.dotDensity(1).*stim.areaSizeppLeft./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsLeft(1),2)==1; stim.nbDotsLeft(1) = stim.nbDotsLeft(1)+1; end
                 stim.nbDotsLeft(2) = round(stim.dotDensity(2).*stim.areaSizeppLeft./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsLeft(2),2)==1; stim.nbDotsLeft(2) = stim.nbDotsLeft(2)+1; end
                 stim.totalNbDotsLeft = sum(stim.nbDotsLeft);

                 % right rds
                 stim.areaSizeppRight = (stim.rightrdsL1(4)-stim.rightrdsL1(2)).*(stim.rightrdsL1(3)-stim.rightrdsL1(1)-abs(L_R_disp_pp(1))); % in squared pp
                 stim.nbDotsRight(1) = round(stim.dotDensity(1).*stim.areaSizeppRight./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsRight(1),2)==1; stim.nbDotsRight(1) = stim.nbDotsRight(1)+1; end
                 stim.nbDotsRight(2) = round(stim.dotDensity(2).*stim.areaSizeppRight./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsRight(2),2)==1; stim.nbDotsRight(2) = stim.nbDotsRight(2)+1; end
                 stim.totalNbDotsRight = sum(stim.nbDotsRight);

             elseif stim.config == 2 %CENTER - SURROUND RDS
                 % center rds
                 stim.areaSizeppCenter = (stim.centerrdsL(4)-stim.centerrdsL(2)).*(stim.centerrdsL(3)-stim.centerrdsL(1)); % in squared pp
                 stim.nbDotsCenter(1) = round(stim.dotDensity(1).*stim.areaSizeppCenter./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsCenter(1),2)==1; stim.nbDotsCenter(1) = stim.nbDotsCenter(1)+1; end
                 stim.nbDotsCenter(2) = round(stim.dotDensity(2).*stim.areaSizeppCenter./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsCenter(2),2)==1; stim.nbDotsCenter(2) = stim.nbDotsCenter(2)+1; end
                 stim.totalNbDotsCenter = sum(stim.nbDotsCenter);
                 
                 % outer rds
                 stim.areaSizeppOuter = (stim.outerrdsL(4)-stim.outerrdsL(2)).*(stim.outerrdsL(3)-stim.outerrdsL(1)) - stim.areaSizeppCenter  ...% in squared pp
                    - 2.*abs(L_R_disp_pp(1)).*(stim.centerrdsL(4)-stim.centerrdsL(2)) - abs(L_R_disp_pp(2)).*(stim.outerrdsL(4)-stim.outerrdsL(2)); % also removing additional exclusion areas
                 stim.nbDotsOuter(1) = round(stim.dotDensity(1).*stim.areaSizeppOuter./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsOuter(1),2)==1; stim.nbDotsOuter(1) = stim.nbDotsOuter(1)+1; end
                 stim.nbDotsOuter(2) = round(stim.dotDensity(2).*stim.areaSizeppOuter./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsOuter(2),2)==1; stim.nbDotsOuter(2) = stim.nbDotsOuter(2)+1; end
                 stim.totalNbDotsOuter = sum(stim.nbDotsOuter);
                 
             elseif stim.config == 3 % CENTRAL STRIP - OUTER STRIPS
                 % central rds
                 stim.areaSizeppCenter = (stim.centerrdsL(4)-stim.centerrdsL(2)).*(stim.centerrdsL(3)-stim.centerrdsL(1)-abs(L_R_disp_pp(2))); % in squared pp
                 stim.nbDotsCenter(1) = round(stim.dotDensity(1).*stim.areaSizeppCenter./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsCenter(1),2)==1; stim.nbDotsCenter(1) = stim.nbDotsCenter(1)+1; end
                 stim.nbDotsCenter(2) = round(stim.dotDensity(2).*stim.areaSizeppCenter./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsCenter(2),2)==1; stim.nbDotsCenter(2) = stim.nbDotsCenter(2)+1; end
                 stim.totalNbDotsCenter = sum(stim.nbDotsCenter);

                 % outer upper and lower rds
                 stim.areaSizeppOuter = (stim.outerrdsL1(4)-stim.outerrdsL1(2)).*(stim.outerrdsL1(3)-stim.outerrdsL1(1)-abs(L_R_disp_pp(1))); % in squared pp
                 stim.nbDotsOuter(1) = round(stim.dotDensity(1).*stim.areaSizeppOuter./(pi.*(stim.dotSize(1)./2).^2));
                 if mod(stim.nbDotsOuter(1),2)==1; stim.nbDotsOuter(1) = stim.nbDotsOuter(1)+1; end
                 stim.nbDotsOuter(2) = round(stim.dotDensity(2).*stim.areaSizeppOuter./(pi.*(stim.dotSize(2)./2).^2));
                 if mod(stim.nbDotsOuter(2),2)==1; stim.nbDotsOuter(2) = stim.nbDotsOuter(2)+1; end
                 stim.totalNbDotsOuter = sum(stim.nbDotsOuter);
             end
             
             if stim.config == 1
                 %choose a size for each dot - we work with half of the dots, and duplicate it because later, we generates coords for half of the list and duplicate
                 stim.dotSizesLeft = repmat(Shuffle([ones(1,stim.nbDotsLeft(1)/2).*stim.dotSize(1),ones(1,stim.nbDotsLeft(2)/2).*stim.dotSize(2)]),[1,2]);
                 stim.dotSizesRight = repmat(Shuffle([ones(1,stim.nbDotsRight(1)/2).*stim.dotSize(1),ones(1,stim.nbDotsRight(2)/2).*stim.dotSize(2)]),[1,2]);
                 
                 %choose a random directions for the not coherent dots
                 stim.directionsLeft = rand(1,stim.totalNbDotsLeft).*2*pi;
                 stim.directionsRight = rand(1,stim.totalNbDotsRight).*2*pi;
                 %and also one for the coherent dot
                 coherent_dir = rand(1).*2*pi;
                 stim.directionsLeft(randsample(stim.totalNbDotsLeft,round(stim.totalNbDotsLeft.*stim.coherence),0)) = coherent_dir;
                 stim.directionsRight(randsample(stim.totalNbDotsRight,round(stim.totalNbDotsRight.*stim.coherence),0)) = coherent_dir;             
             else
                 %choose a size for each dot - we work with half of the dots, and duplicate it because later, we generates coords for half of the list and duplicate
                 stim.dotSizesCenter = repmat(Shuffle([ones(1,stim.nbDotsCenter(1)/2).*stim.dotSize(1),ones(1,stim.nbDotsCenter(2)/2).*stim.dotSize(2)]),[1,2]);
                 stim.dotSizesOuter = repmat(Shuffle([ones(1,stim.nbDotsOuter(1)/2).*stim.dotSize(1),ones(1,stim.nbDotsOuter(2)/2).*stim.dotSize(2)]),[1,2]);
                 
                 %choose a random directions for the not coherent dots
                 stim.directionsCenter = rand(1,stim.totalNbDotsCenter).*2*pi;
                 stim.directionsOuter = rand(1,stim.totalNbDotsOuter).*2*pi;
                 %and also one for the coherent dot
                 coherent_dir = rand(1).*2*pi;
                 stim.directionsCenter(randsample(stim.totalNbDotsCenter,round(stim.totalNbDotsCenter.*stim.coherence),0)) = coherent_dir;
                 stim.directionsOuter(randsample(stim.totalNbDotsOuter,round(stim.totalNbDotsOuter.*stim.coherence),0)) = coherent_dir;
             end
             
            if stim.config == 1 % LEFT - RIGHT RDS 
                 % initiate RDS dots coordinates
                 % Note that we reduce the size of each side by the disparity of the other side because disparities create
                 % some out-of-limits dots that are removed (and replaced) which results in a bigger exclusion area for the side
                 % with the larger disparity (of the size difference = to the disparity difference)
                 coordLeftL1 = nan(2,stim.totalNbDotsLeft, expe.nbFrames);
                 coordRightL1 = nan(2,stim.totalNbDotsRight, expe.nbFrames);
                 coordLeftR1 = coordLeftL1; coordRightR1 = coordRightL1;
                 coordLeftL2 = coordLeftL1; coordRightL2 = coordRightL1;
                 coordRightR2 = coordRightL1; coordLeftR2 = coordLeftL1;
                 coordLeftL = []; coordLeftR = []; coordRightL = []; coordRightR = [];
                 
                 % generates all the dots coordinates for each frame
                 for fram=1:expe.nbFrames
                      %left upper panel
                         [coordLeftL(:,:,fram), coordLeftR(:,:,fram)] = generateRDSStereoCoord(coordLeftL(:,:,end),coordLeftR(:,:,end),stim,stim.leftrdsL1(4)-stim.leftrdsL1(2), stim.leftrdsL1(3)-stim.leftrdsL1(1)-abs(L_R_disp_pp(2)), L_R_disp_pp(1),stim.totalNbDotsLeft,stim.dotSizesLeft, stim.directionsLeft);
                      %right upper panel
                         [coordRightL(:,:,fram), coordRightR(:,:,fram)] = generateRDSStereoCoord(coordRightL(:,:,end),coordRightR(:,:,end),stim,stim.rightrdsL1(4)-stim.rightrdsL1(2), stim.rightrdsL1(3)-stim.rightrdsL1(1)-abs(L_R_disp_pp(1)), L_R_disp_pp(2),stim.totalNbDotsRight, stim.dotSizesRight, stim.directionsRight);
                 end

                % recenter coordinates according to the first pixel of the screen (atm, coded in coordinates relative to background rect)
                % Note that we add an horizontal jitter to the zero disparity side to avoid the use of monocular cues
                % the jitter is all or nothing thing, of the size of the disparity on the other side. One side has zero 
                % jitter because of the zero disparity (on the other side)
                 xjitter1 = round(rand(1)).*abs(L_R_disp_pp(1)); 
                 xjitter2 = round(rand(1)).*abs(L_R_disp_pp(2)); 

                %left upper panel, left eye
                 coordLeftL1(1,:,:) = coordLeftL(1,:,:) + stim.leftrdsL1(1) + xjitter2;
                 coordLeftL1(2,:,:) = coordLeftL(2,:,:) + stim.leftrdsL1(2);
                %left upper panel, right eye  
                 coordLeftR1(1,:,:) = coordLeftR(1,:,:) + stim.leftrdsR1(1) + xjitter2;
                 coordLeftR1(2,:,:) = coordLeftR(2,:,:) + stim.leftrdsR1(2);
                %right upper panel, left eye
                 coordRightL1(1,:,:) = coordRightL(1,:,:) + stim.rightrdsL1(1) + xjitter1;
                 coordRightL1(2,:,:) = coordRightL(2,:,:) + stim.rightrdsL1(2);
                %right upper panel, right eye
                 coordRightR1(1,:,:) = coordRightR(1,:,:) + stim.rightrdsR1(1) + xjitter1;
                 coordRightR1(2,:,:) = coordRightR(2,:,:) + stim.rightrdsR1(2);           
                %left lower panel, left eye
                 coordLeftL2(1,:,:) = coordLeftL(1,:,:) + stim.leftrdsL2(1) + xjitter2;
                 coordLeftL2(2,:,:) = coordLeftL(2,:,:) + stim.leftrdsL2(2);
                %left lower panel, right eye
                 coordLeftR2(1,:,:) = coordLeftR(1,:,:) + stim.leftrdsR2(1) + xjitter2;
                 coordLeftR2(2,:,:) = coordLeftR(2,:,:) + stim.leftrdsR2(2);
                %right lower panel, left eye
                 coordRightL2(1,:,:) = coordRightL(1,:,:) + stim.rightrdsL2(1) + xjitter1;
                 coordRightL2(2,:,:) = coordRightL(2,:,:) + stim.rightrdsL2(2);
                %right lower panel, right eye
                 coordRightR2(1,:,:) = coordRightR(1,:,:) + stim.rightrdsR2(1) + xjitter1;
                 coordRightR2(2,:,:) = coordRightR(2,:,:) + stim.rightrdsR2(2);
                 
             elseif stim.config == 2 %CENTER - SURROUND RDS % NOT OPERATIONAL
                 % initiate RDS dots coordinates
                 % Note that we reduce the size of surround by the amount of disparity 
                 coordCenterL1 = nan(2,stim.totalNbDotsCenter, expe.nbFrames); coordCenterR1 = coordCenterL1;
                 coordOuterL1 = nan(2,stim.totalNbDotsOuter, expe.nbFrames);    coordOuterR1 = coordOuterL1;
                 coordCenterL = []; coordCenterR = [];  coordOuterL = []; coordOuterR = [];
                 
                 % generates all the dots coordinates for each frame
                 for fram=1:expe.nbFrames
                         [coordCenterL(:,:,fram), coordCenterR(:,:,fram)] = generateRDSStereoCoord(coordCenterL(:,:,end),coordCenterR(:,:,end),stim,stim.centerrdsL(4)-stim.centerrdsL(2), stim.centerrdsL(3)-stim.centerrdsL(1), L_R_disp_pp(1),stim.totalNbDotsCenter, stim.dotSizesCenter, stim.directionsCenter);
                         [coordOuterL(:,:,fram), coordOuterR(:,:,fram)] = generateRDSStereoCoord(coordOuterL(:,:,end),coordOuterR(:,:,end),stim,stim.outerrdsL(4)-stim.outerrdsL(2), stim.outerrdsL(3)-stim.outerrdsL(1), L_R_disp_pp(2),stim.totalNbDotsOuter, stim.dotSizesOuter, stim.directionsOuter);
                 end
                 
%                 % recenter coordinates according to the first pixel of the screen (atm, coded in coordinates relative to background rect)
%                 % Note that we add an horizontal jitter to the zero disparity side to avoid the use of monocular cues
%                 % the jitter is all or nothing thing, of the size of the disparity on the other side. One side has zero 
%                 % jitter because of the zero disparity (on the other side)
%                  xjitter1 = round(rand(1)).*abs(L_R_disp_pp(1)); 
%                  xjitter2 = round(rand(1)).*abs(L_R_disp_pp(2)); 

                %center panel, left eye
                 coordCenterL1(1,:,:) = coordCenterL(1,:,:) + stim.centerrdsL(1) ;%+ xjitter2;
                 coordCenterL1(2,:,:) = coordCenterL(2,:,:) + stim.centerrdsL(2);
                %center panel, right eye  
                 coordCenterR1(1,:,:) = coordCenterR(1,:,:) + stim.centerrdsR(1) ;%+ xjitter2;
                 coordCenterR1(2,:,:) = coordCenterR(2,:,:) + stim.centerrdsR(2);
                %outer panel, left eye
                 coordOuterL1(1,:,:) = coordOuterL(1,:,:) + stim.outerrdsL(1) ;%+ xjitter1;
                 coordOuterL1(2,:,:) = coordOuterL(2,:,:) + stim.outerrdsL(2);
                %outer panel, right eye
                 coordOuterR1(1,:,:) = coordOuterR(1,:,:) + stim.outerrdsR(1) ;%+ xjitter1;
                 coordOuterR1(2,:,:) = coordOuterR(2,:,:) + stim.outerrdsR(2);           
            elseif stim.config == 3 % CENTRAL STRIP - OUTER STRIPS
                 % initiate RDS dots coordinates          
                 coordCenterL = []; coordCenterR = [];  coordOuterL = []; coordOuterR = [];
                 
                 % generates all the dots coordinates for each frame
                 % Note that we reduce the size of surround by the amount of disparity 
                 for fram=1:expe.nbFrames
                         [coordCenterL(:,:,fram), coordCenterR(:,:,fram)] = generateRDSStereoCoord(coordCenterL(:,:,end),coordCenterR(:,:,end),stim,stim.centerrdsL(4)-stim.centerrdsL(2), stim.centerrdsL(3)-stim.centerrdsL(1)-abs(L_R_disp_pp(2)), L_R_disp_pp(1),stim.totalNbDotsCenter, stim.dotSizesCenter, stim.directionsCenter);
                         [coordOuterL(:,:,fram), coordOuterR(:,:,fram)] = generateRDSStereoCoord(coordOuterL(:,:,end),coordOuterR(:,:,end),stim,stim.outerrdsL1(4)-stim.outerrdsL1(2), stim.outerrdsL1(3)-stim.outerrdsL1(1)-abs(L_R_disp_pp(1)), L_R_disp_pp(2),stim.totalNbDotsOuter, stim.dotSizesOuter, stim.directionsOuter);
                 end
                 
                % recenter coordinates according to the first pixel of the screen (atm, coded in coordinates relative to background rect)
                % Note that we add an horizontal jitter to the zero disparity side to avoid the use of monocular cues
                % the jitter is all or nothing thing, of the size of the disparity on the other side. One side has zero 
                % jitter because of the zero disparity (on the other side)
                 xjitter1 = round(rand(1)).*abs(L_R_disp_pp(1)); 
                 xjitter2 = round(rand(1)).*abs(L_R_disp_pp(2)); 
                 coordCenterL1 = nan(2,stim.totalNbDotsCenter, expe.nbFrames); coordCenterR1 = coordCenterL1;
                 coordOuterL1 = nan(2,stim.totalNbDotsOuter, expe.nbFrames);    coordOuterR1 = coordOuterL1;
                 coordOuterL2 = coordOuterL1;    coordOuterR2 = coordOuterL1;
                 
                %center strip, left eye
                 coordCenterL1(1,:,:) = coordCenterL(1,:,:) + stim.centerrdsL(1) + xjitter2;
                 coordCenterL1(2,:,:) = coordCenterL(2,:,:) + stim.centerrdsL(2);
                %center strip, right eye  
                 coordCenterR1(1,:,:) = coordCenterR(1,:,:) + stim.centerrdsR(1) + xjitter2;
                 coordCenterR1(2,:,:) = coordCenterR(2,:,:) + stim.centerrdsR(2);
                %outer upper stip, left eye
                 coordOuterL1(1,:,:) = coordOuterL(1,:,:) + stim.outerrdsL1(1) + xjitter1;
                 coordOuterL1(2,:,:) = coordOuterL(2,:,:) + stim.outerrdsL1(2);
                %outer upper stip, right eye
                 coordOuterR1(1,:,:) = coordOuterR(1,:,:) + stim.outerrdsR1(1) + xjitter1;
                 coordOuterR1(2,:,:) = coordOuterR(2,:,:) + stim.outerrdsR1(2);      
                %outer lower stip, left eye
                 coordOuterL2(1,:,:) = coordOuterL(1,:,:) + stim.outerrdsL2(1) + xjitter1;
                 coordOuterL2(2,:,:) = coordOuterL(2,:,:) + stim.outerrdsL2(2);
                %outer lower stip, right eye
                 coordOuterR2(1,:,:) = coordOuterR(1,:,:) + stim.outerrdsR2(1) + xjitter1;
                 coordOuterR2(2,:,:) = coordOuterR(2,:,:) + stim.outerrdsR2(2); 
            end
             
         %--------------------------------------------------------------------------
        %   DISPLAY FRAMES + FIXATION 
        %--------------------------------------------------------------------------

          %--- Background
            Screen('FillRect', scr.w, sc(scr.backgr,scr));
                  
                  
           % ------ Outside frames    
            Screen('FrameRect', scr.w, sc(stim.fixL,scr),stim.frameL, stim.frameLineWidth/2);
            Screen('FrameRect', scr.w, sc(stim.fixR,scr),stim.frameR, stim.frameLineWidth/2);

           %-----fixation
            drawDichFixation(scr,stim,0,1);
                  
            [dummy, onsetFixation]=flip2(expe.inputMode, scr.w,[],1);
            calculationTime = onsetFixation - startTrialTime;
        %--------------------------------------------------------------------------
        %   PRELOADING OF TEXTURES DURING FIXATION 
        %--------------------------------------------------------------------------
  
            feuRouge(expe.beginInterTrial+stim.interTrial/1000,expe.inputMode); 
            waitForKey(scr.keyboardNum,expe.inputMode); 
                   %-------------------- WAIT FOR USER------------------------------------------   
             
%                     if expe.debugMode==1
%                          Screen('DrawDots', scr.w, [scr.LcenterXDot,scr.RcenterXDot;scr.LcenterYDot,scr.LcenterYDot], 1,sc(stim.noniusLum,scr));
% 
%                           displayText(scr,sc(scr.fontColor,scr),[0,0,scr.res(3),200],['b:',num2str(block),'/t:',num2str(t),'/c:',num2str(cond),' /ofst: ', num2str(offset),' /ofp ', num2str(offsetPx), '/upRO:', num2str(upRightOffset),'/jit:',num2str(jitter),'/upF:',num2str(upFactor)]);
%                     end    

        stimulationFlag=1;
        onsetStim=GetSecs;
        fixationDuration = onsetStim - onsetFixation;
        frameOnset=onsetStim;  
             
        % Shuffling white and black dots
        if stim.config == 1 % LEFT - RIGHT RDS
            dots1 = Shuffle(1:stim.totalNbDotsLeft);
            dots2 = Shuffle(1:stim.totalNbDotsRight);
        elseif stim.config == 2 || stim.config == 3 
            dots1 = Shuffle(1:stim.totalNbDotsCenter);
            dots2 = Shuffle(1:stim.totalNbDotsOuter); 
        end
        % ---- TIMING CHECKS ---%
             %Missed = 0;  
             timetable=nan(expe.nbFrames,1);
             frameList = [];
        while stimulationFlag
                %--------------------------------------------------------------------------
                %   STIMULATION LOOP
                %--------------------------------------------------------------------------
                  if stim.flash == 0
                      frame = 1+floor((frameOnset-onsetStim)/(scr.frameTime)); %take the frame nearest to the supposed timing to avoid lags
                  else
                      frame = 1+floor((frameOnset-onsetStim)/(stim.flashDuration/1000)); %take the frame nearest to the supposed timing to avoid lags                     
                  end
                  frameList=[frameList,frame]; %use this to count the nb of different frames shown
                  
               %delete the RDS space         
                    %all of it including center space
                    if stim.config == 1 % LEFT - RIGHT RDS
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsL(1) stim.leftrdsL(2)-1 stim.rightrdsL(3) stim.rightrdsL(4)+1]); 
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsR(1) stim.leftrdsR(2)-1 stim.rightrdsR(3) stim.rightrdsR(4)+1]); 
                    elseif stim.config == 2 % CENTER SURROUND
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsL(1) stim.outerrdsL(2)-1 stim.outerrdsL(3) stim.outerrdsL(4)+1]); 
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsR(1) stim.outerrdsR(2)-1 stim.outerrdsR(3) stim.outerrdsR(4)+1]);
                    else
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.frameL); 
                       Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.frameR);
                    end
                    
                    if expe.debugMode==1
                                       Screen('DrawLines',scr.w, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine-3,scr.LcenterXLine-3,...
                                           scr.LcenterXLine+3,scr.LcenterXLine+3,scr.LcenterXLine+6,scr.LcenterXLine+6;0,scr.res(4),0,scr.res(4),...
                                           0,scr.res(4),0,scr.res(4)],  1, sc(0,scr));
                                       Screen('DrawLines',scr.w, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine-3,scr.RcenterXLine-3,...
                                           scr.RcenterXLine+3,scr.RcenterXLine+3,scr.RcenterXLine+6,scr.RcenterXLine+6;0,scr.res(4),...
                                           0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc(0,scr));
                    end
                       
            if stim.config == 1 % LEFT - RIGHT RDS 
             %UPPER PANEL
             %draw half of the dots with dotColor1
                   Screen('DrawDots', scr.w, coordLeftL1(:,dots1(1:round(stim.totalNbDotsLeft/2)),frame), stim.dotSizesLeft(dots1(1:round(stim.totalNbDotsLeft/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordLeftR1(:,dots1(1:round(stim.totalNbDotsLeft/2)),frame), stim.dotSizesLeft(dots1(1:round(stim.totalNbDotsLeft/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightL1(:,dots2(1:round(stim.totalNbDotsRight/2)),frame), stim.dotSizesRight(dots2(1:round(stim.totalNbDotsRight/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightR1(:,dots2(1:round(stim.totalNbDotsRight/2)),frame), stim.dotSizesRight(dots2(1:round(stim.totalNbDotsRight/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
 
              %draw the other half of the dots with dotColor2 (left side) and dotColor3 (right side)
                   Screen('DrawDots', scr.w, coordLeftL1(:,dots1((round(stim.totalNbDotsLeft/2)+1):end),frame), stim.dotSizesLeft(dots1((round(stim.totalNbDotsLeft/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordLeftR1(:,dots1((round(stim.totalNbDotsLeft/2)+1):end),frame), stim.dotSizesLeft(dots1((round(stim.totalNbDotsLeft/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightL1(:,dots2((round(stim.totalNbDotsRight/2)+1):end),frame), stim.dotSizesRight(dots2((round(stim.totalNbDotsRight/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightR1(:,dots2((round(stim.totalNbDotsRight/2)+1):end),frame), stim.dotSizesRight(dots2((round(stim.totalNbDotsRight/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
             
             %LOWER PANEL
             %draw half of the dots with dotColor1
                   Screen('DrawDots', scr.w, coordLeftL2(:,dots1(1:round(stim.totalNbDotsLeft/2)),frame), stim.dotSizesLeft(dots1(1:round(stim.totalNbDotsLeft/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordLeftR2(:,dots1(1:round(stim.totalNbDotsLeft/2)),frame), stim.dotSizesLeft(dots1(1:round(stim.totalNbDotsLeft/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightL2(:,dots2(1:round(stim.totalNbDotsRight/2)),frame), stim.dotSizesRight(dots2(1:round(stim.totalNbDotsRight/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightR2(:,dots2(1:round(stim.totalNbDotsRight/2)),frame), stim.dotSizesRight(dots2(1:round(stim.totalNbDotsRight/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
 
              %draw the other half of the dots with dotColor2 (left side) and dotColor3 (right side)
                   Screen('DrawDots', scr.w, coordLeftL2(:,dots1((round(stim.totalNbDotsLeft/2)+1):end),frame), stim.dotSizesLeft(dots1((round(stim.totalNbDotsLeft/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordLeftR2(:,dots1((round(stim.totalNbDotsLeft/2)+1):end),frame), stim.dotSizesLeft(dots1((round(stim.totalNbDotsLeft/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightL2(:,dots2((round(stim.totalNbDotsRight/2)+1):end),frame), stim.dotSizesRight(dots2((round(stim.totalNbDotsRight/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordRightR2(:,dots2((round(stim.totalNbDotsRight/2)+1):end),frame), stim.dotSizesRight(dots2((round(stim.totalNbDotsRight/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
            
            elseif stim.config == 2 %CENTER - SURROUND RDS
              %draw half of the dots with dotColor1 (outer)
                   Screen('DrawDots', scr.w, coordOuterL1(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR1(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterL1(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR1(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);

              %draw the other half of the dots with dotColor2 (left side) and dotColor3 (center)
                   Screen('DrawDots', scr.w, coordCenterL1(:,dots1(1:round(stim.totalNbDotsCenter/2)),frame), stim.dotSizesCenter(dots1(1:round(stim.totalNbDotsCenter/2))), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterR1(:,dots1(1:round(stim.totalNbDotsCenter/2)),frame), stim.dotSizesCenter(dots1(1:round(stim.totalNbDotsCenter/2))), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterL1(:,dots1((round(stim.totalNbDotsCenter/2)+1):end),frame), stim.dotSizesCenter(dots1((round(stim.totalNbDotsCenter/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterR1(:,dots1((round(stim.totalNbDotsCenter/2)+1):end),frame), stim.dotSizesCenter(dots1((round(stim.totalNbDotsCenter/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
             
            elseif stim.config == 3  % CENTRAL STRIP - OUTER STRIPS
              %draw half of the dots with dotColor1 (black), the other with dotColor2 (outer)
                   Screen('DrawDots', scr.w, coordOuterL1(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR1(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterL1(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR1(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterL2(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR2(:,dots2(1:round(stim.totalNbDotsOuter/2)),frame), stim.dotSizesOuter(dots2(1:round(stim.totalNbDotsOuter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterL2(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordOuterR2(:,dots2((round(stim.totalNbDotsOuter/2)+1):end),frame), stim.dotSizesOuter(dots2((round(stim.totalNbDotsOuter/2)+1):end)), sc(stim.dotColor2,scr),[],scr.antialliasingMode,scr.lenient);

              %draw the other half of the dots with dotColor1 (black), the other with dotColor3 (center)
                   Screen('DrawDots', scr.w, coordCenterL1(:,dots1(1:round(stim.totalNbDotsCenter/2)),frame), stim.dotSizesCenter(dots1(1:round(stim.totalNbDotsCenter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterR1(:,dots1(1:round(stim.totalNbDotsCenter/2)),frame), stim.dotSizesCenter(dots1(1:round(stim.totalNbDotsCenter/2))), sc(stim.dotColor1,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterL1(:,dots1((round(stim.totalNbDotsCenter/2)+1):end),frame), stim.dotSizesCenter(dots1((round(stim.totalNbDotsCenter/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
                   Screen('DrawDots', scr.w, coordCenterR1(:,dots1((round(stim.totalNbDotsCenter/2)+1):end),frame), stim.dotSizesCenter(dots1((round(stim.totalNbDotsCenter/2)+1):end)), sc(stim.dotColor3,scr),[],scr.antialliasingMode,scr.lenient);
        
            end
                          
                   % feuRouge(frameOnset+stim.frameTime-max(0,Missed),expe.inputMode); 
                   frameOff =frameOnset;
                 [dummy, frameOnset]=flip2(expe.inputMode, scr.w,frameOff+scr.frameTime,1); %-max(0,Missed)
                 timetable(frame)=frameOnset-frameOff;

                 
                 % ---- TIMING CHECKS ---%
%                  frameOnset = GetSecs;
%                 % [dummy frameOnset flip2Timestamp]=flip2(expe.inputMode, scr.w,[],1);
%                  Missed=frameOnset-(frameOff+stim.frameTime);
                            
%         %--------------------------------------------------------------------------
%         %   SCREEN CAPTURE
%         %--------------------------------------------------------------------------

%         %for subpixel test purpose (uncomment all subpixel comments)
          % ---- subpixel
%             theFrame=[coordLeftL(1,1,frame)-stim.dotSize/2-2;coordLeftL(2,1,frame)-stim.dotSize/2-2;coordLeftL(1,1,frame)+stim.dotSize/2+2;coordLeftL(2,1,frame)+stim.dotSize/2+2];
%             WaitSecs(1)
%             im=Screen('GetImage', scr.w, theFrame);
%             im2(:,:,:,jjj)=im;
%             save('im2.mat','im2')
%           --------------------------

%             plot(1:size(im,2),im(25,:,1), 'Color', [jjj/12, 1-jjj/12, 0])
%             hold on
%             zz=22:28;
%            x=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz),[numel(zz),1])))/sum(sum(im(zz,zz,1)))
%            y=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz)',[1,numel(zz)])))/sum(sum(im(zz,zz,1)))
%            
%             zz=24:26;
%            x=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz),[numel(zz),1])))/sum(sum(im(zz,zz,1)))
%            y=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz)',[1,numel(zz)])))/sum(sum(im(zz,zz,1)))
%             stimulationFlag = 0;
%              WaitSecs(1)

            
           %--------------------------------------------------------------------------
           %   DISPLAY MODE STUFF
           %--------------------------------------------------------------------------
           if expe.debugMode==1
            texts2Disp=sprintf('%+5.3f %+5.3f %+5.3f %+5.0f %+5.1f %+5.2f %+5.1f %+5.2f %+5.3f', [dispCenter, dispBg, targCloser, disparitySec]);

               Screen('DrawDots', scr.w, [scr.LcenterXLine;scr.LcenterYLine], 1, 100,[],2); 
            
%                for iii=-200:10:200
%                     Screen('DrawLine', scr.w, sc(stim.LminL,scr), scr.LcenterXLine+iii, scr.LcenterYLine+1000 ,  scr.LcenterXLine+iii, scr.LcenterYLine-1000 , 1);   %Left eye up line
%                     Screen('DrawLine', scr.w, sc(stim.LminL,scr), scr.RcenterXLine+iii, scr.RcenterYLine+1000 ,  scr.RcenterXLine+iii, scr.RcenterYLine-1000 , 1);   %Left eye up line
%                end
               displayText(scr,sc(stim.LminL,scr),[scr.LcenterXLine-75,scr.LcenterYLine+100-2.*scr.fontSize,scr.res(3),200],texts2Disp);
               displayText(scr,sc(stim.LminR,scr),[scr.RcenterXLine-75,scr.RcenterYLine+100-2.*scr.fontSize,scr.res(3),200],texts2Disp);
               flip2(expe.inputMode, scr.w, [], 1);
               waitForKey(scr.keyboardNum,expe.inputMode);
               
           end
             
            if (GetSecs-onsetStim)>= stim.itemDuration/1000 
                stimulationFlag = 0;
            end
%             %--------------------------------------------------------------------------
%             %   IMPLEMENT DELAYED EXIT IF STIM DURATION < MINIMAL
%             %--------------------------------------------------------------------------
%                 if stimulationFlag == 0 && (GetSecs-onsetStim) <  stim.minimalDuration /1000 
%                      delayedExit = 1;
%                      stimulationFlag = 1;
%                 end
%                 if delayedExit == 1 && (GetSecs-onsetStim) >=  stim.minimalDuration 
%                     stimulationFlag = 0;
%                 end
        end
        
%         % ---- TIMING CHECKS ---%
%                 nanmean(timetable)
%                     nanstd(timetable)
%                     sca
%                     xx
        
          % clear stimulus space   
        %--- Background
            Screen('FillRect', scr.w, sc(scr.backgr,scr));
%         %all of it including center space
%         if stim.config == 1 % LEFT - RIGHT RDS
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsL(1) stim.leftrdsL(2)-1 stim.rightrdsL(3) stim.rightrdsL(4)+1]);
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsR(1) stim.leftrdsR(2)-1 stim.rightrdsR(3) stim.rightrdsR(4)+1]);
%         elseif stim.config == 2 % CENTER SURROUND
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsL(1) stim.outerrdsL(2)-1 stim.outerrdsL(3) stim.outerrdsL(4)+1]);
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsR(1) stim.outerrdsR(2)-1 stim.outerrdsR(3) stim.outerrdsR(4)+1]);
%         else
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsL1(1) stim.outerrdsL1(2)-1 stim.outerrdsL2(3) stim.outerrdsL2(4)+1]);
%             Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.outerrdsR1(1) stim.outerrdsR1(2)-1 stim.outerrdsR2(3) stim.outerrdsR2(4)+1]);
%         end

        % ------ Outside frames    
            Screen('FrameRect', scr.w, sc(stim.fixL,scr),stim.frameL, stim.frameLineWidth/2);
            Screen('FrameRect', scr.w, sc(stim.fixR,scr),stim.frameR, stim.frameLineWidth/2);
            
             
        %----- fixation
           drawDichFixation(scr,stim);
           
        [dummy, offsetStim]=flip2(expe.inputMode, scr.w,[],1);
        
         % ---------------------  RESPONSE --------------------------    
        expe.stimTime= offsetStim-onsetStim;
          if responseKey == 0 
            %--------------------------------------------------------------------------
            %   GET RESPONSE if no response at that stage
            %--------------------------------------------------------------------------
               % NOTE THAT ROBOTMODEERDS IS USELESS GIVEN PSI USES ITS OWN SIMULATION IMPLEMENTATION (see Psi_marg_erds6.m)    
               [responseKey, RT]=getResponseKb(scr.keyboardNum,0,expe.inputMode,expe.allowed_key,'robotModeERDS',[L_R_disp(1) L_R_disp(2) 100 800],1,0,0,0); %robotmode takes the 2 pedestal+disparity, the simulated threshold and the Panum area limit (all in arcsec)
          end

        % ------------- ALLOWED RESPONSES as a function of TIME (allows escape in the first 10 min)-----%
        %       Possible response Code Table:
        %               0: no keypress before time limit
        %               1: left 
        %               2: right 
        %               3: space
        %               4: escape
        %               5: up
        %               6: down
        %               8: backspace
        %              52: enter (numpad)
        
           % --- ESCAPE PRESS : escape the whole program ----%
           if responseKey==8 
               disp('Voluntary Interruption: exiting program.')
               
               %set a flag to quit program properly
               stopSignal = 1;
           end

           % --- KEYBOARD for debugging
           if responseKey==3
                sca
                ShowHideWinTaskbarMex
                if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
                diary OFF
                if exist('scr','var'); precautions(scr.w, 'off'); end
                keyboard
           end

           
            % --- FEEDBACK  ---%
            if stim.config == 1 % left -right
                % task: which side is closer to you (1: left, 2: right)?
                 expected_key = expected_side + 1; 
            elseif stim.config == 3 % center - outer 
                % task: are the blue dot surface closer to you than the
                % other one or further (5: further, 6: closer)?
                % expected_side = 0 if centre closer, 1 if outer closer
                if blueDots==0 %center is blue
                    expected_key = 6 - expected_side; 
                else            % outer is blue
                    expected_key = 5 + expected_side; 
                end
            end
             if expe.feedback>0
                if expected_key==responseKey %CORRECT
                   PsychPortAudio('Start', sounds.handle1, 1, 0, 1);
                    psi.correct = 1;
                else
                    %INCORRECT
                    psi.correct = 0;
                    %if expe.feedback == 1 || (expe.feedback == 2 && psi.practice_trial==1) %meaningful auditory feedback
                    if expe.feedback == 1 || expe.feedback == 2 %HERE remove that line and take line above
                        PsychPortAudio('Start', sounds.handle2, 1, 0, 1);
                    else    %keypress auditory feedback
                        PsychPortAudio('Start', sounds.handle1, 1, 0, 1);
                    end
                end
             end
            
           if expe.debugMode==1
                Screen('FillRect', scr.w, sc(scr.backgr,scr));
                displayText(scr,sc(scr.fontColor,scr),[0,100,scr.res(3),200],[num2str(responseKey),' - ',num2str(RT)]);
                flip2(expe.inputMode, scr.w,[],1);
                waitForT(1000,expe.inputMode);
                Screen('FillRect', scr.w, sc(scr.backgr,scr));
                flip2(expe.inputMode, scr.w,[],1);
           end

        %--------------------------------------------------------------------------
        %            INTER TRIAL
        %--------------------------------------------------------------------------
           %inter-trial is actually at the beginning of next trial to allow pre-loading of textures in the meantime.
           %to be able to do that, we have to start counting time
           %from now on:
           expe.beginInterTrial=GetSecs;
           
            if expe.debugMode==1
                %Screen('FillRect', scr.w, sc(scr.backgr,scr));
                displayText(scr,sc(scr.fontColor,scr),[0,100,scr.res(3),200],['responseKey:',num2str(responseKey),'/RT:',num2str(RT)]);
                flip2(expe.inputMode, scr.w,[],1);
                waitForKey(scr.keyboardNum,expe.inputMode);
                %Screen('FillRect', scr.w, sc(scr.backgr,scr));
                %flip2(expe.inputMode, scr.w,[],1);
            end

        %------ Progression bar for robotMode ----%
            if expe.inputMode==2
                Screen('FillRect',scr.w, sc([scr.fontColor,0,0],scr),[0 0 scr.res(3)*trial/expe.goalCounter 10]);
                Screen('Flip',scr.w);
            end
     % removed doublon from framelist and count
      frameList = logic('union', frameList,[]);
      nbFrameShown = numel(frameList);
     
     % update and record psi data
      psi = Psi_marg_erds6('record',trial, psi, expe, scr);

        % -----------   SAVING DATA ------------------%
           if stopSignal==1
               trialLine = nan(1,11);
               timings = nan(1,6);
           else
               trialLine = [trial,L_R_disp(1),L_R_disp(2),expected_key,responseKey, fixationDuration, RT, psi.correct, L_R_disp_pp(1), L_R_disp_pp(2),psi.practice_trial];
               timings = [calculationTime, fixationDuration, nanmean(timetable),expe.stimTime/nbFrameShown,expe.stimTime, RT];
           end
                                       
          expe.results(trial,:)= trialLine;
          expe.timings(trial,:)= timings;
                                   
                                   % ----- response TABLE --------------------------------
                                   %    1:  trial # (different from psi.trial)
                                   %    2:  disparity value in arcsec of left/center side
                                   %    3:  disparity value in arcsec of right/outer side
                                   %    4:  which side is closer (expected answer) - 1: left/center - 2:right/outer
                                   %    5:  responseKey - left/center side is closer(1) or right/outer (2)
                                   %    6:  stimulus duration
                                   %    7:  RT = response duration after stimulus     
                                   %    8:  Correct answer or not
                                   %    9:  disparity value in pp of left/center side
                                   %   10:  disparity value in pp of right/outer side
                                   %   11:  practice trial (1) or not (0)
                                   %   12:  blue dots: 0 centre, 1: outer strips, 2: always right
                                   
    
%end %subpixel
% for j=1:11; plot(mean(im2(25,14:20,:,j),3)); hold on; end %subpixel

catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    disp(err)
    keyboard
    save(fullfile(expe.pathExp,'log',[expe.file,'_menu',num2str(expe.menu),'_crashlog']))
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    PsychPortAudio('Close', sounds.handle1);
    PsychPortAudio('Close', sounds.handle2);
    rethrow(err);
end

end


