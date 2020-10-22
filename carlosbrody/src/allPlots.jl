include("fndefs.jl")

##

# Get the standard starting colors
loadLinespecList()

# How many days previous to today to plot
days_previous = 99


include("global.jl")
include("states.jl")
include("latinamerica.jl")
include("europe.jl")



##
# ======================================
#
#  NEW CASES GROWTH RATE
#
# ======================================

smkernel=vcat(0.1:0.2:1, 0.8:-0.2:0.1);
plotGrowth(["World other than China"], days_previous=25,
   yticks=0:2:30, ylim2=30, fname="newGrowthRate", fignum=16,
   smkernel=smkernel, minval=0,
   fn = x -> smooth(percentileGrowth(diff(x)), smkernel))
ylabel("% daily growth in NEW cases")
##

# ======================================
#
#  MORTALITY
#
# ======================================


## -----  Cumulative Death count
plotMany(paises, db=D, minval=2, fignum=6)
ylabel("cumulative deaths", fontsize=fontsize, fontname=fontname)
title("Cumulative COVID-19 deaths in selected regions", fontsize=fontsize, fontname=fontname)
gca().set_yticks([10, 40, 100, 400, 1000, 4000, 10000])
gca().set_yticklabels(["10", "40", "100", "400", "1000",
   "4000", "10000"])

fname = "deaths"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# ------  New death count
# plotMany(paises, db=D, fn=x -> smooth(diff(x), [0.2, 0.5, 0.7, 0.5, 0.2]),
#    minval=1, fignum=7)
# ylabel("New deaths per day", fontsize=fontsize, fontname=fontname)
# title("Daily COVID-19 mortality in selected regions\nsmoothed with a +/- 2 day window",
#    fontsize=fontsize, fontname=fontname)
# gca().set_yticks([4, 10, 40, 100, 400, 1000, 4000])
# gca().set_yticklabels(["4", "10", "40", "100", "400", "1000",
#    "4000"])
# # ylim(minval, ylim()[2])
# fname = "newDeaths"
# savefig("$fname.png")
# run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# -----   Death growth rate

plotGrowth(paises, fignum=8; db=D, counttype="deaths", mincases=20, yticks=0:10:80,
   ylim2=80, fname="deathGrowthRate")

##
smkernel=[0.5, 1, 0.5]
plotGrowth(paises, fignum=9; db=D, fn=x -> smooth(percentileGrowth(x), smkernel),
   smkernel=smkernel,
   counttype="deaths", mincases=20, yticks=0:10:80, ylim2=80, fname="deathNewGrowthRate")
