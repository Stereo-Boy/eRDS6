function waitForT(t,inputMode)
%Alias of WaitSecs
%t in MILLISECONDS
%inputMode= 1: user; 2: robot
if ~exist('inputMode','var'); inputMode=1; end
if ~exist('t','var'); t=1000; end

    if inputMode==1
        WaitSecs(t/1000);
    end

end