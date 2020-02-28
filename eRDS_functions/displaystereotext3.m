function displaystereotext3(window,color,rect,strings,mode)
%Usage: displaystereotext3(window,color,rect,strings,mode))
%displaystereotext3(window,color,[0,100,500,900],strings,1)
%
%THIS IS THE MOST UP TO DATE
%--------------------------------------------------------------------------
%Features: -doesnt cut the words
%          -centers them (give some random disparities)
%           -adapt itself to the size of the font
%______________________________________________________________
%
%Goal: Display the same text in the two center part of the half screens
%
%--------------------------------------------------------------------------
%Param: 
%window.w: an onscreen
%window.res: onscreen resolution
%window.W: width of the screen in mm
%window.frameSep: the deviation between the center of the screen and the
%centers of the half screens, in mm
%color: your text color
%rect: [top left x, top left y, width, height]
%strings: your text
%mode: 2: mirror ; 1: stereo (rect will be centered on frameSep centers)
%--------------------------------------------------------------------------
%Adapted from displaystereotext2 in nov 09
%Adapted by Adrien Chopin in August 2007
%From displaystereotex
%written 18/06/07 by Adrien Chopin
%To contact me: adrien.chopin@gmail.com
%--------------------------------------------------------------------------

if ~isfield(window,'fontSize');window.fontSize=20;end
if ~isfield(window,'res');window.res=Screen(0,'rect');end
if ~isfield(window,'W');window.W=Screen('displaySize',window.w);end
if ~isfield(window,'frameSep');window.frameSep=121.8; end%in Mm
if ~exist('mode','var');mode=1;end

correctpx=window.frameSep*window.res(3)/window.W;
leftCenter=window.res(3)/2-correctpx;
rightCenter=window.res(3)/2+correctpx;

if mode==2
   rect1=rect;
   rect1(1)=rect1(1)+leftCenter-rect(3)/2;
   rect2=rect;
   rect2(1)=rect2(1)+rightCenter-rect(3)/2;
else
   rect1=rect;
   rect1(1)=leftCenter-rect(3)/2+rect1(1);
   rect2=rect;
   rect2(1)=-rect2(1)+rightCenter-rect(3)/2;
end
displayText(window,color,rect1,strings);
displayText(window,color,rect2,strings);

end





