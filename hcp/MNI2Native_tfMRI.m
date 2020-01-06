function MNI2Native_tfMRI(HCP_path, sessStr)
% This function was built based on MNI2Native.sh (created by Osama Abdullah
% on 9/9/18), which converts the functional (bold) data from MNI space to
% native space (with FSL functions).
%
% Inputs:
%    HCP_path       path to the HCP results ('Path/to/HCP/') [Default is the
%                   current working directory]
%    sessStr        strings (or prefix) for session information (e.g.,
%                   'faceword' is the prefix for 'faceword01', 'faceword02',
%                   'faceword03'. sessStr will help to identify all the 
%                   session folders. In order to perform this
%                   transformation for only one session, just set the sessStr 
%                   as the full name of the session name (e.g., 'faceword01').
% Output:
%    files of functional (bold) data on native space.  
% Dependency:
%    FSL  (Please make sure FSL is installed and sourced properly.)
%
% Created by Haiyang Jin (5/01/2020) (Based on MNI2Native.sh which was 
% created by Osama Abdullah on 9/09/18).

% check if FSL is sourced properly
if isempty(getenv('FSLDIR'))
    error('Please make sure FSL is installed and sourced properly.');
end

if nargin < 1 || isempty(HCP_path)
    HCP_path = '.';
end
if nargin < 2 || isempty(sessStr) || strcmp(sessStr, '.')
    
    % all the folders in HCP path
    tmpSessDir = dir(HCP_path);
    tmpSessList = {tmpSessDir.name};
    
    % the string parts of all folder names
    numericParts =  regexp(tmpSessList, '\d+', 'match');
    stringParts = cellfun(@(x, y) erase(x, y), tmpSessList, numericParts, 'uni', false);
    
    % information of string parts
    [uc, ~, idc] = unique(stringParts) ;
    counts = histcounts(idc);

    % the most frequent string will be used as the prefix
    [~, whichStr] = max(counts);
    sessStr = uc{whichStr};
  
end
% add '*' if last letter is not '*'
if sessStr(end) ~= '*' && ~strcmp(sessStr, '.')
    sessStr = [sessStr, '*'];
end


%% identify all sessions (folders) match sessStr
sess_dir = dir(fullfile(HCP_path, sessStr));

% % remove folders whose superfolder (parent folder) is not HCP_path
% sess_dir(~strcmp({sess_dir.folder}, HCP_path)) = []; 

if isempty(sess_dir)
    error('No sessions were found for %s in %s.', sessStr, HCP_path);
end

sessList = {sess_dir.name};
nSess = numel(sessList);

fileType = {'', '_SBRef'};

for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    sess_path = fullfile(HCP_path, thisSess);
    
    % downsample T2w in native space to fMRI resolution
    flirt_cmd = sprintf(['flirt -in %1$s/T1w/T2w_acpc_dc_restore_brain '...
        '-ref %1$s/T1w/T2w_acpc_dc_restore_brain -applyisoxfm 2 '...
        '-out %1$s/T1w/T2w_acpc_dc_restore_brain_2mm'], sess_path);
    system(flirt_cmd);
    
    % transform BOLD data from MNI space to Native Space
    results_path = fullfile(sess_path, 'MNINonLinear', 'Results');
    bold_dir = dir(fullfile(results_path, 'tfMRI_*'));
    boldList = {bold_dir.name};

    % filenames of all bold data to be transformed
    boldArray = repmat(boldList, numel(fileType), 1);
    fileArray = repmat(fileType', 1, numel(boldList));
    filenameMNI = cellfun(@(x, y) fullfile(results_path, x, [x,y]), boldArray(:), fileArray(:), 'uni', false');
    
    % the cell of all functions
    cmds = cellfun(@(x) sprintf(['echo "Transforming from MNI to Native: "%1$s.nii.gz;'...
        'applywarp --rel --interp=trilinear '...
        '-i %1$s.nii.gz -r %2$s/T1w/T2w_acpc_dc_restore_brain_2mm '...
        '-w %2$s/MNINonLinear/xfms/standard2acpc_dc -o %1$s_native.nii.gz'],...
        x, sess_path), filenameMNI, 'uni', false);
    % run all functions
    cellfun(@system, cmds);

end

end