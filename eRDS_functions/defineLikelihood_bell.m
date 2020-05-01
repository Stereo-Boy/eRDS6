function likelihood = defineLikelihood_bell(g, neg_slope, pos_slope, delta, p, disparities, thresholds, lapse)
% likelihood function used in Serrano-Pedraza et al., 2016
% but adapted to be non-monotonic (goes back to chance for large values)
%
% It is a logistic function of probability of correct response as a
% function of log-disparity with a linear return to chance after two
% threshold values
% g is guess rate
% lapse is finger error rate 
% neg_slope is the linear slope of the function when it returns to guess rate
% pos_slope is the standard deviation
% delta is the function extent considered for calculation [delta to 1-delta]
% p is the performance level defining threshold (usually 0.75 for a 2AFC)
% disparities is the disparity in log arcsec
% thresholds is the threshold in log arcsec

%likelihood = max(min(1,1-neg_slope/100.*(10.^disparities-2.*(10.^thresholds))).*defineLikelihood(g, lapse, pos_slope, delta, p, disparities, thresholds),0.5);
likelihood = max(min(1,1-(neg_slope./100).*(10.^disparities-((10.^thresholds)+1.5.*pos_slope.*(10.^thresholds))))...
    .*defineLikelihood(g, lapse, pos_slope, delta, p, disparities, thresholds),0.5);
end