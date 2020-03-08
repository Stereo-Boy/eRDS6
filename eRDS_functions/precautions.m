function precautions(w,switcher)
%==============================
%Generic function whose goal is to take some
%precautions during an experiment
%===============================
%Switcher can be on or off
%================================
%Created in feb 2008 by Adrien Chopin
%
%================================

switch switcher
    case {'on'}
        FlushEvents;
        priorityLevel=MaxPriority(w);
        Priority(priorityLevel);
        HideCursor;
        echo off
        ListenChar(2);
        if IsWindows
            ShowHideWinTaskbarMex(0) 
        end
        %warning('off','MATLAB:dispatcher:InexactMatch') %disable match error warnings
        %Screen('Preference','Backgrounding',0);
    case{'off'}
        Priority(0);
        ShowCursor;
        ListenChar(0);
        if IsWindows
            ShowHideWinTaskbarMex(1) 
        end
        Screen('Preference', 'SkipSyncTests', 0);
        sca
end

end