function simulERDS
    %---------- robot mode for normal stereopsis

    Box = 21;
    [paths(Box),'ERDS - Eyetracked Random Dot Stereotest',filesep,'dataFiles',filesep]
    cd([paths(Box),'ERDS - Eyetracked Random Dot Stereotest',filesep,'dataFiles',filesep]);
    nb=40;

   
   %name= 'simulERDS_2.mat'; %40 repeats of 11 disp x 20 trials for 13 possible thresholds, bias = 0
   %results: 30% at 10, 15% at 100, 20% at 500, 25-35% after - not good above 1500
   %name= 'simulERDS_1.mat'; %40 repeats of 11 disp x 16 trials for 13 possible thresholds
   %results: 30% at 10, 15% at 60, 20% at 200, 25 at 300, 30-45% after 800 - not good above 1500, poor after 800
   name= 'simulERDS_3'; %40 repeats of 11 disp x 16 trials for 13 possible thresholds - bias = 50
   %results: same but 50% at 800 - not good above 1500, poor after 800
   
    close all
    list=[10,20,30,60,100,150,200,300,500,800,1500,2010,3000];
    nn=numel(list);
    data=nan(nn,nb,2);
    total=nn*nb;
    progBar = ProgressBar(total,'computing...');
    n=1;
    k=1;
    for simulThr=list 
        for repeat=1:nb
            simul_ERDS_artificial(simulThr);
            r=indivAnalysisERDS([],[], 1);
             data(k,repeat,:)=[simulThr,r];
          %   dataPart1(k,repeat,:,1:3)=[simulThr,simulThr,simulThr;rr];
            progBar(n);
            n=n+1;
        end
        k=k+1;
    end

   % close all
    avDataX=squeeze(nanmean(data(:,:,1),2));
    avDataY=squeeze(nanmean(data(:,:,2),2));
    medianX=squeeze(nanmedian(data(:,:,1),2));
    medianY=squeeze(nanmedian(data(:,:,2),2));
    std1=squeeze(std(data(:,:,2),0,2)./sqrt(nb));

TextTable.fig1.subfig1.en={'','Measured threshold (arcsec)','Simulated Threshold'};
TextTable.fig2.subfig1.en={'','Error (%)','Simulated Threshold'};
fontSize = 12;

    h1=figure(1);
    colors=['r','b','g'];

        errorbar(avDataX,avDataY,std1)
        hold on;
        plot(avDataX,avDataX,'LineStyle','-')
        errorbar(medianX,medianY,std1)
        plot(medianX,medianY,'LineStyle','--')
    legendAxis(TextTable,1,1,'en',fontSize)  ;
    
    h2=figure(2);
    errors=squeeze(data(:,:,2)-data(:,:,1));
    errorMean=squeeze(nanmean(abs(errors),2));
    std1=squeeze(std(errors,0,2));
    colors=['r','b','g'];
            plot(squeeze(data(:,1,1)),100*errorMean./squeeze(data(:,1,1)),'LineStyle','-')
            hold on
           % errorbar(squeeze(data(:,1,1,i)),errorM,std1./sqrt(nb))
     line(([0, max(list)]),[5 5],'Color','r','LineStyle','--')
     line(([0, max(list)]),[10 10],'Color','r','LineStyle','--')
    legendAxis(TextTable,2,1,'en',fontSize)  ;
    save(name)
    saveas(h1,[name,'a.fig'])
     saveas(h2,[name,'b.fig'])
    
end

function simul_ERDS_artificial(thres)
    
    load('defaut_ERDS')
    %thresDist=(thres/(sqrt(2)*0.67))/60 ; %divide by 0.67 to get std of the difference and sqrt(2) to get the std of each stimulus noise
    
    for i=1:size(expe.results)
        thisTrial=expe.results(i,:);
        disparityUp = thisTrial(8); disparityDown = thisTrial(9);
        [responseKey]=getResponseKb(0,0,2,[5,6],'robotModeERDS',[(3600*disparityUp/scr.VA2pxConstant) (3600*disparityDown/scr.VA2pxConstant) thres 900],1,0,0,0); 
        expe.results(i,11)=[responseKey];
    end;

    clear thres
    save('defaut_ERDS.mat')

end

