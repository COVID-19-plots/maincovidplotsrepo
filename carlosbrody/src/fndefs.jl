using Revise
using Statistics
using DelimitedFiles
using PyCall
using PyPlot
using Random

push!(LOAD_PATH, ".")
using CarlosUtils
using CovidFunctions

A = loadConfirmedDbase(fname = "time_series_covid19_confirmed_global.csv")
D = loadConfirmedDbase(fname = "time_series_covid19_deaths_global.csv")
# US data showed up per county until 09-March-2020, but then only per state
# thereafter. THis function collapses it all into states
A = collapseUSStates(A)
D = collapseUSStates(D)

#



sourcestring = "source, updates at: https://github.com/COVID-19-plots/maincovidplotsrepo"


#

# Some hand-fixes from Wikipedia: https://en.wikipedia.org/wiki/2020_coronavirus_pandemic_in_Brazil
A = setValue(A, "Brazil", "3/15/20", 200)
A = setValue(A, "Brazil", "3/16/20", 234)
A = mergeJHandCovidTracking(jh=A, ct=loadCovidTrackingUSData()[1])
D = mergeJHandCovidTracking(jh=D, ct=loadCovidTrackingUSData()[2])
#
# A = setValue(A, ("Washington", "US"), "3/17/20", 1014)

# Write out the database with the states consolidated
d2name = "../../consolidated_database"
fname  = "time_series_19-covid-Confirmed.csv"
writedlm("$d2name/$fname", A, ',')


fontname       = "Helvetica Neue"
fontsize       = 20   # for title and x and y labels
legendfontsize = 13

# If we plot more than 10 lines, colors repeat; use next marker in that case
markerorder = ["o", "x", "P", "d", "*", "<"]

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
   if pais == "World other than China"
      # special code for all countries other than China:
      kwargs = Dict(:linewidth=>12, :color=>"gray", :alpha=>0.3, :label=>pais)
   else
      kwargs = Dict(:linestyle=>"-", :label=>string(pais), :marker=>"o",
         :linewidth=>2)
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

   if typeof(pais) == Tuple{String, Array{String,1}} ||
      typeof(pais) == Tuple{String,Array{Tuple{String,String},1}}
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
function plotMany(paises; fignum=1, offsetRange=0.1, alignon="today", kwargs...)

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
      if h != nothing && h.get_marker() != "None"
         h.set_marker(markerorder[Int64(ceil(i/10))])
      end

   end

   gca().legend(prop=Dict("family" =>fontname, "size"=>legendfontsize-2),
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
   mintic=100, maxtic=400000, minval=100, fignum=1, counttype="cases", kwargs...)

   plotMany(regions, minval=minval, fignum=fignum; kwargs...)

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
      counttype="cases", plotFn=semilogy,
      yticbase=[1, 4], mintic=10, maxtic=100000, fname::String="", kwargs...)

   plotMany(regions, fn=x -> smooth(diff(x), smkernel), # [0.2, 0.5, 0.7, 0.5, 0.2]),
      plotFn=plotFn,
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
      minval=10, fignum=3, yticks=0:10:60, ylim2=65,
      fn=x -> smooth(percentileGrowth(x), smkernel),
      mincases=50, fname::String="", counttype="cases", kwargs...)
"""
function plotGrowth(regions; smkernel=[0.2, 0.5, 0.7, 0.5, 0.2],
   fignum=3, yticks=0:10:60, ylim2=65, fn=x -> smooth(percentileGrowth(x), smkernel),
   mincases=50, fname::String="", counttype="cases", kwargs...)

   plotMany(regions, plotFn=plot,
      fn=fn,
      mincases=mincases, fignum=fignum; kwargs...)

   ylabel("% daily growth", fontsize=fontsize, fontname=fontname)
   title("% daily growth in cumulative confirmed COVID-19 $counttype," *
      "\nsmoothed with a +/- $(Int64((length(smkernel)-1)/2)) day window. " *
      "$mincases cases minimum", fontsize=fontsize, fontname=fontname)

   gca().set_yticks(yticks); ylim(0, ylim2); xlim(xlim()[1], 0.5)
   axisHeightChange(0.85, lock="t"); axisMove(0, 0.03)
   axisMove(-0.05, 0)
   t = text(mean(xlim()), -0.18*(ylim()[2]-ylim()[1]), interest_explanation,
      fontname=fontname, fontsize=16,
      horizontalalignment = "center", verticalalignment="top")

   """
      ypos(factor, days)

      given a growth fcator (e.g., 10 for 10x) and a number of days,
      calculates the daily percentile growth that would lead to that
   """
   function growthTick(days::Real, str::String; factor=10)
      x1 = 0.045*(xlim()[2] - xlim()[1]) + xlim()[2]
      x2 = 0.145*(xlim()[2] - xlim()[1]) + xlim()[2]

      ypos = 100*(exp(log(factor)/days) - 1);

      h = plot([x1, x2], [1, 1]*ypos, color="grey", clip_on=false)[1]
      t = text((x1+x2)/2, ypos, str,
         verticalalignment="center", horizontalalignment="center",
         backgroundcolor="w", color="grey")
      return ypos
   end
   yp = growthTick(7, "1 week")
   growthTick(14, "2 weeks")
   growthTick(30, "1 month")
   growthTick(60, "2 months")
   growthTick(180, "6 months")
   xpos = 0.105*(xlim()[2] - xlim()[1]) + xlim()[2]
   ypos = yp + 0.1*(ylim()[2]-ylim()[1])
   text(xpos, ypos, "10X growth time",
      verticalalignment="center", horizontalalignment="center",
      backgroundcolor="w", color="grey", fontname="Helvetica", fontsize=14)

   addSourceString2Linear()
   savefig2jpg(fname)
end



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
   mintic=100, maxtic=400000, minval=100, fignum=4, counttype="cases",
   xlim1 = -20, kwargs...)

   plotMany(setdiff(regions, ["World other than China"]),
      alignon=alignon, minval=alignon/8, fignum=fignum; kwargs...)
   ylabel("cumulative confirmed $counttype", fontsize=fontsize, fontname=fontname)
   title("Cumulative confirmed COVID-19 $counttype in selected regions,\naligned on cases=$alignon",
      fontsize=fontsize, fontname=fontname)
   setLogYTicks(yticbase=yticbase, mintic=mintic, maxtic=maxtic)
   xlim(xlim1, xlim()[2])

   function tenXline(days, str)
      xl = xlim()
      h = plot([0, xl[2]], alignon*(10 .^[0, xl[2]/days]),
         color="grey", linewidth=4, alpha=0.2)[1] ;
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
         rotation=dataAng)

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
