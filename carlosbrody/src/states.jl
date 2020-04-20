##
# ======================================
#
#  US STATES
#
# ======================================

south = ("South: FL+LA+TN+GA+MS+\nAK+NC+SC+AL+KY", [("Florida", "US"), ("Louisiana", "US"),
   ("Tennessee", "US"), ("Georgia", "US"), ("Mississippi", "US"),
   ("Arkansas", "US"), ("North Carolina", "US"), ("South Carolina", "US"),
   ("Alabama", "US"), ("Kentucky", "US")])
mexicoborder = ("Mexico border: TX+NM+AZ", [("Texas", "US"),
   ("New Mexico", "US"), ("Arizona", "US")])
midwest = ("Midwest: IA+MO+OK+KS+NE\nWY, CO, UT",
   [("Iowa", "US"), ("Missouri", "US"),
   ("Oklahoma", "US"), ("Kansas", "US"), ("Nebraska", "US"), ("Wyoming", "US"),
   ("Colorado", "US"), ("Utah", "US")])
canadaborder = ("Canada border:\nMI+IL+WI+MN+ND+MT", [("Michigan", "US"),
   ("Illinois", "US"), ("Wisconsin", "US"), ("Minnesota", "US"),
   ("North Dakota", "US"), ("Montana", "US")])
nostayhome = ("No Stay-At-Home order: SD+ND+IA+NE+AK",
   [("South Dakota", "US"), ("Iowa", "US"),
   ("North Dakota", "US"), ("Nebraska", "US"), ("Arkansas", "US")])

states = ["US", "Italy",
   ("Washington", "US"), ("New York", "US"), ("California", "US"),
   ("Florida", "US"), ("Texas", "US"),
   # "Italy", "Germany", "Brazil", africa,
   ("New Jersey", "US"), ("Illinois", "US"),
   ("Louisiana", "US"), # "Australia",
   south, mexicoborder, midwest, canadaborder, ("Connecticut", "US"),
   nostayhome]

plotGrowth(vcat(states, "World other than China"),
   fignum=10, fname="statesGrowthRate") # , smkernel=[0.2, 0.4, 0.5, 0.7, 0.5, 0.4, 0.2])
plotCumulative(states, fignum=11, maxtic=100000, fname="statesCumulative")
plotAligned(states, fname="states_confirmed_aligned",
   mintic=100, maxtic=100000, fignum=5, minval=10)
plotNew(states, fignum=14, fname="statesNew", mintic=100, minval=80, maxval=40000)
plotNew(states, db=D, minval=1, mintic=1, maxtic = 4000,
   counttype="deaths", fname="statesNewDeaths")



##

mystates = ["Italy", "US",
   ("Washington", "US"), ("New York", "US"), ("California", "US"),
   ("Florida", "US"), ("Texas", "US"),
   ("New Jersey", "US"), ("Illinois", "US"),
   ("Louisiana", "US"), # "Australia",
   nostayhome]

function labelSuffixFn(pais, origSeries, series)
   series = origSeries[.!isnan.(origSeries)]
   series = series[series .!= Inf]

   peak   = Int64(ceil.(smooth(diff(series[end-35:end]), [0.2, 0.5, 1, 0.5, 0.2]))[end])
   popstr = "$(round(country2conf(A, pais, rcols="Population")[1]/1e6, digits=1))M"
   return " currently=$peak/day, pop=$popstr"
end

plotNewGrowth(mystates, fname="statesNewDeathsGrowthRate", db=D, fignum=18,
   counttype="deaths", days_previous=26, legendLocation="lower left", labelSuffixFn=labelSuffixFn)

plotNewGrowth(mystates, fname="statesNewCasesGrowthRate", db=A, ylim1=-70, fignum=19,
   counttype="new cases", days_previous=26, legendLocation="lower left", labelSuffixFn=labelSuffixFn)

##

prefix = "states"
sections = [
   "New cases growth rates"         "$(prefix)NewCasesGrowthRate"
   "New deaths growth rates"        "$(prefix)NewDeathsGrowthRate"
   "New cases per day"              "$(prefix)New"
   "New deaths per day"             "$(prefix)NewDeaths"
   "Cumulative number of confirmed cases by region, aligned on equal caseload"  "$(prefix)_confirmed_aligned"
   "Cumulative number of cases"     "$(prefix)Cumulative"
   "Daily percentile growth rates"  "$(prefix)GrowthRate"
]

writeReadme(prefix=prefix, dirname="../../$prefix", header1="US States", sections=sections)
