
close("all")

europe = ["US", "Italy", "Germany", "Spain", "Portugal", "France", "United Kingdom", "Switzerland",
"Austria", "Greece", "Netherlands", "Sweden", "Norway", "Finland", "Denmark", "Korea, South",
"Hungary", "Turkey"]

alleurope = ("All Europe", setdiff(europe, ["US", "Korea, South"]))

plotGrowth(vcat(europe, "World other than China"),
   fignum=1, fname="europeGrowthRate") # , smkernel=[0.2, 0.4, 0.5, 0.7, 0.5, 0.4, 0.2])
plotCumulative(europe, fignum=12, maxtic=100000, fname="europeCumulative")
plotAligned(europe, fname="europeAligned",
   mintic=40, maxtic=100000, fignum=3, minval=10, alignon=400)
plotNew(vcat(europe, alleurope), fignum=14, fname="europeNew")
