function result= makeLevelEqualBoundsMean(list,m)
%-----------------------------------------------------------------------
%The -mean version of this function is a faster version using only 'nanmean'
%as 'fn', so that fn is not a parameter anymore.
%
%Goal of the function: makes levels on a continuous variable (1st column)
%It will make m levels with equal number of the continuous data.
%Then it applies the fn (ex, sum, mean...) to the second column of list
%Each data in the first is associated with the second.
%In the third column, you get the data number.
%-----------------------------------------------------------------------
%-----------------------------------------------------------------------
%Last edit:
%
%Function created by Adrien Chopin in may 2008
%Project: BPL07
%With: Pascal Mamassian
%-----------------------------------------------------------------------
%_______________________________________________________________________

list=list(isnan(list(:,1))==0,:);
X=sortrows(list,1);
n=size(X,1);
nbDataByLevels=round(n./m);
j=1;
result=nan(m,3);
for i=1:m

    if i==m
        result(i,:)=[mean(X(j:end,:),1),numel(X(j:end,1))];
    else
        result(i,:)=[mean(X(j:(j+nbDataByLevels-1),:),1),numel(X(j:(j+nbDataByLevels-1),1))];
    end
    j=j+nbDataByLevels;
end
