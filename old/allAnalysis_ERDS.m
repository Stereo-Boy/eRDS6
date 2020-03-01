% version August 2019


function thres=allAnalysis_ERDS
% analysis for TestRetest pilot

    close all
    nbFits=100;
        % paths to folders, data and codes
        analysis_path = fileparts(mfilename('fullpath'));
        data_path = fullfile(analysis_path,'dataFiles3'); %HERE pour que les slash soient compatible(MAC Window)
        addpath(fullfile(analysis_path,'shared_functions')) %adding this folder to the search path so that we can use the functions in it

        dispi(' ------------------ STEREO THRESHOLD  ------------------- ')
       % dispi(data_path)
       % check_folder(data_path)
        

            %first, check that there is no tmp file in the folder
        if numel(list_files(data_path,'*_tmp*'))>0   
           error('Tmp files are still in the folder: please clean the folder'); 
        end
        
        %find all the files in that folder
        list_dual=list_files(data_path,'*_ERDS.mat');
        
        %find all the participants in that folder
        ss_list=[] ;% we do not know how many participants we will have
        for i=1:numel(list_dual) % go through each name in the list and extract the nb of the participant
            file_name=list_dual{i};
            ss_list = [ss_list,str2num(file_name(1:3))]; % takes first 3 characters
        end
        
        %remove double items
        ss_list=unique(ss_list);
        n_ss = numel(ss_list);
        
        dispi('We found the following ',n_ss,' participants: ',ss_list)
        
    %build the list of participant names
    listP={};
    for i=1:n_ss
        listP{end+1}=sprintf('%03.f',ss_list(i));% %o3.f = codage de la fonction sprintf qui mets 3 chiffres avant la virgule
    end

    thres=nan(numel(listP),6,2); % cree deja une matrice avec nan pour economiser des ressources si analyses longues (pas besoin d'adapter la matrice en curs d'analyse, juste remplacer les nan)
 for k=1:2
    a=0;
    s=0;
    for i=listP % debut boucle sujet - liste des fichiers loades
        s=s+1;
        ID=i{1};
        dispi('Looking for data file for participant: ',ID)
        disp('We found those files to load')
        %list=dir(fullfile(data_path,[ID,'_T*','_0*'])) 
        list=list_files(data_path, [ID,'_T*_',num2str(k-1),'*.mat'],1)';

        for f=1:numel(list)% du premier fichier au dernier de "list"
          a=a+1;
           fileI = list{f};
           disp('--------------------------------------------------------')
           
           dispi('Loading ', fileI)
           disp('Extracting threshold')
           
           [thr, PSE, ~,~, ~ ,~,~,~,~,~,... 
            ~,~,r,~,~,x1,y1,yg1,pp,minChiInd, modelLabel]=indivAnalysisERDS_simple2(fileI,[],0,nbFits); %reset 2 to 100 (nbrFits for analysis)
            
            minC=(min(min(x1)));
            maxC=(max(max(x1)));
            xx=minC:0.01:maxC;
            wrongFit=0;if pp<0.05;wrongFit=1;end

          thres(s,f,k)=thr ; 
          %  plotAll(fig,row,col,numPlot,x1,y1,xx,yg1,PSE,thr,profile,pp,r,minC,maxC,wrongFit)
          plotAll(k, numel(listP),numel(list),  a,     x1,y1,xx,yg1,PSE,thr,minChiInd,modelLabel,pp,r,minC,maxC,wrongFit)
        end   
    end
 end
 disp('Thresholds')
disp(thres)

end

%a = ans
%plot(log(a(:,:,1)'))
%hold on
%plot(M200)
 %title ('ERDS 200ms')
%xlabel ('Session #')
%ylabel ('Log(10) arcs')
%legend
%hold off

%plot(log(a(:,:,2)'))
%hold on
%plot(M2000)
 %title ('ERDS 2000ms')
%xlabel ('Session #')
%ylabel ('Log(10) arcs')
%legend
% hold off

%plot(log(a(:,:,2)'))
%hold on
%plot(M2000)
%title ('ERDS 2000ms')
%xlabel ('Session #')
%ylabel ('Log(10) arcs')
%legend
%hold off

% extract results in csv file
% csvwrite ('pilot2_testRetest',A(:,:,1))
% csvwrite ('pilot2_testRetest2',A(:,:,2))





function plotAll(fig,row,col,numPlot,x1,y1,xx,yg1,PSE,thr,profile,modelLabel,pp,r,minC,maxC,wrongFit)
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
                         if wrongFit==1; text(textStart,0.1,'Uncrossed blind / large fixation disp.','BackgroundColor',[0.8 0 0]); else text(textStart,0.1,'Uncrossed blind / large fixation disp.');end 
                 end
                 if pp<0.05
                    text(textStart,0.7,['p=' num2str(pp,1)],'BackgroundColor',[0.8 0 0])
                 else
                     text(textStart,0.7,['p=' num2str(pp,2)])
                 end
                 if profile==10; text(textStart,0.8, 'Normaliz. & exp. decay tails'); end
                 if profile==11; text(textStart,0.8, 'Normaliz. & linear decay tails'); end
%                  if abs(PSE)>biasLimit;    text(textStart,0.2,['pse=' num2str(PSE,4)],'BackgroundColor',[0.8 0 0])
%                  else text(textStart,0.2,['pse=' num2str(PSE,4)]); end
                 text(textStart,0.3,['thr=' num2str(thr,4)])
                 text(textStart,0.9,['Resp.Bias=' num2str(r,2)]) 
                 %response bias
                 if abs(r)>0.20; text(textStart,0.9,['Resp.Bias=' num2str(r,2)],'BackgroundColor',[0.8 0 0]); else text(textStart,0.9,['Resp.Bias=' num2str(r,2)]);end

            %TextTable.fig1.subfig1.en={'','P(target reported near)', 'Disparity difference (arcsec)'};
            %legendAxis(TextTable,1,1,'en',fontSize)  ;
            if fig==1
                title('200 ms')
            else
                title('2000 ms')
            end
end
