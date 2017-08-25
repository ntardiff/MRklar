function motion_slice_correction(session_dir,despike,sliceTiming,unwarp,runNums,refvol)

%   Removes large spikes (>7*RMSE), runs motion and slice timing
%   correction.
%
%   Usage:
%   motion_slice_correction(session_dir,despike,sliceTiming,refvol)
%
%   Defaults:
%     despike = 1; % default will despike data
%     SliceTiming = 1; do slice timing correction (custom script)
%
%   Written by Andrew S Bock June 2016

%% Set default parameters
if ~exist('despike','var')
    despike = 1; % despike data
end
if ~exist('sliceTiming','var')
    sliceTiming = 1; % do slice timing correction
end
if ~exist('unwarp','var')
    unwarp = 0; % do B0 unwarping with motion correction
end
% Find bold run directories
d = find_bold(session_dir);
if ~exist('runNums','var')
    runNums = 1:length(d);
end
if ~exist('refvol','var')
    refvol = 1; % reference volume = 1st TR
end
%% Remove spikes
if despike
    for rr = runNums
        remove_spikes(fullfile(session_dir,d{rr},'raw_f.nii.gz'),...
            fullfile(session_dir,d{rr},'despike_f.nii.gz'),fullfile(session_dir,d{rr},'raw_f_spikes'));
    end
end
%% Slice timing correction
if sliceTiming
    for rr = runNums
        if despike
            inFile = fullfile(session_dir,d{rr},'despike_f.nii.gz');
        else
            inFile = fullfile(session_dir,d{rr},'raw_f.nii.gz');
        end
        outFile = fullfile(session_dir,d{rr},'f.nii.gz');
        timingFile = fullfile(session_dir,d{rr},'slicetiming');
        slice_timing_correction(inFile,outFile,timingFile);
    end
end
%% Run motion correction
if sliceTiming
    infunc = 'f';
elseif despike
    infunc = 'despike_f';
else
    infunc = 'raw_f';
end
if strcmp(refvol,'mid')
    usemid = 1;
else
    usemid = 0;
end
for rr = runNums
    inFile = fullfile(session_dir,d{rr},[infunc '.nii.gz']);
    outFile = fullfile(session_dir,d{rr},'rf.nii.gz');
    %mcflirt(inFile,outFile,refvol);
    outDir = fullfile(session_dir,d{rr});
    
    %if specified align to middle volume. 
    if usemid
        [~,midvol] = system(['mri_info --mid-frame ' inFile])
        %need to add plust one b/c of differences in numbering between
        %matlab, fslroi, etc; fslroi begins at 0.
        refvol = str2double(midvol) + 1  
    end
    
    if unwarp
        %this is kind of annoying but necessary b/c of how I patterened
        %B0unwarp on how most other MRklar functions work where they take
        %just the file name and no directory/extension. Could change the
        %inFile code above but lazy.
        B0unwarp(session_dir,rr,infunc);
        
        vsmap = fullfile(session_dir,d{rr},'vsmap.nii.gz');
        mri_robust_register(inFile,outFile,outDir,refvol,vsmap)
    else
        mri_robust_register(inFile,outFile,outDir,refvol)
    end
           
end
