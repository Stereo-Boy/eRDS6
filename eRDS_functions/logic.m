function [answ]= logic(operation,set1,set2)
%-----------------------------------------------------------------------
%Goal of the function: logic operation on sets : 
%'id' : identity
%'inter' : intersection 
%'union' : union
%'comp' : complement : set 1 is the vector, set 2 is the whole (univers)
%-----------------------------------------------------------------------
%Last edit: dec 08
%Function created by Adrien Chopin in dec 2008
%-----------------------------------------------------------------------
%_______________________________________________________________________

if ~exist('operation','var'); operation='inter'; end

switch operation
    case {'id'}
        answ={set1,set2};
    case {'inter'}
        answ=intersect(set1,set2);
    case {'union'}
       answ=union(set1,set2); 
    case {'comp'}  
     answ=setdiff(set2,set1);
end
