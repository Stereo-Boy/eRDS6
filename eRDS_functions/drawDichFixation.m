function drawDichFixation(scr,stim,eye,fixationColor,missingDot)

if ~exist('eye','var') || isempty(eye); eye=0;end % eye = 0 is binocular, eye = 1 is LE, eye = 2 is RE
if ~exist('fixationColor','var') || isempty(fixationColor); fixationColor=0;end % fixationColor = 0 is black dot, fixationColor = 1 is white dot
if ~exist('missingDot','var') || isempty(missingDot); missingDot=0;end % missingDot = 0 -draws central dot, 1 dont
if ~isfield(stim,'fixL') ; stim.fixL= stim.LminL;end 
if ~isfield(stim,'fixR') ; stim.fixR= stim.LminR;end 

        maxi=round(stim.fixationLength+2*stim.fixationOffset+stim.fixationLineWidth/2);
        
if eye==0 || eye==1 %LEFT EYE
    %vertical lines (binocular)
        rectVL1 = [scr.LcenterXLine-stim.fixationLineWidth/2, scr.LcenterYLine-stim.fixationLength-stim.fixationOffset,  scr.LcenterXLine+stim.fixationLineWidth/2,...
            scr.LcenterYLine-stim.fixationOffset];
        rectVL2 = [scr.LcenterXLine-stim.fixationLineWidth/2, scr.LcenterYLine+stim.fixationOffset ,  scr.LcenterXLine+stim.fixationLineWidth/2,...
            scr.LcenterYLine+stim.fixationLength+stim.fixationOffset];
        
       Screen('FillRect', scr.w, sc(stim.fixL,scr), rectVL1); 
        Screen('FillRect', scr.w, sc(stim.fixL,scr), rectVL2); 
        
        %horizontal triangles (binocular)
        polyCoord1L = [scr.LcenterXLine-stim.fixationOffset, scr.LcenterYLine; ...
            scr.LcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.LcenterYLine+stim.fixationLineWidth;...
            scr.LcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.LcenterYLine-stim.fixationLineWidth];
        
        polyCoord2L = [scr.LcenterXLine+stim.fixationOffset, scr.LcenterYLine; ...
            scr.LcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.LcenterYLine+stim.fixationLineWidth;...
            scr.LcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.LcenterYLine-stim.fixationLineWidth];
         Screen('FillPoly', scr.w ,sc(stim.fixL,scr), polyCoord1L, 1);
        Screen('FillPoly', scr.w ,sc(stim.fixL,scr), polyCoord2L, 1);
        
        %centre fixation zone (binocular circle)
         Screen('FrameOval', scr.w ,sc(stim.fixL,scr) ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi] ,stim.fixationLineWidth) ;

        %Middle fixation dot (binocular)
        if missingDot == 0
            if fixationColor == 0 %black 
                Screen('DrawDots', scr.w, [scr.LcenterXDot;scr.LcenterYDot], stim.fixationDotSize,sc(stim.fixL,scr));
            else %white
                Screen('DrawDots', scr.w, [scr.LcenterXDot;scr.LcenterYDot], stim.fixationDotSize,sc(stim.LmaxL,scr));
            end
        end
end

if eye==0 || eye==2 %RIGHT EYE
        rectVR1 = [scr.RcenterXLine-stim.fixationLineWidth/2, scr.RcenterYLine+stim.fixationOffset,...
            scr.RcenterXLine+stim.fixationLineWidth/2, scr.RcenterYLine+stim.fixationOffset+stim.fixationLength];
        rectVR2 = [scr.RcenterXLine-stim.fixationLineWidth/2, scr.RcenterYLine-stim.fixationOffset-stim.fixationLength ,...
            scr.RcenterXLine+stim.fixationLineWidth/2, scr.RcenterYLine-stim.fixationOffset];
  
         Screen('FillRect', scr.w, sc(stim.fixR,scr), rectVR1);
        Screen('FillRect', scr.w, sc(stim.fixR,scr), rectVR2); 
        
        %horizontal triangles (binocular)
        polyCoord1R = [scr.RcenterXLine-stim.fixationOffset, scr.RcenterYLine; ...
            scr.RcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.RcenterYLine+stim.fixationLineWidth;...
            scr.RcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.RcenterYLine-stim.fixationLineWidth];
    
        polyCoord2R = [scr.RcenterXLine+stim.fixationOffset, scr.RcenterYLine; ...
            scr.RcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.RcenterYLine+stim.fixationLineWidth;...
            scr.RcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.RcenterYLine-stim.fixationLineWidth];
        
        Screen('FillPoly', scr.w ,sc(stim.fixR,scr), polyCoord1R, 1);
        Screen('FillPoly', scr.w ,sc(stim.fixR,scr), polyCoord2R, 1);
        
        %centre fixation zone (binocular circle)
            Screen('FrameOval', scr.w ,sc(stim.fixR,scr) ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi] ,stim.fixationLineWidth);

        %Middle fixation dot (binocular)
        if missingDot == 0
            if fixationColor == 0 %black 
                Screen('DrawDots', scr.w, [scr.RcenterXDot;scr.RcenterYDot], stim.fixationDotSize,sc(stim.fixR,scr));
            else %white
                Screen('DrawDots', scr.w, [scr.RcenterXDot;scr.RcenterYDot], stim.fixationDotSize,sc(stim.LmaxR,scr));
            end
        end
end
%     %horizontal lines (binocular)
%         rectH1L = [scr.LcenterXLine-round(stim.fixationLength)-stim.fixationOffset, scr.LcenterYLine-stim.fixationLineWidth/2, ...
%         scr.LcenterXLine-stim.fixationOffset, scr.LcenterYLine+stim.fixationLineWidth/2];
%         rectH2L = [scr.LcenterXLine+stim.fixationOffset, scr.LcenterYLine-stim.fixationLineWidth/2, ...
%         scr.LcenterXLine+round(stim.fixationLength)+stim.fixationOffset, scr.LcenterYLine+stim.fixationLineWidth/2];
%         rectH1R = [ scr.RcenterXLine+round(stim.fixationLength)+stim.fixationOffset, scr.RcenterYLine - stim.fixationLineWidth/2, ...
%         scr.RcenterXLine+stim.fixationOffset, scr.RcenterYLine+stim.fixationLineWidth/2];
%         rectH2R = [scr.RcenterXLine-stim.fixationOffset, scr.RcenterYLine-stim.fixationLineWidth/2, ...
%         scr.RcenterXLine-round(stim.fixationLength)-stim.fixationOffset, scr.RcenterYLine+stim.fixationLineWidth/2];
% 
%        rectsL = [rectVL',rectH1L',rectH2L'];
%        rectsR = [rectVR',rectH1R',rectH2R'];

        
        
       
        
    
    
        
    
       
       
        
    
        
            

