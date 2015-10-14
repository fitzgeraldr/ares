function [cs e Tdt learned offset]=OlympiadHeatControl(cs,sp,data,e,scale,Tdt,learned)
%cs = control signal (between -100 and 100 = power output % around room temp
%e = error (vector containing last minute or two of error values
%data = left and right dummy tube values
%scale = base gain for control system
%Tdt = time since last change in temperature for use in learning


%Offset for left and right peltiers in % (between 0 and 21)
% Not yet exactly sure on which peltier is plugged into which driver
% only one should have a non-zero value at a time
offset(1) = 0;      %2 was good prior to recalib on 1/29/10 wk for Zeus
                    %this was 7 (2/1/10) changed to 0, gkl

offset(2) = 0;

%-------------------------------------------------------
% Learned set points equations fit in excel w/ >.99 r^2 
roomtemp = 26.5;        %
percentDELTA=25;        %extra % to hold baseline bang-bang up high

if sp>roomtemp
    dbc = 110; %delay before active control (seconds)
else
    dbc = 0;
end

if sp>roomtemp
    if Tdt<dbc%heating
        tcs = 2.1595*sp + 44.835-100 + percentDELTA;  
    else
        tcs = 2.1595*sp + 44.835-100 + percentDELTA;  
    end
else%cooling
    tcs = -1.1786*sp^2 + 67.393*sp - 858.43-100;
end
%-------------------------------------------------------


if isnan(cs)
    cs = 0;
end

%Base scale is handed in (100)
%Tdt contains the time of the last transition

%reasons to be in bang-bang area
switchDiff=(46-sp)/4; %empirically determined overshoot analysis, cool to target

    %Error value calculation (for P term
    e=[e, sp-data];
    nHistory=60;
    if length(e)>nHistory
        e=e(end-nHistory:end);
    end

    %Here are the PID terms where the integral/differential terms are averaged
    %over the last nHistory seconds
    diffe=diff(e);
    ie=sum(e)/length(e);
    try de=sum(diffe(end)); catch; de=0; end
    pe=e(end);

    
if (sp>roomtemp)&&(pe>switchDiff)
    
    cs = 100;
    Tdt = 0; %reset the time constant of the learning factor
    
else %breaking around a learned target

    
    %PID control values (This is just P/D)
    Kp=.01;
    Ki=0; %no integral term, use the decaying learn factor below instead
    Kd=1;
    corr=(pe*Kp+ie*Ki+de*Kd);
    if isnan(corr); corr=0; end

    if corr>100; corr=100; end
    if corr<-100; corr=-100; end
    
    if (Tdt<dbc)  %hold at predetermined target for dbc seconds
        cs = tcs;
    else %after 1 minute, start active control

        corr = corr*(10+scale*(exp(-(Tdt-dbc)/240)));
    
        %During changes of set point, this can sometimes be very high due to nature of D Term
        if abs(corr)>5
            corr = 0;
        end
        
        cs = cs+corr;
        %Prevent the power from moving too far from the open loop
        %characterization values.  This helps to settle the temp faster.
        if sp>roomtemp
            if (cs)>(tcs+20)
                cs = tcs+20;
            elseif (cs)<(tcs-30)
                cs = tcs-30;
            end
        end
%         fprintf('%d:,%0.2f, corr:%0.3f\n',7,cs,corr)
        
    end
    %decrease learning parameter w/ a given time constant falling
    %down to a fixed floor so it can respond to long term soaking
    Tdt = Tdt+1;
end


if cs>100; cs=100; end
if cs<-100; cs=-100; end


% disp(num2str([pe*Kp ie*Ki de*Kd corr cs+100 tcs+100]))
