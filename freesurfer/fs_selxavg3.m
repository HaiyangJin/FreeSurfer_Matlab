function fscmd = fs_selxavg3(sessidfile, anaList, runwise, runcmd, allCPU)
% fscmd = fs_selxavg3(sessidfile, anaList, [runwise = 0, overwrite = 2, allCPU = 0])
%
% This function runs the first-level analysis for all analysis and contrasts.
%
% Inputs:
%    sessidfile         <string> filename of the session id file. the file 
%                        contains all session codes.
%    anaList            <cell of strings> the list of analysis names.
%    runwise            <logical> 0: run the first-level analysis for all 
%                        runs together [default]; 1: run the analysis for
%                        each run separately.
%    runcmd             <logical> 2: do not overwrite [default]; 1: run and
%                        overwrite the old results; 0: do not run but only
%                        output fscmd.
%    ncores             <logical> 0: only use one CPU [default]; 1: use all 
%                        CPUs. 
%
% Output:
%    fscmd              <cell of string> FreeSurfer commands run in the
%                        current session.
%
% Created by Haiyang Jin (19-Dec-2019)
%
% See also:
% fs_isxconcat, fs_cvn_print1st

% argument for -run-wise
if ~exist('runwise', 'var') || isempty(runwise)
    runwise = 0;
end
run = {'', ' -run-wise'};
runArg = run{runwise + 1};

% argument for -overwrite
if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 2;
end
ow = {'', ' -overwrite', ''};
owArg = ow{runcmd + 1};

% argument for -max-threads
if ~exist('allCPU', 'var') || isempty(allCPU)
    allCPU = 0;
end
cpu = {'', ' -max-threads'};
cpuArg = cpu{allCPU + 1};

% combine the "other" arguments
otherArg = sprintf('%s%s%s', owArg, runArg, cpuArg);

%% Create the FreeSurfer commands
fscmd = cellfun(@(x) sprintf('selxavg3-sess -sf %s -analysis %s %s', ...
    sessidfile, x, otherArg), anaList, 'uni', false);

if runcmd ~= 0
    % run the analysis
    isnotok = cellfun(@system, fscmd);
else
    % do not run fscmd
    isnotok = zeros(size(fscmd));
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

if any(isnotok)
    warning('Some FreeSurfer commands (selxavg3-sess) failed.');
elseif runcmd ~= 0
    fprintf('\nselxavg3-sess finished without error.\n');
end

end