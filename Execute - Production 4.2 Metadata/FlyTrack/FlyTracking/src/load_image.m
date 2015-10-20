function  I = load_image(inputFile, index, sbfmf_info,ufmf_info)

%% read an image either from an avi file or using the given format
% if (mod(index, 10) == 0)
%     disp(['loading image ' num2str(index)]);
% end

if ~isempty(sbfmf_info)
    [I,stamp] = sbfmfreadframe(index,sbfmf_info.fid,sbfmf_info.frame2file,sbfmf_info.bgcenter); 
elseif ~isempty(ufmf_info)
	I = ufmf_read_frame(ufmf_info,index); 
elseif( isavi(inputFile) )
    if( ispc )
        try 
            frame = aviread(inputFile,index);
            I = frame2im(frame);            
        catch
            disp(['error trapped, frame opened with aviread']);
        end
    else
        %%%% this would be the place to put some avireader for the
        %%%% cluster...
    end
else 
    infile = sprintf(inputFile,index);
    I = imread(infile);
end

if( size(I,3)>1 )
    %I = rgb2gray(I);
    I = call_with_diag([],'rgb2gray',I);
end

%disp(['loaded image ' num2str(index)]);

% %%

% function  I = load_image(ufmf_info, index,varargin)

% %% read an image either from an avi file or using the given format
% % if (mod(index, 10) == 0)
% %     disp(['loading image ' num2str(index)]);
% % end
% if exists(varargin{1})
    % inputFile = varargin{1};
% else
    % inputFile = '';
% end

% if ~isempty(ufmf_info)
    % I = ufmf_read_frame(ufmf_info,index);    
% elseif( isavi(inputFile) )
    % if( ispc )
        % try 
% %             frame = aviread(inputFile,index);
            % frame = VideoReader(inputFile,index);
            % I = frame2im(frame);            
        % catch
            % disp(['error trapped, frame opened with aviread']);
        % end
    % else
        % %%%% this would be the place to put some avireader for the
        % %%%% cluster...
    % end
% else 
    % infile = sprintf(inputFile,index);
    % I = imread(infile);
% end

% if( size(I,3)>1 )
    % %I = rgb2gray(I);
    % I = call_with_diag([],'rgb2gray',I);
% end

% %disp(['loaded image ' num2str(index)]);
