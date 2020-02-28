load temp2
a = num2str(100*sum(~isnan(expe.results(:,1)))/size(expe.results,1));
disp(['Done: ',a,'%'])
if isfield(expe,'abortedTrials')==1
    b = num2str(100*size(expe.abortedTrials,1)./sum(~isnan(expe.results(:,1))));
    disp(['Drift calibration: ',b,'%'])
end
