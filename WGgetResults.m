function [WGtotalRes, bTotalSuccess, nLost] = WGgetResults( WGjob, varargin )
%WGgetResults Returns the aggregated results from a WG job.
%   Call this function after a call to WGexec has finished and you want to
%   do post processing with the results. This method has 2 modes, in the
%   regular case (1-parameter only):
%
%   WGjob - The identifier returned from WGexec.
%
%   Return values: 
%       WGtotalRes - will be a cell array of size Kx1 (where K is
%           the total number of iterations), and will contain the results of each
%           iteration as returned by your work function.
%   
%       bTotalSuccess - a boolean vector of size Kx1 where each entry
%           corresponds to the success code returned by your work function.
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
%       WGjob.k = should be the original total number of iterations
%       WGjob.nparallels = the original number of parallels the work was split into
%       WGjob.sName = the exact name used for the original job
%
%   Also specifiy the option 'LocalFolder' with the path to where you put
%   the files on your PC/
%
%   Return values: exactly the same as in the regular case.
%
%
%   Written by Stav Yagev, 2013

    
    if (length(varargin) >= 2 && strcmp(varargin(1),'LocalFolder') ...
            && ~isempty(varargin{2}))
        bLocalFolder = true;
        sLocalFolder = varargin{2};
    else
        bLocalFolder = false;
    end
    
    if (~isfield(WGjob,'bLocalDebug'))
        WGjob.bLocalDebug = false;
    end
    if (bLocalFolder || ~WGjob.bLocalDebug)
        nLost = 0;
        WGtotalRes{WGjob.k} = [];
        bTotalSuccess(WGjob.k) = false;
        
        %collect results
        for i=1:WGjob.nparallels
            if (~bLocalFolder)
                fname = sprintf('~/.matlab/cluster_jobs/%s/%s_%do.mat', ...
                    WGjob.q,WGjob.sName,i);
            else
                fname = sprintf([sLocalFolder '\\%s_%do.mat'],WGjob.sName,i);
            end
            
            if (exist(fname, 'file'))
                %load the sub-simulation job data
                load(fname);
                WGtotalRes(krng(1):krng(2)) = WGres;
                bTotalSuccess(krng(1):krng(2)) = bSuccess;
                
            else
                %caluclate the correct k-range
                krng = [(i-1)*ceil(WGjob.k/WGjob.nparallels)+1 ...
                    min(WGjob.k, i*ceil(WGjob.k/WGjob.nparallels))];
                bTotalSuccess(krng(1):krng(2)) = false;
                
                nLost = nLost + krng(2)-krng(1)+1;
            end
        end
    
    else
        WGtotalRes = WGjob.WGres;
        bTotalSuccess = WGjob.bSuccess;

    end

end