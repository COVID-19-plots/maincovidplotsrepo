module CovidFunctions

using DelimitedFiles
using PyPlot


export loadConfirmedDbase, collapseUSStates, country2conf, setValue, getValue
export loadCovidTrackingUSData, stateAbbrev2Fullname, mergeJHandCovidTracking
export savefig2jpg

stateAbbrevMapFilename = "StateNamesAndAbbreviations.csv"
stateAbbrevMap         = readdlm(stateAbbrevMapFilename, ',');


"""
   stateAbbrev2Fullname(str)

   Given a state abbreviation like "WA" returns the fullname, like "Washington"

   If given a two-letter abbreviation that is not a string, returns "".
   If given an array of strings, applies function to each entry

"""
function stateAbbrev2Fullname(str::String)
   @assert length(str)==2  "str must be a tw-letter string"
   abvs = stateAbbrevMap
   u = findfirst(abvs[:,2].==str)
   return u==nothing ? "" : abvs[u,1];
end

function stateAbbrev2Fullname(str::Array{String})
   return map(x -> stateAbbrev2Fullname(x), str)
end


"""
   savefig2jpg(fname::String)

   saves current figure to fname.jpg, then calls Mac system executable
   sips to make a jpg version in fname.jpg

   If fname == "" then does nothing
"""
function savefig2jpg(fname::String)
   if fname != ""
      savefig("$fname.png")
      run(`sips -s format JPEG $fname.png --out $fname.jpg`)
   end
end


"""
   A = loadConfirmedDbase(;
      dname::String = "../../../COVID-19/csse_covid_19_data/csse_covid_19_time_series",
      fname::String = "time_series_19-covid-Confirmed.csv")

   returns a matrix containing the data from the Johns Hopkins
   time_series_19-covid-Confirmed.csv file.

   First row indicates column type; first four columns are
   "Province/State", "Country/Region", "Lat", "Long", and then
   columns 5 through the last column are successive days, with
   the date indicated as a string in row 1

   # OPTIONAL PARAMS

   - dname    name of the directory the csv file is in

   - fname    name of the file to read

"""
function loadConfirmedDbase(;
   dname = "../../../COVID-19/csse_covid_19_data/csse_covid_19_time_series",
   fname = "time_series_covid19_confirmed_global.csv")

   return readdlm("$dname/$fname", ',');
end

##
##

"""
   mergeJHandCovidTracking(;jh=NaN, ct=NaN)

   Given a dbase matrix from Johns Hopkins and one from covidtracking,
   and assuming they have identical first row, removes from jh the US
   data and instead adds the rows from covidtracking
"""
function mergeJHandCovidTracking(;jh=NaN, ct=NaN)
   @assert jh != NaN && ct != NaN    "Need both jh and ct"
   @assert jh[1,1:5] == ct[1,1:5]    "jh and ct must start on same date and have equal first 5 cols of first row"
   # Use smallest date range
   jh = jh[:,1:minimum([size(jh,2), size(ct,2)])]
   ct = ct[:,1:minimum([size(jh,2), size(ct,2)])]
   @assert jh[1,:] == ct[1,:]    "after narrowing both to smallest date range, first row of both jh and ct must be equal"


   # remove old US data
   u = findall(jh[:,2] .!= "US")
   nA = jh[u,:];
   return vcat(nA, ct[2:end,:])
end


"""
   loadCovidTrackingUSData(; dname = "../../data/covidtracking.com/api/states",
      fname = "daily.csv")

   Load US state daya from CovidTracking project not Johns Hopkins
"""
function loadCovidTrackingUSData(;
   dname = "../../data/covidtracking.com/api/states",
   fname = "daily.csv")

   C = readdlm("$dname/$fname", ',');

   poscol = findfirst(C[1,:].=="positive")
   dedcol = findfirst(C[1,:].=="death")
   sabcol = findfirst(C[1,:].=="state")
   daycol = findfirst(C[1,:].=="date")

   """
      dayroll(;startdate=20200122, enddate=20200324)

      Return a vector of sequential days, following the calendar,
      using Int64s to define the limits, as in C[:,daycol]
   """
   function dayroll(;startdate=20200122, enddate=20200324)
      ds = zeros(Int64, 0)
      ds = vcat(ds, startdate:(minimum([enddate, 20200131])))

      if enddate >= 20200201
         ds = vcat(ds, 20200201:(minimum([enddate, 20200229])))
      end
      if enddate >= 20200301
         ds = vcat(ds, 20200301:(minimum([enddate, 20200331])))
      end
      if enddate >= 20200401
         ds = vcat(ds, 20200401:(minimum([enddate, 20200430])))
      end
      return ds
   end

   """
      daynum2daystr(num::Int)

      Number in format yyyymmdd gets turned into string mm/dd/yr where
      dd might be length 1
   """
   function daynum2daystr(num::Int)
      yr = fld(num, 10000); num -= yr*10000; yr -= 2000
      mo = fld(num, 100);   num -= mo*100
      dy = num
      return "$mo/$dy/$yr"
   end


   mydays = dayroll(enddate=maximum(C[2:end,daycol])) # use default start date to match JH dbase
   ndays  = length(mydays)
   sabs   = Array{String}(unique(C[2:end,sabcol]))  # state abbreviations
   states = stateAbbrev2Fullname(sabs)              # corresponding fullnames
   u = findall(.!isempty.(states))                  # eliminate unknown states
      sabs = sabs[u]
      states = states[u]
   nstates = length(u)


   As = Array{Any}(undef, nstates+1, ndays+4)   # This will be the output
   Ds = Array{Any}(undef, nstates+1, ndays+4)   # This will be the output
   # Fill in top row
   As[1,1:4] = ["Province/State", "Country/Region", "Lat", "Long"]
   Ds[1,1:4] = ["Province/State", "Country/Region", "Lat", "Long"]
   for i=1:length(mydays)
      As[1, i+4] = daynum2daystr(mydays[i])
      Ds[1, i+4] = daynum2daystr(mydays[i])
   end

   # loop over states
   for s=1:nstates
      mystate = states[s]

      As[s+1,1:4] = [stateAbbrev2Fullname(sabs[s]), "US", 0, 0]
      As[s+1,5:end] .= 0

      Ds[s+1,1:4] = [stateAbbrev2Fullname(sabs[s]), "US", 0, 0]
      Ds[s+1,5:end] .= 0

      # Find all entries for this state
      u = findall(C[:,sabcol] .== sabs[s])
      for d=1:length(u)
         myday   = C[u[d], daycol]
         mypos   = C[u[d], poscol]
         myded   = C[u[d], dedcol]

         Adaycol    = findfirst(As[1,:] .== daynum2daystr(myday))
         # For each entry, put it in corresponding spot in As
         As[s+1, Adaycol] = mypos
         Ds[s+1, Adaycol] = myded != "" ? myded : 0
      end
   end

   return As, Ds
end




"""
   collapseUSStates(A; mapfilename="StateNamesAndAbbreviations.csv")

   Given a matrix A (as loaded with loadConfirmedDbase()), collapse US county
   information into the corresponding state column. Returns the new matrix

   An optional parameter gives the filename for a CSV file in which state names
   are mapped to their abbreviations, for example "Washington, WA"

"""
function collapseUSStates(A; mapfilename="StateNamesAndAbbreviations.csv")
   A = copy(A)
   # Any empty strings where numbers should be get converted to zeros:
   G = A[:,5:end]; G[findall(G .== "")] .= 0;
   A[:,5:end] = G;
   abvs = readdlm(mapfilename, ',');
   # Exclude any lines where the second column isn't two letters long
   abvs = abvs[findall(map(x -> length(x)==2, abvs[:,2])),:]

   # Now find all US counties in A, defined as being in the US (second column)
   # and having a form in their first column like "King County, WA"
   u = findall(map(x -> occursin(r"[\w\s]+, \w\w", x), A[:,1]) .& (A[:,2].=="US"))

   # For each county row, find its fullname state
   correspondingStates = Array{String}(undef, length(u))
   for i=1:length(u)
      # For each county, extract its two-letter state abbreviation
      abbrev = match(r", \w\w", A[u[i],1]).match[3:4]
      # map that onto the full state name (i.e., "NY" -> "New York")
      correspondingStates[i] = abvs[findfirst(abvs[:,2].==abbrev),1]
   end

   statesWithCountyInfo = unique(correspondingStates)

   for i=1:length(statesWithCountyInfo)
      # find all county rows for this state
      uid = findall(statesWithCountyInfo[i] .== correspondingStates)
      # add up all the county data
      z = sum(Array{Float64}(A[u[uid],5:end]), dims=1)

      # Find the row in A that corresponds to that state
      v = findfirst(A[:,1].==statesWithCountyInfo[i])
      # and in each data column, put the number that is greatest, the county
      # number or the state number. When tallying stopped in the counties, their
      # subsequent numbers went to zero; while the state numbers were zero when
      # tallying was by county
      for j=5:size(A,2)
         A[v,j] = A[v,j] > z[j-4] ? A[v,j] : z[j-4]
      end
   end
   # Now remove all the county rows, they've been added to the fullname state rows
   A = A[setdiff(1:size(A,1), u),:]

   return A
end



"""
   country2conf(A, pais::Array{String,1}, invert=false)

   Given a database matrix A and a vector of strings representing a list of
   countries, returns a numeric
   vector of cumulative confirmed cases, summed over all those countries, as a
   function of days. If the optional parameter invert=true, then returns the
   result for all countries *other* than the given countries
"""
function country2conf(A, pais::Array{String,1}; invert=false)

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

function country2conf(A, pais::Array{Tuple{String,String},1}; invert=false)
   if !invert
      crows = findall( map(x -> in(x, pais),
         mapslices(x -> (x[1], x[2]), A, dims=2)[:]) )
   else
      # Be careful to exclude the top row from results in this inverted case
      crows = findall( map(x -> !in(x, pais),
         mapslices(x -> (x[1], x[2]), A[2:end,:], dims=2)[:]) ) .+ 1
   end

   # daily count starts in column 5; turn it into Float64s
   my_confirmed = Array{Float64}(A[crows,5:end])

   # Add all rows for the country
   my_confirmed = sum(my_confirmed, dims=1)[:]

   return my_confirmed
end


"""
   country2conf(pais::String; invert=false)

   Given a string representing country, returns a numeric
   vector of cumulative confirmed cases, as a function of days. If the
   optional parameter invert=true, then returns the result for
   all countries *other* than the given country
"""
function country2conf(A, pais::String; invert=false)
   return country2conf(A, [pais], invert=invert)
end


"""
   country2conf(pais::Tuple{String, String}; invert=false)

   Given a tuple of two strings, representing region, country, respectively,
   returns a numeric vector of cumulative confirmed cases, as a function of days.
   If the optional parameter invert=true, then returns the result for
   all countries *other* than the given country

"""
function country2conf(A, pais::Tuple{String, String}; invert=false)
   crows = findall((A[:,1] .== pais[1])  .&  (A[:,2] .== pais[2]))
   if invert
      crows = setdiff(2:size(A,1), crows)
   end

   # daily count starts in column 5; turn it into Float64s
   my_confirmed = Array{Float64}(A[crows,5:end])

   # Add all rows for the country
   my_confirmed = sum(my_confirmed, dims=1)[:]

   return my_confirmed
end




"""
   country2conf(pais::Tuple{String, Array{String,1}}; invert=false)

   Given a tuple of a strings (representing a label, which will be ignored),
   and an array of strings, representing a list of countries,
   returns a numeric vector of cumulative confirmed cases, as a function of days.
   If the optional parameter invert=true, then returns the result for
   all countries *other* than those in the given list

"""
function country2conf(A, pais::Tuple{String, Array{String,1}}; invert=false)
   return country2conf(A, pais[2], invert=invert)
end



function country2conf(A, pais::Tuple{String, Array{Tuple{String,String},1}}; invert=false)
   return country2conf(A, pais[2], invert=invert)
end


"""
   A = setValue(A, country, datestring, value::Real)

   Given a dbase matrix A, set the value for a single entry specified by
   country and datestring. Returns the new dbase matrix. If country is a
   Tuple of two Strings, then it specifies region/country

   # PARAMETERS

   - A    dbase matrix

   - country   Can be a String, or a Tuple{String,String}. In the first
          case it specifies only a country, in the second it specifes region
          and country

   - datestring    A string of the form "m/d/yy". Must match one of A[1,5:end]

   - value     A scalar value
"""
function setValue(A, country, datestring, value::Real)
   if typeof(country) == Tuple{String, String}
      crows = findall((A[:,1] .== country[1]) .& (A[:,2] .== country[2]))
   else
      crows = findall(A[:,2] .== country)
   end
   ccols = findall(A[1,:] .== datestring)

   @assert (length(ccols)==1) && (length(crows)==1) "$country and $datestring must resolve to a single row and column"

   A[crows[1], ccols[1]] = value

   return A
end


"""
   val = getValue(A, country, datestring)

   Given a dbase matrix A, get the value for a single entry specified by
   country and datestring. If country is a
   Tuple of two Strings, then it specifies region/country

   # PARAMETERS

   - A    dbase matrix

   - country   Can be a String, or a Tuple{String,String}. In the first
          case it specifies only a country, in the second it specifes region
          and country

   - datestring    A string of the form "m/d/yy". Must match one of A[1,5:end]

"""
function getValue(A, country, datestring, value::Real)
   if typeof(country) == Tuple{String, String}
      crows = findall((A[:,1] .== country[1]) .& (A[:,2] .== country[2]))
   else
      crows = findall(A[:,2] .== country)
   end
   ccols = findall(A[1,:] .== datestring)

   @assert (length(ccols)==1) && (length(crows)==1) "$country and $datestring must resolve to a single row and column"

   return A[crows[1], ccols[1]]
end


function __init__()
   stateAbbrevMap         = readdlm(stateAbbrevMapFilename, ',');
end



end # ===== End MODULE
