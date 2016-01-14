function obj_info_validate(obj_info,numFrames)
% obj_info_validate(obj_info,numFrames)
% Validate complete obj_info.

validateattributes(obj_info.obj_num,{'numeric'},{'positive' 'integer'});
Nobj = obj_info.obj_num;

% start/end_frame
assert(isequal(size(obj_info.start_frame),[1 Nobj]));
assert(isequal(size(obj_info.end_frame),[1 Nobj]));
assert(all(1<=obj_info.start_frame & obj_info.start_frame<=numFrames));
assert(all(1<=obj_info.end_frame & obj_info.end_frame<=numFrames));
nFrmObj = obj_info.end_frame - obj_info.start_frame + 1;
% nFrmObj(i) gives number of frames object i was alive
assert(all(nFrmObj>=1)); % checks that end_frame always comes at or after start_frame

% num_active
assert(isequal(size(obj_info.num_active),[1 numFrames]));
for frmIdx = 1:numFrames
    tfActive =   obj_info.start_frame <= frmIdx ...
               & frmIdx <= obj_info.end_frame; % tf for whether each track is active this frame
    assert(nnz(tfActive)==obj_info.num_active(frmIdx));    
end

% data/x/y
assert(isequal(size(obj_info.data),[1 Nobj]));
assert(isequal(size(obj_info.x),[1 Nobj]));
assert(isequal(size(obj_info.y),[1 Nobj]));
for objIdx = 1:Nobj
    assert(isequal(size(obj_info.data{objIdx}), ...
                   size(obj_info.x{objIdx}), ...
                   size(obj_info.y{objIdx}), ...
                   [1 nFrmObj(objIdx)]));
end
