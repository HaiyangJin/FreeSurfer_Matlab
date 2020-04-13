function fscmd = fs_glmfit_perm(glmdir, njobs, nSim, vwthrehold, sign, cwp, spaces, overwrite)
% fscmd = fs_glmfit_perm([glmdir = {'.'}, njobs = 1, nSim = 5000, ...
%    vwthrehold = 3, sign = 'abs', cwp = 0.05, spaces = 2, overwrite = 1])
%
% This function runs permutation to calculate the "p-values" (via 
% mri_glmfit-sim).
%
% Inputs:
%    glmdir        <string> or <cell of strings> path to the glmdir
%                   folders. This can be obtained from fs_glmfit_osgm.m.
%                   [glmdir is the current folder by default.]
%    njobs         <integer> number of jobs to be used for the simulation
%                   (i.e., the simulation [permutation] are divided into
%                   njobs). [Default is 1].
%    nSim          <integer> number of simulations. [Default is 5000].
%    vwthrehold    <numeric> voxel[vertex]-wise (clutering form) threshold. 
%                   -log(p). [Default is 2 (i.e., p < .01)].
%    sign          <string> the direction of the test. ['pos', 'neg',
%                   'abs']. [Default is 'abs'].
%    cwp           <numeric> cluster-wise p-value threshold. [Default is
%                   0.05].
%    spaces        <integer> 2 or 3. Additional Bonferroni correction 
%                   across 2 spaces (eg, lh, rh) or 3 (eg, lh, rh, mni305).
%                   [Default is 2].
%    overwrite     <logical> 1: overwrite the permuation. 0: do not
%                   overwrite the permutation run before.
%
% Output:
%    fscmd         <cell of strings> The first column is FreeSurfer 
%                   commands used in the current session. And the second 
%                   column is whether the command successed. 
%                   [0: successed; other numbers: failed.] 
%
% Created by Haiyang Jin (12-Apr-2020)

if nargin < 1 || isempty(glmdir)
    glmdir = {'.'};
elseif ischar(glmdir)
    glmdir = {glmdir};
end

if nargin < 2 || isempty(njobs)
    njobs = 1;
end

if nargin < 3 || isempty(nSim)
    nSim = 5000; % nsim vwthreshold sign
end

if nargin < 4 || isempty(vwthrehold)
    vwthrehold = 3; % voxel-wise (clutering form) threshold 
end

if nargin < 5 || isempty(sign)
    sign = 'abs';  
end

if nargin < 6 || isempty(cwp)
    cwp = .05;  % cluster-wise p-value threshold 
end

if nargin < 7 || isempty(spaces)
    spaces = 2;
end

if nargin < 8 || isempty(overwrite)
    overwrite = 1;
end

if overwrite
    ow = ' --overwrite';
else
    ow = '';
end    

% parameters for permutation
bg = sprintf(' --bg %d', njobs);
perm = sprintf('%d %d %s', nSim, vwthrehold, sign);

% create FreeSurfer commands
fscmd = cellfun(@(x) sprintf(['mri_glmfit-sim --glmdir %s --perm %s '...
    ' --cwp %d  --%dspaces %s%s'], x, perm, cwp, spaces, bg, ow), ...
    glmdir, 'uni', false); 

% run commands 
isnotok = cellfun(@system, fscmd);
if any(isnotok)
    warning('Some FreeSurfer commands (mri_glmfit) failed.');
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

end