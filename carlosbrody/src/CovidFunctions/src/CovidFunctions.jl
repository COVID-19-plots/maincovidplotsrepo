module CovidFunctions

using DelimitedFiles


export loadConfirmedDbase, collapseUSStates, country2conf, setValue, getValue


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
   fname = "time_series_19-covid-Confirmed.csv")

   return readdlm("$dname/$fname", ',');
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





end # ===== End MODULE
