using Revise
using DelimitedFiles
using Statistics

push!(LOAD_PATH, ".")
using CarlosUtils

dname = "../../../COVID-19/csse_covid_19_data/csse_covid_19_time_series"
fname = "time_series_19-covid-Confirmed.csv"
A  = readdlm("$dname/$fname", ',');

sourcestring = "source: https://github.com/COVID-19-plots/maincovidplotsrepo"





# How many days previous to today to plot
days_previous = 18

# list fo countries to plot
paises = ["Korea, South", "Iran", "Italy", "Germany", "France", "Japan",
   "Spain", "US", "Switzerland", "United Kingdom", "Greece", "China", # "Other European Countries",
   "World other than China"]

# oeurope = ["Netherlands", "Sweden", "Belgium", "Norway", "Austria", "Denmark"]
# other_europe = "Other European Countries"
# other_europe_kwargs = Dict(:linewidth=>6, :color=>"gray", :alpha=>0.3)

fontname       = "Helvetica Neue"
fontsize       = 20   # for title and x and y labels
legendfontsize = 13

# If we plot more than 10 lines, colors repeat; use next marker in that case
markerorder = ["o", "x", "P", "d"]






"""
   pais2conf(pais::Array{String,1}, invert=false)

   Given a vector of strings representing a list of country, returns a numeric
   vector of cumulative confirmed cases, summed over all those countries, as a
   function of days. If the optional parameter invert=true, then returns the
   result for all countries *other* than the given countries
"""
function pais2conf(pais::Array{String,1}; invert=false)

   if !invert
      crows = findall(map(x -> in(x, pais), A[:,2]))
   else
      # Be careful to exclude the top row from results in this inverted case
      crows = findall(map(x -> !in(x, pais), A[2:end,2])) .+ 1
   end

   # daily count starts in column 5; turn it into Float64s
   my_confirmed = Array{Float64}(A[crows,5:end])

   # Add all rows for the country
   my_confirmed = sum(my_confirmed, dims=1)[:]

   return my_confirmed
end

"""
   pais2conf(pais::String; invert=false)

   Given a string representing country, returns a numeric
   vector of cumulative confirmed cases, as a function of days. If the
   optional parameter invert=true, then returns the result for
   all countries *other* than the given country
"""
function pais2conf(pais::String; invert=false)
   return pais2conf([pais], invert=invert)
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
      kwargs = Dict(:linestyle=>"-", :label=>pais, :marker=>"o", :label=>pais)
   end
   return kwargs
end


"""
   h = plot_cumulative(pais; alignon="today")

   Adds a single line to a semilogy plot of the cumulative count for the
   indicated country. pais can be anything that pai2conf accepts.

   Returns a graphics handle to the line


"""
function plot_cumulative(pais; alignon="today", days_previous=days_previous, minval=0)
   if pais == "World other than China"
      conf = pais2conf("China", invert=true)
   else
      conf = pais2conf(pais)
   end
   # Make zeros into NaNs so they don't disturb the log plot
   conf[conf.==0.0] .= NaN
   conf[conf .< minval] .= NaN

   h = nothing
   if alignon=="today"
      dias = 1:size(A,2)-4  # first for columns are not daily data
      h = semilogy(dias[end-days_previous:end] .- dias[end], conf[end-days_previous:end];
         plot_kwargs(pais)...)[1]
   elseif typeof(alignon) <: Real
      u = findfirst(conf .>= alignon)
      if u != nothing && u>=2
         frac = (alignon-conf[u-1])/(conf[u] - conf[u-1])
         h = semilogy((1:length(conf)).-(u+frac), conf; plot_kwargs(pais)...)[1]
      end
   end

   println("$pais = $(conf[end])")
   return h
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
   prettify_cumulative_plot()

   Adds things like titles, ticks, source string, etc. etc.
"""
function prettify_cumulative_plot()
   gca().legend(fontsize=legendfontsize, loc="upper left")
   xlabel("days", fontsize=fontsize, fontname=fontname)
   ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
   title("Cumulative confirmed COVID-19 cases in selected countries", fontsize=fontsize, fontname=fontname)
   gca().set_yticks([1, 4, 10, 40, 100, 400, 1000, 4000, 10000, 40000])
   gca().set_yticklabels(["1", "4", "10", "40", "100", "400", "1000",
      "4000", "10000", "40000"])
   grid("on")
   gca().tick_params(labelsize=16)
   gca().yaxis.tick_right()
   gca().tick_params(labeltop=false, labelleft=true)

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
function plot_many_cumulative(paises; fignum=1, alignon="today", minval=0,
   adjust_zero=true)
   figure(fignum); clf(); println()
   set_current_fig_position(115, 61, 1496, 856)

   for i=1:length(paises)
      # plot each country
      h = plot_cumulative(paises[i], alignon=alignon, minval=minval)

      # World other than China gets no marker, but everybody
      # else gets a different marker every ten countries:
      if h != nothing && h.get_marker() != "None"
         h.set_marker(markerorder[Int64(ceil(i/10))])
      end
   end

   # Add titles, etc.
   prettify_cumulative_plot()

   if adjust_zero
      # make the rightmost ctick label the current date
      h = gca().get_xticklabels()
      for i=1:length(h)
         if h[i].get_position()[1] == 0.0
            h[i].set_text(mydate(A[1,end]))
         end
      end
      gca().set_xticklabels(h)
   end
end


# #########################################
#
#  FUNCTION DEFS DONE, PRODUCE PLOTS
#
# #########################################

plot_many_cumulative(paises)
savefig("confirmed.png")
run(`sips -s format JPEG confirmed.png --out confirmed.jpg`)


alignon=100
plot_many_cumulative(setdiff(paises, ["World other than China"]), fignum=3,
   alignon=alignon, minval=alignon/8, adjust_zero=false)
title("Cumulative confirmed COVID-19 cases in selected countries\naligned on cases=$alignon",
   fontsize=fontsize, fontname=fontname)
xlabel("days from reaching $alignon")

gca().set_ylim(alignon/8, ylim()[2])
addSourceString2Semilogy()

savefig("confirmed_aligned.png")
run(`sips -s format JPEG confirmed_aligned.png --out confirmed_aligned.jpg`)

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
money, it is cumulative number of cases. We want that interest rate as low as possible. A horizontal flat line on this plot is like
steady compound interest, i.e., it is exponential growth. Stopping the disease means the growth rate has to go all the way down to
zero. The horizontal axis shows days before the date on the bottom right.
"""

using PyCall
hs      = Array{PyObject}(undef, 0)   # line handles

function plotOneGrowthRate(pais; alignon="today", days_previous=days_previous,
   minimum_cases=50, smkernel = [0.1, 0.4, 0.7, 0.4, 0.1], xOffset=0)
   if pais == "World other than China"
      myconf = pais2conf("China", invert=true)
   else
      myconf = pais2conf(pais)
   end
   myconf[myconf.<minimum_cases] .= NaN

   global mratio = (myconf[2:end]./myconf[1:end-1] .- 1) .* 100

   h = nothing
   if alignon=="today"
      global dias = 1:size(A,2)-4
      dias = dias[end-days_previous:end] .- dias[end]
      mratio = mratio[end-days_previous:end]

      u = findall(.!isnan.(mratio))
      h = plot(dias[u].+xOffset, smooth(mratio[u], smkernel) ;
            plot_kwargs(pais)...)[1]
   elseif typeof(alignon) <: Real
      v = findfirst(myconf .>= alignon)
      if v != nothing && v>=2
         u = findall(.!isnan.(mratio))
         frac = (alignon-conf[v-1])/(conf[v] - conf[v-1])
         h = plot((1:length(conf)-1).-(v+frac).+xOffset, smooth(mratio, smkernel);
            plot_kwargs(pais)...)[1]
      end
   end

   return h
end

offsetRange = 0.1

i = 1; f=1;
while i <= 3
   global i, f
   figure(2); clf(); println()
   hs = zeros(0)
   plotted = Array{String}(undef, 0)
   for j=1:ngroup
      h = plotOneGrowthRate(paises[i], xOffset=((j/(ngroup/2))-1)*offsetRange)

      if h != nothing
         # World other than China gets no marker, but everybody
         # else gets a different marker every ten countries:
         if h.get_marker() != "None"
            h.set_marker(markerorder[Int64(ceil(j/10))])
         end
         hs = vcat(hs, h)
         plotted = vcat(plotted, paises[i])
      end

      global i += 1
      if i > length(paises)
         break
      end
   end

   if ~isempty(hs)
      gca().legend(hs, plotted, fontsize=legendfontsize, loc="upper left")
      xlabel("days", fontname=fontname, fontsize=fontsize)
      ylabel("% daily growth", fontname=fontname, fontsize=fontsize)
      title("% daily growth in cumulative confirmed COVID-19 cases\n(smoothed with a +/- 1-day moving average; $minimum_cases cases minimum)",
         fontname="Helvetica Neue", fontsize=20)
      PyPlot.show(); gcf().canvas.flush_events()  # make graphics are ready to ask for tick labels
      h = gca().get_xticklabels()
      for i=1:length(h)
         if h[i].get_position()[1] == 0.0
            h[i].set_text(mydate(A[1,end]))
         end
      end
      gca().set_yticks(0:10:110)
      gca().set_xticklabels(h)
      gca().tick_params(labelsize=16)
      grid("on")
      gca().tick_params(labeltop=false, labelright=true)

      axisHeightChange(0.85, lock="t"); axisMove(0, 0.03)
      t = text(mean(xlim()), -0.23*(ylim()[2]-ylim()[1]), interest_explanation,
         fontname=fontname, fontsize=16,
         horizontalalignment = "center", verticalalignment="top")

      x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
      y = ylim()[1] - 0.1*(ylim()[2] - ylim()[1])
      t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
         verticalalignment="top", horizontalalignment="right")

      figname = "multiplicative_factor"
      savefig("$(figname)_$f.png")
      run(`sips -s format JPEG $(figname)_$f.png --out $(figname)_$f.jpg`)
      f += 1
   end
end
