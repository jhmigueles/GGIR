g.IVIS = function(Xi, epochsizesecondsXi = 5, IVIS_epochsize_seconds = 3600, IVIS_windowsize_minutes = 60, IVIS.activity.metric = 1) {
  
  if (IVIS.activity.metric == 2) { # use binary scoring
    Xi = ifelse((Xi*1000) < 20, 0, 1) # explored on 5 June 2018 as an attempt to better mimic original ISIV construct
    Xi = zoo::rollsum(x=Xi,k=(600/epochsizesecondsXi)) # explored on 5 June 2018 as an first attempt to better mimic original ISIV construct
  }
  if (length(Xi) > (IVIS_epochsize_seconds/epochsizesecondsXi) & length(Xi) >  (IVIS_windowsize_minutes*60)/epochsizesecondsXi) {
    if (IVIS_epochsize_seconds > epochsizesecondsXi) { # downsample Xi now
      Xicum =cumsum(Xi)
      step = IVIS_epochsize_seconds/epochsizesecondsXi # should be 6 when epochsizesecondsXi=5 and IVIS_epochsize_seconds = 30
      select= seq(1,length(Xicum),by=step) # adjusted 17/7/2017
      Xi = diff(c(0,Xicum[select]))/step
    }
    nhr = 24*round(60/IVIS_windowsize_minutes) # Number of hours in a day (modify this variable if you want to study different resolutions)
    Nsecondsinday = 24*3600
    ni = (Nsecondsinday/nhr)/IVIS_epochsize_seconds # number of epochs in an hour
    # derive average day with 1 'hour' resolution (hour => windowsize):
    N = length(Xi)
    hour = rep(1:ceiling(N/ni),each=ni)
    if (length(hour) > N) hour = hour[1:N]
    dat = data.frame(Xi=Xi, hour=hour, stringsAsFactors = TRUE)
    InterdailyStability = NA
    IntradailyVariability = NA
    if (nrow(dat) > 1) {
      hh = aggregate(. ~ hour,data=dat,mean)
      hh$hour_perday = hh$hour - (floor(hh$hour/nhr)*nhr) # 24 hour in a day
      hh$day = ceiling(hh$hour/nhr)
      if (nrow(hh) > 1) {
        hh2 = aggregate(. ~ hour_perday,data=hh,mean)
        Xh = hh2$Xi
        # average acceleration per day
        Xm = suppressWarnings(mean(Xh,na.rm = TRUE))
        p = length(Xh)
        InterdailyStability = (sum((Xh - Xm)^2) * N) / (p * sum((Xi-Xm)^2)) # IS: lower is less synchronized with the 24 hour zeitgeber
        IntradailyVariability = (sum(diff(Xi)^2) * N) / ((N-1) * sum((Xm-Xi)^2)) #IV: higher is more variability within days (fragmentation)
      }
    }
  } else {
    InterdailyStability = NA
    IntradailyVariability = NA
  }
  invisible(list(InterdailyStability=InterdailyStability, IntradailyVariability=IntradailyVariability))
}