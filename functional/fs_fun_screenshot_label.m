function fs_fun_screenshot_label(projStr, labelList, outputPath, whichOverlay, locSmooth, threshold)
% This function gets the screenshots of labels with overlays.
%
% Inputs:
%    projStr           the proejct structure (e.g., FW)
%    labelList         a list of label names
%    whichOverlay      show overlay of the contrast of which label
%    outputPath       where the labels to be saved
% Output:
%    screenshots in the folder
%
% Created by Haiyang Jin (10/12/2019)

if nargin < 3 
    outputPath = '';
end
if nargin < 4 || isempty(whichOverlay)
    whichOverlay = 1; % show the overlay of the first label by default
end
if nargin < 5 || isempty(locSmooth)
    locSmooth = '';
elseif ~strcmp(locSmooth(1), '_')
    locSmooth = ['_' locSmooth];
end
if nargin < 6 || isempty(threshold)
    threshold = '';
end

% number of labels
nLabels = size(labelList, 1);

% functional information about the structure
subjList = projStr.subjList;
nSubj = projStr.nSubj;
boldext = projStr.boldext;

isfsavg = endsWith(projStr.boldext, {'fsavg', 'fs'});

waitHandle = waitbar(0, 'Generating screenshots for labels...');

for iLabel = 1:nLabels
    
    theLabel = labelList(iLabel, :);
    [hemi, nHemi] = fs_hemi_multi(theLabel);
    
    % move to next loop if the labels are not for the same hemisphere
    if nHemi ~= 1
        continue;
    end

    % get the contrast name from the label name
    if ~whichOverlay
        labelName = theLabel{1};
    else
        labelName = theLabel{whichOverlay};
    end
    theContrast = fs_label2contrast(labelName);

    
    for iSubj = 1:nSubj
        
        % this subject code
        thisBoldSubj = subjList{iSubj};  % bold subjCode
        subjCode = fs_subjcode(thisBoldSubj, projStr.funcPath); % FS subjCode
        
        % waitbar
        progress = ((iLabel-1) * nSubj + iSubj) / (nLabels * nSubj);
        waitMsg = sprintf('Label: %s  SubjCode: %s \n%0.2f%% finished...', ...
            strrep(labelName, '_', '\_'), strrep(subjCode, '_', '\_'), progress*100);
        waitbar(progress, waitHandle, waitMsg);
        
        % other information for screenshots
        analysis = sprintf('loc%s%s.%s', locSmooth, boldext, hemi); % analysis name
        overlayFile = fullfile(projStr.funcPath, thisBoldSubj, 'bold',...
            analysis, theContrast, 'sig.nii.gz'); % the overlay file
        
        % skip if the overlay file is not available
        if ~whichOverlay
            overlayFile = '';
        elseif ~exist(overlayFile, 'file')
            warning('Cannot find the overlay file: %s', overlayFile);
            continue
        end
        
        % create the screenshot
        fs_screenshot_label(subjCode, theLabel, outputPath, overlayFile, threshold, isfsavg);

    end
    
end

close(waitHandle);

