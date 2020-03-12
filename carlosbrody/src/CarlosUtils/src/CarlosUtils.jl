module CarlosUtils

export mydate, smooth, axisWidthChange, axisHeightChange, axisMove

export stateName2Abbrev, abbrev2StateName

stateName2Abbrev = Dict(
    "New Jersey"    => "NJ",
    "California"    => "CA",
    "Florida"       => "FL",
    "Washington"    => "WA",
    "New York"      => "NY",
    "Texas"         => "TX",
    "Illinois"      => "IL",
    "Connecticut"   => "CT"
)

abbrev2StateName = Dict()


"""
   mydate(str)
   Turns a struing of the form 03/02/20  into 2-March-20
"""
function mydate(str)
   d = Date(str, "mm/dd/yy")
   return "$(Dates.day(d))-$(Dates.monthname(d))-$(Dates.year(d))"
end


"""
    smooth(s::Vector, k::Vector)

    Convolves vector s with vector k. The vector k must be odd in length and the
    center element corresponds to position 0. Treats edge effects gracefully and
    returns a vector of same length as s
"""
function smooth(s::Vector, k::Vector)
   @assert isodd(length(k)) "k should have odd length"

   mid = Int64((length(k)+1)/2)

   sout = copy(s)
   for i=1:length(s)
      sguys = maximum([i-(mid-1), 1]) : minimum([i+(mid-1), length(s)])
      kguys = sguys .- i .+ mid

      sout[i] = sum(s[sguys].*k[kguys])./sum(k[kguys])
   end
   return sout
end




"""
ax = axisWidthChange(factor; lock="c", ax=nothing)

Changes the width of the current axes by a scalar factor.

= PARAMETERS:
 - factor      The scalar value by which to change the width, for example
               0.8 (to make them thinner) or 1.5 (to make them fatter)

= OPTIONAL PARAMETERS:
 - lock="c"    Which part of the axis to keep fixed. "c", the default does
               the changes around the middle; "l" means keep the left edge fixed
               "r" means keep the right edge fixed

 - ax = nothing   If left as the default (nothing), works on the current axis;
               otherwise should be an axis object to be modified.
"""
function axisWidthChange(factor; lock="c", ax=nothing)
    if ax==nothing; ax=gca(); end
    x, y, w, h = ax.get_position().bounds

    if lock=="l";
    elseif lock=="c" || lock=="m"; x = x + w*(1-factor)/2;
    elseif lock=="r"; x = x + w*(1-factor);
    else error("I don't know lock type ", lock)
    end

    w = w*factor;
    ax.set_position([x, y, w, h])

    return ax
end


"""
ax = axisHeightChange(factor; lock="c", ax=nothing)

Changes the height of the current axes by a scalar factor.

= PARAMETERS:
 - factor      The scalar value by which to change the height, for example
               0.8 (to make them shorter) or 1.5 (to make them taller)

= OPTIONAL PARAMETERS:
 - lock="c"    Which part of the axis to keep fixed. "c", the default does
               the changes around the middle; "b" means keep the bottom edge fixed
               "t" means keep the top edge fixed

 - ax = nothing   If left as the default (nothing), works on the current axis;
               otherwise should be an axis object to be modified.
"""
function axisHeightChange(factor; lock="c", ax=nothing)
    if ax==nothing; ax=gca(); end
    x, y, w, h = ax.get_position().bounds

    if lock=="b";
    elseif lock=="c" || lock=="m"; y = y + h*(1-factor)/2;
    elseif lock=="t"; y = y + h*(1-factor);
    else error("I don't know lock type ", lock)
    end

    h = h*factor;
    ax.set_position([x, y, w, h])

    return ax
end


"""
   ax = axisMove(xd, yd; ax=nothing)

Move an axis within a figure.

= PARAMETERS:
- xd      How much to move horizontally. Units are scaled figure units, from
           0 to 1 (with 1 meaning the full width of the figure)

- yd      How much to move vertically. Units are scaled figure units, from
            0 to 1 (with 1 meaning the full height of the figure)

= OPTIONAL PARAMETERS:
 - ax = nothing   If left as the default (nothing), works on the current axis;
               otherwise should be an axis object to be modified.

"""
function axisMove(xd, yd; ax=nothing)
    if ax==nothing; ax=gca(); end
    x, y, w, h = ax.get_position().bounds

    x += xd
    y += yd

    ax.set_position([x, y, w, h])
    return ax
end


function __init__()
    for k in keys(stateName2Abbrev)
        abbrev2StateName[stateName2Abbrev[k]] = k
    end

end

end # ====== END MODULE ========
