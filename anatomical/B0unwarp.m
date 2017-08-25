function B0unwarp(session_dir, runNum, func, epidewarp_path, tmp_dir)

%   Creates a voxel-shift map from a double-echo B0 map for use in B0
%   unwarping.
%
%   Usage:
%   B0unwarp(session_dir, runNum, func, epidewarp_path, tmp_dir)
%
%   Defaults:
%     func = 'raw_f'; % will create the vsm for unwarping raw
%     unpreprocessed BOLD run.
%     epidewarp_path = epidewarp.fsl in cwd or otherwise on path % full path (including file name) for epidewarp.fsl
%     tmp_dir = environment variable $TMPDIR % location to store temporary
%     files. If on UPenn cluster, best to use $TMPDIR.
%
%   Requires epidewarp.fsl to be available in path. Newest version can be
%   found at: ftp://surfer.nmr.mgh.harvard.edu/transfer/outgoing/flat/greve/epidewarp.fsl
%
%   Written by Nathan Tardiff Sept 2016


fprintf('\nDEWARPING EPI IMAGES\n');

%% Set default parameters
if ~exist('session_dir','var')
    error('"session_dir" not defined');% must define a session_dir
end
if ~exist('func','var')
    func = 'raw_f'; % functional data file
end
if ~exist('epidewarp_path','var')
    epidewarp_path = 'epidewarp.fsl';
end
if ~exist('tmp_dir','var')
    tmp_dir = '$TMPDIR';
end

%% Find bold run directories
d = find_bold(session_dir);
nruns = length(d);
%% Set runs
if ~exist('runNum','var')
    runNum = 1:nruns;
end

%% Get echo time diff, B0 magnitude and phase images
delta_te = num2str(dlmread(fullfile(session_dir,'B0','delta_TE')));
mag1file = fullfile(session_dir,'B0','mag1.nii.gz');
phasefile = fullfile(session_dir,'B0','phase_all.nii.gz');

%% Compute and ouput b0 unwarped EPI
for rr = runNum
    %Get echo spacing and EPI TE
    echo_spacing = num2str(dlmread(fullfile(session_dir,d{rr},'EchoSpacing')));
    epi_te = num2str(dlmread(fullfile(session_dir,d{rr},'EPI_TE')));
    
    %create voxel-shift map
    status = system([epidewarp_path ' --mag ' mag1file ' --dph ' phasefile ...
        ' --epi ' fullfile(session_dir,d{rr},[func,'.nii.gz']) ' --tediff ' delta_te ...
        ' --esp ' echo_spacing ' --vsm ' fullfile(session_dir,d{rr},'vsmap.nii.gz') ...
        ' --exfdw ' fullfile(session_dir,d{rr},'exfu.nii.gz') ...
        ' --tmpdir ' tmp_dir ' --cleanup'])

    if status == 0
        fprintf('\ndone.\n')
    else
        warning('\nWARNING: epidewarp.fsl did not exit cleanly.\n');
    end
end

