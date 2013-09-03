%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sample.m - Sample usage of WeizGrid
%
%   Together with 'calcPrimes' this is a very simple example of 
%   using WeizGrid. 
%
%   In this example we have 50 different values for parameters
%   X and Y. For each set of values we run 20 tests which take
%   the average of X and Y and check which prime factors the
%   result has in common with a random integer.
%   
% By Stav Yagev, 2013


%% Part 1: General Usage %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


%STEP 1: Setup the parameters for each sub-work into a cell array of structs

%setup parameters that are relevant for all iterations
%TODO: include in this structure any variables you want available in all the sub-iterations
WGglobalParam.bCount1AsAFactor = false;

%preallocate the parameters structure array
%TODO: change to the total number of tests you are performing
clear WGsubParam;
WGsubParam(50) = struct;

for i=1:length(WGsubParam)
    %TODO: change to your own set of parameters neccessery for each sub-iteration
    WGsubParam(i).X = randi(intmax,1);
    WGsubParam(i).Y = randi(intmax,1);
    
    %this tells WG grid to execute this specific set of sub-paramaters 20 times
    WGsubParam(i).k = 20;
end



%STEP 2: Invoke WG:

%TODO: replace 'calcPrimes' with your private work function, and change the
%       rest of the parameters as you see fit
tic;
WGjob = WGexec('nparallels', 100, 'Name', 'PCRK', ...
    'WorkFunc', 'calcPrimes', 'LocalDebug', false, 'GlobalParams', WGglobalParam, ...
    'SubParams', WGsubParam, 'RngShuffle', true, 'WaitTillFinished', true); 
    %Please right click on 'WGexec' for help on this function



%STEP 3: Aggregate results:

[WGresults, bSuccess] = WGgetResults(WGjob);    %right click on 'WGgetResults' for help

%TODO: do whatever you want with the results
fprintf('Done in %d seconds\n',round(toc));

bDone = false;
for j = 1:length(WGresults)
    for k = 1:length(WGresults{j})
        if (bSuccess{j}(k))
            fprintf('\nIteration #%d for sub-parameters set #%d succeeded!\n', k,j);

            disp('And the result was:');
            WGresults{j}{k}
            
            bDone = true;
            break;
        end
    end
    
    if (bDone)
        break;
    end
end




%% Part 2: Recovering from failure %%%%%%%%%%%%%%%%%%%%%% 

%in case you hade a bug in your aggregation, then you might not have saved
%all the results from the different sub-works. To recover from this case
%copy all the files from the following UNIX directory to somewhere on your PC
%   ~/.matlab/cluster_jobs/yourq.q/

% sTempDir = 'S:\\Expendable\\Temp';   %this is where you saved the files
% 
% %call the get results (which will return immediatley) with the local
% %option. We need to specify some extra information since the original job
% %was lost
% WGjob.k(1:length(WGsubParam)) = WGsubParam(:).k;    %the original k values for each sub-parameters set
% WGjob.nparallels = 3;               %orignal number of parallels the job was split to
% WGjob.sName = 'ParallelCracker';    %the original job's name
% [WGresults, bSuccess, nLost] = WGgetResults(WGjob, 'LocalFolder', sTempDir);
% 
% %TODO: do whatever you want with the results
% fprintf('%d iterations failed and could not be recovered\n',nLost);
% bDone = false;
% for j = 1:length(WGresults)
%     for k = 1:length(WGresults{j})
%         if (bSuccess{j}(k))
%             fprintf('\nIteration #%d for sub-parameters set #%d succeeded!\n', k,j);
% 
%             disp('And the result was:');
%             WGresults{j}{k}
%             
%             bDone = true;
%             break;
%         end
%     end
%     
%     if (bDone)
%         break;
%     end
% end

