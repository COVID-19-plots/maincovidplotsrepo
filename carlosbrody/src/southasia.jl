
close("all")

southasia = ["Pakistan", "India", "Bangladesh", "Thailand", "Vietnam"]

plotGrowth(vcat(southasia, "World other than China"),
   fignum=1, fname="southasiaGrowthRate") # , smkernel=[0.2, 0.4, 0.5, 0.7, 0.5, 0.4, 0.2])
plotCumulative(southasia, fignum=12, maxtic=100000, fname="southasiaCumulative")
plotAligned(southasia, fname="southasiaAligned",
   mintic=100, maxtic=100000, fignum=3, minval=10, alignon=400)
plotNew(southasia, fignum=14, fname="southasiaNew")
plotNew(southasia, db=D, minval=1, mintic=1, maxtic = 10000,
   counttype="deaths", fname="southasiaNewDeaths")



writeReadme(prefix="southasia", header1="South Asia")
