%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sample.m - Sample usage of WeizGrid
%
%   Together with 'calcPrimes' this is a very simple example of 
%   using WeizGrid. 
%
%   In this example we have 1000 different values for parameters
%   X and Y, for each set of values we check which prime factors
%   X and Y have in common.
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
end



%STEP 2: Invoke WG:

%TODO: replace 'calcPrimes' with your private work function, and change the
%       rest of the parameters as you see fit
WGjob = WGexec('nparallels', 3, 'Name', 'ParallelCracker', ...
    'WorkFunc', 'calcPrimes', 'LocalDebug', false, 'GlobalParams', WGglobalParam, ...
    'SubParams', WGsubParam, 'RngShuffle', true, 'WaitTillFinished', true); 
    %Please right click on 'WGexec' for help on this function



%STEP 3: Aggregate results:

[WGresults, bSuccess] = WGgetResults(WGjob);    %right click on 'WGgetResults' for help

%TODO: do whatever you want with the results
disp('The following iterations succeeded:');
goodResults = find(bSuccess)
fprintf('And the result from iteration #%d is:\n',goodResults(1));
WGresults{goodResults(1)}



%% Part 2: Recovering from failure %%%%%%%%%%%%%%%%%%%%%% 

% %in case you hade a bug in your aggregation, then you might not have saved
% %all the results from the different sub-works. To recover from this case
% %copy all the files from the following UNIX directory to somewhere on your PC
% %   ~/.matlab/cluster_jobs/yourq.q/
% 
% sTempDir = 'S:\\Expendable\\Temp';   %this is where you saved the files
% 
% %call the get results (which will return immediatley) with the local
% %option. We need to specify some extra information since the original job
% %was lost
% WGjob.k = 50;           %total number of iterations
% WGjob.nparallels = 3;   %orignal number of parallels the job was split to
% WGjob.sName = 'ParallelCracker';    %the original job's name
% [WGresults, bSuccess] = WGgetResults(WGjob, 'LocalFolder', sTempDir, ...
%     'nparallels',3,'TotalIterations',50);
% 
% %TODO: do whatever you want with the results
% disp('The following iterations succeeded:');
% goodResults = find(bSuccess)
% fprintf('And the result from iteration #%d is:\n',goodResults(1));
% WGresults{goodResults(1)}

