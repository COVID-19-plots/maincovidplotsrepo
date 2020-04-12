
close("all")

europe = ["US", "Italy", "Germany", "Spain", "Portugal", "France", "United Kingdom", "Switzerland",
"Austria", "Greece", "Netherlands", "Sweden", "Norway", "Finland", "Denmark", "Korea, South",
"Hungary", "Turkey", "Russia"]

alleurope = ("All Europe", setdiff(europe, ["US", "Korea, South"]))

plotGrowth(vcat(europe, "World other than China"),
   fignum=1, fname="europeGrowthRate") # , smkernel=[0.2, 0.4, 0.5, 0.7, 0.5, 0.4, 0.2])
plotCumulative(europe, fignum=12, maxtic=100000, fname="europeCumulative")
plotAligned(europe, fname="europeAligned",
   mintic=100, maxtic=100000, fignum=3, minval=10, alignon=400)
plotNew(vcat(europe, alleurope), fignum=14, fname="europeNew")
plotNew(vcat(europe, alleurope), db=D, minval=1, mintic=1, maxtic = 10000,
   counttype="deaths", fname="europeNewDeaths")


smkernel=[0.3, 0.5, 0.7, 1, 0.7, 0.5, 0.3];
myfun = x -> smooth(diff(x), smkernel)./maximum(smooth(diff(x), smkernel))


##


soffsets = Dict(
   "Austria"=>0,
   "Sweden"=>-0.5,
   "Norway"=>1,
   "Italy"=>-0.5,
   "Spain"=>0,
   alleurope=>-0.5,
   "Korea, South"=>2,
   "Portugal"=>-1,
   ("Hubei", "China")=>-2
)

plotDeathPeakAligned([("Hubei", "China"), # "Portugal",
   "Italy", "Spain", "Netherlands", "Denmark", "Greece"], fname="deathPeakAligned", soffsets=soffsets,
   fignum=24)

##

writeReadme(prefix="europe", header1="Europe")
