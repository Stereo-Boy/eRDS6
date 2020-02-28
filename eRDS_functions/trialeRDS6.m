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
    
    % find out what is the next disparity
    psi = Psi_marg_erds6('value',trial, psi, expe, scr);
    
                                   % ----- response TABLE --------------------------------
                                   %    1:  trial # (different from psi.trial)
                                   %    2:  disparity value in arcsec of left side
                                   %    3:  disparity value in arcsec of right side
                                   %    4:  which side is closer (expected answer) - 1: left - 2: right
                                   %    5:  responseKey - left side is closer(1) or right (2)
                                   %    6:  stimulus duration
                                   %    7:  RT = response duration after stimulus     
                                   %    8:  Correct answer or not
                                   %    9:  disparity value in pp of left side
                                   %   10:  disparity value in pp of left side
                                   %   11:  practice trial (1) or not (0)
                                   
%im2=nan(50,50,3,11); %subpixel
%for jjj=1:10 %subpixel
   expected_side = round(rand(1)); % 0: left side closer - 1: right side closer
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
   L_R_disp_pp = L_R_disp./scr.dispByPx;

       % dispCenter=(jjj-1)/5; %subpixel
      %dispBg=(jjj-1)/10; %subpixel
      %--------------------------------------------------------------------------
      %=====  Check BREAK TIME  ====================
      %--------------------------------------------------------------------------
       if (GetSecs-expe.lastBreakTime)/60>=expe.breakTime
           Screen('FillRect',scr.w, sc(scr.backgr,scr));
           beginbreak=GetSecs;
           countdown(30,scr,expe)
           %stereo: 
           displaystereotext3(scr,sc(scr.fontColor,scr),expe.instrPosition,expe.breakInstructions.(expe.language),1);
           %or normal:
           %displayText(scr,sc(scr.fontColor,scr),[scr.res(3)/2-250,100,500,900],instructions.(expe.))
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
             if stim.flash == 0
                expe.nbFrames =  round(stim.itemDuration / (1000*scr.frameTime));  % +20?
             else
                expe.nbFrames =  round(stim.itemDuration / stim.flashDuration);   % +20?
             end
            if stim.flash == 0 % NOT IMPLEMENTED YET
            % [coordbgL, coordbgR, stim.nbDotsBg ]=generateRDSStereoCoord(expe.nbFrames, stim.bgRectL(4)-stim.bgRectL(2)+1, stim.bgRectL(3)-stim.bgRectL(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, dispBg);
            else                
                %first obtain the number of dots to generate for that area
                %size, dot density, and possible dot sizes (assuming equal
                %number of each possible size
                %stim.areaSizeVA2 = ((stim.leftrdsL(4)-stim.leftrdsL(2))./scr.VA2pxConstant).*((stim.leftrdsL(3)-stim.leftrdsL(1))./scr.VA2pxConstant); % in squared VA 
                stim.areaSizepp = (stim.leftrdsL(4)-stim.leftrdsL(2)).*(stim.leftrdsL(3)-stim.leftrdsL(1)); % in squared pp
                stim.nbDots = round(stim.dotDensity.*stim.areaSizepp./(pi.*mean(stim.dotSize./2).^2));
                if numel(stim.nbDots,2)>1 && mod(stim.nbDots,1)==1; stim.nbDots = stim.nbDots+1; end
                
                %choose a size for each dot
                if numel(stim.nbDots,2)>1
                    stim.dotsizes = Shuffle([ones(1,stim.nbDots/2).*stim.dotSize(1),ones(1,stim.nbDots/2).*stim.dotSize(2)]);
                else
                    stim.dotsizes = ones(1,stim.nbDots).*stim.dotSize;
                end
                
                %choose a random directions for the not coherent dots
                stim.directions = rand(1,stim.nbDots).*2*pi;
                stim.nbCoherentDots = round(stim.nbDots.*stim.coherence./100);
                
                %and also one for the coherent dot
                stim.directions(randsample(stim.nbDots,stim.nbCoherentDots,0))=rand(1).*2*pi;

              % initiate left RDS dots coordinates
                % Note that we reduce the size of each side by the disparity of the other side because disparities create
                % some out-of-limits dots that are removed (and replaced) which results in a bigger exclusion area for the side
                % with the larger disparity (of the size difference = to the disparity difference)
                [coordLeftL, coordLeftR] = generateRDSStereoCoord([],[],stim,stim.leftrdsL(4)-stim.leftrdsL(2), stim.leftrdsL(3)-stim.leftrdsL(1)-abs(L_R_disp_pp(2)), L_R_disp_pp(1));                   
                %now generates all the dots coordinates for each frame
                for fram=2:expe.nbFrames
                    [coordLeftL(:,:,fram), coordLeftR(:,:,fram)] = generateRDSStereoCoord(coordLeftL(:,:,fram-1),coordLeftR(:,:,fram-1),stim,stim.leftrdsL(4)-stim.leftrdsL(2), stim.leftrdsL(3)-stim.leftrdsL(1)-abs(L_R_disp_pp(2)), L_R_disp_pp(1));                   
                end
              % initiate right RDS dots coordinates
                [coordRightL, coordRightR] = generateRDSStereoCoord([],[],stim,stim.rightrdsL(4)-stim.rightrdsL(2), stim.rightrdsL(3)-stim.rightrdsL(1)-abs(L_R_disp_pp(1)), L_R_disp_pp(2));                   
                %now generates all the dots coordinates for each frame
                for fram=2:expe.nbFrames
                    [coordRightL(:,:,fram), coordRightR(:,:,fram)] = generateRDSStereoCoord(coordRightL(:,:,fram-1),coordRightR(:,:,fram-1),stim,stim.rightrdsL(4)-stim.rightrdsL(2), stim.rightrdsL(3)-stim.rightrdsL(1)-abs(L_R_disp_pp(1)), L_R_disp_pp(2));                   
                end
            end
            
            % recenter coordinates according to the first pixel of the
            % screen (atm, in coordinates relative to background rect)
             % Note that we add an horizontal jitter to the zero disparity side to avoid the use of monocular cues
             % the jitter is all or nothing thing, of the size of the disparity on the other side. One side has zero 
             % jitter because of the zero disparity (on the other side)
             xjitter1 = round(rand(1)).*abs(L_R_disp_pp(1)); 
             xjitter2 = round(rand(1)).*abs(L_R_disp_pp(2)); 
             coordLeftL(1,:,:) = coordLeftL(1,:,:) + stim.leftrdsL(1) + xjitter2;
             coordLeftL(2,:,:) = coordLeftL(2,:,:) + stim.leftrdsL(2);
             coordLeftR(1,:,:) = coordLeftR(1,:,:) + stim.leftrdsR(1) + xjitter2;
             coordLeftR(2,:,:) = coordLeftR(2,:,:) + stim.leftrdsR(2);
             coordRightL(1,:,:) = coordRightL(1,:,:) + stim.rightrdsL(1) + xjitter1;
             coordRightL(2,:,:) = coordRightL(2,:,:) + stim.rightrdsL(2);
             coordRightR(1,:,:) = coordRightR(1,:,:) + stim.rightrdsR(1) + xjitter1;
             coordRightR(2,:,:) = coordRightR(2,:,:) + stim.rightrdsR(2);
           
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
                    %left one
                    %Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.leftrdsL);   
                    %Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.leftrdsR);

                    %right one
                    %Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.rightrdsL);   
                    %Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.rightrdsR);
                    
                    %all of it including center space
                 %      Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsL(1) stim.leftrdsL(2) stim.rightrdsL(3) stim.rightrdsL(4)]); 
                 %      Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsR(1) stim.leftrdsR(2) stim.rightrdsR(3) stim.rightrdsR(4)]); 
                    
                    if expe.debugMode==1
                                       Screen('DrawLines',scr.w, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine-3,scr.LcenterXLine-3,...
                                           scr.LcenterXLine+3,scr.LcenterXLine+3,scr.LcenterXLine+6,scr.LcenterXLine+6;0,scr.res(4),0,scr.res(4),...
                                           0,scr.res(4),0,scr.res(4)],  1, sc(0,scr));
                                       Screen('DrawLines',scr.w, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine-3,scr.RcenterXLine-3,...
                                           scr.RcenterXLine+3,scr.RcenterXLine+3,scr.RcenterXLine+6,scr.RcenterXLine+6;0,scr.res(4),...
                                           0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc(0,scr));
                    end
                 
              %draw half of the dots with dotColor1
                   Screen('DrawDots', scr.w, coordLeftL(:,1:round(stim.nbDots/2),frame), stim.dotsizes(1:round(stim.nbDots/2)), sc(stim.dotColor1,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordLeftR(:,1:round(stim.nbDots/2),frame), stim.dotsizes(1:round(stim.nbDots/2)), sc(stim.dotColor1,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordRightL(:,1:round(stim.nbDots/2),frame), stim.dotsizes(1:round(stim.nbDots/2)), sc(stim.dotColor1,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordRightR(:,1:round(stim.nbDots/2),frame), stim.dotsizes(1:round(stim.nbDots/2)), sc(stim.dotColor1,scr),[],3,0);
% 
%             %draw half of the dots with dotColor2
                   Screen('DrawDots', scr.w, coordLeftL(:,(round(stim.nbDots/2)+1):end,frame), stim.dotsizes(round(stim.nbDots/2)+1), sc(stim.dotColor2,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordLeftR(:,(round(stim.nbDots/2)+1):end,frame), stim.dotsizes(round(stim.nbDots/2)+1), sc(stim.dotColor2,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordRightL(:,(round(stim.nbDots/2)+1):end,frame), stim.dotsizes(round(stim.nbDots/2)+1), sc(stim.dotColor2,scr),[],3,0);
                   Screen('DrawDots', scr.w, coordRightR(:,(round(stim.nbDots/2)+1):end,frame), stim.dotsizes(round(stim.nbDots/2)+1), sc(stim.dotColor2,scr),[],3,0);
       
                %-----fixation
                %  drawDichFixation(scr,stim);
                  
                 
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

%                Screen('DrawLines',scr.w, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine+1,scr.LcenterXLine+1,scr.LcenterXLine+2,scr.LcenterXLine+2,...
%                    scr.LcenterXLine+6,scr.LcenterXLine+6,scr.LcenterXLine+12,scr.LcenterXLine+12;0,scr.res(4),0,scr.res(4),...
%                    0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr));
%                Screen('DrawLines',scr.w, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine+1,scr.RcenterXLine+1,scr.RcenterXLine+2,scr.RcenterXLine+2,...
%                    scr.RcenterXLine+6,scr.RcenterXLine+6,scr.RcenterXLine+12,scr.RcenterXLine+12;0,scr.res(4),0,scr.res(4),...
%                    0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr));


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
        
        % ---------------------  RESPONSE --------------------------%

       %delete the RDS space
        %left one
        %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.leftrdsL);
        %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.leftrdsR);
        %right one
        %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.rightrdsL);
        %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , stim.rightrdsR);
            
        %all of it including center space
       %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsL(1) stim.leftrdsL(2) stim.rightrdsL(3) stim.rightrdsL(4)]); 
       %    Screen('FillRect', scr.w ,sc(scr.backgr,scr) , [stim.leftrdsR(1) stim.leftrdsR(2) stim.rightrdsR(3) stim.rightrdsR(4)]);
                    
        %----- fixation
           drawDichFixation(scr,stim);
           
        %----- big frames around
            Screen('FrameRect', scr.w, sc(stim.fixL,scr), stim.frameL, stim.frameLineWidth/2);
            Screen('FrameRect', scr.w, sc(stim.fixR,scr), stim.frameR, stim.frameLineWidth/2);

        [dummy, offsetStim]=flip2(expe.inputMode, scr.w,[],1);
        expe.stimTime= offsetStim-onsetStim;
          if responseKey == 0 
            %--------------------------------------------------------------------------
            %   GET RESPONSE if no response at that stage
            %--------------------------------------------------------------------------
              % [dummy offsetMask2]=flip2(expe.inputMode, scr.w,offsetStim+stim.mask2Duration/1000);
               %[responseKey, RT]=getResponseKb(scr.keyboardNum,0,expe.inputMode,allowR]); (keyboardNum,timeLimit,expe.inputMode,allowedResponses,robotFn,robotprofil,speed,skipCheck,skipWaitForKeyRelease,oneTime)
               % NOTE THAT ROBOTMODEERDS IS USELESS HERE GIVEN PSI USES ITS OWN SIMULATION IMPLEMENTATION (see Psi_marg_erds6.m)    
               [responseKey, RT]=getResponseKb(scr.keyboardNum,0,expe.inputMode,expe.allowed_key,'robotModeERDS',[L_R_disp(1) L_R_disp(2) 100 800],1,0,0,0); %robotmode takes the 2 pedestal+disparity, the simulated threshold and the Panum area limit (all in arcsec)
                  %  [responseKey, RT]=getResponseKb(scr.keyboardNum,0,expe.inputMode,allowR,'robotModeSOMEv2',[abs(3600*dispCenter/scr.VA2pxConstant) abs(3600*dispBg/scr.VA2pxConstant) stim.robotThr 900],1,0,0,0); %robotmode takes the 2 pedestal+disparity, the simulated threshold and the Panum area limit (all in arcsec)
          end

        % ------------- ALLOWED RESPONSES as a function of TIME (allows escape in the first 10 min)-----%
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
            expected_key = expected_side + 1; 
             if expe.inputMode==1 
                if (expected_key-responseKey)==0 %CORRECT
                    play(sounds.success.obj);
                    psi.correct = 1;
                else
                    %UNCORRECT
                    psi.correct = 0;
                    if expe.feedback == 1 %meaningful auditory feedback
                        play(sounds.fail.obj);
                    else    %keypress auditory feedback
                        play(sounds.success.obj);
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
                                   %    2:  disparity value in arcsec of left side
                                   %    3:  disparity value in arcsec of right side
                                   %    4:  which side is closer (expected answer) - 1: left - 2: right
                                   %    5:  responseKey - left side is closer(1) or right (2)
                                   %    6:  stimulus duration
                                   %    7:  RT = response duration after stimulus     
                                   %    8:  Correct answer or not
                                   %    9:  disparity value in pp of left side
                                   %   10:  disparity value in pp of left side
                                   %   11:  practice trial (1) or not (0)
                                   
    
%end %subpixel
% for j=1:11; plot(mean(im2(25,14:20,:,j),3)); hold on; end %subpixel

catch err   %===== DEBUGING =====%
    sca
    ShowHideWinTaskbarMex
    disp(err)
    %save(fullfile(pathExp,'log',[expe.file,'-crashlog']))
    %saveAll(fullfile(pathExp,'log',[expe.file,'-crashlog.mat']),fullfile(pathExp,'log',[expe.file,'-crashlog.txt']))
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    keyboard
    rethrow(err);
end

end


