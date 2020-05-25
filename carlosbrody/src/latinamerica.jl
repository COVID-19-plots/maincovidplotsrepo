
##
# ======================================
#
#  LATIN AMERICA
#
# ======================================

la = ["Mexico", "Uruguay", "Argentina", "Brazil", "Chile", "Colombia",
   "Peru", "Ecuador", "Bolivia", "Panama", "Venezuela", "Costa Rica"]

allLA = ("All Latin America", la)

plotCumulative(la, fname="laCumulative", fignum=8, minval=100,
   mintic=100, maxtic=40000)
plotGrowth(vcat(la, ["Italy", "World other than China"]), days_previous=15,
   yticks=0:10:40, ylim2=45, fname="laGrowthRate", fignum=15)
plotAligned(vcat(la, "Italy"), fname="laAligned",
   mintic=100, maxtic=400000, fignum=16, minval=10)
plotNew(vcat(la, allLA), fignum=17, fname="laNew", maxtic=40000, minval=1, mintic=1)
plotNew(la, db=D, minval=1, mintic=1, maxtic = 1000,
   counttype="deaths", fname="laNewDeaths")

##

function labelSuffixFn(pais, origSeries, series)
   series = origSeries[.!isnan.(origSeries)]
   series = series[series .!= Inf]

   peak   = Int64(ceil.(smooth(diff(series[end-35:end]), [0.2, 0.5, 1, 0.5, 0.2]))[end])
   popstr = "$(round(country2conf(A, pais, rcols="Population")[1]/1e6, digits=1))M"
   return " currently=$peak/day, pop=$popstr"
end


plotNewGrowth(la, fname="laNewDeathsGrowthRate", db=D, fignum=18,
   ylim1=-90, ylim2=140,
   counttype="deaths", days_previous=26, legendLocation="lower left", labelSuffixFn=labelSuffixFn,
   smkernel=[0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 1.0, 0.7, 0.5, 0.4, 0.3, 0.2, 0.1],
   fn=x -> smooth(percentileGrowth(smooth(diff(x), smkernel), assessDelta=14, expressDelta=7), [0.5, 1, 0.5]))

plotNewGrowth(la, fname="laNewCasesGrowthRate", db=A, ylim1=-70, fignum=19,
   counttype="new cases", days_previous=26, legendLocation="lower left", labelSuffixFn=labelSuffixFn,
   smkernel=[0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 1.0, 0.7, 0.5, 0.4, 0.3, 0.2, 0.1],
   fn=x -> smooth(percentileGrowth(smooth(diff(x), smkernel), assessDelta=14, expressDelta=7), [0.5, 1, 0.5]))


writeReadme(prefix="la", dirname="../../latinamerica", header1="Latin America")
