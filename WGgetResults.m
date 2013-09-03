function [WGtotalRes, bTotalSuccess, nLost] = WGgetResults( WGjob, varargin )
%WGgetResults Returns the aggregated results from a WG job.
%   Call this function after a call to WGexec has finished and you want to
%   do post processing with the results. This method takes 1 parameter
%   'WGjob' and a couple of named options:
%
%   Parameters:
%       WGjob - The identifier returned from WGexec.
%
%   Named Options:
%       'LocalFolder' (default: false) - if true recovery mode is enabled,
%           see the description below.
%       'Flatten' (default: false) - if true the results will be in a
%           1-dimensional cell array (instead of 2). This is useful
%           especially for cases where every sub-parameter set is tested
%           only once.
%
%   Return values: 
%       WGtotalRes - will be a cell array of size Jx1 (where J is
%           the total number of sub-parameter sets), and each cell will be 
%           another cell array of size Kx1 (where K is the total number of 
%           iterations for the j'th sub-parameters set). So
%           WGtotalRes{j}{k} will contain the results of the work function
%           for sub-parameters set j and iteration k. 
%
%           If 'Flatten' is set to true, this will instead be a 1
%           dimensional (J*K)x1 cell array
%   
%       bTotalSuccess - has the same structure as WGtotalRes, except that 
%           every entry is a boolean corresponding to the success code returned 
%           by your work function.
%
%       nLost - the count of iterations that was lost to unknown errors.
%           Suppose for example you had a 1000 iteration jobs split into 5 so that 
%           each parallel work got to handle 200 iterations. And suppose one of
%           these jobs failed due to some bug or unknown error, nLost will have
%           a value of 200 so you know your data is only from 800 iterations
%           which actually finished.
%
%
%   Recovery mode
%   --------------------------
%   If there was a bug during post-processing, you may have not saved the
%   results in a meaningful way. To avoid having to re-run the whole work,
%   copy the files from the following UNIX directory to somewhere on your PC
%      ~/.matlab/cluster_jobs/yourq.q/
%   You can then invoke WGgetResults in the following manner to get the
%   results again:
%   
%   WGjob - A structure constructed by YOU the following way:
%       WGjob.k = is a Jx1 vector containing the original k values for each
%           sub-parameters set
%       WGjob.nparallels = should be equal to what you used when calling WGexec
%       WGjob.sName = the exact name used for the original job
%
%   Also specifiy the option 'LocalFolder' with the path to where you put
%   the files on your PC.
%
%   Return values: exactly the same as in the regular case.
%
%
%   Written by Stav Yagev, 2013

    bLocalFolder = false;
    bFlatten = false;
    
    for i = 1 : 2 : length(varargin)
        name = varargin{i};
        value = varargin{i+1};
        switch name
            case 'LocalFolder'
                bLocalFolder = true;
                sLocalFolder = value;
            case 'Flatten'
                bFlatten = value;
        end
    end
    
    
    
    if (~isfield(WGjob,'bLocalDebug'))
        WGjob.bLocalDebug = false;
    end
    if (bLocalFolder || ~WGjob.bLocalDebug)
        nLost = 0;
        nGood = 0;
        
        WGtotalRes = cell(WGjob.j,1);
        bTotalSuccess = cell(WGjob.j,1);
        iTotalK = sum(WGjob.k);
        
        %if we are recovering, then it is defnitely from a case where
        %someone used the WaitTillFinished option. so active nparallels is
        %1 less than that specified
        WGjob.nparallels = WGjob.nparallels - 1;
        
        %collect results
        for i=1:WGjob.nparallels
            if (~bLocalFolder)
                fname = sprintf('~/.matlab/cluster_jobs/%s/%s_%do.mat', ...
                    WGjob.q,WGjob.sName,i);
            else
                fname = sprintf([sLocalFolder '\\%s_%do.mat'],WGjob.sName,i);
            end
            
            for j = 1:WGjob.j
                WGtotalRes{j} = cell(WGjob.k(j),1);
                bTotalSuccess{j} = false(WGjob.k(j),1);
            end
            
            if (exist(fname, 'file'))
                %load the sub-simulation job data
                load(fname);
                
                for iAss = 1:size(mAssRng,1)
                    WGtotalRes{mAssRng(iAss,1)}{mAssRng(iAss,2)} = WGres{iAss}; %#ok<USENS>
                    bTotalSuccess{mAssRng(iAss,1)}(mAssRng(iAss,2)) = bSuccess(iAss);
                end
                
                nGood = nGood + size(mAssRng,1);
                
            else
                %calculate how many iterations this parallel had
                nLost = nLost - (i-1)*ceil(iTotalK/WGjob.nparallels)+1 + ...
                    min(iTotalK, i*ceil(iTotalK/WGjob.nparallels)) + 1;
            end
            
            %less maybe enough due to rounding
            if ((nGood + nLost) == iTotalK)
                break;
            end
        end
    
    else
        WGtotalRes = WGjob.WGres;
        bTotalSuccess = WGjob.bSuccess;

    end
    
    if (bFlatten)
        WGtotalRes = cat(1,WGtotalRes{:});
        bTotalSuccess = cat(1,bTotalSuccess{:});
    end

end