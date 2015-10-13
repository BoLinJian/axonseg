function as_Segmentation_full_image(im_fname,SegParameters,blocksize,overlap,output)
% as_Segmentation_full_image(im_fname,SegParameters,blocksize (# of pixels),overlap,output)
% as_Segmentation_full_image('Control_2.tif', 'SegParameters.mat',5000,100,'Control_2_results')
%
% im_fname: input image (filename)
% SegParameters: output of SegmentationGUI
% blocksize: input image is divided in smaller pieces in order to limit memory usage..
% See also: SegmentationGUI

%% INPUTS
if ~exist('im_fname','var') || isempty(im_fname)
    im_fname=uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
          '*.*','All Files' });
end

if ~exist('SegParameters','var') || isempty(SegParameters)
    SegParameters=uigetfile({'*.mat'});
end
load(SegParameters);

if ~exist('blocksize','var') || isempty(blocksize)
    blocksize=1000;
end
if ~exist('overlap','var') || isempty(overlap)
    overlap=200;
end
if ~exist('output','var') || isempty(output)
    [~,name]=fileparts(im_fname);
    output=[name '_Segmentation'];
end

if ~exist(output,'dir'), mkdir(output); end
output=[output filesep];

disp('reading the image')
handles.data.img=imread(im_fname);
if length(size(handles.data.img))==3
    handles.data.img=rgb2gray(handles.data.img(:,:,1:3));
end

%% SEGMENTATION
disp('Starting segmentation..')
myelin_seg_results=as_improc_blockwising(@(x) fullimage(x,SegParameters),handles.data.img,blocksize,overlap);
% clean conflicts
myelin_seg_results=as_blockwise_fun(@(x,y) myelinCleanConflict(x,y,0.5),myelin_seg_results, 1,0);

save([output, 'bwmyelin_seg_results'], 'myelin_seg_results', 'blocksize', 'overlap', 'PixelSize', '-v7.3')
[ axonlist ] = as_myelinseg_blocks_bw2list( myelin_seg_results, PixelSize, blocksize, overlap);
img=cell2mat(cellfun(@(x) x.img, myelin_seg_results,'Uniformoutput',0));
img=as_improc_rm_overlap(img,blocksize,overlap);


%% SAVE
save([output 'myelin_seg_results.mat'], 'axonlist', 'img', 'PixelSize','-v7.3')
delete([output, 'bwmyelin_seg_results.mat'])

gRatio_map=as_display_label(axonlist, size(img),'gRatio');
axonEquivDiameter_map=as_display_label(axonlist, size(img),'axonEquivDiameter');
RGB = ind2rgb8(gRatio_map,hot(100));
imwrite(0.5*RGB+0.5*repmat(img,[1 1 3]),[output 'gRatio_0_1.jpg'])

maxdiam=ceil(prctile(cat(1,axonlist.axonEquivDiameter),99));
RGB = ind2rgb8(axonEquivDiameter_map,hot(maxdiam*10));
imwrite(0.5*RGB+0.5*repmat(img,[1 1 3]),[output 'axonEquivDiameter_0�m_' num2str(maxdiam) '�m.jpg'])
copyfile(which('colorbarhot.png'),output)




function [im_out,AxSeg]=fullimage(im_in,state)

%Preproc
if state.invertColor, im_in=imcomplement(im_in); end

im_in=histeq(im_in,state.histEq);

im_in=Deconv(im_in,state.Deconv);

%Step1
AxSeg=step1(im_in,state);


%Step 2
AxSeg=step2(AxSeg,state);



%Myelin Segmentation
AxSeg_rb=RemoveBorder(AxSeg);
backBW=AxSeg & ~AxSeg_rb; % backBW = axons that have been removed by RemoveBorder
[im_out] = myelinInitialSegmention(im_in, AxSeg_rb, backBW,0,1);