%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calcPrimes.m - Sample usage of WeizGrid
%
%   Together with 'smaple' this is a very simple example of 
%   using WeizGrid. 
%
%   In this example our main 'work' function takes 2 integers and finds
%   common factors between them. It also accepts a 'global' parameter that
%   determines whether to include the number 1 as a common factor.
%   
% By Stav Yagev, 2013


function [WGres,bSuccess] = calcPrimes(WGglobalParam, WGsubParam, k)
        
    %TODO: replace this with your own implementation code
    fprintf('Processing iteration #%d\n',k);
    
    f1 = factor(WGsubParam.X);
    f2 = factor(WGsubParam.Y);
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