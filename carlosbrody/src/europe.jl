
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
   "France"=>1,
   "Netherlands"=>1,
   ("New Jersey", "US")=>-1,
   ("Hubei", "China")=>-2
)

plotDeathPeakAligned([("Hubei", "China"), # ("New York", "US"), ("New Jersey", "US"), # "Portugal",
   "Italy", "Spain", "Germany"], # "Denmark", "Greece", "Austria"
   # "Netherlands", "Austria"],
   fname="deathPeakAligned",
   soffsets=soffsets,
   fignum=24, x0=-35, x1=25)

##

plotNew([("Hubei", "China")], fignum=15, db=D,
   counttype="deaths", days_previous=size(A,2)-22, maxtic=400,
   fname="deathsHubei", mintic=1, minval=0,
   smkernel=[0.3, 0.5, 0.7, 1, 0.7, 0.5, 0.3])
d = -(size(A,2)-26):0
h = plot(d, 170*10 .^ (-(d.+61)./29), color="red",
   label="1/10 every 29 days")[1]
gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize),
   loc="upper left")
savefig2jpg("logClimbdowncl")

##


writeReadme(prefix="europe", header1="Europe")
