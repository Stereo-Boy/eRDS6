function likelihood = defineLikelihood(g, lapse, sp, delta, p, disparities, thresholds)
% this psychometric function is used in Serrano-Pedraza et al., 2016 (IOVS)
% It is a logistic function of probability of correct response as a function of log-disparity
% g is guess rate
% lapse is finger error rate
% sp is the standard deviation (slope)
% delta is the function extent considered for calculation [delta to 1-delta]
% p is the performance level defining threshold (usually 0.75 for a 2AFC)
% disparities is the disparity in log arcsec
% thresholds is the threshold in log arcsec

    b = (2./sp).*log((1 - lapse - g - delta)./delta);
    a = (1./b).*log((1-lapse-p)./(p-g));
    likelihood = g + ((1 - lapse - g)./(1 +exp(-b.*(a + disparities - thresholds))));
end