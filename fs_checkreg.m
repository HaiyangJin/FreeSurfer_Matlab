function output = fs_checkreg(project, sessCode, isSort)
% This function check the co-registration conducted by prepro-sess.
%
% Inputs:
%     project            <struct> the project information. Created by fs_fun_projinfo.m.
%     sessCode           <string> or <a cell of strings> session codes
%     isSort             <logical> sort the results by the quality (last
%                        column)
% Output:
%     output             a cell of registration quality if isSort is true.
%                        Otherwise output is empty.
%
% Created by Haiyang Jin (26-Jan-2020)

if nargin < 1 || isempty(project)
    funcPath = getenv('FUNCTIONALS_DIR');
else
    funcPath = project.funcPath;
end

if nargin < 2 || isempty(sessCode)
    sessCode = project.sessList;
elseif ischar(sessCode)
    sessCode = {sessCode};
end

if nargin < 3 || ismepty(isSort)
    isSort = 0;
end

% creat the commands for checking co-registration
wdBackup = pwd;
cd(funcPath);

fscmd = cellfun(@(x) sprintf('tkregister-sess -s %s -fsd bold -per-run -bbr-sum',...
    x), sessCode, 'uni', false);

if isSort
    % run cmds and save the results
    [isok, cmdOutput] = cellfun(@system, fscmd, 'uni', false);
    
    % make sure the commands were performed successfully
    assert(all(~[isok{:}]), 'The ''tkregisgter-sess'' failed for some sessions.');
    
    %% sort out the results
    % replace ? with space
    tempOutput = cellfun(@(x) strrep(x, '?', ' '), cmdOutput, 'uni', false);
    
    % divided a row of strings into multiple strings
    tempStrings = cellfun(@(x) reshape(regexp(x, '\w*\S', 'match'), 4, [])', tempOutput, 'uni', false);
    
    % combine the third and forth columns as a new column
    strings = cellfun(@(z) horzcat(z(:, 1:2), cellfun(@(x, y) [x y], z(:, 3), z(:, 4), 'uni', false)),...
        tempStrings, 'uni', false);
    
    % combine the output from multiple sessions and multiple runs
    output = vertcat(strings{:});
    
    output = sortrows(output, 3, 'descend'); 
    
else
    % only run the cmds but donot save anything
    output = '';
    cellfun(@system, fscmd);
end

% fprintf('Please do the registration manually if any number is larger than 0.8.\n');
cd(wdBackup);
end