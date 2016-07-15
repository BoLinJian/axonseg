function [stats_downsample, statsname]=as_stats_downsample_2nii(axonlist,matrixsize,PixelSize,resolution)
% [stats_downsample, statsname]=as_stats_downsample_2nii(axonlist,matrixsize,PixelSize (in �m),resolution (in �m))
% Create a folder "stats" in current directory and generate NIFTI with the
% different statistics
%
% IN:   -axonlist (output structure from AxonSeg, containing axon & myelin
%       info
%       -matrixsize (size x and y of image in axonlist)      
%       -PixelSize (size of one pixel, output of AxonSeg, comes with
%       axonlist)
%       -resolution (um value of downsampled image, i.e. you can take the
%       resolution of your MRI image, can take different resolutions for x
%       and y)
%       -outputstats (true if you want the output stats)
%
%
%--------------------------------------------------------------------------

% EXAMPLE: as_stats_downsample_2nii(axonlist,size(img),PixelSize,150)

[stats_downsample, statsname]=as_stats_downsample(axonlist,matrixsize,PixelSize,resolution);
imagesc(stats_downsample(:,:,end))
mkdir('stats')
save_nii(make_nii(permute(stats_downsample,[1 2 4 3]),[150 150 1]),'stats/stats_downsample4D.nii');
for istat=1:length(statsname)
    save_nii(make_nii(permute(stats_downsample(:,:,istat),[1 2 4 3]),[150 150 1]),['stats/' num2str(istat) '_' statsname{istat} '.nii']);
end
