function [thr, PSE,  lapse,thr_SE, bias_SE,menu,sec_est_thr,sec_est_thr_SE,dates,profileFound,...
            dataFile,fitQuality,r,prec,totalTime,x1,y1,yg1,pp,minChiInd,modelLabel]=indivAnalysisERDS_simple2(file, optResults,plotOrNot,nbFits, folder)
% For a full description of this function, see powerpoint "ERDS analysis -
% description.pptx"
% If you enter a cell array with more than one ID as file, the code
% will attempt to load all files and concatenate the data
% As a result, we can have different number of data by dot and the
% algorythm will fit giving a stronger weight to the more data
% Use file='simul' and provide optResults=respTotal to enter ideal file simulation
%
% modelLabel and minChiInd are the number of best model and profileFound is its name.
% Model 10 performs a normalization before trying to estimate the fit
% through other models. In that case, minChiInd=10 but with a different
% modelLabel number (the one finally identified through model 10) while the others
% have always minChiInd = modelLabel
% If plotOrNot=0, the function does not verbose and does not plot figures
% nbFits is the number of time we run each model with random initial
% parameters (100 is a good number)
% folder is where we will look for the file to load. In general, it is
% safer to provide the full file name in absolute path format, rather than
% specifying a folder name here.
%------------------------------------------------------------------------
% It is part of :
% VRS Project [Virtual Reality Stereo]
% 2018
%
% Inputs: simply gives the name of the data file and start from the ERDS folder
% If simul if 1, the function does not issue any output on command window or figure and tak
%   This function is done to analyse results of the experiment individually   
%-----------------------------------------------------------------------


if exist('file','var')==0 || isempty(file)
    thr=nan;     lapse=0;    thr_SE=0;    bias_SE=0; sec_est_thr_SE=0;
    return;
end
simul=0;
if strcmp(file,'simul')==1;plotOrNot=0;simul=1;end
if strcmp(file,'simulPlot')==1;simul=1;end
if exist('optResults','var')==0 || isempty(optResults); optResults=[];end
if exist('plotOrNot','var')==0 || isempty(plotOrNot);plotOrNot=1;end 
if iscell(file)==0;file={file};end
if exist('nbFits','var')==0 || isempty(nbFits);nbFits=100;end 
if exist('folder','var')==0 || isempty(folder);folder='dataFiles3';end 
if plotOrNot==1
    clc
    close all
end
    [pathExp,~]=fileparts(mfilename('fullpath'));
    addpath(fullfile(pathExp,'fonctions_analysis'))    
if simul==0
    pathData=fullfile(pathExp,folder);
    disp(pathData)

    respTotal=[]; totalTime=0;
    for i=1:numel(file)
        file2=file;
        file{i}=fullfile(pathData,[file{i},'.mat']);
        j=1;
        while exist(file{i}, 'file')~=2
             dispi('Current file: ',file{i})
             warning('file does not exist, lets try something different')
            if j==1;        file{i}=fullfile(pathData,[file{i},'_ERDS.mat']); end
            if j==2;        file{i}=fullfile(pathData,[file{i},'_200_ERDS.mat']); end
            if j==3;        file{i}=fullfile(pathData,[file{i},'_2000_ERDS.mat']); end
            if j==4;        file{i}=file2{i}; end
            if j==5;        error('File not found'); end
            j=j+1;
        end
        dispi(' ---------- ',file{i},' ---------- ')
        dispi('Loading file : ', file{i})
        load(file{i}, 'expe','scr');
        respTotal=[respTotal;expe.results];
        totalTime=totalTime+sum(expe.time);
        if i>1; dataFile='Several files';else; [~,dataFile]=fileparts(file{1}); end
    end
    

        %--------------------------------------------------------------------------

                                       % ----- response TABLE --------------------------------
                                       %    1:  trial
                                       %    2:  pedestal condition # (always 1)
                                       %    3:  pedestal value in pp (always 0)
                                       %    4:  repetition
                                       %    5:  value (disparity) # (background)
                                       %    6:  nan
                                       %    7:  is the target closer or not ? (correct answer) - 1: yes - 2: no
                                       %    8:  disparity of Center stim in pp
                                       %    9:  disparity of background stim in pp
                                       %    10:  disparity value in arcsec
                                       %    11  responseKey - target stim is closer(6) or not (5)
                                       %    12  fixation duration
                                       %    13  RT = stimulus duration
                                       %    14  Gaze outside of area or not? (1 yes, 0 no)
                                       %    15  Correct response or not (1 or 0)
                                       %    16  disparity of background in arcsec
                                       %    17  and of target

           %--------------------------------------------------------------------------
           %    Extract responses
           %--------------------------------------------------------------------------

           invertIt = 0;
           %invert response here
           if invertIt==1
                input('WARNING - you decided to invert responses: check that it is still correct. Press any key')
                respTotal(:,11)= 11-respTotal(:,11);
           end
else
    respTotal=optResults; 
    totalTime=0;
    scr.VA2pxConstant=103.6507;
    dataFile='';
end
            
            %CORRECT RESPONSES - this column is used later for calculating average %CR
              respTotal(:,15)=((7-respTotal(:,11))==respTotal(:,7) | respTotal(:,9) == 0);

            %Disparity of background and target in arcsec
            respTotal(:,16)=3600*respTotal(:,9)./scr.VA2pxConstant;
            respTotal(:,17)=3600*respTotal(:,8)./scr.VA2pxConstant;
            
            TextTable.fig1.subfig1.en={'Zero pedestal','p(Target closer response)','Disparity relative to background dots (arcsec)'};
            
             if plotOrNot==1;                verbose='verboseON';             else;                 verbose='verboseOFF';             end
                color=1;
                averageCR=roundit(100*nanmean(respTotal(:,15),1),1);
            dispi('Average correct response rate (%): ',num2str(averageCR),verbose)


%fit the data by a psychometric curve to get an approximate of the threshold
       Disparity_Targ_Bg = respTotal(:,16);
       Resp_Targ_Near =  respTotal(:,11)-5;

       x1=sort(logic('union', Disparity_Targ_Bg,[])); %the disparity of the data to fit
       count=nan(numel(x1),1);%the nb of data by dot
       y1=nan(numel(x1),1);%the nb of data by dot
       stdY=nan(numel(x1),1);%
        for j=1:numel(x1)%the data to fit
             count(j)=sum(Disparity_Targ_Bg==x1(j));
             y1(j)=nanmean(Resp_Targ_Near(Disparity_Targ_Bg==x1(j)));
             stdY(j)=sqrt(y1(j)*(1-y1(j)));
        end
          
        % the abscisca of the continuous line to fit the model
            minC=(min(min(x1)));
            maxC=(max(max(x1)));
            xx=minC:0.01:maxC;
            textStart=minC+(maxC-minC)*0.05; %text will show at 10% of the axis

        profiles={'Full-range stereovision',...             % #1
            'Full stereo / small Panum',...                 % #2
            'Uncrossed-blind (blind to divergent)',...      % #3
            'Crossed-blind (blind to convergent)',...       % #4
            'Stereoblind',...                               % #5
            'Full stereo / large fixation disp.(far)',...   % #6
            'Crossed blind / large fixation disp.',...      % #7
            'Full stereo / large fixation disp.(near)',...  % #8
            'Uncrossed blind / large fixation disp.',...    % #9
            'Normalized function with exp. decay tails',... % #10
            'Normalized function with linear decay tails'}; % #11
          %  '3 lines spline approximation'};                % 
          
          % We now calculate the best possible precision knowing the data
          % (assuming a PSE=0)
          % find disparity between the two dots closest to PSE, then estimate min threshold precision
          PSE=0;diffs=abs(x1-PSE); [~, idx]=sort(diffs); twoDots=x1(idx(1:2));
          dist=abs(twoDots(1)-twoDots(2)); preca=dist/4;
             
        % profile 1 - typical stereo, each lapse <=10%, bias<200"
             dispi('Model 1: estimate threshold', verbose);biasLimit=150;
             pMin=[preca -biasLimit 0.001 0.001]; pMax=[2000 biasLimit 0.1 0.1];
             [paramsLSQa(1,:), ra(1), lapsea(1), PSEa(1), thra(1), yg1a(1,:), chisqLSQa(1), ppa(1),thr_SEa(1),bias_SEa(1),modelLabel(1)]=fitLSQprobit_multi2(1,nbFits, pMin, pMax, count, x1, y1, xx, verbose);     
             if plotOrNot; plotIt(1,2,6,1,x1,y1,xx,yg1a(1,:),PSEa(1),thra(1),1,ppa(1),ra(1),minC,maxC,ppa(1)<0.05); end   
        % profile 2 - full-range stereo with small Panum fusion area (go back to chance in the extremas), each lapse <=10%, bias<150"
             dispi('Model 2: estimate threshold', verbose);biasLimit=150;
             pMin=[preca -biasLimit 0.001 0.00005]; pMax=[2000 biasLimit 0.1 0.00025];
             [paramsLSQa(2,:), ra(2), lapsea(2), PSEa(2), thra(2), yg1a(2,:), chisqLSQa(2), ppa(2),thr_SEa(2),bias_SEa(2),modelLabel(2)]=fitLSQprobit_multi2(2,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,2,x1,y1,xx,yg1a(2,:),PSEa(2),thra(2),2,ppa(2),ra(2),minC,maxC,ppa(2)<0.05);end   
        % profile 3 - Uncrossed-blind (blind to divergent), upper lapse 40%-60%, lower lapse <=20%, bias<400" - 0 -> 0.5
             dispi('Model 3: estimate threshold', verbose);biasLimit=400;
             pMin=[preca -biasLimit 0.40 0.001]; pMax=[2000 biasLimit 0.60 0.2];
             [paramsLSQa(3,:), ra(3), lapsea(3), PSEa(3), thra(3), yg1a(3,:), chisqLSQa(3), ppa(3),thr_SEa(3),bias_SEa(3),modelLabel(3)]=fitLSQprobit_multi2(3,nbFits, pMin, pMax, count, x1, y1, xx, verbose);            
             if plotOrNot;plotIt(1,2,6,3,x1,y1,xx,yg1a(3,:),PSEa(3),thra(3),3,ppa(3),ra(3),minC,maxC,ppa(3)<0.05);end
         % profile 4 - Crossed-blind (blind to convergent), upper lapse <=20%, lower lapse 40%-60%, bias<400"  - 0.5 -> 1
             dispi('Model 4: estimate threshold', verbose);biasLimit=400;
             pMin=[preca -biasLimit 0.001 0.40]; pMax=[2000 biasLimit 0.2 0.60];
             [paramsLSQa(4,:), ra(4), lapsea(4), PSEa(4), thra(4), yg1a(4,:), chisqLSQa(4), ppa(4),thr_SEa(4),bias_SEa(4),modelLabel(4)]=fitLSQprobit_multi2(4,nbFits, pMin, pMax, count, x1, y1, xx, verbose);            
             if plotOrNot; plotIt(1,2,6,4,x1,y1,xx,yg1a(4,:),PSEa(4),thra(4),4,ppa(4),ra(4),minC,maxC,ppa(4)<0.05);end
             dispi('--- Model 5: estimate threshold', verbose);
          % profile 5 - Stereoblind, constant model with 1 parameter
              pMin=[0 nan nan nan]; pMax=[1 nan nan nan]; %constant 
             [paramsLSQa(5,:), ra(5), lapsea(5), PSEa(5), thra(5), yg1a(5,:), chisqLSQa(5), ppa(5),thr_SEa(5),bias_SEa(5),modelLabel(5)]=fitLSQprobit_multi2(5,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot; plotIt(1,2,6,5,x1,y1,xx,yg1a(5,:),PSEa(5),thra(5),5,ppa(5),ra(5),minC,maxC,ppa(5)<0.05);end
         % profile 6 - full-range stereo with large fixation disparity (asymetric Parum -far fixation), each lapse <=10%, bias<150"
              dispi('Model 6: estimate threshold', verbose);biasLimit=150;
              pMin=[preca -biasLimit 0.001 0.00005]; pMax=[2000 biasLimit 0.1 0.001];  %0.001 could be 0.0005
              [paramsLSQa(6,:), ra(6), lapsea(6), PSEa(6), thra(6), yg1a(6,:), chisqLSQa(6), ppa(6),thr_SEa(6),bias_SEa(6),modelLabel(6)]=fitLSQprobit_multi2(6,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,6,x1,y1,xx,yg1a(6,:),PSEa(6),thra(6),6,ppa(6),ra(6),minC,maxC,ppa(6)<0.05);end   
         % profile 7 - Crossed-blind (blind to convergent), with large fixation disparity (asymetric Parum), lower lapse 40%-60%, no upper lapse, bias<400" - 0.5 -> 1
              dispi('Model 7: estimate threshold', verbose);biasLimit=400;
              pMin=[preca -biasLimit 0.40 0.00005]; pMax=[2000 biasLimit 0.60 0.001]; %0.001 could be 0.0005
              [paramsLSQa(7,:), ra(7), lapsea(7), PSEa(7), thra(7), yg1a(7,:), chisqLSQa(7), ppa(7),thr_SEa(7),bias_SEa(7),modelLabel(7)]=fitLSQprobit_multi2(7,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
              if plotOrNot;  plotIt(1,2,6,7,x1,y1,xx,yg1a(7,:),PSEa(7),thra(7),7,ppa(7),ra(7),minC,maxC,ppa(7)<0.05);end   
         % profile 8 - full-range stereo with large fixation disparity (asymetric Parum - near fixation), each lapse <=10%, bias<150"
              dispi('Model 8: estimate threshold', verbose)
              pMin=[preca -biasLimit 0.001 0.00005]; pMax=[2000 biasLimit 0.1 0.001];  %0.001 could be 0.0005
              [paramsLSQa(8,:), ra(8), lapsea(8), PSEa(8), thra(8), yg1a(8,:), chisqLSQa(8), ppa(8),thr_SEa(8),bias_SEa(8),modelLabel(8)]=fitLSQprobit_multi2(8,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,8,x1,y1,xx,yg1a(8,:),PSEa(8),thra(8),8,ppa(8),ra(8),minC,maxC,ppa(8)<0.05);end 
        % profile 9 - Uncrossed-blind (blind to divergent), with large
        % fixation disparity (asymetric Panum), upper lapse 40%-60%, no lower lapse, bias<400" - 0 -> 0.5
              dispi('Model 9: estimate threshold', verbose)
              pMin=[preca -biasLimit 0.40 0.00005]; pMax=[2000 biasLimit 0.60 0.001]; %0.001 could be 0.0005
              [paramsLSQa(9,:), ra(9), lapsea(9), PSEa(9), thra(9), yg1a(9,:), chisqLSQa(9), ppa(9),thr_SEa(9),bias_SEa(9),modelLabel(9)]=fitLSQprobit_multi2(9,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,9,x1,y1,xx,yg1a(9,:),PSEa(9),thra(9),9,ppa(9),ra(9),minC,maxC,ppa(9)<0.05);end   
         % profile 10 - normalized function with exp. decay tails
         % for this one, we normalized the data between min and max, then
         % we approximate with a function with no lapse parameters (so
         % threshold and bias only) and 2 parameters for left asymptote and
         % right asymptote of the tails
              dispi('Model 10: estimate threshold', verbose);biasLimit=150; %normalization model with exp. decay tails
              pMin=[preca -biasLimit 0.001 0.001]; pMax=[2000 biasLimit 0.8 0.8]; %threshold, bias, left tail, right tail
              [paramsLSQa(10,:), ra(10), lapsea(10), PSEa(10), thra(10), yg1a(10,:), chisqLSQa(10), ppa(10),thr_SEa(10),bias_SEa(10),modelLabel(10)]=fitLSQprobit_multi2(10,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,10,x1,y1,xx,yg1a(10,:),PSEa(10),thra(10),10,ppa(10),ra(10),minC,maxC,ppa(10)<0.05);end               
          % profile 10 - normalized function with linear decay tails
             dispi('Model 11: estimate threshold', verbose);biasLimit=150; %normalization model with linear decay tails
              pMin=[preca -biasLimit 0 0]; pMax=[2000 biasLimit 1/500 1/500]; %threshold, bias, left tail, right tail
              [paramsLSQa(11,:), ra(11), lapsea(11), PSEa(11), thra(11), yg1a(11,:), chisqLSQa(11), ppa(11),thr_SEa(11),bias_SEa(11),modelLabel(11)]=fitLSQprobit_multi2(11,nbFits, pMin, pMax, count, x1, y1, xx, verbose);
             if plotOrNot;  plotIt(1,2,6,11,x1,y1,xx,yg1a(11,:),PSEa(11),thra(11),11,ppa(11),ra(11),minC,maxC,ppa(11)<0.05);end  
             
         %select the best chi square (min) as the appropriate profile
          [minChi, minChiInd]=min(chisqLSQa);
          %if the selected model is not stereoblindness, it needs to be
          %specifically tested against it, because stereoblind profile
          %model has less parameters (1 vs. 4)
          % for this, we will compare the diffrerence of chi square and see
          % whether it is significant with a dl that is the difference of
          % dl
          if minChiInd~=5
            chiDiff=chisqLSQa(5)-minChi;
            dlDiff=(numel(x1)-1)-(numel(x1)-4); %actually always 3
            ppDiff = chi2pval2(chiDiff, dlDiff);
            if ppDiff<=0.05
                %the selected model is better so we keep it
            else
                dispi('The model with lower chi square is not proven significantly better than the constant model', verbose)
                dispi('(stereoblind) so we take the stereoblind model as the best one', verbose)
                minChiInd=5; 
            end
          end
          paramsLSQ=paramsLSQa(minChiInd,:);
          r=ra(minChiInd);
          lapse=lapsea(minChiInd);
          PSE=PSEa(minChiInd);
          thr=thra(minChiInd);
          yg1=yg1a(minChiInd,:);
          chisqLSQ=chisqLSQa(minChiInd);
          pp=ppa(minChiInd);
          thr_SE=thr_SEa(minChiInd);
          bias_SE=bias_SEa(minChiInd);
          thr_SE_McKee1985 = 0.67.*(3*paramsLSQ(1)./sqrt(sum(count)));
          profile=minChiInd;
          prec=preca;
          modelLabel=modelLabel(minChiInd);
          wrongFit=0;if pp<0.05;wrongFit=1;end
          profileFound=profiles{modelLabel};
          dispi('Best model: Model ',minChiInd,verbose)
          dispi('Best profile: label ',modelLabel,' (',profileFound,')',verbose)
          
          
        sec_est_thr=roundit(paramsLSQ(1)*0.67,1); sec_est_thr_SE=roundit(thr_SE_McKee1985,1); %this estimate underestimate the real threshold because it is determine before scaling with lapse parameters
        if profile==5; sec_est_thr=2000; sec_est_thr_SE=nan; end

        if plotOrNot
            figure(2)
            fontSize=16;
            %PLOT
            subplot(1, 2, 1)
            CR=respTotal(:,15);
            plot(1:size(CR,1),simpleMovingAverage(CR',15))
            xlabel('Trials'); ylabel('% CR'); axis([15,size(CR,1)-15,0,1]);
            text(20,0.9,['mean %CR: ',num2str(averageCR)] )
            
            subplot(1, 2, 2)
            colors=['r'; 'g'; 'b'; 'k'; 'r'; 'r'; 'r'; 'r'; 'k'; 'k' ;'k' ;'k'];

                plot(x1,y1,'o','color',colors(color))
                hold on
                plot(xx,yg1,'color',colors(color))
                line(([PSE+thr, PSE+thr]),[0 1],'Color',colors(color),'LineStyle','-')
                line(([PSE-thr, PSE-thr]),[0 1],'Color',colors(color),'LineStyle','-')
                line(([PSE, PSE]),[0 1],'Color','k','LineStyle','-')
                line(([-2000, 2000]),[0.5 0.5],'Color','r','LineStyle','--')
                line(([-2000, 2000]),[0.75 0.75],'Color','r','LineStyle','--')
                line(([-2000, 2000]),[0.25 0.25],'Color','r','LineStyle','--')
                axis([minC maxC 0 1])
                 switch modelLabel
                     case {1}
                         if wrongFit==1; text(textStart,0.1,'Full stereo','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo');end
                     case {2}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / small Panum','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / small Panum');end    
                     case {3}
                         if wrongFit==1; text(textStart,0.1,'Uncrossed-blind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Uncrossed-blind');end
                     case {4}
                         if wrongFit==1; text(textStart,0.1,'Cross-blind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Crossed-blind');end
                     case {5}
                         if wrongFit==1; text(textStart,0.1,'Stereoblind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Stereoblind');end
                     case {6}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / large fixation disp. (far)','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / large fixation disp. (far)');end
                    case {7}
                         if wrongFit==1; text(textStart,0.1,'Crossed blind / large fixation disp.','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Crossed blind / large fixation disp.');end
                    case {8}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / large fixation disp. (near)','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / large fixation disp. (near)');end
                    case {9}
                         if wrongFit==1; text(textStart,0.1, 'Uncrossed blind / large fixation disp.','BackgroundColor',[0.8 0 0]); else text(textStart,0.1, 'Uncrossed blind / large fixation disp.');end     
                        
                 end
                 if profile==10; text(textStart,0.8, 'Normaliz. & exp. decay tails'); end
                 if profile==11; text(textStart,0.8, 'Normaliz. & linear decay tails'); end
                 
                 if pp<0.05
                    text(textStart,0.7,['p=' num2str(pp,1)],'BackgroundColor',[0.8 0 0])
                 else
                     text(textStart,0.7,['p=' num2str(pp,2)])
                 end
                 
                 if abs(PSE)>biasLimit;    text(textStart,0.2,['pse=' num2str(PSE,4)],'BackgroundColor',[0.8 0 0])
                 else text(textStart,0.2,['pse=' num2str(PSE,4)]); end
                 text(textStart,0.3,['thr=' num2str(thr,4)])
                 text(textStart,0.9,['Resp.Bias=' num2str(r,2)]) 
                 %response bias
                 if abs(r)>0.20; text(textStart,0.9,['Resp.Bias=' num2str(r,2)],'BackgroundColor',[0.8 0 0]); else text(textStart,0.9,['Resp.Bias=' num2str(r,2)]);end

            TextTable.fig1.subfig1.en={'','P(target reported near)', 'Disparity difference (arcsec)'};
            legendAxis(TextTable,1,1,'en',fontSize)  ;
        end

if ~exist('expe')||isfield(expe,'menu')==0;    menu='unkonwn'; else; menu=expe.menu; end
if ~exist('expe')||isfield(expe,'date')==0;    dates='unkonwn'; else; dates=expe.date; end
if wrongFit==1; fitQuality='Bad'; else;  fitQuality=' Good';end


if plotOrNot == 1
        disp('  ')
        disp(' ============== Final results ============================================================ ')
        dispi('Total test duration: ', roundit(totalTime),' min / Menu: ',menu,'');
        dispi('Detected min. threshold precision: ',roundit(prec,1), '"')
        dispi('Threshold (75% critical point - PSE) +/-SE:           ',roundit(thr,1),'" +/-',roundit(thr_SE,1))
        dispi('Second estimate of threshold (using probit parameter): ', sec_est_thr,'" +/- ',sec_est_thr_SE)
        dispi('Bias +/-SE:                                           ',roundit(PSE,1),'" +/-',roundit(bias_SE,1))
        dispi('Second estimate of bias (using probit parameter):      ', roundit(paramsLSQ(2),1),'"')
        disp('(a positive bias is a preference for background seen in front)')
        dispi('Model #',profile)
        dispi(profileFound)  
        dispi('Quality of fit: ',fitQuality);
        dispi('Chi2 (from LSQ 2-norm of squared residuals): ',chisqLSQ)
        dispi('Lapse rate (inattentional errors): ',roundit(100*lapse,1),'%')
        dispi('Response bias: ',roundit(100*r,1),'%')
        dispi('Chosen threshold: ',roundit(thr,1))
        %determine what menu to run at next session
        switch menu
            case{14,15,12}
                if roundit(thr,1)>20 || profile==3 || profile==4 || profile==5 || profile==7
                    next_menu=14;
                else
                    if roundit(thr,1)<=2; next_menu=12;
                    elseif roundit(thr,1)<=20; next_menu=15;
                    else
                        warning('something went wrong with next menu decision tree - notify Adrien')
                    end
                end
            case{7,8,11}
                if roundit(thr,1)>20 || profile==3 || profile==4 || profile==5 || profile==7
                    next_menu=7;
                else
                    if roundit(thr,1)<=2; next_menu=11;
                    elseif roundit(thr,1)<=20; next_menu=8;
                    else
                        warning('something went wrong with next menu decision tree - notify Adrien')
                    end
                end
            otherwise
                warning('Current menu is unknown so we cannot go through the decision tree')
                next_menu='?';
        end
        dispi('Next session, run menu ',next_menu)
end
%We take the parametric estimate of threshold
end

function plotIt(fig,row,col,numPlot,x1,y1,xx,yg1,PSE,thr,profile,pp,r,minC,maxC,wrongFit)
    figure(fig)
        fontSize=16;
        textStart=minC+(maxC-minC)*0.05; %text will show at 10% of the axis
        color=1;
            %PLOT
            subplot(row, col, numPlot)
            colors=['r'; 'g'; 'b'; 'k'; 'r'; 'r'; 'r'; 'r'; 'k'; 'k' ;'k' ;'k'];

                plot(x1,y1,'o','color',colors(color))
                hold on
                plot(xx,yg1,'color',colors(color))
                line(([PSE+thr, PSE+thr]),[0 1],'Color',colors(color),'LineStyle','-')
                line(([PSE-thr, PSE-thr]),[0 1],'Color',colors(color),'LineStyle','-')
                line(([PSE, PSE]),[0 1],'Color','k','LineStyle','-')
                line(([-2000, 2000]),[0.5 0.5],'Color','r','LineStyle','--')
                line(([-2000, 2000]),[0.75 0.75],'Color','r','LineStyle','--')
                line(([-2000, 2000]),[0.25 0.25],'Color','r','LineStyle','--')
                axis([minC maxC 0 1])
                 switch profile
                     case {1}
                         if wrongFit==1; text(textStart,0.1,'Full stereo','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo');end
                     case {2}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / small Panum','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / small Panum');end    
                     case {3}
                         if wrongFit==1; text(textStart,0.1,'Uncrossed-blind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Uncrossed-blind');end
                     case {4}
                         if wrongFit==1; text(textStart,0.1,'Cross-blind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Crossed-blind');end
                     case {5}
                         if wrongFit==1; text(textStart,0.1,'Stereoblind','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Stereoblind');end  
                    case {6}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / large fixation disp. (far)','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / large fixation disp. (far)');end               
                    case {7}
                         if wrongFit==1; text(textStart,0.1,'Crossed blind / large fixation disp.','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Crossed blind / large fixation disp.');end 
                    case {8}
                         if wrongFit==1; text(textStart,0.1,'Full stereo / large fixation disp. (near)','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Full stereo / large fixation disp. (near)');end  
                    case {9}
                         if wrongFit==1; text(textStart,0.1,'Uncrossed blind / large fixation disp.','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Uncrossed blind / large fixation disp.');end 
                 end
                 if pp<0.05
                    text(textStart,0.75,['p=' num2str(pp,1)],'BackgroundColor',[0.8 0 0])
                 else
                     text(textStart,0.75,['p=' num2str(pp,2)])
                 end
                 
%                  if abs(PSE)>biasLimit;    text(textStart,0.2,['pse=' num2str(PSE,4)],'BackgroundColor',[0.8 0 0])
%                  else text(textStart,0.2,['pse=' num2str(PSE,4)]); end
                 text(textStart,0.3,['thr=' num2str(thr,4)])
                 text(textStart,0.9,['Resp.Bias=' num2str(r,2)]) 
                 %response bias
                 if abs(r)>0.20; text(textStart,0.9,['Resp.Bias=' num2str(r,2)],'BackgroundColor',[0.8 0 0]); else text(textStart,0.9,['Resp.Bias=' num2str(r,2)]);end

            TextTable.fig1.subfig1.en={'','P(target reported near)', 'Disparity difference (arcsec)'};
            legendAxis(TextTable,1,1,'en',fontSize)  ;
end

