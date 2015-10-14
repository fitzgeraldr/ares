function v = isanglename(prop)

anglenames = {'theta','dtheta','absdtheta','d2theta','absd2theta','smooththeta',...
  'smoothdtheta','smoothd2theta','abssmoothd2theta','phi','yaw','absyaw',...
  'dtheta_tail','absdtheta_tail','phisideways','absphisideways','theta2wall','anglesub',...
  'absdangle2wall','absthetadiff_center','absthetadiff_nose2ell','absthetadiff_ell2nose',...
  'absthetadiff_anglesub','absphidiff_center','absphidiff_nose2ell','absphidiff_ell2nose',...
  'absphidiff_anglesub','absanglefrom1to2_center','absanglefrom1to2_nose2ell',...
  'absanglefrom1to2_ell2nose','absanglefrom1to2_anglesub','danglesub'};
v = ismember(prop,anglenames);