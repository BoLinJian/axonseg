function [im_out,AxStats]=as_display_label( axonlist,matrixsize,metric,displaytype, writeimg, verbose)
%[im_out,AxStats]=AS_DISPLAY_LABEL(axonlist, matrixsize, metric);
%[im_out,AxStats]=AS_DISPLAY_LABEL(axonlist, matrixsize, metric, displaytype, writeimg?);
%
% --------------------------------------------------------------------------------
% INPUTS:   
%   metric {'gRatio' | 'axonEquivDiameter' | 'myelinThickness' | 'axon number'}
%   Units: gRatio in percents / axonEquivDiameter in  um x 10 /
%   myelinThickness in um x 10
%   displaytype {'axon' | 'myelin'} = 'myelin'
%   writeimg {img,0} = 0
%
% --------------------------------------------------------------------------------
% EXAMPLE:
%   bw_axonseg=as_display_label(axonlist,size(img),'axonEquivDiameter','axon');
%   sc(sc(bw_axonseg,'hot')+sc(img))


dbstop error

% If no displaytype specified in argument, 'myelin' by default
if nargin<4; displaytype='myelin';end
% If writeimg not specified in input, false
if ~exist('writeimg','var') || max(writeimg(:))==0, writeimg=[]; end
if ~exist('verbose','var'), verbose=1; end

% Init. output image
im_out=zeros(matrixsize,'uint8');

% Get number of axons contained in the axon list
Naxon=length(axonlist);

% Copy axonlist
AxStats=axonlist;

if verbose
    tic
    disp('Loop over axons...')
end
for i=Naxon:-1:1
    if ~mod(i,1000), disp(i); end
    if size(axonlist(i).data,1)>5
        index=round(axonlist(i).data);
        %     tmp=index(1)<matrixsize(:,1) | index(:,1)>matrixsize(1);
        %     index(find(tmp))=[];
        %     tmp=index(2)<matrixsize(:,2) | index(:,2)>matrixsize(2);
        %     index(find(tmp))=[];
        
        %   If 'axon' display type is specified, find axon index instead of
        %   myelin index
        if strcmp(displaytype,'axon')
            index=as_myelin2axon(max(1,index));
        end
        
        
        ind=sub2ind(matrixsize,min(matrixsize(1),max(1,index(:,1))),min(matrixsize(2),max(1,index(:,2))));
        
        
        if ~isempty(AxStats(i))
            switch metric
                case 'gRatio'
                    scale = 100; unit = '';
                    im_out(ind)=uint8(AxStats(i).gRatio(1)*scale);
                case 'axonEquivDiameter'
                    scale = 10; unit = '�m';
                    im_out(ind)=uint8(AxStats(i).axonEquivDiameter(1)*scale);
                case 'myelinThickness'
                    scale = 10; unit = '�m';
                    im_out(ind)=uint8(AxStats(i).myelinThickness(1)*scale);
                case 'axon number'
                    scale = 1; unit = '';
                    im_out(ind)=i;
                otherwise
                    scale = 1; unit = '';
                    im_out = double(im_out);
                    im_out(ind)=AxStats(i).(metric);
            end
            
        end
    end
end

if verbose
    disp('done')
    toc
end

if ~isempty(writeimg)
    writeimg = imadjust(uint8(writeimg));
    im_out_NZ = im_out(im_out>0);
    if ~isempty(im_out_NZ)
        maxval=ceil(prctile(im_out(im_out>0),99));
    else
        maxval = 1; scale =1; unit = '_NoAxonsDetected';
    end
    try
    reducefactor=max(1,ceil(max(size(writeimg))/25000));   
    RGB = ind2rgb8(im_out(1:reducefactor:end,1:reducefactor:end,:),hot(maxval));
    if reducefactor>1 % if quality is reduced
        warning('Image too big. Output image quality will is  reduced.')
    end
    
    catch % ind2rgb8 not installed
        try %  install ind2rgb8
            ind2rgb8dir = fileparts(fileparts(mfilename('fullpath')));
            mex([ind2rgb8dir filesep 'utils' filesep 'ind2rgb8.c'])
        catch % reduce quality
            reducefactor=max(1,ceil(max(size(writeimg))/5000));   
            if reducefactor>1 % if quality is reduced
                warning('ind2rgb8 not installed correctly for your OS. Output image quality will is  reduced.')
            end
            RGB = uint8(ind2rgb(im_out(1:reducefactor:end,1:reducefactor:end,:),hot(maxval)));
        end
    end
    imwrite(0.5*RGB+0.5*repmat(writeimg(1:reducefactor:end,1:reducefactor:end),[1 1 3]),[metric '_(' displaytype ')_0_' num2str(maxval/scale) unit '.jpg'])
end