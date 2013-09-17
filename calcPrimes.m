%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calcPrimes.m - Sample usage of WeizGrid
%
%   Together with 'sample' this is a very simple example of 
%   using WeizGrid. 
%
%   In this example our main 'work' function takes 2 integers and finds
%   common factors between their average and a random number. It also accepts 
%   a 'global' parameter that determines whether to include the number 1 as a 
%   common factor.
%   
% By Stav Yagev, 2013


function [WGres,bSuccess] = calcPrimes(WGglobalParam, WGsubParam, j, k)
        
    %TODO: replace this with your own implementation code
    fprintf('Processing iteration #%d of sub-parameters #%d\n',k,j);
    
    f1 = factor(mean(WGsubParam.X + WGsubParam.Y));
    f2 = factor(randi(intmax,1));
    WGres = intersect(f1,f2);

    if (WGglobalParam.bCount1AsAFactor)
        WGres = [1 WGres];
    end
    
    %report success/failure
    %this mechanism allows you to easily filter out iterations that are
    %"wrong" in the aggregation stage. For the sake of the example, lets
    %say we don't want to include pairs of numbers that are co-prime
    bSuccess = ~isempty(WGres);
        
end