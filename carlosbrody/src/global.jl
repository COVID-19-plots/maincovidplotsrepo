# ====================================
#
#  AROUND THE WORLD
#
# ====================================


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


plotCumulative(paises, fname="confirmed");
plotNew(paises, fignum=2, fname="newConfirmed")
plotGrowth(paises, counttype="cases", fname = "multiplicative_factor_1", ylim2=51)
plotAligned(paises, fignum=4, fname="confirmed_aligned")
plotNew(paises, db=D, minval=1, mintic=1, maxtic = 10000,
   counttype="deaths", fname="newDeaths")

## ---- states confirmed aligned
