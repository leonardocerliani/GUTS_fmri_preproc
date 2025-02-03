
% run from terminal with:
% octave run_dicm2nii.m [/path/to/PARREC] [/path/to/destination] [fmt]
% 
% update the location of dicm2nii

orig = argv(){1};  % PARREC location
dest = argv(){2};  % raw_data location
fmt = str2num(argv(){3});  % Convert fmt to a number

addpath(genpath('/data00/leonardo/warez/dicm2nii'))
dicm2nii(orig, dest, fmt)




