function [coordL, coordR] = generateRDSStereoCoord(coordL, coordR, stim, heightpp, widthpp, disparity)
%------------------------------------------------------------------------
% Goal : generate coordinates for dynamic random dot stereograms
% - generates a set of coords for each eye coordL and coordR
% -sequence:
% -generate random dots
% -insert disparity
% -remove MONOCULARLY the dots in the exclusion area and outside of the area
% -> the process let no monocular cues, but non-corresponding dots on all edges
%   (the outside edge and the inner edge with the exclusion area) 
%------------------------------------------------------------------------
%
%   nbFrames specifies the nb of frames for which coordinates will be generated
%   heightpp and widthpp defines a rect window whose left up corner pixel is 0,0
%   dotDensity in % defines the nb of dots drawed according to their stim.dotSize and the rect area
%   stim.ppByFlash is in pp by frame (1 frame = 1 flash)
%   disparity is in pp (positive disparity is uncrossed) - it will be
%   split between left and right eye
%   stim.directions is a list of directions for each dot - it defines both the coherence and the direction of motion then 
%   coordL and coordR dimensions are:
%       1:  x, y
%       2:  dot
%       3:  frame
try
    
max_hdot_size = max(round(stim.dotsizes/2));

% We generate a grid of possible coordinates, without including coordinates
% close to the border, that would generate out-of-limits dots for sure
% [xArea, yArea] = meshgrid(round((max_hdot_size+max(0,disparity/2))):round(widthpp-max_hdot_size-max(0,disparity/2)), max_hdot_size:(heightpp-max_hdot_size));
 [xArea, yArea] = meshgrid(max_hdot_size:round(widthpp-max_hdot_size), max_hdot_size:(heightpp-max_hdot_size));
xAreaLine=xArea(:); yAreaLine = yArea(:);
 sizeXY = numel(xAreaLine);

% if it is initialization of the first dots
if isempty(coordL)==1
    %choose the first dots randomly
    chosenDots = randsample(sizeXY,stim.nbDots, 0) ;
    %introduce disparity into left eye by translating everything with a given disparity shift (leftward) and copy pasting what is out of frame on the other side
    coordL = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
    coordR = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
    %[coordL, coordR]= avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity);
end

% apply the direction to the frame step to get motion vectors
rotationMatrix=nan(2,stim.nbDots);
for ii=1:stim.nbDots %We first move all dots a step to the 0 deg direction (speed related) and then rotate around the initial position coordinates
    rotationMatrix(:,ii) =[stim.ppByFlash,0]*[cos(stim.directions(ii)), -sin(stim.directions(ii));sin(stim.directions(ii)),cos(stim.directions(ii))];
end

% add the motion vectors and prevent overlap / out-of-limits dots
coordL = coordL+rotationMatrix;
coordR = coordR+rotationMatrix;
overlap=1; outOfLimits=1;
while overlap==1 || outOfLimits==1 % we avoid them jointly because avoiding one can generate the other
    [coordL, coordR, overlap]= avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity);
    [coordL, coordR, outOfLimits]= avoidOutOfLimits(coordL,coordR,xAreaLine,yAreaLine,disparity,stim);
end

catch err  % DEBUGGING
    sca
    ShowHideWinTaskbarMex
    disp(err)
    if exist('scr','var');     changeResolution(scr.screenNumber, scr.oldResolution.width, scr.oldResolution.height, scr.oldResolution.hz); end
    diary OFF
    if exist('scr','var'); precautions(scr.w, 'off'); end
    keyboard
    rethrow(err);
end

end

function [coordL,coordR, pastOverlap] = avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity)
try
    % function correcting coords to avoid overlap between dots
    pastOverlap=0; % this one is 0 only if no correction is applied at all
    overlap = 1;
    sizeXY = numel(xAreaLine);
    min_distance = max(stim.distBetwDots,mean(stim.dotsizes)); % in pp
    tic;
%    possibleDots = Shuffle(1:sizeXY); nextDot = 1;
%     for j=1:size(coordL,2) % first remove all potential dots that are not good candidate
%         dist1 = sqrt((xAreaLine(possibleDots)-disparity/2-coordL(1,j)).^2+(yAreaLine(possibleDots)-coordL(2,j)).^2);
%         %dist2 = sqrt((yAreaLine(possibleDots)+disparity/2-coordR(1,j)).^2+(yAreaLine(possibleDots)-coordR(2,j)).^2);
%         wrongDots = (sum(dist1<min_distance,2)>0);%|(sum(dist2<min_distance,2)>0);
%         possibleDots(wrongDots) = [];
%     end
    while overlap %then find the current overlapping dots and replace them
        overlap=0;
        %possibleDots = Shuffle(1:sizeXY); nextDot = 1;
        for i=1:size(coordL,2)
            distance1 = sqrt((coordL(1,:)-coordL(1,i)).^2+(coordL(2,:)-coordL(2,i)).^2);
            distance2 = sqrt((coordR(1,:)-coordR(1,i)).^2+(coordR(2,:)-coordR(2,i)).^2);
            if sum(distance1<min_distance)>1 || sum(distance2<min_distance)>1
                overlap = 1;
                pastOverlap = 1;  
                chosenDots =  round(rand(1).*sizeXY);
                %chosenDots = possibleDots(nextDot); nextDot = nextDot+1;
                coordL(:,i) = [xAreaLine(chosenDots)-disparity/2; yAreaLine(chosenDots)];
                coordR(:,i) = [xAreaLine(chosenDots)+disparity/2; yAreaLine(chosenDots)];      
                break
            end
        end
        if stim.trial==1 && toc>stim.maxLoadingTime; erri('Time limit for initialization reached: adjust distance between dots and density to correct this'); end 
    end
catch err
    sca
    keyboard
end
end

function [coordL, coordR, pastOutOfLimits]= avoidOutOfLimits(coordL,coordR,xAreaLine,yAreaLine,disparity,stim)
try
    % function correcting for dots outside the area of drawing
    pastOutOfLimits = 0; % this one is 0 only if no correction is applied at all
    outOfLimits = 1;
    miniX = min(xAreaLine); miniY = min(yAreaLine);
    maxiX = max(xAreaLine); maxiY = max(yAreaLine);
    sizeXY = numel(xAreaLine);
    min_distance = max(stim.distBetwDots,mean(stim.dotsizes)); % in pp
    tic;
    possibleDots = Shuffle(1:sizeXY); nextDot = 1;
    for j=1:size(coordL,2) % first remove all potential dots that are not good candidate
        dist1 = sqrt((xAreaLine(possibleDots)-disparity/2-coordL(1,j)).^2+(yAreaLine(possibleDots)-coordL(2,j)).^2);
        %dist2 = sqrt((yAreaLine(possibleDots)+disparity/2-coordR(1,j)).^2+(yAreaLine(possibleDots)-coordR(2,j)).^2);
        wrongDots = (sum(dist1<min_distance,2)>0);%|(sum(dist2<min_distance,2)>0);
        possibleDots(wrongDots) = [];
    end
    while outOfLimits
        outOfLimits = 0;
        dot2replace = (coordL(1, :)<miniX) | (coordR(1, :)<miniX) | (coordL(2, :)<miniY) | (coordR(2, :)<miniY) | ...
           (coordL(1, :)>maxiX) | (coordR(1, :)>maxiX) | (coordL(2, :)>maxiY) | (coordR(2, :)>maxiY);
        if any(dot2replace)     
             outOfLimits = 1;
             pastOutOfLimits = 1;
             chosenDots =  possibleDots(nextDot:(nextDot+sum(dot2replace)-1)); nextDot = nextDot + sum(dot2replace);
             coordL(:,dot2replace) = [xAreaLine(chosenDots)'-disparity/2; yAreaLine(chosenDots)'];
             coordR(:,dot2replace) = [xAreaLine(chosenDots)'+disparity/2; yAreaLine(chosenDots)'];         
        end
        if stim.trial==1 && toc>stim.maxLoadingTime; erri('Time limit for initialization reached: adjust distance between dots and density to correct this'); end 
    end
catch err
    sca
    keyboard
end
end