function fs_hcp_runlistfile(boldPath)
% This function reads the run_info.txt generated by fs_hcp_prepro and 
% creates the run list files.
%
% Input:
%    boldPath       path to the bold folder
% Output:
%    run list files in the bold folder
%
% Created by Haiyang Jin (6-Jan-2020)

if nargin < 1 || isempty(boldPath)
    boldPath = pwd;
end

% load run_info.txt
runInfo = readtable(fullfile(boldPath, 'run_info.txt'), 'Delimiter', ',',...
    'Format','%s%s');

%% find unique task names and numbers
% the unique strings of run names
runNums = cellfun(@(x) regexp(x, '\d+', 'match'), runInfo.RunName);
[taskNames, ~, groupNum] = unique(cellfun(@(x, y) erase(x, y), runInfo.RunName, runNums, 'uni', false));

% classify runs into different types (loc and main(s))
nTask = numel(taskNames);
mainCell = cell(nTask-1, 1);
mainNum = 0;
for iTask = 1:nTask
    
    thisTaskName = taskNames{iTask};
    if contains(thisTaskName, 'loc', 'IgnoreCase', true)
        % runs are treated as loc runs if the run names contains 'loc'
        locList = groupNum == iTask;
    else
        % other runs are treated as main runs
        mainNum = mainNum + 1;
        mainCell(mainNum, 1) = {groupNum == iTask};
    end
    
end

%% Create run list files
% backup directory
wdBackup = pwd;
cd(boldPath);

% loc runs
createrunlistfile('run_loc', runInfo, locList);

% main runs
if mainNum == 1 % if there is only one task (main) run
    
    createrunlistfile('run_main', runInfo, mainCell{1, 1});
    
elseif mainNum > 1 % if there are more than one tasks
    
    arrayfun(@(x) createrunlistfile(sprintf('task%d_run_main', x), ...
        runInfo, mainCell{x, 1}), 1:mainNum, 'uni', false);
end

% change back to the backup working directory
cd(wdBackup);

end


function createrunlistfile(runType, runInfo, logicalList) 

% create run list files for each run separately
arrayfun(@(x,y) fs_createfile([runType num2str(x) '.txt'],...
    y), 1:sum(logicalList), runInfo{logicalList, 'RunCode'}', 'uni', false);

% create run list file for all runs together
fs_createfile([runType '.txt'], runInfo{logicalList, 'RunCode'});

end