using Revise
using Statistics
using DelimitedFiles
using PyPlot
using Random

push!(LOAD_PATH, ".")
using CarlosUtils
using CovidFunctions

A = loadConfirmedDbase()
D = loadConfirmedDbase(fname = "time_series_19-covid-Deaths.csv")
# US data showed up per county until 09-March-2020, but then only per state
# thereafter. THis function collapses it all into states
A = collapseUSStates(A)
D = collapseUSStates(D)

#

sourcestring = "source: https://github.com/COVID-19-plots/maincovidplotsrepo"

#

# Some hand-fixes from Wikipedia: https://en.wikipedia.org/wiki/2020_coronavirus_pandemic_in_Brazil
A = setValue(A, "Brazil", "3/15/20", 200)
A = setValue(A, "Brazil", "3/16/20", 234)
A = setValue(A, ("Washington", "US"), "3/17/20", 1014)

# Write out the database with the states consolidated
d2name = "../../consolidated_database"
fname  = "time_series_19-covid-Confirmed.csv"
writedlm("$d2name/$fname", A, ',')


# How many days previous to today to plot
days_previous = 29

africa = ("Africa below Sahara", ["South Africa", "Namibia", "Congo", "Gabon",
"Cameroon", "Equatorial Guinea", "Nigeria", "Benin", "Togo",
"Ghana", "Cote d'Ivoire", "Liberia", "Guinea", "Senegal",
"Burkina Faso", "Mauritania",
"Sudan", "Central African Republic", "Ethiopia",
"Somalia", "Kenya", "Tanzania"])

# list of countries to plot
paises = ["Korea, South", "Iran", "Italy", "Germany", "France", "Japan",
   "Spain", "US", "Switzerland", "United Kingdom", ("New York", "US"),
   "China", ("California", "US"),
   "Brazil", "Argentina", "Mexico",
   "India", africa, "Australia", # ("New Jersey", "US"), # "Other European Countries",
   "World other than China"]


# paises = ["Germany", "United Kingdom", "Italy",
#    ("Washington", "US"), ("California", "US"),
#    # ("New Jersey", "US"), ("New York", "US"),
#    "Belgium", africa, "Australia", # ("New Jersey", "US"), # "Other European Countries",
#    "World other than China"]

# oeurope = ["Netherlands", "Sweden", "Belgium", "Norway", "Austria", "Denmark"]
# other_europe = "Other European Countries"
# other_europe_kwargs = Dict(:linewidth=>6, :color=>"gray", :alpha=>0.3)

fontname       = "Helvetica Neue"
fontsize       = 20   # for title and x and y labels
legendfontsize = 13

# If we plot more than 10 lines, colors repeat; use next marker in that case
markerorder = ["o", "x", "P", "d"]

# ####################################
#
#  GENERALIZED FUNCTIONS
#
# ####################################

function percentileGrowth(series; smkernel=[1])
   series = (series[2:end]./series[1:end-1] .- 1) .* 100
   series = smooth(series, smkernel)
end

"""
   addSourceString2Semilogy()

   Adds the text in sourcestring at a bottom right
   spot appropriate for a semilogy plot.
"""
function addSourceString2Semilogy()
   x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
   y = exp(log(ylim()[1]) - 0.1*(log(ylim()[2]) - log(ylim()[1])))
   t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
      verticalalignment="top", horizontalalignment="right")
end

"""
   addSourceString2Linear()

   Adds the text in sourcestring at a bottom right
   spot appropriate for a regular plot.
"""
function addSourceString2Linear()
   x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
   y = ylim()[1] - 0.1*(ylim()[2] - ylim()[1])
   t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
   verticalalignment="top", horizontalalignment="right")
end


"""
   plot_kwargs(pais)

   Returns the plotting arguments appropriate for the indicated country.
   For example, "World other than China" has special line thickness, etc.
"""
function plot_kwargs(pais)
   if pais == "World other than China"
      # special code for all countries other than China:
      kwargs = Dict(:linewidth=>12, :color=>"gray", :alpha=>0.3, :label=>pais)
   else
      kwargs = Dict(:linestyle=>"-", :label=>string(pais), :marker=>"o",
         :linewidth=>2)
   end

   kwargs[:fillstyle] = "none"

   if typeof(pais) == Tuple{String, Array{String,1}}
      kwargs[:label] = pais[1]
   end
   return kwargs
end


"""
   h = plotSingle(pais; db=A, alignon="today", days_previous=days_previous,
         minval=0, maxval=Inf, mincases=0,
         xOffset=0, fn=identity, plotFn=semilogy, adjustZeroXLabel=true)

   Adds a single line of a time series to a  plot, correspondong to data for the
   indicated country. pais can be anything that country2conf accepts.  The
   time series for the country, obtained from country2conf, is first put
   through the function fn, and is then plotted with plotFn

   Returns a graphics handle to the line plotted.

   # PARAMETERS

   - pais  The country or region to be plotted, as a function of days.
           Anything that country2conf accepts is ok here.

   # OPTIONAL PARMETERS

   - db    A database matrix as loaded from loadConfirmedDbase()

   - fn    The time series obtained from country2conf is put through this
           function before being processed.

   - plotFn   The function used to plot the series. Usually plot() or semilogy()

   - alignon   Either the string "today", in which case the rightmost data
           plot is the latest day in the database, or a real number, in which
           case zero on the x-axis is aligned to the moment the series crossed
           the value alignon.

   - days_previous  If alignon="today", then this indicates how far back to
           go. Irrelevant when alignon is a real number.

   - minval    Any value below this in the series will be a NaN, and if
           minval > 0, then the bottom y value will be set to this.

   - maxval  Any value above this is set to NaN. Does not affect y limits.

   - xOffset  Data points are shifted horizontally by this value.

   - adjustZeroXLabel  Boolean, if alignon="today" and this parameter is true,
               then the xtick label for the 0 point is changed to a string
               with today's date.

"""
function plotSingle(pais; db=A, alignon="today", days_previous=days_previous,
      minval=0, maxval=Inf, mincases=0,
      xOffset=0, fn=identity, plotFn=semilogy, adjustZeroXLabel=true)
   if pais == "World other than China"
      series = country2conf(db, "China", invert=true)
   else
      series = country2conf(db, pais)
   end
   # Make zeros into NaNs so they don't disturb the log plot
   series[series .< mincases] .= NaN

   series = fn(series)
   series[series .< minval] .= NaN
   series[series .> maxval] .= NaN

   dias   = 1:length(series)

   h = nothing
   if alignon=="today"
      h = plotFn(dias[end-days_previous:end] .- dias[end].+xOffset,
         series[end-days_previous:end]; plot_kwargs(pais)...)[1]
         # make the rightmost ctick label the current date

      if adjustZeroXLabel
         # Now replace the tick label for "0" with a string with today's date
         PyPlot.show(); gcf().canvas.flush_events()  # make graphics are ready to ask for tick labels
         tl = gca().get_xticklabels()
         for i=1:length(tl)
            if tl[i].get_position()[1] == 0.0
               tl[i].set_text(mydate(db[1,end]))
            end
         end
         gca().set_xticklabels(tl)
      end

   elseif typeof(alignon) <: Real
      # Can we align on what is being requested?
      u = findfirst(series .>= alignon)
      if u != nothing && u>=2
         # Compute the fractional offset needed
         frac = (log10(alignon)-log10(series[u-1]))/(log10(series[u]) - log10(series[u-1]))

         pkwargs = plot_kwargs(pais)
         myoffset = -(u+frac)
         daysago = length(series)+Int64(round(myoffset))+1
         pkwargs[:label] = pkwargs[:label]*" $daysago days ago"
         h = plotFn((1:length(series)) .+ myoffset .+ 1 .+ xOffset,
            series; pkwargs...)[1]
      else
         # if not enough points or alignment not available or for whatever reason
         # should not be plotted, then fake plot and make invisible, so color and
         # properties remain
         h = plot(xlim(), ylim(); plot_kwargs(pais)... )[1]
         h.set_visible(false)
      end
   else
      error("I don''t know what to do with an alignon with value=", alignon)
   end

   gca().autoscale(true)
   if minval>0
      # PyPlot.show(); gcf().canvas.flush_events()  # make graphics are ready to ask for tick labels
      gca().set_ylim(maximum([minval, ylim()[1]]), ylim()[2])
   end

   println("$pais = $(series[end])")
   return h
end


"""
   plotMany(paises; fignum=1, offsetRange=0.1, kwargs...)

   Each entry in the list paises gets plotted onto a figure using plotSingle,
   all overlaid on each other, and a legend gets created.  All of the arguments
   for plotSingle are accepted, except for pais, xOffset, adjustZeroXLabel.

   # PARAMETERS:

   - paises a vector of entries, each of which can be accepted by plotSingle

   # OPTIONAL PARAMETERS:

   - fignum  Integer. This figure gets cleared and resized and is used for plotting.

   - offsetRange how much to jitter x position across different lines

   # EXAMPLE CALLS:

   paises2 = ["Italy", "Spain", "Germany", "US", "Australia", "Brazil"]

   plotMany(paises2, fn=identity, plotFn=plot, db=A, alignon="today", minval=40)
   plotMany(paises2, fignum=2, fn=diff, plotFn=semilogy, db=A, alignon="today", minval=40)
   plotMany(paises2, fignum=3, fn= x -> smooth(diff(x), [0.3, 0.6, 0.3]),
      plotFn=plot, alignon=40, minval=0)

"""
function plotMany(paises; fignum=1, offsetRange=0.1, kwargs...)

   figure(fignum); clf(); println()
   set_current_fig_position(115, 61, 1496, 856)

   u = randperm(length(paises))

   h = nothing
   for i=1:length(paises)
      # Randomly offset plots w.r.t to each other by a small amount.
      xOffset = ((u[i]/(length(paises)/2))-1)*offsetRange

      if i<length(paises) && alignon != "today"
         h = plotSingle(paises[i]; xOffset=xOffset, adjustZeroXLabel=false, kwargs...)
      else
         h = plotSingle(paises[i]; xOffset=xOffset, adjustZeroXLabel=true, kwargs...)
      end

      # World other than China gets no marker, but everybody
      # else gets a different marker every ten countries:
      if h != nothing && h.get_marker() != "None"
         h.set_marker(markerorder[Int64(ceil(i/10))])
      end

   end

   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize),
      loc="upper left")
   xlabel("days", fontsize=fontsize, fontname=fontname)
   grid("on")
   gca().tick_params(labelsize=16)
   gca().yaxis.tick_right()
   gca().tick_params(labeltop=false, labelleft=true)

   if gca().yaxis.get_scale() == "log"
      addSourceString2Semilogy()
   else
      addSourceString2Linear()
   end
end


#############################################
#
#  FN DEFS DONE - PRODUCE PLOTS
#
#############################################

# ------  Cumulative case count
plotMany(paises, minval=10)
ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
title("Cumulative confirmed COVID-19 cases in selected regions", fontsize=fontsize, fontname=fontname)
gca().set_yticks([10, 40, 100, 400, 1000, 4000, 10000, 40000, 100000])
gca().set_yticklabels(["10", "40", "100", "400", "1000",
   "4000", "10000", "40000", "100000"])
# ylim(minval, ylim()[2])
fname = "confirmed"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# ------  New case count
plotMany(paises, fn=x -> smooth(diff(x), [0.2, 0.5, 0.7, 0.5, 0.2]),
   minval=1, fignum=2)
ylabel("New cases each day", fontsize=fontsize, fontname=fontname)
title("New confirmed COVID-19 cases per day\nin selected regions, smoothed with a +/- 2 day window",
   fontsize=fontsize, fontname=fontname)
gca().set_yticks([10, 40, 100, 400, 1000, 4000, 10000, 40000])
gca().set_yticklabels(["10", "40", "100", "400", "1000",
   "4000", "10000", "40000"])
# ylim(minval, ylim()[2])
fname = "newConfirmed"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# ------  Percentile growth in case count
plotMany(paises, plotFn=plot,
   fn=x -> smooth(percentileGrowth(x), [0.1, 0.2, 0.5, 0.7, 0.5, 0.2, 0.1]),
   mincases=50, fignum=3)
ylabel("% daily growth", fontsize=fontsize, fontname=fontname)
title("% daily growth in cumulative confirmed COVID-19 cases,\nsmoothed with a +/- 2 day window",
   fontsize=fontsize, fontname=fontname)
gca().set_yticks(0:10:60)
ylim(0, 65)
axisHeightChange(0.85, lock="t"); axisMove(0, 0.03)
t = text(mean(xlim()), -0.18*(ylim()[2]-ylim()[1]), interest_explanation,
   fontname=fontname, fontsize=16,
   horizontalalignment = "center", verticalalignment="top")
a = gcf().findobj(x -> py"hasattr"(x, "get_text") && x.get_text() == sourcestring)
a[1].remove()
addSourceString2Linear()
fname = "multiplicative_factor_1"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# --------   case count aligned on caseload
alignon=200
plotMany(setdiff(paises, ["World other than  China"]),
   alignon=alignon, minval=alignon/8, fignum=4)
ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
title("Cumulative confirmed COVID-19 cases in selected regions,\naligned on cases=$alignon",
   fontsize=fontsize, fontname=fontname)
gca().set_yticks([40, 100, 400, 1000, 4000, 10000, 40000, 100000])
gca().set_yticklabels(["40", "100", "400", "1000",
   "4000", "10000", "40000", "100000"])
# ylim(minval, ylim()[2])

fname = "confirmed_aligned"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)

# ---- states confirmed aligned
alignon=200
states = [("Washington", "US"), ("New York", "US"), ("California", "US"),
   "Italy", "Germany", "Brazil", africa, ("New Jersey", "US"), "Australia"]
plotMany(states, alignon=alignon, minval=alignon/8, fignum=5)
ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
title("Cumulative confirmed COVID-19 cases in selected countries and U.S. states,\naligned on cases=$alignon",
      fontsize=fontsize, fontname=fontname)
gca().set_yticks([40, 100, 400, 1000, 4000, 10000, 40000, 100000])
gca().set_yticklabels(["40", "100", "400", "1000",
   "4000", "10000", "40000", "100000"])

figname = "states_confirmed_aligned"
savefig("$figname.png")
run(`sips -s format JPEG $figname.png --out $figname.jpg`)



# -----  Cumulative Death count
plotMany(paises, db=D, minval=2, fignum=3)
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
   minval=1, fignum=4)
ylabel("New deaths per day", fontsize=fontsize, fontname=fontname)
title("Daily COVID-19 mortality in selected regions\nsmoothed with a +/- 2 day window",
   fontsize=fontsize, fontname=fontname)
gca().set_yticks([10, 40, 100, 400, 1000, 4000])
gca().set_yticklabels(["10", "40", "100", "400", "1000",
   "4000"])
# ylim(minval, ylim()[2])
fname = "newDeaths"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


# -----   Death growth rate
plotMany(paises, db=D, minval=0, fignum=4,
   fn=x -> smooth(percentileGrowth(x), [0.2, 0.5, 0.7, 0.5, 0.2]), plotFn=plot)
ylabel("daily % growth in cumulative deaths", fontsize=fontsize, fontname=fontname)
title("Percentile daily growth in cumulative COVID-19 deaths in selected regions\nsmoothes with a +/- 2 day window", fontsize=fontsize, fontname=fontname)
# gca().set_yticks([10, 40, 100, 400, 1000, 4000, 10000])
# gca().set_yticklabels(["10", "40", "100", "400", "1000",   "4000", "10000"])

fname = "deathGrowthRate"
savefig("$fname.png")
run(`sips -s format JPEG $fname.png --out $fname.jpg`)


## ===================




## ########################

function plot_many_cumulative(paises; db=A, fignum=1, alignon="today", minval=0,
   adjust_zero=true, offsetRange=0)
   figure(fignum); clf(); println()
   set_current_fig_position(115, 61, 1496, 856)

   u = randperm(length(paises))

   for i=1:length(paises)
      # plot each country
      h = plot_cumulative(paises[i], db=db, alignon=alignon, minval=minval,
         xOffset=((u[i]/(length(paises)/2))-1)*offsetRange)

      # World other than China gets no marker, but everybody
      # else gets a different marker every ten countries:
      if h != nothing && h.get_marker() != "None"
         h.set_marker(markerorder[Int64(ceil(i/10))])
      end
   end

   # Add titles, etc.
   prettify_cumulative_plot(minval=minval)

   if adjust_zero
      # make the rightmost ctick label the current date
      h = gca().get_xticklabels()
      for i=1:length(h)
         if h[i].get_position()[1] == 0.0
            h[i].set_text(mydate(db[1,end]))
         end
      end
      gca().set_xticklabels(h)
   end
end

##


#####################################
#
#  CUMULATIVE FUNCTIONS
#
#####################################



"""
   h = plot_cumulative(pais; alignon="today")

   Adds a single line to a semilogy plot of the cumulative count for the
   indicated country. pais can be anything that pai2conf accepts.

   Returns a graphics handle to the line


"""
function plot_cumulative(pais; db=A, alignon="today", days_previous=days_previous,
      minval=0, xOffset=0)
   if pais == "World other than China"
      conf = country2conf(db, "China", invert=true)
   else
      conf = country2conf(db, pais)
   end
   # Make zeros into NaNs so they don't disturb the log plot
   conf[conf.==0.0] .= NaN
   conf[conf .< minval] .= NaN

   h = nothing
   if alignon=="today"
      dias = 1:size(db,2)-4  # first for columns are not daily data
      h = semilogy(dias[end-days_previous:end] .- dias[end].+xOffset,
         conf[end-days_previous:end]; plot_kwargs(pais)...)[1]
   elseif typeof(alignon) <: Real
      u = findfirst(conf .>= alignon)
      if u != nothing && u>=2
         frac = (log10(alignon)-log10(conf[u-1]))/(log10(conf[u]) - log10(conf[u-1]))
         h = semilogy((1:length(conf)).-(u+frac).+1 .+ xOffset,
            conf; plot_kwargs(pais)...)[1]
      else
         # if not enough points or alignment not available or for whatever reason
         # should not be plotted, then fake plot and make invisible, so color and
         # properties remain
         h = plot(xlim(), ylim(); plot_kwargs(pais)... )[1]
         h.set_visible(false)
      end
   end

   println("$pais = $(conf[end])")
   return h
end



"""
   prettify_cumulative_plot()

   Adds things like titles, ticks, source string, etc. etc.
"""
function prettify_cumulative_plot(;minval=0)
   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize), loc="upper left")
   xlabel("days", fontsize=fontsize, fontname=fontname)
   ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
   title("Cumulative confirmed COVID-19 cases in selected regions", fontsize=fontsize, fontname=fontname)
   gca().set_yticks([1, 4, 10, 40, 100, 400, 1000, 4000, 10000, 40000, 100000])
   gca().set_yticklabels(["1", "4", "10", "40", "100", "400", "1000",
      "4000", "10000", "40000", "100000"])
   grid("on")
   gca().tick_params(labelsize=16)
   gca().yaxis.tick_right()
   gca().tick_params(labeltop=false, labelleft=true)

   if minval>0
      gca().set_ylim(maximum([minval, ylim()[1]]), ylim()[2])
   end

   addSourceString2Semilogy()
end

"""
   plot_many_cumulative(paises; fignum=1, alignon="today", minval=0,
      adjust_zero=true)

   plots all the countries in the array paises.

   # OPTIONAL PARAMS:

   - fignum     The figure number to plot on

   - alignon    Can be either the string "today" or a number. If "today",
                the rightmost data point corresponds to the latest in the
                time series. If alignon is a number, then 0 omn the horizontal
                axis will correspond to the day in which each time series
                reached alignon cases.

   - minval     Remove data points less than minval from plot

   - adjust_zero  If true, replaces the "0.0" tick mark with the latest date entry,
                in human-readable form
"""
function plot_many_cumulative(paises; db=A, fignum=1, alignon="today", minval=0,
   adjust_zero=true, offsetRange=0)
   figure(fignum); clf(); println()
   set_current_fig_position(115, 61, 1496, 856)

   u = randperm(length(paises))

   for i=1:length(paises)
      # plot each country
      h = plot_cumulative(paises[i], db=db, alignon=alignon, minval=minval,
         xOffset=((u[i]/(length(paises)/2))-1)*offsetRange)

      # World other than China gets no marker, but everybody
      # else gets a different marker every ten countries:
      if h != nothing && h.get_marker() != "None"
         h.set_marker(markerorder[Int64(ceil(i/10))])
      end
   end

   # Add titles, etc.
   prettify_cumulative_plot(minval=minval)

   if adjust_zero
      # make the rightmost ctick label the current date
      h = gca().get_xticklabels()
      for i=1:length(h)
         if h[i].get_position()[1] == 0.0
            h[i].set_text(mydate(db[1,end]))
         end
      end
      gca().set_xticklabels(h)
   end
end


# #########################################
#
#  FUNCTION DEFS DONE, PRODUCE CUMULATIVE PLOTS
#
# #########################################

# -----  base set of countries cumulative plot
plot_many_cumulative(paises, minval=10, offsetRange=0.1)
savefig("confirmed.png")
run(`sips -s format JPEG confirmed.png --out confirmed.jpg`)

# -----  base set of countries cumulative plot
plot_many_cumulative(paises, db=D, minval=10, offsetRange=0.1, fignum=6)
title("Cumulative COVID-19 deaths in selected regions", fontsize=fontsize, fontname=fontname)
savefig("deaths.png")
run(`sips -s format JPEG deaths.png --out deaths.jpg`)


# ------   aligned on when they hit 100 cases
alignon=200
plot_many_cumulative(setdiff(paises, ["World other than China"]), fignum=3,
   alignon=alignon, minval=alignon/8, adjust_zero=false)
title("Cumulative confirmed COVID-19 cases in selected regions\naligned on cases=$alignon",
   fontsize=fontsize, fontname=fontname)
xlabel("days from reaching $alignon")
gca().set_ylim(alignon/8, ylim()[2])
addSourceString2Semilogy()
figname = "confirmed_aligned"
savefig("$figname.png")
run(`sips -s format JPEG $figname.png --out $figname.jpg`)


# ------   US states, Italy, Germany, Brazil aligned on when they hit 100 cases
alignon=200
states = [("Washington", "US"), ("New York", "US"), ("California", "US"),
   # ("New Jersey", "US"),
   "Italy", "Germany", "Brazil", africa]
plot_many_cumulative(states, fignum=4,
   alignon=alignon, minval=alignon/8, adjust_zero=false)
title("Cumulative confirmed COVID-19 cases in selected\nregions, aligned on cases=$alignon",
   fontsize=fontsize, fontname=fontname)
xlabel("days from reaching $alignon")
gca().set_ylim(alignon/8, ylim()[2])
addSourceString2Semilogy()
figname = "states_confirmed_aligned"
savefig("$figname.png")
run(`sips -s format JPEG $figname.png --out $figname.jpg`)

#



#
# ###########################################
#
#  MULTIPLICATIVE CHANGE
#
# ###########################################


ngroup = 20


interest_explanation = """
How to read this plot: Think of the vertical axis values like interest rate per day being paid into an account. The account is not
money, it is cumulative number of cases. We want that interest rate as low as possible.  20% daily growth is a factor of 10 every
two weeks. A horizontal flat line on this plot is like steady compound interest, i.e., it is exponential growth. Stopping the disease
means the growth rate has to go all the way down to zero. The horizontal axis shows days before the date on the bottom right.
"""

using PyCall
hs      = Array{PyObject}(undef, 0)   # line handles

function plotOneGrowthRate(pais; db=A, alignon="today", days_previous=days_previous,
   # minimum_cases=50, smkernel = [0.2, 0.5, 0.7, 0.5, 0.2], xOffset=0, maxval=100)
   minimum_cases=50, smkernel = [0.1, 0.2, 0.5, 0.7, 0.5, 0.2, 0.1], xOffset=0,
   maxval=100)
   if pais == "World other than China"
      myconf = country2conf(db, "China", invert=true)
   else
      myconf = country2conf(db, pais)
   end
   myconf[myconf.<minimum_cases] .= NaN

   global mratio = (myconf[2:end]./myconf[1:end-1] .- 1) .* 100
   mratio = smooth(mratio, smkernel)
   mratio[mratio.>maxval] .= NaN

   h = nothing
   if alignon=="today"
      global dias = 1:size(db,2)-4
      dias = dias[end-days_previous:end] .- dias[end]
      mratio = mratio[end-days_previous:end]

      u = findall(.!isnan.(mratio))
      h = plot(dias[u].+xOffset, mratio[u] ; plot_kwargs(pais)...)[1]
   elseif typeof(alignon) <: Real
      v = findfirst(myconf .>= alignon)
      if v != nothing && v>=2
         u = findall(.!isnan.(mratio))
         frac = (alignon-conf[v-1])/(conf[v] - conf[v-1])
         h = plot((1:length(conf)-1).-(v+frac).+xOffset, mratio;
            plot_kwargs(pais)...)[1]
      else
         # if not enough points or alignment not available or for whatever reason
         # should not be plotted, then fake plot and make invisible, so color and
         # properties remain
         h = plot(xlim(), ylim(); plot_kwargs(pais)... )[1]
         h.set_visible(true)
      end
   end

   return h
end



offsetRange = 0.1
minimum_cases=50



function prettifyGrowthRatePlot(; minimum_cases=50, ymax=80)
   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize),
      loc="upper left")
   xlabel("days", fontname=fontname, fontsize=fontsize)
   ylabel("% daily growth", fontname=fontname, fontsize=fontsize)
   title("% daily growth in cumulative confirmed COVID-19 cases\n(smoothed with a +/- 2-day moving average; $minimum_cases cases minimum)",
      fontname="Helvetica Neue", fontsize=20)

   ylim(0, ymax)
   PyPlot.show(); gcf().canvas.flush_events()  # make graphics are ready to ask for tick labels

   gca().set_yticks(0:10:ymax)
   gca().tick_params(labelsize=16)
   grid("on")
   gca().tick_params(labeltop=false, labelright=true)

   axisHeightChange(0.85, lock="t"); axisMove(0, 0.03)
   t = text(mean(xlim()), -0.18*(ylim()[2]-ylim()[1]), interest_explanation,
      fontname=fontname, fontsize=16,
      horizontalalignment = "center", verticalalignment="top")

   x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
   y = ylim()[1] - 0.1*(ylim()[2] - ylim()[1])
   t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
      verticalalignment="top", horizontalalignment="right")
end

"""
   plotManyGrowthRate(paises; fignum=2, alignon="today", minval=0,
      adjust_zero=true)

   plots growth rate all the countries in the array paises.

   # OPTIONAL PARAMS:

   - fignum     The figure number to plot on

   - alignon    Can be either the string "today" or a number. If "today",
                the rightmost data point corresponds to the latest in the
                time series. If alignon is a number, then 0 on the horizontal
                axis will correspond to the day in which each time series
                reached alignon cases.

   - minimum_cases     Countries with fewer than these cases don't make it in

   - adjust_zero  If true, replaces the "0.0" tick mark with the latest date entry,
                in human-readable form
"""
function plotManyGrowthRate(paises; db=A, fignum=2, alignon="today",
   adjust_zero=true, offsetRange=0.1, ngroup=20, minimum_cases=50,
   smkernel = [0.1, 0.2, 0.5, 0.7, 0.5, 0.2, 0.1], days_previous=days_previous,
   ymax=80)

   i = 1; f=1;
   while i <= 3
      figure(fignum); clf(); println()
      set_current_fig_position(115, 61, 1496, 906)

      hs = zeros(0)
      for j=1:ngroup
         h = plotOneGrowthRate(paises[i], db=db, minimum_cases=minimum_cases,
            xOffset=((j/(ngroup/2))-1)*offsetRange, smkernel=smkernel,
            days_previous=days_previous)

         if h != nothing
            # World other than China gets no marker, but everybody
            # else gets a different marker every ten countries:
            if h.get_marker() != "None"
               h.set_marker(markerorder[Int64(ceil(j/10))])
            end
            hs = vcat(hs, h)
         end

         i += 1
         if i > length(paises)
            break
         end
      end

      if ~isempty(hs)
         prettifyGrowthRatePlot(minimum_cases=minimum_cases, ymax=ymax)

         h = gca().get_xticklabels()
         for i=1:length(h)
            if h[i].get_position()[1] == 0.0
               h[i].set_text(mydate(db[1,end]))
            end
         end
         gca().set_xticklabels(h)
      end
      f += 1
   end
end


# #########################################
#
#  FUNCTION DEFS DONE, PRODUCE GROWTH RATE PLOTS
#
# #########################################


plotManyGrowthRate(paises, fignum=2, offsetRange=0.1, ngroup=20, ymax=60)
figname = "multiplicative_factor" ; f=1
savefig("$(figname)_$f.png")
run(`sips -s format JPEG $(figname)_$f.png --out $(figname)_$f.jpg`)


plotManyGrowthRate(paises, db=D, fignum=5, offsetRange=0.1, ngroup=20,
   days_previous=15)
title("% daily growth in cumulative COVID-19 deaths\n(smoothed with a +/- 2-day moving average; $minimum_cases deaths minimum)",
   fontname="Helvetica Neue", fontsize=20)
figname = "multiplicative_death_factor" ; f=1
savefig("$(figname)_$f.png")
run(`sips -s format JPEG $(figname)_$f.png --out $(figname)_$f.jpg`)
