function [x,error] = equSolve2(f,params,lowerBound, upperBound,goalValue)
% This is solving the equation f(x, cst_params)=goalValue and returns an approximation of x independent of the starting parameter
% However, it will solve only between x=[lowerBound : upperBound]
% equSolve2 only transmits xx and params to f




precision=100000; amplitude=upperBound-lowerBound; step=amplitude/precision;
xx=lowerBound:step:upperBound;
yy=feval(f,xx,params);
[error, solutionIdx] = min(abs(yy-goalValue));
x=xx(solutionIdx);