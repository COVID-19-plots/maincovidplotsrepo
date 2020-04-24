using Revise
using Statistics
using DelimitedFiles
using PyCall
using PyPlot
using Random

push!(LOAD_PATH, ".")
using CarlosUtils
using CovidFunctions

# Data from all countries except US: (US data will come in the next file)
A = loadConfirmedDbase(fname = "time_series_covid19_confirmed_global.csv")
A = dropRows(A, "Country/Region", "US")
# Now deaths:
D = loadConfirmedDbase(fname = "time_series_covid19_deaths_global.csv")
D = dropRows(D, "Country/Region", "US")

# Now add population for them
A = addPopulationColumn(A)
D = addPopulationColumn(D)



# Data from US, including state-by-state
A2 = loadConfirmedDbase(fname="time_series_covid19_confirmed_US.csv")
A2 = dropColumns(A2, ["UID", "iso2", "iso3", "code3", "FIPS", "Admin2", "Combined_Key"])
A2 = renameColumn!(renameColumn!(renameColumn!(A2, "Province_State", "Province/State"), "Country_Region", "Country/Region"), "Long_", "Long")
# Now deaths:
D2 = loadConfirmedDbase(fname="time_series_covid19_deaths_US.csv")
D2 = dropColumns(D2, ["UID", "iso2", "iso3", "code3", "FIPS", "Admin2", "Combined_Key"])
D2 = renameColumn!(renameColumn!(renameColumn!(D2, "Province_State", "Province/State"), "Country_Region", "Country/Region"), "Long_", "Long")
@assert all(A2[:,1:2] .== D2[:,1:2])  "A2 and D2 matrices have a mismatch"

if !any(A2[1,:] .== "Population")  # A2 is missing the Population column, copy it from D2
   fc = firstDataColumn(A2)
   A2 = hcat(A2[:, 1:fc-1], D2[:,getColNums(D2, "Population")], A2[:,fc:end])
end

# Now put them together
A = [A ; A2[2:end,:]]
D = [D ; D2[2:end,:]]




##

days_previous=29


sourcestring = "source, updates at: https://github.com/COVID-19-plots/maincovidplotsrepo"


#
# COVID tracking is failing on WA and CA!
#
# Did some hand-fixes from Wikipedia: https://en.wikipedia.org/wiki/2020_coronavirus_pandemic_in_Brazil
# and directly from Johns Hopkins dashboard, but then went back to all Johns Hopkins data source since
# they now put state information back in.
#
# A = setValue(A, "Brazil", "3/15/20", 200)
# A = setValue(A, "Brazil", "3/16/20", 234)
# A = mergeJHandCovidTracking(jh=A, ct=loadCovidTrackingUSData()[1])
# A = setValue(A, ("Washington", "US"), "4/9/20", 9753)
# A = setValue(A, ("Washington", "US"), "4/10/20", 10219)
# A = setValue(A, ("Washington", "US"), "4/11/20", 10375)
# A = setValue(A, ("Washington", "US"), "4/12/20", 10530)
# A = setValue(A, ("Washington", "US"), "4/13/20", 10838)
# A = setValue(A, ("Washington", "US"), "4/14/20", 11055)
# A = setValue(A, ("Washington", "US"), "4/15/20", 11065)
# A = setValue(A, ("Washington", "US"), "4/16/20", 11217)
# A = setValue(A, ("Washington", "US"), "4/17/20", 11586)
# A = setValue(A, ("California", "US"), "4/11/20", 22289)
# A = setValue(A, ("California", "US"), "4/12/20", 23209)
# A = setValue(A, ("California", "US"), "4/13/20", 24379)
# A = setValue(A, ("California", "US"), "4/14/20", 25537)
# A = setValue(A, ("California", "US"), "4/15/20", 26940)
# A = setValue(A, ("California", "US"), "4/16/20", 27697)
# A = setValue(A, ("California", "US"), "4/17/20", 29171)
# D = mergeJHandCovidTracking(jh=D, ct=loadCovidTrackingUSData()[2])
# D = setValue(D, ("Washington", "US"), "4/10/20", 487)
# D = setValue(D, ("Washington", "US"), "4/11/20", 495)
# D = setValue(D, ("Washington", "US"), "4/12/20", 510)
# D = setValue(D, ("Washington", "US"), "4/13/20", 522)
# D = setValue(D, ("Washington", "US"), "4/14/20", 546)
# D = setValue(D, ("Washington", "US"), "4/15/20", 562)
# D = setValue(D, ("Washington", "US"), "4/16/20", 587)
# D = setValue(D, ("Washington", "US"), "4/17/20", 610)
# D = setValue(D, ("California", "US"), "4/11/20", 632)
# D = setValue(D, ("California", "US"), "4/12/20", 681)
# D = setValue(D, ("California", "US"), "4/13/20", 732)
# D = setValue(D, ("California", "US"), "4/14/20", 783)
# D = setValue(D, ("California", "US"), "4/15/20", 880)
# D = setValue(D, ("California", "US"), "4/16/20", 956)
# D = setValue(D, ("California", "US"), "4/17/20", 1041)
#
# D = setValue(D, "Germany", "4/11/20", 2871)
# D = setValue(D, "Germany", "4/14/20", 3494)


# Remove late April correction on Wuhan, so as to keep
# initial trends:
A = setValue(A, ("Hubei", "China"), "4/17/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/17/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/18/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/18/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/19/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/19/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/20/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/20/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/21/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/21/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/22/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/22/20", 3222)
A = setValue(A, ("Hubei", "China"), "4/23/20", 67803)
D = setValue(D, ("Hubei", "China"), "4/23/20", 3222)


# Write out the database with the states consolidated
d2name = "../../consolidated_database"
fname  = "time_series_19-covid-Confirmed.csv"
writedlm("$d2name/$fname", A, ',')


fontname       = "Helvetica Neue"
fontsize       = 20   # for title and x and y labels
legendfontsize = 13


# ####################################
#
#  GENERALIZED FUNCTIONS
#
# ####################################

"""
   percentileGrowth(series; smkernel=[1], assessDelta=1)

   Return the series replaced by its element-by-element percentile
   change, smoothed with smkernel after calculation

   # OPTIONAL PARAMS

   - smkernel      The smoothing kernel after the percentile is calculated

   - assessDelta   Percentile is measured at this many bins different; then.
                   assuming an exponential process, it is expressed as percentile
                   per bin.
"""
function percentileGrowth(series; smkernel=[1], assessDelta=1, expressDelta=assessDelta)
   series = series[assessDelta+1:end]./series[1:end-assessDelta]
   series = series.^(expressDelta/assessDelta)
   series = (series .- 1) .* 100
   series = smooth(series, smkernel)
end

"""
   addSourceString2Semilogy(;replaceOld=true)

   Adds the text in sourcestring at a bottom right
   spot appropriate for a semilogy plot.

   If replaceOld is true, the first existing previous text
   matching the source string is removed from the plot before
   placing a new one.
"""
function addSourceString2Semilogy(;replaceOld=true)
   if replaceOld
      # Find and remove the old source string
      a = gcf().findobj(x -> py"hasattr"(x, "get_text") &&
         x.get_text() == sourcestring)
      if !isempty(a)
         a[1].remove()
      end
   end

   x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
   y = exp(log(ylim()[1]) - 0.1*(log(ylim()[2]) - log(ylim()[1])))
   t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
      verticalalignment="top", horizontalalignment="right")
end

"""
   addSourceString2Linear(;replaceOld=true)

   Adds the text in sourcestring at a bottom right
   spot appropriate for a regular plot.

   If replaceOld is true, the first existing previous text
   matching the source string is removed from the plot before
   placing a new one.
"""
function addSourceString2Linear(;replaceOld=true)
   if replaceOld
      # Find and remove the old source string
      a = gcf().findobj(x -> py"hasattr"(x, "get_text") &&
         x.get_text() == sourcestring)
      if !isempty(a)
         a[1].remove()
      end
   end

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
   # If pais is a Tuple representing not a single region but a sum of regions,
   # use only its first element as the label
   if typeof(pais) == Tuple{String, Array{String,1}} ||
      typeof(pais) == Tuple{String,Array{Tuple{String,String},1}}
      pais = pais[1]
   end

   if pais == "World other than China"
      # special code for all countries other than China:
      kwargs = Dict(:linewidth=>12, :color=>"gray", :alpha=>0.3, :label=>pais,
         :marker=>"None")
   else
      ml = handMeLinespec(pais)
      kwargs = Dict(:linestyle=>"-", :label=>string(pais), :marker=>ml.marker,
         :linewidth=>ml.linewidth, :color=>ml.color, :alpha=>ml.alpha)
      # lspec = getLinespecs(pais)
      # if isempty(lspec)
      #    kwargs = Dict(:linestyle=>"-", :label=>string(pais), :marker=>"o",
      #       :linewidth=>2)
      # else
      #    lspec = lspec[1]
      #    kwargs = Dict(:linestyle=>"-", :label=>lspec.label, :marker=>lspec.marker,
      #       :color=>lspec.color, :linewidth=>lspec.linewidth)
      # end
   end

   kwargs[:fillstyle] = "none"

   ml = myLinespec(kwargs[:label], kwargs[:linewidth], kwargs[:marker],
      kwargs[:color], kwargs[:alpha])
   addToLinespecList(ml)
   return kwargs
end


"""
   h = plotSingle(pais; db=A, alignon="today", days_previous=days_previous,
         minval=0, maxval=Inf, mincases=0,
         xOffset=0, fn=identity, plotFn=semilogy, adjustZeroXLabel=true,
         labelSuffixFn=(pais,origSeries,series)->"")

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

   labelSuffixFn   If passed, must be a function that takes pais, origSeries (what
               country2conf returns) and series (fn(origSeries)), and returns a
               string that will be appended to the lines label
"""
function plotSingle(pais; db=A, alignon="today", days_previous=days_previous,
      minval=0, maxval=Inf, mincases=0,
      xOffset=0, fn=identity, plotFn=semilogy, adjustZeroXLabel=true,
      labelSuffixFn=(pais,origSeries,series)->"")
   if pais == "World other than China"
      series = country2conf(db, "China", invert=true)
   else
      series = country2conf(db, pais)
   end
   # Make zeros into NaNs so they don't disturb the log plot
   series[series .< mincases] .= NaN

   origSeries = copy(series) # in case we need the original for aligning further below
   series = fn(series)       # apply the function
   series[series .< minval] .= NaN
   series[series .> maxval] .= NaN

   dias   = 1:length(series)

   pkwargs = plot_kwargs(pais)
   pkwargs[:label] = pkwargs[:label]*labelSuffixFn(pais, origSeries, series)

   h = nothing
   if alignon=="today"
      h = plotFn(dias[end-days_previous:end] .- dias[end].+xOffset,
         series[end-days_previous:end]; pkwargs...)[1]
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

         myoffset = -(u+frac)
         daysago = length(series)+Int64(round(myoffset))+1
         # pkwargs[:label] = pkwargs[:label]*" $daysago days ago"
         h = plotFn((1:length(series)) .+ myoffset .+ 1 .+ xOffset,
            series; pkwargs...)[1]
      else
         # if not enough points or alignment not available or for whatever reason
         # should not be plotted, then fake plot and make invisible, so color and
         # properties remain
         h = plot(xlim(), ylim(); pkwargs... )[1]
         h.set_visible(false)
      end
   elseif typeof(alignon) <: Function
      myoffset = labelsuffix = nothing
      try
         myoffset, labelsuffix = alignon(pais, origSeries)
      catch
         println("alignon function should take pais and series, return a number and a string (for label suffix)")
      end
      println(pais, ": myoffset is ", myoffset)
      pkwargs = plot_kwargs(pais)
      pkwargs[:label] = pkwargs[:label]*labelsuffix
      h = plotFn((1:length(series)) .- myoffset .+ xOffset .- length(series),
         series; pkwargs...)[1]
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


##

"""
   plotMany(paises; fignum=1, offsetRange=0.1, legendLocation::String="upper left",
      kwargs...)

   Each entry in the list paises gets plotted onto a figure using plotSingle,
   all overlaid on each other, and a legend gets created.  All of the arguments
   for plotSingle are accepted, except for pais, xOffset, adjustZeroXLabel.

   # PARAMETERS:

   - paises a vector of entries, each of which can be accepted by plotSingle

   # OPTIONAL PARAMETERS:

   - fignum  Integer. This figure gets cleared and resized and is used for plotting.

   - offsetRange how much to jitter x position across different lines

   - legendLocation   self-explanatory, follows PyPlot.gca().legend()

   # EXAMPLE CALLS:

   paises2 = ["Italy", "Spain", "Germany", "US", "Australia", "Brazil"]

   plotMany(paises2, fn=identity, plotFn=plot, db=A, alignon="today", minval=40)
   plotMany(paises2, fignum=2, fn=diff, plotFn=semilogy, db=A, alignon="today", minval=40)
   plotMany(paises2, fignum=3, fn= x -> smooth(diff(x), [0.3, 0.6, 0.3]),
      plotFn=plot, alignon=40, minval=0)

"""
function plotMany(paises; fignum=1, offsetRange=0.1, alignon="today",
   legendLocation::String="upper left", kwargs...)

   figure(fignum); clf(); println()
   set_current_fig_position(115, 61, 1496, 856)

   u = randperm(length(paises))

   h = nothing
   for i=1:length(paises)
      # Randomly offset plots w.r.t to each other by a small amount.
      xOffset = ((u[i]/(length(paises)/2))-1)*offsetRange

      if i<length(paises) || alignon != "today"
         h = plotSingle(paises[i]; alignon=alignon, xOffset=xOffset, adjustZeroXLabel=false, kwargs...)
      else
         h = plotSingle(paises[i]; alignon=alignon, xOffset=xOffset, adjustZeroXLabel=true, kwargs...)
      end

      # World other than China gets no marker, but everybody
      # else gets a different marker every ten countries:
      # if h != nothing && h.get_marker() != "None"
      #    h.set_marker(markerOrder[Int64(ceil(i/10))])
      # end

   end

   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize-2),
      loc=legendLocation)
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


"""
   setLogYTicks(;yticbase=[1, 4], mintic=100, maxtic=400000)

   Sets yticks and ytick labels for log plots, at powers of 10
   of the yticbase
"""
function setLogYTicks(;yticbase=[1, 4], mintic=100, maxtic=400000)
   tb = 1; tenpow=0;
   ticklist = 10^tenpow * mintic * yticbase[tb]
   while ticklist[end] < maxtic
      tb += 1;
      ticklist = vcat(ticklist, 10^tenpow * mintic * yticbase[tb])
      if tb==2
         tb = 0
         tenpow += 1
      end
   end

   gca().set_yticks(ticklist)
   gca().set_yticklabels(string.(ticklist))
   return ticklist
end

# ======================================
#
#  TOP-LEVEL PLOT-MAKING FUNCTIONS
#
# ======================================

# ======================================
#
#  plotCumulative()
#
# ======================================

"""
   plotCumulative(regions; fname::String="", yticbase=[1, 4],
      mintic=100, maxtic=400000, minval=100, fignum=1, counttype="cases", kwargs...)
"""
function plotCumulative(regions; fname::String="", yticbase=[1, 4],
   mintic=100, maxtic=1000000, minval=100, fignum=1, counttype="cases",
   labelSuffixFn = (pais, origSeries, series) -> begin
      popstr = "$(round(country2conf(A, pais, rcols="Population")[1]/1e6, digits=1))M";
      return " : $(Int64(round(series[end]/1e3, digits=0)))K pop=$popstr"
   end,
   kwargs...)

   plotMany(regions, minval=minval, fignum=fignum; labelSuffixFn=labelSuffixFn, kwargs...)

   ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
   title("Cumulative confirmed COVID-19 $counttype in selected regions", fontsize=fontsize, fontname=fontname)
   setLogYTicks(yticbase=yticbase, mintic=mintic, maxtic=maxtic)

   addSourceString2Semilogy()

   savefig2jpg(fname)
end


##
# ======================================
#
#  plotNew()
#
# ======================================

"""
   plotNew(regions; smkernel=[0.5, 1, 0.5], minval=10, fignum=2,
      yticbase=[1, 4], mintic=10, maxtic=100000, fname::String="", kwargs...)
"""
function plotNew(regions; smkernel=[0.5, 1, 0.5], minval=10, fignum=2,
      counttype="cases", plotFn=semilogy, fn=x -> smooth(diff(x), smkernel), # [0.2, 0.5, 0.7, 0.5, 0.2]),
      yticbase=[1, 4], mintic=10, maxtic=100000, fname::String="",
      labelSuffixFn = (pais, origSeries, series) -> begin
         popstr = "$(round(country2conf(A, pais, rcols="Population")[1]/1e6, digits=1))M";
         return " : $(ceil(series[end]))/day pop=$popstr"
      end,
      kwargs...)

   plotMany(regions, fn=fn, plotFn=plotFn, labelSuffixFn=labelSuffixFn,
      minval=minval, fignum=fignum; kwargs...) # days_previous=size(A,2)-6)
   ylabel("New $counttype each day", fontsize=fontsize, fontname=fontname)
   title("New confirmed COVID-19 $counttype per day\nin selected regions, " *
      "smoothed with a +/- $(Int64((length(smkernel)-1)/2)) day window",
      fontsize=fontsize, fontname=fontname)
   ylim(minval, ylim()[2])
   if plotFn==semilogy
      setLogYTicks(yticbase=yticbase, mintic=mintic, maxtic=maxtic)
      addSourceString2Semilogy()
   else
      addSourceString2Linear()
   end


   savefig2jpg(fname)
end

##

# ======================================
#
#  plotGrowth()
#
# ======================================

interest_explanation = """
How to read this plot: Think of the vertical axis values like interest rate per day being paid into an account. The account is not
money, it is cumulative number. We want that interest rate as low as possible. A horizontal flat line on this plot is like
steady compound interest, i.e., it is exponential growth. The horizontal axis shows days before the date on the bottom right.
Grey lines at right indicate time to grow by a factor of 10X.
"""

"""
   plotGrowth(regions; smkernel=[0.2, 0.5, 0.7, 0.5, 0.2],
      minval=10, fignum=3, yticks=0:10:60, ylim1=0, ylim2=65,
      fn=x -> smooth(percentileGrowth(x), smkernel),
      mincases=50, fname::String="", counttype="cases",
      explain=true, weekly=false,
      tenXGrowAnchor=7, tenXDecayAnchor=14, kwargs...)
"""
function plotGrowth(regions; smkernel=[0.2, 0.5, 0.7, 0.5, 0.2],
   fignum=3, yticks=0:10:60, ylim1=0, ylim2=65, fn=x -> smooth(percentileGrowth(x), smkernel),
   mincases=50, fname::String="", counttype="cases", explain=true, weekly=false,
   tenXGrowAnchor=7, tenXDecayAnchor=14, kwargs...)

   plotMany(regions, plotFn=plot,
      fn=fn,
      mincases=mincases, fignum=fignum; kwargs...)

   ylabel("% daily change in $counttype", fontsize=fontsize, fontname=fontname)
   title("% daily change in confirmed COVID-19 $counttype," *
      "\nsmoothed with a +/- $(Int64((length(smkernel)-1)/2)) day window. " *
      "$mincases cases minimum", fontsize=fontsize, fontname=fontname)

   gca().set_yticks(yticks); ylim(ylim1, ylim2); xlim(xlim()[1], 0.5)
   axisMove(-0.06, 0)
   if explain
      axisHeightChange(0.85, lock="t"); axisMove(0, 0.03)
      t = text(mean(xlim()), -0.18*(ylim()[2]-ylim()[1])+ylim()[1], interest_explanation,
         fontname=fontname, fontsize=16,
         horizontalalignment = "center", verticalalignment="top")
   end

   """
      growthTick(days::Real, str::String; factor=10,
         color= factor>1 ? "red" : "green")

      given a number of days, and a growth factor (e.g., 10 for 10x)
      and a number of days, calculates the daily percentile growth that would
      lead to that and places a labeled tick to indicated that.
   """
   function growthTick(days::Real, str::String; factor=10,
      color= factor>1 ? "red" : "green")

      x1 = 0.065*(xlim()[2] - xlim()[1]) + xlim()[2]
      x2 = 0.165*(xlim()[2] - xlim()[1]) + xlim()[2]

      ypos = 100*(exp(log(factor)/days) - 1);

      h = plot([x1, x2], [1, 1]*ypos, color=color, clip_on=false)[1]
      t = text((x1+x2)/2, ypos, str,
         verticalalignment="center", horizontalalignment="center",
         backgroundcolor="w", color=color)
      return ypos
   end
   if weekly
      growthTick(26, "6 months")
      growthTick(8.66, "2 months")
      growthTick(4.33, "1 month")
      growthTick(2, "2 weeks")
      growthTick(1, "1 week")
   else
      growthTick(180, "6 months")
      growthTick(60, "2 months")
      growthTick(30, "1 month")
      growthTick(14, "2 weeks")
      growthTick(7, "1 week")
   end
   yp = 100*(exp(log(10)/tenXGrowAnchor) - 1);
   xpos = 0.115*(xlim()[2] - xlim()[1]) + xlim()[2]
   ypos = yp + 0.1*(ylim()[2]-ylim()[1])
   text(xpos, ypos, "X10 growth time",
      verticalalignment="center", horizontalalignment="center",
      backgroundcolor="w", color="red", fontname="Helvetica", fontsize=14)

   if ylim1<0
      if weekly
         growthTick(26, "6 months", factor=1/10)
         growthTick(8.66, "2 months", factor=1/10)
         growthTick(4.33, "1 month", factor=1/10)
      else
         growthTick(180, "6 months", factor=1/10)
         growthTick(60, "2 months", factor=1/10)
         growthTick(30, "1 month", factor=1/10)
      end

      xpos = 0.125*(xlim()[2] - xlim()[1]) + xlim()[2]
      yp = 100*(exp(log(1.0/10)/tenXDecayAnchor) - 1);
      ypos = yp - 0.1*(ylim()[2]-ylim()[1])
      text(xpos, ypos, "X 1/10 decay time",
         verticalalignment="center", horizontalalignment="center",
         backgroundcolor="w", color="green", fontname="Helvetica", fontsize=14)

      hlines([0], xlim()[1], xlim()[2], color="black", linewidth=2)
      growthTick(10, "Inf (R=1)", factor=1, color="black")
   end

   addSourceString2Linear()
   savefig2jpg(fname)
end



# ======================================
#
#  plotNewGrowth()
#
# ======================================


"""
   plotNewGrowth(regions; counttype="new cases", ylim1=-55, ylim2=100, yticks=-200:10:200, weekly=true,
      tenXGrowAnchor=4, tenXDecayAnchor=5, smkernel=[0.2, 0.4, 0.7, 1.0, 0.7, 0.4, 0.2], fname="",
      fn=x -> smooth(percentileGrowth(smooth(diff(x), smkernel), assessDelta=7, expressDelta=assessDelta), [0.5, 1, 0.5]),
      kwargs...)

   Plots weekly % change in new entries, can show positive or negative change

"""
function plotNewGrowth(regions; counttype="new cases", ylim1=-55, ylim2=100, yticks=-200:10:200, weekly=true,
   tenXGrowAnchor=4, tenXDecayAnchor=5, smkernel=[0.2, 0.4, 0.7, 1.0, 0.7, 0.4, 0.2], fname="",
   fn=x -> smooth(percentileGrowth(smooth(diff(x), smkernel), assessDelta=7, expressDelta=7), [0.5, 1, 0.5]),
   legendLocation::String="upper left", kwargs...)


   plotGrowth(regions, explain=false, fn=fn,
      smkernel=smkernel, weekly=weekly,
      ylim1=ylim1, ylim2=ylim2, yticks=yticks, counttype=counttype,
      tenXGrowAnchor=tenXGrowAnchor, tenXDecayAnchor=tenXDecayAnchor, mincases=0, minval=-200; kwargs...)
   title("% change after one week in new COVID-19 $counttype/day, smoothed", fontsize=fontsize, fontname=fontname)
   ylabel("% change per week in daily $counttype")

   kwargs = Dict(getLinespecs(label=string(("Hubei", "China")))[1])
   delete!(kwargs, :marker)
   kwargs[:label] = "Hubei, China average decay rate after peaking ~ -41% ~ 1/10 per month"
   hlines([-41], xlim()[1], xlim()[2]; kwargs...)

   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize-1),
      loc=legendLocation)

      savefig2jpg(fname)

end

##


# ======================================
#
#  plotAligned()
#
# ======================================
"""
   plotAligned(regions; alignon=200, fname::String="", yticbase=[1, 4],
      mintic=100, maxtic=400000, minval=100, fignum=4, counttype="cases",
      xlim1 = -20, kwargs...)
"""
function plotAligned(regions; alignon=200, fname::String="", yticbase=[1, 4],
   mintic=100, maxtic=1000000, minval=100, fignum=4, counttype="cases",
   xlim1 = -30,
   labelSuffixFn = (pairs, origSeries, series) -> " : $(Int64(ceil(series[end]/1000)))K ",
   kwargs...)

   plotMany(setdiff(regions, ["World other than China"]),
      labelSuffixFn = labelSuffixFn,
      alignon=alignon, minval=alignon/8, fignum=fignum; kwargs...)
   ylabel("cumulative confirmed $counttype", fontsize=fontsize, fontname=fontname)
   title("Cumulative confirmed COVID-19 $counttype in selected regions,\naligned on cases=$alignon",
      fontsize=fontsize, fontname=fontname)
   setLogYTicks(yticbase=yticbase, mintic=mintic, maxtic=maxtic)
   xlim(xlim1, xlim()[2])

   function tenXline(days, str)
      xl = xlim()
      h = plot([0, xl[2]], alignon*(10 .^[0, xl[2]/days]),
         color="grey", linewidth=4, alpha=0.2, zorder=1)[1] ;
      x2 = xl[2];    y2 = alignon*(10 .^(xl[2]/days))
      y1 = ylim()[2] ; x1 = days*log10(y1/alignon)
      if x1 < x2
         ypos = exp(log(ylim()[2]) - 0.08*(log(ylim()[2]) - log(ylim()[1])))
         xpos = days*log10(ypos/alignon)
      else
         xpos = xlim()[2] - 0.05*(xlim()[2]-xlim()[1])
         ypos = alignon*(10 .^(xpos/days))
      end
      bbox = gca().get_window_extent().transformed(gcf().dpi_scale_trans.inverted())
      dataAng = (180/pi)*atan((log(ypos)-log(alignon))*bbox.height/(log(ylim()[2])-log(ylim()[1])),
         xpos*bbox.width/(xlim()[2]-xlim()[1]))
      tx = text(xpos, ypos, "10X every\n$str", backgroundcolor="white",
         color="gray", horizontalalignment="center", verticalalignment="center",
         rotation=dataAng, zorder=1)

      xlim(xl)
      return h
   end

   tenXline(3, "3 days")
   tenXline(7, "week")
   tenXline(14, "2 weeks")
   tenXline(30, "month")
   tenXline(180, "6 months")

   savefig2jpg(fname)
end

##


# ==============================================
#
#   plotDeathPeakAligned()
#
# ==============================================

"""
   plotDeathPeakAligned(paises; plotFn=plot, db=D, fname="",
      smkernel=[0.3, 0.5, 0.7, 1, 0.7, 0.5, 0.3],
      fn=x -> smooth(diff(x), smkernel)./maximum(smooth(diff(x), smkernel)),
      tickdiff = 5, x0=-25, x1=17, alignon=nothing, soffsets = Dict(
         "Austria"=>0,
         "Sweden"=>-0.5,
         "Norway"=>1,
         "Italy"=>-0.5,
         "Spain"=>0,
         "Korea, South"=>2,
         ("Hubei", "China")=>-2
      ), kwargs...)

   Linear plot of deaths per day, aligned on the peak

   If alignon is not nothing, it should be a function that takes (paise, series)
   as inputs and returns (offset, label) as outouts. Each series will be offset
   horizontally by offset, and label will be added to its label in the legend
"""
function plotDeathPeakAligned(paises; plotFn=plot, db=D, fname="", multFactor=1,
   smkernel=[0.3, 0.5, 0.7, 1, 0.7, 0.5, 0.3], counttype="deaths",
   fn=x -> multFactor.*smooth(diff(x), smkernel)./maximum(smooth(diff(x), smkernel)),
   tickdiff = 5, x0=-25, x1=17, alignon=nothing, soffsets = Dict(
      "Austria"=>0,
      "Sweden"=>-0.5,
      "Norway"=>1,
      "Italy"=>-0.5,
      "Spain"=>0,
      "Korea, South"=>2,
      ("Hubei", "China")=>-2
   ), kwargs...)

   """
      myalign(pais, series; soffsets=soffsets)

      Default aligning function, returns argum of peak of fn(series),
      and a label that uses peak of the original series

      OPTIONAL param soffsets is a Dict of country=>extra horizontal offset
      default extra horizontal offset is zero
   """
   function myalign(pais, series; soffsets=soffsets)
      offset = findmax(fn(series))[2]-length(series)
      label  = " peak=$(Int64(round(maximum(diff(series))))) deaths/day $(-offset) days ago"
      return offset-(haskey(soffsets, pais) ? soffsets[pais] : 0), label
   end

   plotNew(paises, plotFn=plotFn, db=db, smkernel=smkernel,
      fn=fn, minval=0, days_previous=size(db,1)-5,
      alignon = (alignon==nothing ? myalign : alignon), offsetRange=0.1,
      counttype="deaths", fname=""; kwargs...)
   ylabel("Deaths/day relative to peak")
   xlabel("days relative to peak")
   title("data up to $(mydate(db[1,end])): COVID-19 $counttype per day in selected regions,\n" *
      "smoothed with a +/- $(Int64((length(smkernel)-1)/2)) day window and normalized to maximum",
      fontsize=fontsize, fontname=fontname)
   xlim(x0,x1)
   gca().set_xticks(minimum(gca().get_xticks()):tickdiff:maximum(gca().get_xticks()))

   addSourceString2Linear()  # the xlim() misplaces it
   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize),
      loc="upper left")
   savefig2jpg(fname)
end

##

# ==============================================
#
#   writeReadme()
#
# ==============================================


standardHeader = """
[[Regions around the world](../README.md) | [States of the US](../states) | [Latin America](../latinamerica) | [Europe](../europe) | [Mortality](../mortality)]
"""

"""
   writeReadme(prefix=prefix, dirname="../../\$prefix", header1="US States",
      jpgDirname="../carlosbrody/src", sections=sections)
"""
function writeReadme(;prefix="", dirname="../../$prefix", header1="US States",
      jpgDirname="../carlosbrody/src", sections=[
         "New cases growth rates"         "$(prefix)NewCasesGrowthRate"
         "New deaths growth rates"        "$(prefix)NewDeathsGrowthRate"
         "New cases per day"              "$(prefix)New"
         "New deaths per day"             "$(prefix)NewDeaths"
         "Cumulative number of confirmed cases by region, aligned on equal caseload"  "$(prefix)Aligned"
         "Cumulative number of cases"     "$(prefix)Cumulative"
         "Daily percentile growth rates"  "$(prefix)GrowthRate"
      ])
   @assert !isempty(prefix) "Need to specify a prefix"
   io = open("$dirname/README.md", "w")
   println(io, standardHeader)
   println(io)
   println(io, "## $header1 confirmed cases and deaths")
   println(io)

   function writeLink(str)
      linkstr = replace(replace(lowercase("$header1 $str"), " "=>"-"), ","=>"")
      println(io, "* [$header1: $str](#$linkstr)")
   end
   for i=1:size(sections,1)
      writeLink(sections[i,1])
   end
   println(io)

   println(io, "## Focus on $header1")
   println(io)
   for i=1:size(sections,1)
      println(io, "### $header1: $(sections[i,1])")
      println(io)
      println(io, "Click on the plot to see an expanded version.")
      println(io)
      println(io, "<img src=\"$jpgDirname/$(sections[i,2]).jpg\" width=\"1000\">")
      println(io)
   end

   close(io)
end
