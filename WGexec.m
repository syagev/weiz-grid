function [WGjob] = WGexec( varargin )
%WGexec Executes a job in a parallel fashion using WeizGrid
%   This is the core function of WeizGrid, after you've setup an array of
%   parameters for your iterations, call this method and the WG will spawn
%   jobs to parallelize your work. Specifiy the following mandatory
%   name/value pairs:
%   
%   Name - The name for the whole show. This will be used for file and job
%       naming on the cluster. IT MUST NOT CONTAIN SPACES OR SPECIAL CHARACHTERS.
%
%   nparallels - Into how many cluster-jobs do you want to split the work.
%       If for example you have 1000 iterations and you use 5, each sub-job
%       spawned will process 200 iterations. Note that the job quota on
%       Weizmann on the day of publishing this code was 80.
%   
%   WorkFunc - The name of your function that does the work. It must have
%       the following signature:
%           function [WGres,bSuccess] = doOneIteration(WGglobalParam, WGsubParam, k)
%
%       The WG engine will inject into WGglobalParam the global parameters
%       you set when calling this function, in WGsubParam you will have the
%       parameters for a particular iteration, and in k the number of the
%       iteration. The function is expected to return some result which can
%       later be collected with WGgetResults, and a success boolean value.
%       This success value can be later used when aggregating results for
%       the purposing of filtering out "bad" results.
%
%   SubParams - This should be an array of structures. It's length
%       determines the number of total iterations. The k'th entry will be
%       made availble to the work function that will process the k'th
%       iteration.
%   
%   GlobalParams (Default: Empty matrix) - This can be any MATLAB entity which 
%       will be made available to the work function for all iterations.
%
%   LocalDebug (Default: false) - When set to true the WG engine will simply 
%       execute your iterations localy (without splitting to sub-jobs). This 
%       useful feature allowd you to use THE EXACT SAME CODE when debuging on 
%       your PC or when running on the cluster. 
%
%   WaitTillFinished (Default:true) - If set to true, the function will return 
%       only after all sub-jobs have completed. Use this when aggregating results.
%       IF YOU ATTEMPT TO CALL WGgetResults AFTER A CALL TO WGexec WITHOUT THIS 
%       OPTION YOU MUST ENSURE BY YOURSELF ALL SUB-JOBS ON THE CLUSTER FINISHED
%       OTHERWISE BEHAVIOUR IS UNPREDICTABLE!
%
%   RngShuffle (Default:true) - Because your job is split, every parallel piece 
%       of work will by MATLAB's default behaviour generate the same series of 
%       random numbers. To remedy this, set this to true so that
%       rng('shuffle') is invoked on every piece of parallel work.
%
%   Return value: The functions returns a structure identifying the job
%       which can be used when calling WGgetResults.
%
%
%   Written by Stav Yagev, 2013
    
    global WGq;
    WGjob.q = WGq;
    WGjob.bLocalDebug = false;
    bWait = true;
    WGglobalParams = []; %#ok<NASGU>
    bRngShuffle = true;
        
    iMandatory = 0;
    for i = 1 : 2 : length(varargin)
        name = varargin{i};
        value = varargin{i+1};
        switch name
            case 'nparallels'
                WGjob.nparallels = value;
                iMandatory = iMandatory + 1;
            case 'Name'
                WGjob.sName = value;
                iMandatory = iMandatory + 1;
            case 'WorkFunc'
                sWorkFunc = value;
                iMandatory = iMandatory + 1;
            case 'LocalDebug'
                WGjob.bLocalDebug = value;
            case 'SubParams'
                WGallSubParams = value;
                WGjob.k = length(WGallSubParams);
                iMandatory = iMandatory + 1;
            case 'GlobalParams'
                WGglobalParams = value; %#ok<NASGU>
            case 'WaitTillFinished'
                bWait = value;
            case 'RngShuffle'
                bRngShuffle = value;
            otherwise
                error(['Unknown option "' name]);
        end
    end
    if (iMandatory < 4)
        error('One of the 4 mandatory property/value pairs is missing');
    end
    
    
    %check if doing work locally or not
    if (WGjob.bLocalDebug)
        if (bRngShuffle)
            rng('shuffle');
        end
        
        WGjob.WGres{WGjob.k} = [];
        WGjob.bSuccess(WGjob.k) = false;
        for k=1:WGjob.k
            [WGjob.WGres{k},WGjob.bSuccess(k)] = ...
                eval([sWorkFunc '(WGglobalParams, WGsubParams(k), k)']);
        end
        
    else   
        
        for i=1:WGjob.nparallels
            %caluclate the correct k-range
            krng = [(i-1)*ceil(WGjob.k/WGjob.nparallels)+1 ...
                    min(WGjob.k, i*ceil(WGjob.k/WGjob.nparallels))]; 
            
            %save the simulation data to a unique file
            WGsubParams = WGallSubParams(krng(1):krng(2)); %#ok<NASGU>
            save(sprintf('~/.matlab/cluster_jobs/%s/%s_%di',WGq,WGjob.sName,i), ...
                'WGsubParams', 'WGglobalParams', 'krng', 'bRngShuffle');
            
            %submit a job for this sub simulation to SGE
            system(sprintf('qsub -cwd -q %s -V -N %s_%d ~/WeizGrid/dowork %s %s %d %s', ...
                WGq, WGjob.sName, i, WGq, WGjob.sName, i, sWorkFunc));
        end
        
        if (bWait)
            %use an empty job to wait for all sub-simulations to finish
            pause(10);
            system(sprintf('qsub -cwd -q %s -V -sync yes -hold_jid "%s_*" -N %s_w ~/WeizGrid/empty', ...
                WGq, WGjob.sName, WGjob.sName));
        end
    end
    
end