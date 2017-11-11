function [ patches,bbox_location ] = sw_detect_face( img,window_size, scale,stride )
% sw_multiscale_detect_face
% - This is a function to proposed the potential face images via moving the
% sliding window. 
%==========================================================================
% Output:
%   - patches: a cell to store every window_size proposed images. The size
%               of save images are H*W*N, where N is the number of sliding
%   - bbox_location: bounding box [x,y,height,width]
%--------------------------------------------------------------------------
% Input:
%   - real_image : The original images without resize
%   - window_size: The proposed sliding window size
%   - scale      : The scale of for each original image
%   - stride     : The steps between each save images
%==========================================================================

real_image = img;
% img = imresize(img, scale);

% single-scale sliding window
[irow, icol] = size(img);
window_size = int16(window_size / scale);
stride = int16(stride / scale);
window_r = window_size(1);
window_c = window_size(2);



single_patches = zeros(window_r, window_c, floor(((irow-window_r)/stride) + 1) * floor(((icol-window_c)/stride) + 1), 'uint8');
% single_patches = zeros(window_r, window_c,5, 'uint8');

% Iteratively save the patches.
% r = randi(irow-window_r,5,1);
% c = randi(icol-window_c,5,1);
for i = 1:((irow-window_r)/stride) + 1 %1:irow/window_r
    for j = 1:((icol-window_c)/stride) + 1%1:icol/window_c
        single_patches(:,:,(i-1)*floor(irow/stride) + j) = img(stride*(i-1) + 1:stride*(i-1)+window_size, stride*(j-1)+1:stride*(j-1)+window_size);
        single_bbox_location((i-1)*floor(irow/stride) + j, :) = [(i-1)*stride+1,(j-1)*stride+1,window_r,window_c]; % top-left y,x, height, width
    end
end

patches{1} = single_patches;
bbox_location{1} = single_bbox_location;

end

