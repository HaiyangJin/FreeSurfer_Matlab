function dt_sl = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
% dt_sl = fs_cosmo_cvsl(ds, classPairs, surfDef, sessCode, anaName, varargin)
%
% This function performs the searchlight analysis with cosmoMVPA.
%
% Inputs:
%    ds              <structure> cosmo dataset.
%    classPairs      <cell of strings> the pairs to be classified for the
%                     searchlight; a PxQ (usually is 2) cell matrix for
%                     the pairs to be classified. Each row is one
%                     classfication pair.
%    surf_def        <cell of numeric array> surface denitions. The first
%                     element is the array of vertex number and coordiantes;
%                     the second element is the array of face number and
%                     vertex indices. Both can be obtained by
%                     fs_cosmo_surfcoor. More information can be found in
%                     cosmo_surficial_neighborhood.m .
%    sessCode        <string> subject code in $FUNCTIONALS.
%    anaName         <string> analysis name.
%
% Varargin:
% %%%%% cosmo_surficial_neighborhood settings %%%%%%%%%%%%%%%%
%    'metric'        <string> the method used for neighboor. Options are
%                     'geodesic' [default], 'dijkstra', 'Euclidean'.
%    'radius'        <numeric> the radius in mm. Default is 0.
%    'count'         <integer> number of features to be used for each
%                     decoding. Default is 0.
% %%%%% cosmo_searchlight settings %%%%%%%%%%%%%%%%
%    'measure'       <funtion handel> the function/analysis to be run. The
%                     avaiable options are: @cosmo_crossvalidation_measure
%                     [default], @cosmo_correlation_measure,
%                     @cosmo_target_dsm_corr_measure.
%    'centerids'     <intger vector> center indices. Default is [], i.e.,
%                     excludes vertices outside the brain mask.
%    'nproc'         <integer> number of processors if Matlab parallel
%                     processing toolbox is available. Default is 1.
% %%%%% cross-validation settings %%%%%%%%%%%%%%%%
%    'partitioner'   <function handle> the method to set partition
%                     datasets. Available options for corss-validation are:
%                     @cosmo_nfold_partitioner [default],
%                     @cosmo_nchoosek_partitioner,
%                     @cosmo_balance_partitioner,
%                     @cosmo_oddeven_partitioner (will be used if 'measure'
%                     is @cosmo_correlation_measure).
%    'classifier'    <numeric> or <strings> or <cells> the classifiers
%                     to be used (only 1).
% %%%%% other settings %%%%%%%%%%%%%%%%
%    'applyuseless'  <logical> apply cosmo_remove_useless_data to ds.
%                     Default is 1.
%    'applycortex'   <logical> only run searchlight on vertices in the
%                     ?h.cortex.label. Default is 1.
%    'outprefix'     <string> strings to be added at the beginning of the
%                     ouput folder (the pseudo-analysis folder). Default is
%                     'sl'.
%    'maskedvalue'   <numeric> the default (accuracy) values for masked
%                     vertices. Default is -999.
%    'nbrstr'        <string> strings to be added to the nbr files. Default
%                     is ''.
%    'funcPath'      <string> where to save the output. Default is
%                     $FUNCTIONALS_DIR.
%
% Output:
%    dt_sl           <structure> data set of the searchlight results.
%    For each hemispheres, the results will be saved as a *.mgz file in
%    funcPath/sessCode/bold/analysisFolder/contrastFolder/.
%    For the whole brain, the results will be saved as *.gii.
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (15-Dec-2019)

% default options
defaultOpt=struct(...
    ... %%% cosmo_surficial_neighboor settings %%%%
    'metric', 'geodesic', ...
    'radius', 0, ... % in mm
    'count', 0, ...
    ... %%% cosmo_searchlight settings %%%
    'measure', @cosmo_crossvalidation_measure, ...
    'centerids', [], ... % all indices.
    'nproc', 1, ...
    ... %%% cross-validation settings %%%
    'partitioner', @cosmo_nfold_partitioner, ...
    'classifier', '', ... % libsvm will be used.
    ... %%% other settings %%%
    'applyuseless', 1, ...
    'applycortex', 1, ...
    'outprefix', 'sl', ...
    'maskedvalue', -999, ...
    'nbrstr', '', ...
    'funcpath', getenv('FUNCTIONALS_DIR') ...
    );

% parse options
options=fs_mergestruct(defaultOpt, varargin{:});
%%% cosmo_surficial_neighboor %%%
metric = options.metric; % 'euclidean'; % method used for distance
radius = options.radius;
count = options.count;
%%% cosmo_searchlight %%%
measure = options.measure;
center_ids = options.centerids;
nproc = options.nproc;
%%% crossvalidation settings %%%
classifier = options.classifier;
partitioner = options.partitioner;
%%% other settings %%%
applyUseless = options.applyuseless;
applyCorterx = options.applycortex;
outPrefix = options.outprefix;
maskedValue = options.maskedvalue;
nbrStr = options.nbrstr;
funcPath = options.funcpath;

% pre-process classifer
if isempty(classifier)
    [classifier, ~, shortName, nClass] = cosmo_classifier;
else
    [classifier, ~, shortName, nClass] = cosmo_classifier(classifier);
end
% error if multiple classifiers are chosed
if nClass ~= 1
    error('Please choose only one classifier for search light analysis here.');
else
    classifier = classifier{1}; % convert cell to string
end

template = fs_2template(anaName, '', 'fsaverage');
hemi = fs_2template(anaName, {'lh', 'rh'}, 'both');

% decide whose surface information will be used
subjCode = fs_subjcode(sessCode, funcPath);
trgSubj = fs_trgsubj(subjCode, template);

% use oddeven for split-half correlations
if strcmp(func2str(measure), 'cosmo_correlation_measure')
    partitioner = @cosmo_oddeven_partitioner;
end

%% Neighborhood
% which method is used for neighbors
if radius ~= 0
    nbr_args.metric = metric;
    nbr_args.radius = radius;
    nbrStr = sprintf('%s_r%d', nbrStr, radius);
elseif count ~= 0
    nbr_args.count = count;
    nbrStr = sprintf('%s_count%d', nbrStr, count);
else
    error(['Please define the method for identifying neighboorhood.' ...
        'e.g., set ''r'' or ''count''']);
end

% Define the feature neighborhood for each node on the surface
% load the surficial neighborhood
nbhFn = sprintf('sl_cosmo_nbr_%s_%s_%s.mat', hemi, trgSubj, nbrStr);
% the target folder
if strcmp(trgSubj, 'fsaverage')
    saveSubj = 'fsaverageSL';
    accPath = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf');
    if ~exist(accPath, 'dir'); mkdir(accPath); end
else
    saveSubj = trgSubj;
end

% the temporary neighborhood file to be saved/read
nbhFilename = fullfile(getenv('SUBJECTS_DIR'), saveSubj, 'surf', nbhFn);
if exist(nbhFilename, 'file') % load the file if it is available
    fprintf('\nLoading the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    
    temp = load(nbhFilename);
    
    if ~strcmp(temp.trgSubj, trgSubj) || ~strcmp(temp.hemi, hemi)
        error('The wrong file is loaded...');
    end
    % obtain the variables
    nbrhood = temp.nbrhood;
    vo = temp.vo;
    fo = temp.fo;
    
    clear temp
end

% calculate the surficial neighborhood if necessary
if ~exist('nbrhood', 'var') || ~exist('vo', 'var') || ~exist('fo', 'var')
    % calculate the surficial neighborhood
    fprintf('\n\nGenerating the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    [nbrhood,vo,fo,~]=cosmo_surficial_neighborhood(ds,surfDef,nbr_args);
    
    % save the the surficial neighborhood file
    fprintf('\nSaving the surficial neighborhood for %s (%s):\n',...
        trgSubj, hemi);
    save(nbhFilename, 'nbrhood', 'vo', 'fo', 'trgSubj', 'hemi',...
        'template', 'metric', '-v7.3');
end

% print neighborhood
fprintf('Searchlight neighborhood definition:\n');
cosmo_disp(nbrhood);
fprintf('The output surface has %d vertices, %d nodes\n',...
    size(vo,1), size(fo,1));

%% Set center_ids
if ismember(hemi, {'lh', 'rh'}) && isempty(center_ids)
    
    % remove uselessdta
    if applyUseless
        [~, useMask] = cosmo_remove_useless_data(ds);
        useVtx = find(useMask);
    else
        useVtx = 1:size(ds.samples, 2);
    end
    
    % mask applied to searchlight (2)
    if applyCorterx
        % load ?h.cortex.label as a mask for surface
        cortexVtx = fs_cortexmask(trgSubj, hemi);
    else
        cortexVtx = 1:size(ds.samples, 2);
    end
    
    tempIn = sort(intersect(cortexVtx, useVtx));
    
    % only keep neighborhood within <tempIn>    
    isRemoved = cellfun(@(x) sum(~ismembc(sort(x), tempIn))>0, nbrhood.neighbors);
    rmvVtx = nbrhood.fa.node_indices(isRemoved);
    
    % combine center_ids
    center_ids = setdiff(tempIn, rmvVtx);
    
elseif isempty(center_ids)
    % use all vertices
    center_ids = 1:size(ds.samples, 2);
end

%% Set analysis parameters
measure_args = struct();

% Define which classifier to use, using a function handle.
measure_args.classifier = classifier; % @cosmo_classify_libsvm;
% folders for saving results (Pseudo-analysis folder)
anaFolder = [outPrefix '_' anaName];

% define the pairs for classification
nPairs = size(classPairs, 1);

for iPair = 1:nPairs
    
    % define this classification
    thisPair = classPairs(iPair, :);
    
    % skip if the pair is not available in this dataset
    if ~all(ismember(thisPair, unique(ds.sa.labels)))
        warning('Cannot find %s vs. %s in the dataset.', thisPair{:});
        continue;
    end
    
    % dataset for this classification
    thisPairMask = cosmo_match(ds.sa.labels, thisPair);
    ds_thisPair = cosmo_slice(ds, thisPairMask);
    
    %% Set partition scheme.
    measure_args.partitions = partitioner(ds_thisPair);
    
    % print measure and arguments
    fprintf('Searchlight measure:\n');
    cosmo_disp(measure);
    fprintf('Searchlight measure arguments:\n');
    cosmo_disp(measure_args);
    
    %% Run the searchlight
    dt_sl = cosmo_searchlight(ds_thisPair,nbrhood,measure,measure_args,...
        'center_ids', center_ids, 'nproc', nproc);
    
    % print searchlight output
    fprintf('Dataset output:\n');
    cosmo_disp(dt_sl);
    
    % set the accuracy for non-cortex vertices as -1
    accuracy = ones(size(vo, 1), 1) * maskedValue;
    accuracy(center_ids) = dt_sl.samples';
    
    %% Save results as *.mgz files
    % (Pseudo-contrast folder)
    conFolder = sprintf('%s-vs-%s', thisPair{:});
    
    % store searchlight results
    accFn = sprintf('sl.%s.%s.acc', shortName{1}, hemi);
    accPath = fullfile(funcPath, sessCode, 'bold', anaFolder, conFolder);
    
    if ismember(hemi, {'lh', 'rh'})
        if ~exist(accPath, 'dir'); mkdir(accPath); end
        % save the accuracy as *.mgz
        fs_savemgz(trgSubj, accuracy, accFn, accPath, hemi);
    elseif strcmp(hemi, 'both')  % save as .gii for the whole brain
        outputFile = fullfile(accPath, accFn);
        cosmo_map2surface(dt_sl, [outputFile '.gii'], 'encoding','ASCII');
    end
    
    %% store counts
    
    
    %% save other information
    
    
end  % iPair

end