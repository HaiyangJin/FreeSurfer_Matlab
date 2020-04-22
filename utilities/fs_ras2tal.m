function outpoints = fs_ras2tal(inpoints, subjCode, struPath)
% outpoints = fs_ras2tal(inpoints, subjCode)
%
% This function converts self RAS to Talairach coordinates. But the output
% is not exactly he Talairach coordinates, see:
% (https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems).
%
% In TkSurfer:
%    Vertex Talairach = fs_ras2tal(Vertex RAS, subjCode);
% In TkMedit:
%    Volume Talairach = fs_ras2tal(Volume RAS, subjcode);
%
% Inputs:
%    inpoints        <numeric array> RAS on self surface [real world].
%    subjCode        <string> subject code in struPath.
%    struPath        <string> $SUBJECTS_DIR.
%    
% Output:
%    outpoints       <numeric array> cooridnates in Talairach space. 
%
% Created by Haiyang Jin (13-Nov-2019)

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% from Vertex RAS (or Volume RAS) to MNI305 RAS (fsaverage or MNI Talairach)
outpoints1 = fs_ras2fsavg(inpoints, subjCode, struPath);

% from MNI305 RAS (fsaverage or MNI Talairach) to Talairach
outpoints = mni2tal(outpoints1);

end