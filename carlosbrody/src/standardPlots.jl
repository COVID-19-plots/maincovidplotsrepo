##

# ====================================
#
#  CUMULATIVE CONFIRMED
#
# ====================================


# ======================================
#
#  REGIONS AROUND THE WORLD
#
# ======================================
# How many days previous to today to plot
days_previous = 29

africa = ("Africa below Sahara", ["South Africa", "Namibia", "Congo", "Gabon",
"Niger", "Chad", "South Sudan",
"Cameroon", "Equatorial Guinea", "Nigeria", "Benin", "Togo",
"Ghana", "Cote d'Ivoire", "Liberia", "Guinea", "Senegal",
"Burkina Faso", "Mauritania",
"Sudan", "Central African Republic", "Ethiopia",
"Rwanda", "Uganda", "Somalia", "Kenya", "Tanzania"])

# list of countries to plot
paises = ["Korea, South", "Iran", "Italy", "Germany", "France",
   "Japan",
   "Spain",
   "US", "Switzerland",
   "United Kingdom", ("New York", "US"),
   "China", ("California", "US"),
   "Brazil", "Argentina", "Mexico",
   "India", africa, ("New Jersey", "US"), # "Other European Countries",
   ("Hong Kong", "China"),
   "Singapore", ("Washington", "US"),
   "World other than China"]


# paises = ["Germany", "United Kingdom", "Italy",
#    ("Washington", "US"), ("California", "US"),
#    # ("New Jersey", "US"), ("New York", "US"),
#    "Belgium", africa, "Australia", # ("New Jersey", "US"), # "Other European Countries",
#    "World other than China"]

# oeurope = ["Netherlands", "Sweden", "Belgium", "Norway", "Austria", "Denmark"]
# other_europe = "Other European Countries"
# other_europe_kwargs = Dict(:linewidth=>6, :color=>"gray", :alpha=>0.3)


plotCumulative(paises, fname="confirmed")
plotNew(paises, fignum=2, fname="newConfirmed")
plotGrowth(paises, counttype="cases", fname = "multiplicative_factor_1", ylim2=51)
plotAligned(paises, fignum=4, fname="confirmed_aligned")

## ---- states confirmed aligned

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

states = ["US", "Italy",
   ("Washington", "US"), ("New York", "US"), ("California", "US"),
   ("Florida", "US"), ("Texas", "US"),
   # "Italy", "Germany", "Brazil", africa,
   ("New Jersey", "US"), # "Australia",
   south, mexicoborder, midwest, canadaborder]

plotGrowth(vcat(states, "World other than China"),
   fignum=10, fname="statesGrowthRate") # , smkernel=[0.2, 0.4, 0.5, 0.7, 0.5, 0.4, 0.2])
plotCumulative(states, fignum=11, maxtic=100000, fname="statesCumulative")
plotAligned(states, fname="states_confirmed_aligned",
   mintic=40, maxtic=100000, fignum=5, minval=10)
plotNew(states, fignum=14, fname="statesNew")


# ======================================
#
#  LATIN AMERICA
#
# ======================================

la = ["Mexico", "Uruguay", "Argentina", "Brazil", "Chile", "Colombia",
   "Peru", "Ecuador", "Bolivia", "Panama", "Venezuela", "Costa Rica"]

plotCumulative(la, fname="confirmedLA", fignum=8, minval=100,
   mintic=100, maxtic=4000)
plotGrowth(vcat(la, ["Italy", "World other than China"]), days_previous=15,
   yticks=0:10:40, ylim2=45, fname="multiplicative_factorLA", fignum=15)
plotAligned(vcat(la, "Italy"), fname="laAligned",
   mintic=40, maxtic=100000, fignum=16, minval=10)
plotNew(la, fignum=17, fname="laNew", maxtic=1000)



# ======================================
#
#  NEW CASES GROWTH RATE
#
# ======================================

smkernel=vcat(0.1:0.2:1, 0.8:-0.2:0.1);
plotGrowth(["World other than China"], days_previous=11,
   yticks=0:10:40, ylim2=40, fname="newGrowthRate", fignum=16,
   smkernel=smkernel,
   fn = x -> smooth(percentileGrowth(diff(x)), smkernel))



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
plotMany(paises, db=D, fn=x -> smooth(diff(x), [0.2, 0.5, 0.7, 0.5, 0.2]),
   minval=1, fignum=7)
ylabel("New deaths per day", fontsize=fontsize, fontname=fontname)
title("Daily COVID-19 mortality in selected regions\nsmoothed with a +/- 2 day window",
   fontsize=fontsize, fontname=fontname)
gca().set_yticks([4, 10, 40, 100, 400, 1000, 4000])
gca().set_yticklabels(["4", "10", "40", "100", "400", "1000",
   "4000"])
# ylim(minval, ylim()[2])
fname = "newDeaths"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# -----   Death growth rate

plotGrowth(paises, fignum=8; db=D, counttype="deaths", mincases=20, yticks=0:10:80,
   ylim2=80, fname="deathGrowthRate")

##
smkernel=[0.5, 1, 0.5]
plotGrowth(paises, fignum=9; db=D, fn=x -> smooth(percentileGrowth(x), smkernel),
   smkernel=smkernel,
   counttype="deaths", mincases=20, yticks=0:10:80, ylim2=80, fname="deathNewGrowthRate")
