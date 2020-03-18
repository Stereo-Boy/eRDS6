function scr = screen_parameters
% This is function that is used to define specific screen parameters
% It needs to be modified for each screen/location of an experiment

scr.W = 540;                  % screen width in mm 540 or 300
scr.H = 320;                  % screen height in mm 320 or 210
scr.goalWidthRes = 1920;    % appropriate resolution for that experiment (width in px) 1920 or 1366
scr.goalHeightRes = 1080;   % appropriate resolution for that experiment (height in px)1080 or 768
scr.goalRefreshRate = 60;   % refresh rate
scr.distFromScreen = 150;   % distance screen-eye through any mirror - in cm
scr.viewpixx = 0;           % if this is a viewpixx screen (1) or not (0)

% You will need a photometer to determine the parameters below (exact same
% thing as box parameter in DST8
scr.paramOptim1 =  0.0062;  % gamma parameter 1 for screen luminance calibration following equation output=(luminance./paramOptim1).^(1/paramOptim2);
scr.paramOptim2 = 1.7274;   % gamma parameter 2 for screen luminance calibration
                


