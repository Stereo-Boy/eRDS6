function [success, oldResolution, currentResolution] = changeResolution(screenNumber, width, height, hz)
%function success=changeResolution(screenNumber, width, height, hz)
% The function checks for the screen screenNumber that width and height (in
% pixels) and refresh rate (hz in  hz) are an appropriate supported combination of resolution and then
% tries to change the screen to that resolution and refresh rate using PsychToolBox
% success can be 0 (fail), 1 (success), 2 neutral (did not change
% resolution but it is actually already correct)
% Adrien Chopin - oct 2016
%
% Usage:
% at the beginning of the code:
% oldResolution=Screen('Resolution', screenNumber);
% changeResolution(screenNumber, goalWidthRes, goalHeightRes, goalRefreshRate);
% at the end of the code:
% changeResolution(screenNumber, oldResolution.width, oldResolution.height, oldResolution.hz);


currentResolution=Screen('Resolution', screenNumber);

%checking the resolution
if currentResolution.width == width && currentResolution.height==height  && currentResolution.hz==hz
       dispi('changeResolution: We will do nothing because the current resolution is already at ',width, 'x',height)
       dispi('and the current refresh rate is already ', hz, 'hz')
       success=2;
       oldResolution = currentResolution;
else
    disp(['changeResolution: attempting to change resolution of screen ', num2str(screenNumber), ' to ', num2str(width), 'x', num2str(height)])
    dispi('and the refresh rate to ', hz, 'hz')
    resolutions=Screen('Resolutions',screenNumber);

        compatible=0;
        for i=1:numel(resolutions)
            if resolutions(i).width==width && resolutions(i).height==height && resolutions(i).hz==hz
                compatible=1;
            end
        end

        if compatible==0
            success=0;
            warning(['That screen does not support that resolution/refresh rate: we keep the current resolution at ', num2str(currentResolution.width), 'x', num2str(currentResolution.height)])
        else
           oldResolution = Screen('Resolution', screenNumber , width, height, hz); 
           currentResolution=Screen('Resolution', screenNumber);
           WaitSecs(1);
            if currentResolution.width == width && currentResolution.height==height && currentResolution.hz==hz
               success=1;
               disp(['We changed the current resolution to ', num2str(currentResolution.width), 'x', num2str(currentResolution.height)])
               dispi('and the refresh rate to ', currentResolution.hz, 'hz')
            else
                success=0;
                currentResolution=Screen('Resolution', screenNumber);
                warning(['We try that resolution/refresh rate but it did not work - we kept it at ', num2str(currentResolution.width), 'x', num2str(currentResolution.height)])
            end
        end
end

end