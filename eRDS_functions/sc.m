function output=sc(lum,scr)
% screen luminance linearization
% Corrects the screen luminance display
% 
% wanted lumimance (in candela/m2)
% scr must at least contain:
% scr.paramOptim1 and scr.paramOptim2 (gamma function parameters for that
% particular screen)
% output is the 0-255 (bit) value

% constraining value between 0 and 255 
if numel(scr)==1
    output = max(0,min(255,(lum./scr.paramOptim1).^(1/scr.paramOptim2)));
else
    output = max(0,min(255,(lum./scr(1)).^(1/scr(2))));
end

