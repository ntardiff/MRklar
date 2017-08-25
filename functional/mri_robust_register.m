function mri_robust_register(inVol,outVol,outDir,refvol,vsmap)

% Motion corrects a 4D volume using Freesurfer's 'mri_robust_register'
% If supplied w/ voxel-shift map, combines B0 unwarping and motion
% correction.
%
%   Usage:
%   mri_robust_register(inVol,outVol,outDir,refvol,vsmap)
%
%   Based on:
%   Highly Accurate Inverse Consistent Registration: A Robust Approach
%   M. Reuter, H.D. Rosas, B. Fischl.
%   NeuroImage 53(4), pp. 1181-1196, 2010.
%
%   Note:
%   refvol = 1 is the first volume
%   vsmap: a voxel-shift map created by epidewarp.fsl (see B0unwarp.m) to
%   perform B0 unwarping.
%
%   Written by Andrew S Bock May 2016
%   B0 unwarping added by Nathan Tardiff Sept 2016

%% Set output for .lta files
outMC = fullfile(outDir,'mc');
if exist(outMC,'dir')
    warning('MC directory already exists. Removing old files.');
    rmdir(outMC,'s');
end
mkdir(outMC);
if ~exist('vsmap','var') 
    unwarp=0;
elseif exist(vsmap, 'file')
    unwarp=1;
else
    warning('\nWarning: Voxel Shift Map not found. Not performing unwarping.\n');
    unwarp=0;
end
%% Split input 4D volume into 3D volumes
system(['mri_convert ' inVol ' ' fullfile(outMC,'split_f.nii.gz') ' --split']);
%% Register volumes
inVols = listdir(fullfile(outMC,'split_f0*'),'files');
progBar = ProgressBar(length(inVols),'mri_robust_registering...');
dstFile = fullfile(outMC,inVols{refvol}); % register to first volume
for i = 1:length(inVols)
    inFile = fullfile(outMC,inVols{i});
    outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
    register_string = ['mri_robust_register --mov ' inFile ...
        ' --dst ' dstFile ' --lta ' fullfile(outMC,sprintf('%04d.lta',i)) ...
        ' --vox2vox --satit'];
    if ~unwarp
        register_string = [register_string ' --mapmov ' outFile];
    end
    [~,~] = system(register_string);
    
    if unwarp
        system(['mri_vol2vol --mov ' inFile ' --targ ' dstFile ' --o ' outFile ...
            ' --lta ' fullfile(outMC,sprintf('%04d.lta',i)) ' --vsm ' vsmap ...
            ' --cubic --no-save-reg']);
    end
    progBar(i);
end
system(['rm ' fullfile(outMC,'split_f0*')]); % remove split volumes
%% Merge into output 4D volume
commandc = ['fslmerge -t ' outVol];
for i = 1:length(inVols)
    outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
    commandc = [commandc ' ' outFile];
end
system(commandc);
system(['rm ' fullfile(outMC,'tmp_*nii.gz')]); % remove tmp volumes
%% Convert .lta files to translations and rotations
clear x y z pitch yaw roll
ltaFiles = listdir(fullfile(outMC,'*.lta'),'files');
x       = nan(1,length(ltaFiles));
y       = nan(1,length(ltaFiles));
z       = nan(1,length(ltaFiles));
pitch   = nan(1,length(ltaFiles));
yaw     = nan(1,length(ltaFiles));
roll    = nan(1,length(ltaFiles));
for i = 1:length(ltaFiles);
    inFile = fullfile(outMC,ltaFiles{i});
    [x(i),y(i),z(i),pitch(i),yaw(i),roll(i)] = convertlta2tranrot(inFile);
end
motion_params = [pitch',yaw',roll',x',y',z'];
dlmwrite(fullfile(outDir,'motion_params6.txt'),motion_params,'delimiter',' ','precision','%10.5f');
