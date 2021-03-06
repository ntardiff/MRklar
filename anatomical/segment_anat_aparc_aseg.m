function segment_anat_aparc_aseg(session_dir,subject_name,SUBJECTS_DIR)
% Segments the freesurfer anatomical aparc+aseg.mgz volume into several ROIs in 
%   the session_dir:
%
%   brain.nii.gz
%   aseg.gm.nii.gz
%   aseg.wm.nii.gz
%   aseg.lh_ventricle.nii.gz
%   aseg.rh_ventricle.nii.gz
%   aseg.third_ventricle.nii.gz
%   aseg.fourth_ventricle.nii.gz
%   aseg.csf
%   aseg.brainstem.nii.gz
%   aseg.unknown.nii.gz
%
%   Usage: segment_anat_aparc_aseg(session_dir,subject_name,SUBJECTS_DIR)
%
%   NOTE: aparc+aseg has the advantage of being based on final surfs, and thus
%   should provide a more accurate parcellation of wm/gm than aseg.mgz, 
%   which is from the initial parcellation. 
%
%   Based on segment_aparc, Written by Andrew S Bock Apr 2015
%   Modified to use aparc+aseg by Nathan Tardiff Sept 2015

%% Set default parameters
if ~exist('session_dir','var')
    error('"session_dir" not defined')
end
if ~exist('subject_name','var')
    error('"subject_name" not defined')
end
if ~exist('SUBJECTS_DIR','var')
    SUBJECTS_DIR = getenv('SUBJECTS_DIR');
end
%% Segment GM
disp(['session_dir = ' session_dir]);
disp(['subject = ' subject_name]);
disp('Segmenting GM, WM, ventricles, brainstem, and non-brain tissue...');
% Brain (will be used as brain mask and to find grey matter)
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','brain.mgz') ...
    ' --min 1 --o ' fullfile(session_dir,'brain.nii.gz')]);
% White matter
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 2 7 41 46 251 252 253 254 255 --o ' fullfile(session_dir,'aseg.wm.nii.gz')]);
% Left lateral ventricle
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 4 5 --o ' fullfile(session_dir,'aseg.lh_ventricle.nii.gz')]);
% Right right lateral ventricle
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 43 44 --o ' fullfile(session_dir,'aseg.rh_ventricle.nii.gz')]);
% Third ventricle
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 14 --o ' fullfile(session_dir,'aseg.third_ventricle.nii.gz')]);
% Fourth ventricle
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 15 --o ' fullfile(session_dir,'aseg.fourth_ventricle.nii.gz')]);
% brainstem (WM)
% note: need to erode brainstem more, as it includes some GM structures (e.g. SC)
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 16 --erode 5 --o ' fullfile(session_dir,'aseg.brainstem.nii.gz')]);
% OTHER: Choroid plexus (left and right), CSF (probably foramen), Optic Chiasm
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 31 63 24 85 --o ' fullfile(session_dir,'aseg.other.nii.gz')]);
% Unknown (non-brain voxels)
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --match 0 --o ' fullfile(session_dir,'aseg.unknown.nii.gz')]);
[~,~] = system(['fslmaths ' fullfile(session_dir,'aseg.unknown.nii.gz') ' -mul '...
    fullfile(session_dir,'brain.nii.gz') ' ' fullfile(session_dir,'aseg.unknown.nii.gz')]);
% Segment GM by removing non-GM structures from aparc+aseg
[~,~] = system(['mri_binarize --i ' fullfile(SUBJECTS_DIR,subject_name,'mri','aparc+aseg.mgz') ...
    ' --min 1 --o ' fullfile(session_dir,'aparc+aseg.nii.gz')]);;
[~,~] = system(['fslmaths ' fullfile(session_dir,'aparc+aseg.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.wm.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.lh_ventricle.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.rh_ventricle.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.third_ventricle.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.fourth_ventricle.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.brainstem.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.other.nii.gz') ' -sub ' ...
    fullfile(session_dir,'aseg.unknown.nii.gz') ' -bin ' ...
    fullfile(session_dir,'aseg.gm.nii.gz')]);
disp('done.');