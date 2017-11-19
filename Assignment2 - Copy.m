% Image and Visual Computing Assignment 2: Face Verification & Recognition
%==========================================================================
%   In this assignment, you are expected to use the previous learned method
%   to cope with face recognition and verification problem. The vl_feat, 
%   libsvm, liblinear and any other classification and feature extraction 
%   library are allowed to use in this assignment. The built-in matlab 
%   object-detection functionis not allowed. Good luck and have fun!
%
%                                               Released Date:   31/10/2017
%==========================================================================

%% Initialisation
%==========================================================================
% Add the path of used library.
% - The function of adding path of liblinear and vlfeat is included.
%==========================================================================
clear all
clc
run ICV_setup

% Hyperparameter of experiments
resize_size=[64 64];


%% Part I: Face Recognition: Who is it?
%==========================================================================
% The aim of this task is to recognize the person in the image(who is he).
% We train a multiclass classifer to recognize who is the person in this
% image.
% - Propose the patches of the images
% - Recognize the person (multiclass)
%==========================================================================


disp('Recognition :Extracting features..')

Xtr = []; Ytr = [];
Xva = []; Yva = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading the training data
% -tr_img_sample/va_img_sample:
% The data is store in a N-by-3 cell array. The first dimension of the cell
% array is the cropped face images. The second dimension is the name of the
% image and the third dimension is the class label for each image.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load('./data/face_recognition/face_recognition_data_tr.mat')

%run matlab/vl_setupnn ;

cellSize = 8;

All = [];

for i =1:length(tr_img_sample)
%     foldername = strsplit(tr_img_sample{i,2}, '_');
%     foldername = ['data/face_recognition/images/', foldername{1}, '_', foldername{2}];
%     mkdir(foldername);
%     imwrite(tr_img_sample{i,1}, [foldername, '/', tr_img_sample{i,2}, '.png']);
    temp = single(tr_img_sample{i,1})/255;
    
    All = [All reshape(temp, 4096, 1)];
    
    hog = vl_hog(temp, cellSize);
    lbp = vl_lbp(temp, cellSize);
    Xtr = [Xtr;[hog(:);lbp(:)]'];
    Ytr = [Ytr;tr_img_sample{i,3}];
end


load('./data/face_recognition/face_recognition_data_va.mat')
for i =1:length(va_img_sample)
    %foldername = strsplit(va_img_sample{i,2}, '_')
    %foldername = ['data/face_recognition/val_images/', foldername{1}, '_', foldername{2}]
    %mkdir(foldername)
    %imwrite(va_img_sample{i,1}, [foldername, '/', va_img_sample{i,2}, '.png']);
    temp = single(va_img_sample{i,1})/255;
    hog = vl_hog(temp, cellSize);
    lbp = vl_lbp(temp, cellSize);
    Xva = [Xva;[hog(:);lbp(:)]'];
    Yva = [Yva;va_img_sample{i,3}];
end

%imset = imageSet('data/face_recognition/temp/', 'recursive');
%val_imset = imageSet('data/face_recognition/val_temp/', 'recursive');

%extractorFcn = @custom_extractor;

%bag = bagOfFeatures(imset,'CustomExtractor', extractorFcn)

%bag = bagOfFeatures(imset, 'VocabularySize', 50)





%%

% Calculates mean value
m = mean(All, 2);

Train_Number = size(All, 2);

% Calculates the deviation of each image from the mean image
A = [ ];  

for i = 1 : Train_Number
    temp = double(All(:,i)) - m; 
    A = [A temp];
end

% Create covariance matrix
L = A'*A;

% Calculate eigen values and eigen vector V-eigen vector D-diagonal matrix with eigen values
[V D] = eig(L); 

L_eig_vec = [];

for i = 1 : size(V,2) 

    if( D(i,i)>1 )

        L_eig_vec = [L_eig_vec V(:,i)];
    end
end

% Eigenvectors of covariance matrix C (or so-called "Eigenfaces") can be recovered from L's eiegnvectors.
Eigenfaces = A * L_eig_vec;





%%

TestImage = 'data/face_recognition/images/Atal_Bihari/Atal_Bihari_Vajpayee_0002.pgm.png';

% Recognizing step....
%
% Description: This function compares two faces by projecting the images into facespace and 
% measuring the Euclidean distance between them.
%
% Argument:      TestImage              - Path of the input test image
%
%                m                      - (M*Nx1) Mean of the training
%                                         database, which is output of 'EigenfaceCore' function.
%
%                Eigenfaces             - (M*Nx(P-1)) Eigen vectors of the
%                                         covariance matrix of the training
%                                         database, which is output of 'EigenfaceCore' function.
%
%                A                      - (M*NxP) Matrix of centered image
%                                         vectors, which is output of 'EigenfaceCore' function.
% 
% Returns:       OutputName             - Name of the recognized image in the training database.          

%%%%%%%%%%%%%%%%%%%%%%%% Projecting centered image vectors into facespace
% All centered images are projected into facespace by multiplying in
% Eigenface basis's. Projected vector of each face will be its corresponding
% feature vector.

ProjectedImages = [];
Train_Number = size(Eigenfaces,2);
for i = 1 : Train_Number
    temp = Eigenfaces'*A(:,i); % Projection of centered images into facespace
    ProjectedImages = [ProjectedImages temp]; 
end

imshow(reshape(Eigenfaces(:,1),[64,64]));

%%%%%%%%%%%%%%%%%%%%%%%% Extracting the PCA features from test image
InputImage = imread(TestImage);
temp = InputImage(:,:,1);

[irow icol] = size(temp);
InImage = reshape(temp',irow*icol,1);
Difference = double(InImage)-m; % Centered test image
ProjectedTestImage = Eigenfaces'*Difference; % Test image feature vector

%%%%%%%%%%%%%%%%%%%%%%%% Calculating Euclidean distances 
% Euclidean distances between the projected test image and the projection
% of all centered training images are calculated. Test image is
% supposed to have minimum distance with its corresponding image in the
% training database.

Euc_dist = [];
for i = 1 : Train_Number
    q = ProjectedImages(:,i);
    temp = ( norm( ProjectedTestImage - q ) )^2;
    Euc_dist = [Euc_dist temp];
end

[Euc_dist_min , Recognized_index] = min(Euc_dist);
OutputName = int2str(Recognized_index);





%% Train the recognizer and evaluate the performance
Xtr = double(Xtr);
Xva = double(Xva);

% Train the recognizer
%model = fitcknn(Xtr,Ytr,'NumNeighbors',3);
%[l,prob] = predict(model,Xva);

%model = trainImageCategoryClassifier(imset, bag)
%[l,prob] = predict(model, Xva);

%evaluate(model, val_imset)

model = fitcecoc(Xtr,Ytr);
[l,prob] = predict(model,Xva);

%model = fitcsvm(Xtr,Ytr);
%[l,prob] = predict(model,Xva);

% Compute the accuracy
acc = mean(l==Yva)*100;

fprintf('The accuracy of face recognition is:%.2f \n', acc)
% Check your result on the raw images and try to analyse the limits of the
% current method.


%% Visualization the result of face recognition

data_idx = [1,30,50]; % The index of image in validation set
nSample = 3; % number of visualize data. maximum should be 3
% nPairs = length(data_idx); % unconment to get full size of 
visualise_recognition(va_img_sample,prob,Yva,data_idx,nSample )


%% Part II: Face Verification: 
%==========================================================================
% The aim of this task is to verify whether the two given people in the
% images are the same person. We train a binary classifier to predict
% whether these two people are actually the same person or not.
% - Extract the features
% - Get a data representation for training
% - Train the verifier and evaluate its performance
%==========================================================================


disp('Verification:Extracting features..')


Xtr = [];
Xva = [];
load('./data/face_verification/face_verification_tr.mat')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading the training data
% -tr_img_pair/va_img_pair:
% The data is store in a N-by-4 cell array. The first dimension of the cell
% array is the first cropped face images. The second dimension is the name 
% of the image. Similarly, the third dimension is another image and the
% fourth dimension is the name of that image.
% -Ytr/Yva: is the label of 'same' or 'different'
%%%%%%%%%%%%%%%%%

% All = [];

% You should construct the features in here. (read, resize, extract)
for i =1:length(tr_img_pair)
%     foldername = ['data/face_verification/images/', num2str(i)];
%     mkdir(foldername);
%     imwrite(tr_img_pair{i,1}, [foldername, '/', tr_img_pair{i,2}, '.png']);
%     imwrite(tr_img_pair{i,3}, [foldername, '/', tr_img_pair{i,4}, '.png']);

    temp = single(tr_img_pair{i,1})/255;
    
%     All = [All reshape(temp, 4096, 1)];
    
%     temp = vl_lbp(temp, cellSize);
%     temp_Xtr1 = temp(:)';
    
    temp = single(tr_img_pair{i,3})/255;
    
%     All = [All reshape(temp, 4096, 1)];
    
%     temp = vl_lbp(temp, cellSize);
%     temp_Xtr2 = temp(:)';
%     
%     Xtr = [Xtr;temp_Xtr1-temp_Xtr2];
end

% % Calculates mean value
% m = mean(All, 2);
% 
% Train_Number = size(All, 2);
% 
% % Calculates the deviation of each image from the mean image
% A = [ ];  
% 
% for i = 1 : Train_Number
%     temp = double(All(:,i)) - m; 
%     A = [A temp];
% end
% 
% % Create covariance matrix
% L = A'*A;
% 
% % Calculate eigen values and eigen vector V-eigen vector D-diagonal matrix with eigen values
% [V D] = eig(L); 
% 
% L_eig_vec = [];
% 
% for i = 1 : size(V,2) 
% 
%     if( D(i,i)>1 )
% 
%         L_eig_vec = [L_eig_vec V(:,i)];
%     end
% end
% 
% % Eigenvectors of covariance matrix C (or so-called "Eigenfaces") can be recovered from L's eiegnvectors.
% Eigenfaces = A * L_eig_vec;






%%




% TestImage = 'data/face_verification/images/2/Abdel_Nasser_Assidi_0001.pgm.png'
% 
% % Recognizing step....
% %
% % Description: This function compares two faces by projecting the images into facespace and 
% % measuring the Euclidean distance between them.
% %
% % Argument:      TestImage              - Path of the input test image
% %
% %                m                      - (M*Nx1) Mean of the training
% %                                         database, which is output of 'EigenfaceCore' function.
% %
% %                Eigenfaces             - (M*Nx(P-1)) Eigen vectors of the
% %                                         covariance matrix of the training
% %                                         database, which is output of 'EigenfaceCore' function.
% %
% %                A                      - (M*NxP) Matrix of centered image
% %                                         vectors, which is output of 'EigenfaceCore' function.
% % 
% % Returns:       OutputName             - Name of the recognized image in the training database.          
% 
% %%%%%%%%%%%%%%%%%%%%%%%% Projecting centered image vectors into facespace
% % All centered images are projected into facespace by multiplying in
% % Eigenface basis's. Projected vector of each face will be its corresponding
% % feature vector.
% 
% ProjectedImages = [];
% Train_Number = size(Eigenfaces,2);
% for i = 1 : Train_Number
%     temp = Eigenfaces'*A(:,i); % Projection of centered images into facespace
%     ProjectedImages = [ProjectedImages temp]; 
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%% Extracting the PCA features from test image
% InputImage = imread(TestImage);
% temp = InputImage(:,:,1);
% 
% [irow icol] = size(temp);
% InImage = reshape(temp',irow*icol,1);
% Difference = double(InImage)-m; % Centered test image
% ProjectedTestImage = Eigenfaces'*Difference; % Test image feature vector
% 
% %%%%%%%%%%%%%%%%%%%%%%%% Calculating Euclidean distances 
% % Euclidean distances between the projected test image and the projection
% % of all centered training images are calculated. Test image is
% % supposed to have minimum distance with its corresponding image in the
% % training database.
% 
% Euc_dist = [];
% for i = 1 : Train_Number
%     q = ProjectedImages(:,i);
%     temp = ( norm( ProjectedTestImage - q ) )^2;
%     Euc_dist = [Euc_dist temp];
% end
% 
% [Euc_dist_min , Recognized_index] = min(Euc_dist);
% OutputName = int2str(Recognized_index);


















% imshow(reshape(Eigenfaces(1,:),[64,64]));

% % steps 1 and 2: find the mean image and the mean-shifted input images
% mean_face = mean(images, 2);
% shifted_images = images - repmat(mean_face, 1, num_images);
%  
% % steps 3 and 4: calculate the ordered eigenvectors and eigenvalues
% [evectors, score, evalues] = princomp(images');
%  
% % step 5: only retain the top 'num_eigenfaces' eigenvectors (i.e. the principal components)
% num_eigenfaces = 20;
% evectors = evectors(:, 1:num_eigenfaces);
%  
% % step 6: project the images into the subspace to generate the feature vectors
% features = evectors' * shifted_images;


% BoW visual representation (Or any other better representation)


load('./data/face_verification/face_verification_va.mat')
for i =1:length(va_img_pair)
    temp = single(va_img_pair{i,1})/255;
    temp = vl_lbp(temp, cellSize);
    temp_Xva1 = temp(:)';
    
    temp = single(va_img_pair{i,3})/255;
    temp = vl_lbp(temp, cellSize);
    temp_Xva2 = temp(:)';
    
    Xva = [Xva;temp_Xva1-temp_Xva2];
end

%% Train the verifier and evaluate the performance
Xtr = double(Xtr);
Xva = double(Xva);


% Train the recognizer and evaluate the performance
%model = fitcknn(Xtr,Ytr,'NumNeighbors',3);
%[l,prob] = predict(model,Xva);

model = fitcecoc(Xtr,Ytr);
[l,prob] = predict(model,Xva);

% Compute the accuracy
acc = mean(l==Yva)*100;

fprintf('The accuracy of face recognition is:%.2f \n', acc)



%% Visualization the result of face verification

data_idx = [100,200,300]; % The index of image in validation set
nPairs = 3; % number of visualize data. maximum is 3
% nPairs = length(data_idx); 
visualise_verification(va_img_pair,prob,Yva,data_idx,nPairs )