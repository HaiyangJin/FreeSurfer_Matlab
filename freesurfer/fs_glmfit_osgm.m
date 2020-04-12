function [glmdir, fscmd] = fs_glmfit_osgm(contraPath, yFilename, outFolder)
% [glmdir, fscmd] = fs_glmfit_osgm(contraPath, yFilename, outFolder)
%
% This function runs one-sample group mean (osgm) glm analysis (via
% mri_glmfit).
%
% Inputs:
%    contraPath        <string> or <cell of strings> the path to all the
%                       contrast folders. OR
%                      <struct> the struct include analysis, contrast and
%                       group names. [generated by fs_isxconcat.m]
%    yFilename         <string> the filename of dependent variable.
%                       [ces.nii.gz by default.]
%    outFolder         <string> name of the folder where glm results will
%                       be saved. [for --glmdir]. ['glm-group' by default.]
%
% Output: 
%    glmdir            <cell of strings> full path to glmdir folders. [This
%                       will be needed for fs_glmfit_sim.m.]
%    fscmd             <cell of strings> The first column is FreeSurfer 
%                       commands used in the current session. And the  
%                       second column is whether the command successed. 
%                       [0: successed; other numbers: failed.] 
%
% Created by Haiyang Jin (12-Apr-2020)

if nargin < 2 || isempty(yFilename)
    yFilename = 'ces.nii.gz';
end

if nargin < 3 || isempty(outFolder)
    outFolder = 'glm-group';
end

% obtain the path to contrast folders
if isstruct(contraPath)
    funcPath = getenv('FUNCTIONALS_DIR');
    conPaths = fullfile(funcPath, {contraPath.group}, {contraPath.analysisName}, ...
        {contraPath.contrastName}, filesep);
else
    if ischar(contraPath); contraPath = {contraPath}; end
    conPaths = fullfile(contraPath, filesep);
end

% template and hemi for the y filename(s)
templates = fs_2template(conPaths);
hemi = fs_2template(conPaths, {'lh', 'rh'});

% the argument for running analysis for surface
if ismember(hemi, {'lh', 'rh'})
    fscmd_surf = cellfun(@(x, y) sprintf(' --surface %s %s', x, y), ...
        templates, hemi, 'uni', false);
else
    fscmd_surf = repmat({''}, size(hemi));
end

% create FreeSurfer commands
fscmd = cellfun(@(x, y) sprintf(['mri_glmfit --y %1$s%2$s' ... % the input values to analyze
    '%3$s' ... % indicates surface-based data (not used for volume data)
    ' --osgm' ... % use One-Sample Group Mean
    ' --glmdir %1$s%4$s' ... % output directory
    ' --save-eres' ... % save residual error (needed with permutation)
    ' --nii.gz'],... % use compressed NIFTI as output format
    x, yFilename, y, outFolder), conPaths, fscmd_surf, 'uni', false);
% Note --wls is no longer recommended because it is incompatible with permutation

% run commands 
isnotok = cellfun(@system, fscmd);
if any(isnotok)
    warning('Some FreeSurfer commands (mri_glmfit) failed.');
end

% make the fscmd one column
fscmd = [fscmd; num2cell(isnotok)]';

% full path to glmdir
glmdir = fullfile(conPaths, outFolder);

end