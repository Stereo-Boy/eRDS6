function response=robotModeERDS(robotprofil)
% robotprofil
%   numel(robotprofil) = 4
%       1   disparity on the left in arcsec
%       2   disparity on the right in arcsec
%       3   threshold in arcsec
%       4   eventual return to chance after that amount of disparity in arcsec

  %random
%    response = randsample([6,5], 1,1,[0.5 0.5]);
%======================================================================
   %constant
 %  response = 5;
%======================================================================    
   %profils: 
     %  response=robotprofil;
   % response = robotprofil+4;
%======================================================================
%     %psychophysic function
%         if any(abs([robotprofil(1),robotprofil(2)])>robotprofil(4))  %in diplopia, threshold rises exponentially
%             robotprofil(3) = robotprofil(3)+10*exp((abs(robotprofil(1)-robotprofil(2))-robotprofil(4))/100);
%         end
    %    bias = norminv(rand(1),400,20); %bias to see up in the back
    %    bias = 100;
 response=1;   
%  
% if numel(robotprofil) == 4
%         bias=0;              
%         noise1=norminv(rand(1),0,robotprofil(3)/(0.67*sqrt(2)));
%         noise2=norminv(rand(1),0,robotprofil(3)/(0.67*sqrt(2)));
%         disp1=robotprofil(1)+noise1+bias;
%         disp2=robotprofil(2)+noise2;
%         if disp1<disp2
%             response=1;
%         elseif disp1>disp2
%             response=2;
%         else
%           response= randsample([1,2],1);
%         end
% else
%        response = 1 + rand(1)>0.5;
% end
% % 
% %        %===== test what happens when a virtual stereoblind uses diplopia cue
% %        diplU=0; diplD = 0; diplThr=1000;
% %         if robotprofil(1)>diplThr || robotprofil(1)<-diplThr %if diplopia, simulates a diplopic bias for front
% %             diplU = 1;
% %         end
% %         if robotprofil(2)>diplThr || robotprofil(2)<-diplThr
% %             diplD = 1;
% %         end
% %         if (diplU==1 && diplD==1) || (diplU==0 && diplD==0)
% %             response= randsample([5,6],1);
% %         elseif diplU==1
% %             response = 5;
% %         elseif diplD==1
% %             response = 6;
% %         end
% %          
% %==== ERROR RATE ====%
%          errorRate=3/100;% here is the % of error
%         if rand(1)<errorRate
%             response=3-response; %error
%         end
%      
