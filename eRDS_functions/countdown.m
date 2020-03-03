function countdown(begin,scr,stim)
%====================================
%countdown(begin,window,color)
%
%This is a Count Down in stereo
%
%====================================
%Created by Adrien Chopin in feb 2007
%=====================================

for i=begin:-1:1
    displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,sprintf('%s%d','BREAK -------------> ', i),1);
    Screen('Flip', scr.w);
    WaitSecs(1);
end
end
