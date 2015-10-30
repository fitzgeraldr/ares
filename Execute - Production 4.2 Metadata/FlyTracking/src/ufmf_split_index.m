%% Split index struct into individual tubes of information to be
%  compatible with wrapup function

%% Frame information
indexes.tube1.frame.loc = index.frame.loc(:,1);indexes.tube1.frame.timestamp = index.frame.timestamp(:,1);
indexes.tube2.frame.loc = index.frame.loc(:,2);indexes.tube2.frame.timestamp = index.frame.timestamp(:,2);
indexes.tube3.frame.loc = index.frame.loc(:,3);indexes.tube3.frame.timestamp = index.frame.timestamp(:,3);
indexes.tube4.frame.loc = index.frame.loc(:,4);indexes.tube4.frame.timestamp = index.frame.timestamp(:,4);
indexes.tube5.frame.loc = index.frame.loc(:,5);indexes.tube5.frame.timestamp = index.frame.timestamp(:,5);
indexes.tube6.frame.loc = index.frame.loc(:,6);indexes.tube6.frame.timestamp = index.frame.timestamp(:,6);

%% Keyframe information
indexes.tube1.keyframe.mean.loc = index.keyframe.mean.loc(:,1);indexes.tube1.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,1);
indexes.tube2.keyframe.mean.loc = index.keyframe.mean.loc(:,2);indexes.tube2.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,2);
indexes.tube3.keyframe.mean.loc = index.keyframe.mean.loc(:,3);indexes.tube3.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,3);
indexes.tube4.keyframe.mean.loc = index.keyframe.mean.loc(:,4);indexes.tube4.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,4);
indexes.tube5.keyframe.mean.loc = index.keyframe.mean.loc(:,5);indexes.tube5.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,5);
indexes.tube6.keyframe.mean.loc = index.keyframe.mean.loc(:,6);indexes.tube6.keyframe.mean.timestamp = index.keyframe.mean.timestamp(:,6);
