function countdown(begin,scr,stim,expe)
%====================================
%countdown(begin,window,color)
%
%This is a Count Down in stereo
%
%====================================
%Created by Adrien Chopin in feb 2007
%=====================================

for i=begin:-1:1
    instr1 = expe.breakInstructions1.(expe.language);
    instr2 = expe.breakInstructions2.(expe.language);
    instr = sprintf('%s                %s                   %s',instr1, instr2, [' -------------> ', num2str(i)]);
    displaystereotext3(scr,sc(scr.fontColor,scr),stim.instrPosition,instr,1);
    Screen('Flip', scr.w);
    WaitSecs(1);
end
end
