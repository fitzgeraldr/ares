function handles = fix_SwapIdentities( handles, f, fly1, fly2 )
% swaps the identites of two flies, from frame f until their ends
% splintered from fixerrorsgui 6/21/12 JAB

trk1 = fix_GetPartOfTrack(handles.trx(fly1),f,inf);
trk2 = fix_GetPartOfTrack(handles.trx(fly2),f,inf);
handles.trx(fly1) = fix_GetPartOfTrack(handles.trx(fly1),1,f-1);
handles.trx(fly2) = fix_GetPartOfTrack(handles.trx(fly2),1,f-1);
handles.trx(fly1) = fix_CatTracks(handles.trx(fly1),trk2);
handles.trx(fly2) = fix_CatTracks(handles.trx(fly2),trk1);

handles = fix_FixDeathEvent(handles,fly1);
handles = fix_FixDeathEvent(handles,fly2);

handles = fix_SwapEvents(handles,fly1,fly2,f,inf);

fix_FixUpdateFly(handles,fly1);
fix_FixUpdateFly(handles,fly2);
