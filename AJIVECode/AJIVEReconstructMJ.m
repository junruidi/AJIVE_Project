function outstruct = AJIVEReconstructMJ(datablock, threshold, dataname, row_joint, ioutput)
%  function for AJIVE Matrix re-construction
% Inputs:
%   datablock        - cells of data matrices {datablock 1, ..., datablock k}
%                    - Each data matrix is a d x n matrix that each row is
%   dataname         - a cell of strings: name of each data block; default
%                    - name is {'datablock1', ..., 'datablockk'}
%   row_joint        - orthonormal basis of estimated joint row space 
%                      output of 'AJIVEJointSelectMJ.m'
%    ioutput         - 0-1 indicator vector of output's structure 
%                      [CNS,  
%                       CNSloading, 
%                       BSSjoint,
%                       BSSjointLoading, 
%                       BSSindiv, 
%                       BSSindivLoading,
%                       MatrixJoint,
%                       MatrixIndiv, 
%                       MatrixResid
%                       ] 
% Outputs:
%   outstruct        - a structure contains all elements in ioutput
%
%    Copyright (c) Meilei Jiang, Qing Feng, Jan Hannig & J. S. Marron 2017

k = length(datablock);

% check and re-adjust the joint rank

DeleteJointRows = []; % Delete the rows in the row_joint, which have low 
                % variance projected on some datablocks.
for ib = 1:k
    JointDirection = datablock{ib} * row_joint';
    % Rows in the joint space basis have sd lower than threshold.
    LowSdJointRow = find(sqrt(sum(JointDirection.^2, 1)) <= threshold(ib));    
    if size(LowSdJointRow) > 0
        if size(LowSdJointRow) == 1
            disp(['Note: The ' num2order(LowSdJointRow) ' joint space basis vector has low variance in ' dataname{ib} '.'])
        else
            disp(join(['Note: The ' join(cellstr(num2order(LowSdJointRow)), ', ') ' joint space basis vectors have low variance in ' dataname{ib} '.'],''))
        end       
        DeleteJointRows = union(DeleteJointRows, LowSdJointRow);
    end    
end 

if size(DeleteJointRows) >  0
    if size(DeleteJointRows) == 1
            disp(['Note: The ' num2order(DeleteJointRows) ' joint space basis vector will be dropped.'])
    else
            disp(join(['Note: The ' join(cellstr(num2order(DeleteJointRows)), ', ') ' joint space basis vectors will be dropped.'],''))
    end 
end

row_joint( DeleteJointRows, :) = [];
rjoint = size(row_joint, 1);
disp(['Final Joint rank: ' num2str(rjoint)]);

% Reconstruction the AJIVE decomposition in each datablock

CNS = row_joint;

CNSloading = cell(1,k);
BSSjoint = cell(1,k);
BSSjointLoading = cell(1,k);
BSSindiv = cell(1,k);
BSSindivLoading = cell(1,k);

MatrixJoint = cell(1,k);
MatrixIndiv = cell(1,k);
MatrixResid = cell(1,k);

rankI = zeros(1, k);

for ib = 1:k
    
% Joint reconstruction
    % Loadings of Common Normalized Score on each data block 
    CNSloading{ib} = datablock{ib}/row_joint;
    
    % Joint Block in each data block
    MatrixJoint{ib} = datablock{ib} * (row_joint' * row_joint);
    
    % Block Specitic Scores
    [t1,t2,t3] = svds(MatrixJoint{ib},rjoint);
    BSSjointLoading{ib} = t1;
    BSSjoint{ib} = t2*t3';

    %  Individual reconstruction 
    % orthogonal basis od null space of joint
    p = null(MatrixJoint{ib})';
    proj_joint_row = p'*p;

    indiv = datablock{ib}*proj_joint_row;
    s_indiv = svd(indiv);

    rI = length(find(s_indiv>threshold(ib)));
    [t1,t2,t3] = svds(indiv,rI);
    MatrixIndiv{ib} = t1*t2*t3';
    BSSindivLoading{ib} = t1;
    BSSindiv{ib} = t2*t3';
    rankI(ib) = rI;
    disp(['Final individual ' dataname{ib} ' rank: ' num2str(rI)]);

    % Residual reconstruction
    row = [orth(CNS')';orth(MatrixIndiv{ib}')'];
    p = null(row)'; %orthogonal basis od null space of joint
    proj = p'*p;
    MatrixResid{ib} = datablock{ib}*proj;
end;



% return needed results based on ioutput
if ioutput(1) == 1 % output common normalized score
    outstruct.CNS = CNS;
else 
    outstruct.CNS = [];
end

if ioutput(2) == 1 % output projection loadings of common normalized score
    outstruct.CNSloading = CNSloading;
else 
    outstruct.CNSloading = {};
end

if ioutput(3) == 1 % output block specific scores of each joint
    outstruct.BSSjoint = BSSjoint;
else 
    outstruct.BSSjoint = {};
end

if ioutput(4) == 1 % output the loading matrix of each joint block specific score
    outstruct.BSSjointLoading = BSSjointLoading;
else 
    outstruct.BSSjointLoading = {};
end


if ioutput(5) == 1 % output block specific scores of each individual
    outstruct.BSSindiv = BSSindiv;
else 
    outstruct.individualbss = {};
end

if ioutput(6) == 1 % output the loading matrix of each individual block specific score
    outstruct.BSSindivLoading = BSSindivLoading;
else 
    outstruct.BSSindivLoading = {};
end

if ioutput(7) == 1 % output joint matrices
    outstruct.MatrixJoint = MatrixJoint;
else 
    outstruct.MatrixJoint = {};
end

if ioutput(8) == 1 % output individual matrices
    outstruct.MatrixIndiv = MatrixIndiv;
else 
    outstruct.MatrixIndiv = {};
end

if ioutput(9) == 1 % output residual matrices
    outstruct.MatrixResid = MatrixResid;
else 
    outstruct.MatrixResid = {};
end

