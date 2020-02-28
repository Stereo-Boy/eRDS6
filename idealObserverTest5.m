function idealObserverTest5
%Instead of calculating the found threshold for different ideal observer's
%thresholds, this function focuse on one particular target threshold (say
%100") and shows how the number of repetitions affects the data quality 

try
    clc
    close all
    expe.nbPedestal=1;
    expe.pedestal=0;
    thrSimul=100;
    for code=1:3
        if code==1
             expe.valueList= [-32 -16 -8 -4 -2 -1 0 1 2 4 8 16 32]; %menu 7 and 14
        elseif code==2 
            expe.valueList= [-3 -1.5 -0.75 -0.375 -0.1875 0 0.1875 0.375 0.75 1.5 3]; %menu 8 and 15
        else
            expe.valueList= [-0.4375 -0.2188 -0.1094 -0.0547 -0.0273 0 0.0273 0.0547 0.1094 0.2188 0.4375]; %menu 11 and 12
        end

        scr.dispByPx=34.732;
        expe.valueListSec=expe.valueList.*scr.dispByPx;
        expe.nbValues=numel(expe.valueList);
        t=1; nbRep=100; i=1; n2test=[10 15 20 25 30];
        %progBar = ProgressBar(nbRep*numel(n2test),'computing...');
        %storingThr=nan(nbRep,numel(n2test));
        medThres=nan(numel(n2test),1);
        IC=nan(numel(n2test),2);
        f=waitbar(0,'Processing the data');
        for ni=n2test
            PSE=sign(rand(1)-0.5)*ni*0.1; lapse1=0.02; lapse2=0.02; thr=nan(nbRep,1); %sec_est_thr=nan(nbRep,1);
            for rep=1:nbRep
                expectedResp = probitValues(expe.valueListSec, [thrSimul/0.67, PSE, lapse1, lapse2]);
                nn=expe.nbValues.*ni;
                respTotal=initializeTable(nn, expe.valueList,expectedResp,ni);
                 [thr(rep), bias,  lapse,thr_SE, bias_SE,menu,sec_est_thr,sec_est_thr_SE,dates,profileFound,...
                dataFile,fitQuality,r,prec,totalTime]=indivAnalysisERDS_simple2('simul', respTotal,0,100);
                %progBar(i);
                %ProgressBar(i,nbRep*numel(n2test))
                waitbar(i/(nbRep*numel(n2test)),f);
                i=i+1;
                %storingThr(rep,t)
            end 
            medThres(t)=median(thr); 
            IC(t,1:2)=[quantile(thr,0.05),quantile(thr,0.95)]; IC75(t,1:2)=[quantile(thr,0.25),quantile(thr,0.75)];
            %medThres2(t)=median(sec_est_thr); IC2(t,1:2)=[quantile(sec_est_thr,0.05),quantile(sec_est_thr,0.95)]; IC75_2(t,1:2)=[quantile(sec_est_thr,0.25),quantile(sec_est_thr,0.75)];

            %diffs(t)=medThres(t)-medThres2(t);
            t=t+1;
        end
        
        figure(code);% subplot(1,2,1);
        line([min(n2test) max(n2test)],[thrSimul thrSimul]); hold on;
        errorbar(n2test',medThres,abs(IC(:,1)-medThres),abs(IC(:,2)-medThres),'r-')
        %errorbar(n2test+5*n2test/100,medThres2,abs(IC2(:,1)-medThres2'),abs(IC2(:,2)-medThres2'),'b-')
        %plot(n2test,IC75(:,1),'ro')
        %plot(n2test,IC75(:,2),'ro')
        %plot(n2test+5*n2test/100,IC75_2(:,1),'bo')
        %plot(n2test+5*n2test/100,IC75_2(:,2),'bo')
        xlabel('Nb of trials');ylabel(['Measured threshold (',num2str(thrSimul),')'])
        %subplot(1,2,2)
        %plot(n2test,diffs)
        %xlabel('Simulated threshold');ylabel('Difference in estimates')
        
%         if code==1
%              save('menu7and14')
%         elseif code==2 
%             save('menu8and15')
%         else
%             save('menu11and12')
%         end
        
    
    end
    keyboard
catch erro
    keyboard
end
end

function table=initializeTable(nn,valueList,expectedResp,nbRepeat)

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

     table=nan(nn,14);
     table(:,6)=rand(nn,1);
     table(:,8)=zeros(nn,1);
     table(:,9)=repmat(valueList',[nbRepeat,1]);
     table(:,7)=table(:,8)<table(:,9);
     table(:,2)=repmat(expectedResp',[nbRepeat,1]);
     table(:,11)=5+(table(:,6)<table(:,2));
end