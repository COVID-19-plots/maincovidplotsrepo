using Revise
using DelimitedFiles
using Statistics

push!(LOAD_PATH, ".")
using CarlosUtils

dname = "../../COVID-19/csse_covid_19_data/csse_covid_19_time_series"
fname = "time_series_19-covid-Confirmed.csv"
A  = readdlm("$dname/$fname", ',');
# --- Special fix for occasional empty entries: if not the US, then copy
# previous day; if it is the US, enter zero, for it is a county row that has
# noe been subsumed by state rows
a = findall(A[:,5:end] .== "")
for i=1:length(a)
   if A[a[i][1],2] != "US"
      # copy from previous day
      A[a[i][1], a[i][2]+4] = A[a[i][1], a[i][2]+3]
   else
      # if US, enter zero, county rows are now superseded and subsumed in whole-state rows
      A[a[i][1], a[i][2]+4] = 0
   end
end
# --- end fix


# special code for all countries other than China:
other = "World other than China"
other_kwargs = Dict(:linewidth=>12, :color=>"gray", :alpha=>0.3)


days_previous = 18

paises = ["South Korea", "Iran", "Italy", "Germany", "France", "Japan",
   "Spain", "US", "Switzerland", "UK", "Greece", "Mainland China", # "Other European Countries",
   "World other than China"]

oeurope = ["Netherlands", "Sweden", "Belgium", "Norway", "Austria", "Denmark"]
other_europe = "Other European Countries"
other_europe_kwargs = Dict(:linewidth=>6, :color=>"gray", :alpha=>0.3)

fontname       = "Helvetica Neue"
fontsize       = 20
legendfontsize = 13

markerorder = ["o", "x", "P", "d"]


"""
   fixNameChange!(oldname::String, newname::String)

   Mutates A. Finds the row of A where the country is newname;
   copies their non-zero counts columns into the row with oldname,
   overwriting as it copies; then removes the row with newname.

   Only works if there is only one oldname row and only one newname; checks for
   that condition being true.

   EXAMPLE:

   fixNameChange!("South Korea", "Republic of Korea")
"""
function fixNameChange!(oldname::String, newname::String)
   global A

   u1 = findall(A[:,2] .== oldname)
   @assert length(u1)==1 "more than 1 $oldname"
   u1 = u1[1]

   u2 = findall(A[:,2] .== newname)
   @assert length(u2)==1 "more than 1 $newname"
   u2 = u2[1]

   # Copy non-zeros in row u2 to row u1
   z = findall(A[u2,5:end] .> 0); A[u1,z.+4] = A[u2,z.+4]

   # remove the newname row
   A = A[setdiff(1:size(A,1), u2),:]
end

fixNameChange!("South Korea", "Republic of Korea")
fixNameChange!("Iran", "Iran (Islamic Republic of)")



# ###########################################
#
#  CUMULATIVE TOTAL
#
# ###########################################




confirmed = Array{Float64}(undef, length(paises), size(A,2)-4)


"""
   pais2conf(pais::String)

   Given a string representing a country, returns a numeric vector of cumulative
   confirmed cases as a function of days. ***ASSUMES MATRIX A HAS BEEN
   POPULATED WITH A READ FROM TEH CSV FILE***
"""
function pais2conf(pais::String; region::String="")
   # Find all rows for this country
   if pais == other
      crows = findall(A[2:end,2] .!= "Mainland China") .+ 1
   elseif pais == other_europe
      crows = findall(map(x -> in(x, oeurope), A[:,2]))
   else
      crows = findall(A[:,2] .== pais)
      if !isempty(region)
         rrows1 = findall(map(x -> occursin(", $region", x), A[:,1]))
         rrows2 = findall(A[:,1] .== abbrev2StateName[region])
         crows  = intersect(crows, vcat(rrows1, rrows2))
      end
   end

   # daily count starts in column 5; turn it into Float64s
   my_confirmed = Array{Float64}(A[crows,5:end])

   # Add all rows for the country
   my_confirmed = sum(my_confirmed, dims=1)[:]

   return my_confirmed
end



for i = 1:length(paises)
   pais = paises[i]

   confirmed[i,:] = pais2conf(pais)
end

# We're not going to sort countries-- use the order in paises, so the order,
# and colors, is consistent from day to day
# Hence commenting out sorting:
# v = sortperm(confirmed[:,end])[end:-1:1]
# # We're going to put China last for now, just to keep plot colors
# # consistent with previous versions
# v = [v[2:end]; v[1]]
# paises = paises[v]
# confirmed = confirmed[v,:]


figure(1); clf(); println()
   # Make zeros into NaNs so they don't disturb the log plot
confirmed[confirmed.==0.0] .= NaN
for i=1:length(paises)
   pais = paises[i]

   dias = 1:size(A,2)-4
   if pais == other
      semilogy(dias[end-days_previous:end] .- dias[end],
         confirmed[i, end-days_previous:end], "-", label=pais; other_kwargs...)
   elseif pais==other_europe
      semilogy(dias[end-days_previous:end] .- dias[end],
         confirmed[i, end-days_previous:end], "--", label=pais; other_europe_kwargs...)
   else
      semilogy(dias[end-days_previous:end] .- dias[end],
         confirmed[i, end-days_previous:end], "-", label=pais,
         marker = markerorder[Int64(ceil(i/10))])
   end
   println("$pais = $(confirmed[i,end])")
end

gca().legend(fontsize=legendfontsize)
xlabel("days", fontsize=fontsize, fontname=fontname)
ylabel("cumulative confirmed cases", fontsize=fontsize, fontname=fontname)
title("Cumulative onfirmed COVID-19 cases in selected countries", fontsize=fontsize, fontname=fontname)
gca().set_yticks([1, 4, 10, 40, 100, 400, 1000, 4000, 10000, 40000])
gca().set_yticklabels(["1", "4", "10", "40", "100", "400", "1000",
   "4000", "10000", "40000"])
h = gca().get_xticklabels()
for i=1:length(h)
   if h[i].get_position()[1] == 0.0
      h[i].set_text(mydate(A[1,end]))
   end
end
gca().set_xticklabels(h)
grid("on")
gca().tick_params(labelsize=16)
gca().yaxis.tick_right()
gca().tick_params(labeltop=false, labelleft=true)

x = xlim()[2] + 0.1*(xlim()[2] - xlim()[1])
y = exp(log(ylim()[1]) - 0.1*(log(ylim()[2]) - log(ylim()[1])))
t = text(x, y, sourcestring, fontname=fontname, fontsize=13,
   verticalalignment="top", horizontalalignment="right")

savefig("confirmed.png")
run(`sips -s format JPEG confirmed.png --out confirmed.jpg`)


#
# ###########################################
#
#  MULTIPLICATIVE CHANGE
#
# ###########################################


minimum_cases = 50
ngroup = 20
smkernel = [0.1, 0.4, 0.7, 0.4, 0.1]

interest_explanation = """
How to read this plot: Think of the vertical axis values like interest rate per day being paid into an account. The account is not
money, it is cumulative number of cases. We want that interest rate as low as possible. A horizontal flat line on this plot is like
steady compound interest, i.e., it is exponential growth. Stopping the disease means the growth rate has to go all the way down to
zero. The horizontal axis shows days before the date on the bottom right.
"""

sourcestring = "source: https://github.com/carlosbrody/COVID-19-plots"

using PyCall
hs      = Array{PyObject}(undef, 0)   # line handles

i = 1; f=1;
while i <= 3
   global i, f
   figure(2); clf(); println()
   plotted = Array{String}(undef, 0)     # plotted country strings
   for j=1:ngroup
      pais = paises[i]
      myconf = confirmed[i,:]
      myconf[myconf.<minimum_cases] .= NaN

      global mratio = (myconf[2:end]./myconf[1:end-1] .- 1) .* 100
      mratio = mratio[end-days_previous:end]
      u = findall(.!isnan.(mratio))

      global dias = 1:size(A,2)-4
      dias = dias[end-days_previous:end] .- dias[end]

      if pais == other
         h = plot(dias[u], smooth(mratio[u], smkernel), "-", label=pais;
            other_kwargs...)[1]
      elseif pais == other_europe
         h = plot(dias[u], smooth(mratio[u], smkernel), "--", label=pais;
            other_europe_kwargs...)[1]
      else
         h = plot(dias[u], smooth(mratio[u], smkernel), "-", label=pais,
            marker = markerorder[Int64(ceil(i/10))])[1]
      end
      if length(u)>0
         global hs = vcat(hs, h)
         plotted = vcat(plotted, pais)
         println("$pais = $(confirmed[i,end])")
      end

      global i += 1
      if i > length(paises)
         break
      end
   end

   if ~isempty(plotted)
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
