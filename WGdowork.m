%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WGdowork.m - Internal script for WG
%
%   This script is an internal part of WG and is not intented
%   for users. It is essential for proper function and should
%   available to MATLAB's path.


if (bRngShuffle) 
    rng('shuffle'); 
end

WGres = cell(size(mAssRng,1),1);
bSuccess = false(size(mAssRng,1),1);

for iAss=1:size(mAssRng,1)
    
    [WGres{iAss},bSuccess(iAss)] = workFunc(WGglobalParams, ...
        WGsubParams(mAssRng(iAss,1) - mAssRng(1,1) + 1), ...
        mAssRng(iAss,1), mAssRng(iAss,2));
end