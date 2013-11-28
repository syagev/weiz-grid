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
%   nparallels - Into how many parallel cluster-jobs do you want to split the work.
%       If for example you have a total of 1000 iterations and you set nparallels to
%       115, each cluster-job spawned will process 9 iterations (rounded up). Usually
%       just set this to the amount of quota you have, note that the job quota on 
%       the CS department's cluster at Weizmann on the day of publishing this code was 115.
%       NOTE: If WaitTillFinished is true, 1 job is dedicated to spawning the
%           jobs and waiting on results. So in the above example 114 jobs
%           will do the actual work.
%       NOTE: WeizGrid may decide to use less actual jobs than your quota
%           due to rounding.
%   
%   WorkFunc - The name of your function that does the work. It must have
%       the following signature:
%           function [WGres,bSuccess] = doOneIteration(WGglobalParam, WGsubParam, j, k)
%
%       The WG engine will inject into WGglobalParam the global parameters
%       you set when calling this function, in WGsubParam you will have the
%       parameters for a particular iteration, in j the index of the set of 
%       sub parameters and in k the index of the iteration. The function is 
%       expected to return some result which can later be collected with 
%       WGgetResults, and a success boolean value. This success value can be 
%       later used when aggregating results for the purpose of filtering out 
%       "bad" results.
%
%   SubParams - This should be an array of structures. Every structure can hold an
%       optional field 'k' which determines how many iterations will be performed
%       with the specified set of paramaters. If the 'k' field is not speicifed, the
%       the default will be taken as 1. The total number of iterations is therefore the
%       sum of the 'k's of all sub-params. The work function will have to process
%       one entry out of this array at a time.
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
%   Que (Default: queue specified with qsubWG) - Setting this parameter
%       with a name of a queue can optionally submit the child jobs to a
%       different queue than that specified with the qsubWG UNIX command. This
%       way for example child jobs can run on a "cheap" low-memory and short-length 
%       while the aggregation can be done on high-memory queue.
%
%   Mail (Default: empty) - If this parameter is set with an e-mail address
%       then the e-mail is notified once the job is done (in Debug mode)
%       this option is ignored.
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
    sEmail = [];
        
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
                WGjob.j = length(WGallSubParams);
                iMandatory = iMandatory + 1;
            case 'GlobalParams'
                WGglobalParams = value; %#ok<NASGU>
            case 'WaitTillFinished'
                bWait = value;
            case 'RngShuffle'
                bRngShuffle = value;
            case 'Que'
                WGjob.q = value;
            case 'Mail'
                sEmail = [' -m ea -M ' value];
            otherwise
                error(['Unknown option "' name]);
        end
    end
    if (iMandatory < 4)
        error('One of the 4 mandatory property/value pairs is missing');
    end
    
    
    WGjob.k = zeros(WGjob.j,1);

    %check if doing work locally or not
    if (WGjob.bLocalDebug)
        if (bRngShuffle)
            rng('shuffle');
        end
        
        WGjob.WGres = cell(WGjob.j,1);
        WGjob.bSuccess = cell(WGjob.j,1);
        for j=1:WGjob.j
            if (isfield(WGallSubParams(j),'k'))
                WGjob.k(j) = WGallSubParams(j).k;
            else
                WGjob.k(j) = 1;
            end
            
            WGjob.bSuccess{j} = false(WGjob.k(j),1);
            WGjob.WGres{j} = cell(WGjob.k(j),1);
            
            for k=1:WGjob.k(j)
                [WGjob.WGres{j}{k},WGjob.bSuccess{j}(k)] = ...
                    eval([sWorkFunc '(WGglobalParams, WGallSubParams(j), j, k)']);
            end
        end
        
    else   
        %create a "flat" assignment matrix
        iTotalK = 0;
        for j = 1:WGjob.j
            if (isfield(WGallSubParams(j),'k'))
                WGjob.k(j) = WGallSubParams(j).k;
            else
                WGjob.k(j) = 1;
            end
            vKInd = 1:WGjob.k(j);
            
            mAssignment(vKInd + iTotalK,1) = j; %#ok<AGROW>
            mAssignment(vKInd + iTotalK,2) = vKInd; %#ok<AGROW>
            
            iTotalK = iTotalK + WGjob.k(j);
        end
        
        %if we are waiting then 1 job is dedicated to the aggregation
        if (bWait)
            WGjob.nparallels = WGjob.nparallels - 1;
        end
             
        for i=1:WGjob.nparallels
            
            %caluclate the correct k-range
            jkrng = [(i-1)*ceil(iTotalK/WGjob.nparallels)+1 ...
                    min(iTotalK, i*ceil(iTotalK/WGjob.nparallels))]; 
            mAssRng = mAssignment(jkrng(1):jkrng(2),:);
                
            %save the simulation data to a unique file
            WGsubParams = WGallSubParams(mAssRng(1,1):mAssRng(end,1)); %#ok<NASGU>
            save(sprintf('~/.matlab/cluster_jobs/%s/%s_%di',WGjob.q,WGjob.sName,i), ...
                'WGglobalParams', 'bRngShuffle', 'WGsubParams', 'mAssRng');
            
            %submit a job for this sub simulation to SGE
            system(sprintf(['qsub -o out/%s_%d.o -e out/%s_%d.e -cwd -q %s -V -N %s_%d ' ...
                '~/WeizGrid/dowork %s %s %d %s'], ...
                WGjob.sName, i, WGjob.sName, i, WGjob.q, WGjob.sName, i, WGjob.q, ...
                WGjob.sName, i, sWorkFunc));
            
            %less maybe enough due to rounding
            if (jkrng(2) == iTotalK)
                break;
            end
        end
        
        %use an empty job to wait for all sub-simulations to finish, if
        %bWait is enabled then add syncing
        if (bWait)
            sSync = '-sync yes';
        else
            sSync = [];
        end
        pause(10);
        system(sprintf('qsub -cwd -o /dev/null -e /dev/null -q %s %s -V %s -hold_jid "%s_*" -N %s_w ~/WeizGrid/empty', ...
            WGjob.q, sEmail, sSync, WGjob.sName, WGjob.sName));
                
    end
    
end