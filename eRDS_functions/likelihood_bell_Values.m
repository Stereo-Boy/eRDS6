function likelihood =likelihood_bell_Values(disparities,param)

    g = param(1);
    neg_slo = param(2);
    sp = param(3);
    delta = param(4);
    p = param(5);
    thresholds = param(6);
    lapse=param(7);
    likelihood = defineLikelihood_bell(g, neg_slo, sp, delta, p, disparities, thresholds,lapse);
end