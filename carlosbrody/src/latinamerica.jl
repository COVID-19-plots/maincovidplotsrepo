
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
   mintic=100, maxtic=4000)
plotGrowth(vcat(la, ["Italy", "World other than China"]), days_previous=15,
   yticks=0:10:40, ylim2=45, fname="laGrowthRate", fignum=15)
plotAligned(vcat(la, "Italy"), fname="laAligned",
   mintic=100, maxtic=100000, fignum=16, minval=10)
plotNew(vcat(la, allLA), fignum=17, fname="laNew", maxtic=1000, minval=1, mintic=1)
plotNew(la, db=D, minval=1, mintic=1, maxtic = 100,
   counttype="deaths", fname="laNewDeaths")

##

plotNewGrowth(la, fname="laNewDeathsGrowthRate", db=D, fignum=18,
   ylim1=-90, ylim2=140,
   counttype="deaths", days_previous=26, legendLocation="lower left")

plotNewGrowth(la, fname="laNewCasesGrowthRate", db=A, ylim1=-70, fignum=19,
   counttype="new cases", days_previous=26, legendLocation="lower left")


writeReadme(prefix="la", dirname="../../latinamerica", header1="Latin America")
