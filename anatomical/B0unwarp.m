function B0unwarp(session_dir, runNum, func, epidewarp_path, tmp_dir)
%% I just realized B0calc basically calculates everything I need and can just pull--but check
%   Calculate B0 map from double echo Siemens fieldmap sequence. Images are
%   phase unwrapped and in units of Hertz.
%
%   Usage;
%   B0calc(outDir,phaseDicomDir,subject)
%
%   defaults:
%   outDir = no default, must specify
%   phaseDicomDir = no default, must specify
%   subject = no default, not necessary except if brain extraction using
%   bet is poor, in which case will use bbregister and brain.mgz
%
%   Requires FSL
%   modified from scripts provided by Mark Elliot
%
%   Written by Andrew S Bock Feb 2014
%   Requires epidewarp.fsl to be available in path. Newest version can be
%   found at: ftp://surfer.nmr.mgh.harvard.edu/transfer/outgoing/flat/greve/epidewarp.fsl

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
    
    %{
    if exist(fullfile(session_dir,d{rr},['nu',func,'.nii.gz']),'file')
        fprintf('\nDewarping was already run. Rerunning on undewarped EPIs.\n');
        prefix = 'nu';
    else
        prefix = '';
    end

    
    %apply correction
    status = system([epidewarp_path ' --mag ' mag1file ' --dph ' phasefile ...
        ' --epi ' fullfile(session_dir,d{rr},[prefix,func,'.nii.gz']) ' --tediff ' delta_te ...
        ' --esp ' echo_spacing ' --vsm ' fullfile(session_dir,d{rr},'vsmap.nii.gz') ...
        ' --exfdw ' fullfile(session_dir,d{rr},'exfu.nii.gz') ' --epidw ' fullfile(session_dir,d{rr},['u',func,'.nii.gz']) ...
        ' --tmpdir ' tmp_dir ' --cleanup'])
    %}
    status = system([epidewarp_path ' --mag ' mag1file ' --dph ' phasefile ...
        ' --epi ' fullfile(session_dir,d{rr},[func,'.nii.gz']) ' --tediff ' delta_te ...
        ' --esp ' echo_spacing ' --vsm ' fullfile(session_dir,d{rr},'vsmap.nii.gz') ...
        ' --exfdw ' fullfile(session_dir,d{rr},'exfu.nii.gz') ...
        ' --tmpdir ' tmp_dir ' --cleanup'])
    %NOT DOING THIS ANYMORE: rename EPI files -- append 'nu' for not unwarped to original files and then
    %rename 'u' (unwarped) files to original name [wanted to use 'dw' for
    %'dewarped' but conflicts w/ naming convention for later steps
    if status == 0
        %{
        if isempty(prefix)
            movefile(fullfile(session_dir,d{rr},[func,'.nii.gz']), fullfile(session_dir,d{rr},['nu',func,'.nii.gz']))
        end
        movefile(fullfile(session_dir,d{rr},['u',func,'.nii.gz']), fullfile(session_dir,d{rr},[func,'.nii.gz']))
        %}
        fprintf('\ndone.\n')
    else
        warning('\nWARNING: epidewarp.fsl did not exit cleanly.\n');
    end
end

