function [coordL, coordR] = generateRDSStereoCoord(coordL, coordR, stim, heightpp, widthpp, disparity, nbDots, dotSize,directions)
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
%   directions is a list of directions for each dot - it defines both the coherence and the direction of motion then 
%   coordL and coordR dimensions are:
%       1:  x, y
%       2:  dot
%       3:  frame
try
    
max_hdot_size = round(dotSize/2);

% We generate a grid of possible coordinates, without including coordinates
% close to the border, that would generate out-of-limits dots for sure
% [xArea, yArea] = meshgrid(round((max_hdot_size+max(0,disparity/2))):round(widthpp-max_hdot_size-max(0,disparity/2)), max_hdot_size:(heightpp-max_hdot_size));
% We only draw on half of the height and then duplicate the panel (to
% increase computation speed)
 [xArea, yArea] = meshgrid(max_hdot_size:floor(widthpp-max_hdot_size), max_hdot_size:floor(heightpp/2-max_hdot_size)); 
 nbDots = nbDots/2;
 directions = directions(1:nbDots);
 xAreaLine=xArea(:); yAreaLine = yArea(:);
 sizeXY = numel(xAreaLine);

% if it is initialization of the first dots
if isempty(coordL)==1
    %choose the first dots randomly
    chosenDots = randsample(sizeXY,nbDots, 0) ;
    %introduce disparity into left eye by translating everything with a given disparity shift (leftward) and copy pasting what is out of frame on the other side
    coordL = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
    coordR = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
    %[coordL, coordR]= avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity);
else
    % we work only with the top panel of dots, that we duplicate then
    coordL = coordL(:,1:(size(coordL,2)/2));
    coordR = coordR(:,1:(size(coordR,2)/2));
end

% apply the direction to the frame step to get motion vectors
rotationMatrix=nan(2,nbDots);
for ii=1:nbDots %We first move all dots a step to the 0 deg direction (speed related) and then rotate around the initial position coordinates
    rotationMatrix(:,ii) =[stim.ppByFlash,0]*[cos(directions(ii)), -sin(directions(ii));sin(directions(ii)),cos(directions(ii))];
end

% add the motion vectors and prevent overlap / out-of-limits dots
coordL = coordL+rotationMatrix;
coordR = coordR+rotationMatrix;

min_distance = max(stim.distBetwDots,dotSize); % in pp
possibleDots = Shuffle(1:sizeXY);
for j=1:size(coordL,2) % first remove all potential dots that are not good candidate
    dist1 = sqrt((xAreaLine(possibleDots)-disparity/2-coordL(1,j)).^2+(yAreaLine(possibleDots)-coordL(2,j)).^2);
    %dist2 = sqrt((yAreaLine(possibleDots)+disparity/2-coordR(1,j)).^2+(yAreaLine(possibleDots)-coordR(2,j)).^2);
    wrongDots = (sum(dist1<min_distance,2)>0);%|(sum(dist2<min_distance,2)>0);
    possibleDots(wrongDots) = [];
end

overlap=1; outOfLimits=1;
while overlap==1 || outOfLimits==1 % we avoid them jointly because avoiding one can generate the other
    [coordL, coordR, overlap, possibleDots]= avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity,dotSize,possibleDots);
    [coordL, coordR, outOfLimits, possibleDots]= avoidOutOfLimits(coordL,coordR,xAreaLine,yAreaLine,disparity,stim,dotSize,possibleDots);
end

    
% now duplicate the panel and put one below the other
coordL2 = coordL; coordL2(2,:) = coordL2(2,:) + heightpp/2;
coordL = [coordL, coordL2];
coordR2 = coordR; coordR2(2,:) = coordR2(2,:) + heightpp/2;
coordR = [coordR, coordR2];


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

function [coordL,coordR, pastOverlap,possibleDots] = avoidOverlap(coordL,coordR,xAreaLine,yAreaLine,stim,disparity,dotSize,possibleDots)
try
    % function correcting coords to avoid overlap between dots
    pastOverlap=0; % this one is 0 only if no correction is applied at all
    overlap = 1;
    sizeXY = numel(xAreaLine);
    min_distance = max(stim.distBetwDots,dotSize); % in pp
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
                if isempty(possibleDots)
                    possibleDots = Shuffle(1:sizeXY);
                    for j=1:size(coordL,2) % first remove all potential dots that are not good candidate
                        dist1 = sqrt((xAreaLine(possibleDots)-disparity/2-coordL(1,j)).^2+(yAreaLine(possibleDots)-coordL(2,j)).^2);
                        %dist2 = sqrt((yAreaLine(possibleDots)+disparity/2-coordR(1,j)).^2+(yAreaLine(possibleDots)-coordR(2,j)).^2);
                        wrongDots = (sum(dist1<min_distance,2)>0);%|(sum(dist2<min_distance,2)>0);
                        possibleDots(wrongDots) = [];
                    end
                end
                %chosenDots =  ceil(rand(1).*sizeXY);
                chosenDots = possibleDots(1); possibleDots(1) = [];
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

function [coordL, coordR, pastOutOfLimits,possibleDots]= avoidOutOfLimits(coordL,coordR,xAreaLine,yAreaLine,disparity,stim,dotSize,possibleDots)
try
    % function correcting for dots outside the area of drawing
    pastOutOfLimits = 0; % this one is 0 only if no correction is applied at all
    outOfLimits = 1;
    miniX = min(xAreaLine); miniY = min(yAreaLine);
    maxiX = max(xAreaLine); maxiY = max(yAreaLine);
    sizeXY = numel(xAreaLine);
    min_distance = max(stim.distBetwDots,dotSize); % in pp
    tic;
    while outOfLimits
        outOfLimits = 0;
        dot2replace = (coordL(1, :)<miniX) | (coordR(1, :)<miniX) | (coordL(2, :)<miniY) | (coordR(2, :)<miniY) | ...
           (coordL(1, :)>maxiX) | (coordR(1, :)>maxiX) | (coordL(2, :)>maxiY) | (coordR(2, :)>maxiY);
        if any(dot2replace)     
             outOfLimits = 1;
             pastOutOfLimits = 1;
             if isempty(possibleDots)
                    possibleDots = Shuffle(1:sizeXY);
                    for j=1:size(coordL,2) % first remove all potential dots that are not good candidate
                        dist1 = sqrt((xAreaLine(possibleDots)-disparity/2-coordL(1,j)).^2+(yAreaLine(possibleDots)-coordL(2,j)).^2);
                        %dist2 = sqrt((yAreaLine(possibleDots)+disparity/2-coordR(1,j)).^2+(yAreaLine(possibleDots)-coordR(2,j)).^2);
                        wrongDots = (sum(dist1<min_distance,2)>0);%|(sum(dist2<min_distance,2)>0);
                        possibleDots(wrongDots) = [];
                    end
             end
             chosenDots =  possibleDots(1:sum(dot2replace)); possibleDots(1:sum(dot2replace)) = [];
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