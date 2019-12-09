function [v_merged, f_merged] = merge_surfaces(filenames)
% merge surface filesep
%
% Input:
%   filenames:      cell filenames of surfaces to merge, for example
%                   these can be '.asc'  files as generated by FreeSurfer's
%                   recon_all
%
% Output:
%   v_merged        Nx3 matrix with vertex coordinates for N vertices
%   f_merged        Mx3 matrix with face indices for M faces
%
% Example:
%   % merge left and right hemispheres of pial surface
%   fns = {'lh.pial.asc', 'rh.pial.asc'}
%   [v,f]=merge_surfaces(fns)
%   surfing_write('mh.pial.asc',v,f);
%
% Note:
% - this function uses surfing_read from the Surfing toolbox.
%   See https://github.com/surfing/surfing
% - the output can be saved with surfing_write
%
% Nick Oosterhof 2018-10-12
%
% Noted by Haiyang Jin (21/11/2019)
% Obtained from cosmoMVPA
% http://www.cosmomvpa.org/faq.html?highlight=freesurfer#make-a-merged-hemisphere-from-a-left-and-right-hemisphere

    if ~iscellstr(filenames)
        error('input must be cell with filenames')
    end

    n_surfaces = numel(filenames);
    v_s = cell(n_surfaces,1);
    f_s = cell(n_surfaces,1);

    n_total = 0;
    for k=1:n_surfaces
        filename = filenames{k};
        [v, f] = surfing_read(filename);
        cosmo_disp(v)
        cosmo_disp(f)

        % keep the vertex coordinates
        v_s{k} = v;

        % update face indices to take into account previous input surfaces
        f_s{k} = f + n_total;

        % update index of first face for next surface
        n_vertices = size(v,1);
        n_total = n_total + n_vertices;
    end

    v_merged = cat(1,v_s{:});
    f_merged = cat(1,f_s{:});