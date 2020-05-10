##

function pgs(;db=D, smkernel=[[0.3, 0.7]; ones(9); [0.7, 0.3]],
   assessDelta=14, expressDelta=7, doplot=true, plottype="R", counttype="deaths", fname="",
   mincases=10, fignum=nothing,
   p2RFn= p ->(p./100 .+ 1).^(5.2/7), R2pFn = R -> Int64.(round.((R.^(7/5.2) .- 1) .* 100)) )

   stateAbbrevMapFilename = "StateNamesAndAbbreviations.csv"
   stateList         = readdlm(stateAbbrevMapFilename, ',');
   stateList         = stateList[[1:50;52],:]

   p  = zeros(size(stateList,1))
   R  = zeros(size(stateList,1))
   cs = zeros(size(stateList,1))

   for i=1:length(p)
      c = country2conf(db, (String(stateList[i,1]), "US"))
      if smooth(diff(c), [ones(7);zeros(6)])[end] >= mincases
         pg = smooth(percentileGrowth(smooth(diff(c), smkernel),
            assessDelta=assessDelta, expressDelta=expressDelta), [0.5, 1, 0.5])
            p[i]  = pg[end]
            R[i]  = (1+p[i]/100).^(5.2/7)
            cs[i] = smooth(diff(c), [0.5, 1, 0.5])[end]
      else
         p[i] = NaN;
         R[i] = NaN;
      end
   end

   u = sortperm(R)
   stateList = stateList[u,:]; R = R[u]; p = p[u]; cs = cs[u];
   u = findall(.!isnan.(R))
   stateList = stateList[u,:]; R = R[u]; p = p[u]; cs = cs[u];

   z = hcat(stateList, p, R, cs)

   if doplot
      if fignum != nothing
         figure(fignum)
      end
      set_current_fig_position(115, 61, 1496, 856)
      clf();
      s = plottype=="R" ? R : p
      bar(1:length(s), s)
      for i=1:length(s)
         delta = 0.01*(ylim()[2]-ylim()[1])
         delta = s[i] >= 0 ? delta : -2.5*delta
         text(i, s[i]+delta, z[i,2], horizontalAlignment="center", fontsize=10);
      end


      if plottype=="p"
         ylabel("% change per week", fontsize=fontsize, fontname=fontname)
      else
         ylabel("R", fontsize=fontsize, fontname=fontname)
         mn = floor(minimum(R)*10)/10; mx = ceil(maximum(R)*10)/10
         ylim(mn, mx)
         thingy = ""
         title("$(mydate(db[1,end])) : $counttype : current R (change factor in 5.2 days; LEFT) "*
            "\nand % weekly change (RIGHT) for states with current $counttype/day>=$mincases)",
            fontsize=fontsize, fontname=fontname)
      end

      grid("on")
      gca().tick_params(labelsize=16)
      gca().yaxis.tick_right()
      gca().tick_params(labeltop=false, labelleft=true)
      addSourceString2Linear()
      gca().set_xticks([])
      if plottype=="p"
         secax = rightHandAxis(old2newFn=p2RFn, ticks2convert=-20:20:60)
         secax.set_ylabel("R", fontsize=fontsize, fontname=fontname)
      else
         secax = rightHandAxis(old2newFn=R2pFn, ticks2convert=0.7:0.1:1.5)
         secax.set_ylabel("% change per week", fontsize=fontsize, fontname=fontname)
      end
      hlines(plottype=="R" ? 1 : 0, -1, length(s)+1, linestyle="--", color="#ff7777")
      # axisWidthChange(0.95, lock="l")
      # PyPlot.show()

      savefig2jpg(fname)
   end

   return z
end

pgs(db=D[:,1:end], mincases=10, fignum=2000, fname="statesCurrentDeathGrowthRates")
##


# dname = "../../data/covidtracking.com/api/states"
# fname = "daily.csv"
#
# C = readdlm("$dname/$fname", ',');
# PV = covid2JHParsing(C, "positive./(positive + negative)")
#
# region = ("California", "US")
#
# d = country2conf(D, region)
# pv = country2conf(PV, region)
# pg = smooth(percentileGrowth(smooth(diff(d), smkernel), assessDelta=14, expressDelta=7),
#    [0.5, 1, 0.5])
#
# dp=20
# clf()
# subplot(2,1,1)
# plot(pg[end-dp:end])
#
# subplot(2,1,2)
# n=length(pg)
# plot(pv[end-n+1:end][end-dp:end])


##
# function newguys(str)
#    return "hcat(zeros(size($str,1)), diff($str, dims=2))"
# end
#
# TP = covid2JHParsing(C, newguys("positive")*"./"*newguys("totalTestResults"))
# regions = [("Massachusetts", "US"), ("New York", "US"), ("New Jersey", "US"),
#    ("Florida", "US"), ("Ohio", "US"), ("Pennsylvania", "US"),
#    ("Indiana", "US"), ("Iowa", "US"), ("Minnesota", "US"),
#    ("South Carolina", "US"), ("California", "US"), ("Georgia", "US")]
#
# plotMany(regions, db=TP, plotFn=plot, days_previous=28, fignum=1000,
#    fn = x ->smooth(x, [0.1:0.1:0.7; 0.6:-0.1:0.1]),
#    labelSuffixFn = (pais, origSeries, series) -> " curr=$(round(series[end], digits=2))")
# title("test positivity", fontname=fontname, fontsize=fontsize)
#
# ##


##
"""
Response to 2020-05-05 Washington Post opinion piece by "5 Republican Governors"
"""

badStates = ("5 Republican Governors\nWY+NE+AR+IA+MO",
   [("Wyoming", "US"), ("Nebraska", "US"), ("Arkansas", "US"),
   ("Iowa", "US"), ("Missouri", "US")])



plotNew([badStates, ("Wyoming", "US"), ("Nebraska", "US"), ("Arkansas", "US"),
("Iowa", "US"), ("Missouri", "US"), ("Arizona", "US"), ("Mississippi", "US")],
   db=D[:,1:end], plotFn=semilogy, days_previous=56,
   smkernel=[[0.3,0.7,1,1,1,1,1];zeros(6)], fignum=1001, counttype="deaths",
   mincases=1, minval=1, fname="", maxtic=40, mintic=1, maxval=40)
ylim(1, 40)
gca().set_yticks([1;5:5:40]);
gca().set_yticklabels(["1", "5", "10", "15", "20", "25", "30", "35", "40"])
savefig2jpg("Temp/5RepStatesDeathsByState")

plotNew([badStates], db=D[:,1:end], plotFn=semilogy, days_previous=56,
   smkernel=[[0.3,0.7,1,1,1,1,1];zeros(6)], fignum=1000, counttype="deaths",
   mincases=10, minval=10, fname="", maxtic=40, mintic=10)

gca().set_yticks(10:5:40);
gca().set_yticklabels(["10", "15", "20", "25", "30", "35", "40"])
savefig2jpg("Temp/5RepStatesDeaths")

function newguys(str)
   return "hcat(zeros(size($str,1)), diff($str, dims=2))"
end

C = loadRawCovidTrackingMatrix()
NP = covid2JHParsing(C, newguys("positive"));         np = country2conf(NP, badStates)
NT = covid2JHParsing(C, newguys("totalTestResults")); nt = country2conf(NT, badStates)

figure(2001); clf();
plot(-(length(np)-1):0, smooth(np./nt, [[0.3,0.7];ones(5);zeros(6)]), "-o"); grid("on")
title("Test positivity", fontname=fontname, fontsize=fontsize)
ylabel("test positivity")
xlabel("days")
xAxisTickPeriod(7)

savefig2jpg("Temp/5RepStatesTestPositivity")
