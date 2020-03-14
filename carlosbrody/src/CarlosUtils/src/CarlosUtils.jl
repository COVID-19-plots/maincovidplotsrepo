module CarlosUtils

export mydate, smooth, axisWidthChange, axisHeightChange, axisMove
export get_current_fig_position, set_current_fig_position

export stateName2AbbrevDict, abbrev2StateNameDict, abbrev2StateName, stateName2Abbrev

stateName2AbbrevDict = Dict(
    "New Jersey"    => "NJ",
    "California"    => "CA",
    "Florida"       => "FL",
    "Washington"    => "WA",
    "New York"      => "NY",
    "Texas"         => "TX",
    "Illinois"      => "IL",
    "Connecticut"   => "CT"
)

abbrev2StateNameDict = Dict()

"""
    abbrev2StateName(abrs::Array{String,1})

    Given an array of state name abbreviations, like ["NY", "CT"] returns
    the corresponding full state names, ["New York", "Connecticut"]
"""
function abbrev2StateName(abrs::Array{String,1})
    return map(x -> abbrev2StateNameDict[x], abrs)
end


"""
    stateName2Abbrev(snms::Array{String,1})

    Given an array of state names, like ["New York", "Connecticut"], returns
    the corresponding full state abbreviations, ["NY", "CT"]
"""
function stateName2Abbrev(snms::Array{String,1})
    return map(x -> stateName2AbbrevDict[x], snms)
end


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

using PyPlot
using PyCall

"""

(x, y, w, h) = get_current_fig_position()

Returns the current figure's x, y, width and height position on the screen.

Works only when pygui(true) and when the back end is Tk or QT.
Has been tested only with PyPlot.
"""
function get_current_fig_position()
    try
        if occursin("Tk", PyCall.pystring(PyPlot.get_current_fig_manager()))
            g = split(plt.get_current_fig_manager().window.geometry(), ['x', '+'])
            w = parse(Int64, g[1])
            h = parse(Int64, g[2])
            x = parse(Int64, g[3])
            y = parse(Int64, g[4])
        elseif occursin("QT", pystring(plt.get_current_fig_manager()))
            x = PyPlot.get_current_fig_manager().window.pos().x()
            y = PyPlot.get_current_fig_manager().window.pos().y()
            w = PyPlot.get_current_fig_manager().window.width()
            h = PyPlot.get_current_fig_manager().window.height()
        else
            error("Only know how to work with matplotlib graphics backends that are either Tk or QT")
        end

        return (x, y, w, h)
    catch
        error("Failed to get current figure position. Is pygui(false) or are you using a back end other than QT or Tk?")
    end
end


"""

set_current_fig_position(x, y, w, h)

Sets the current figure's x, y, width and height position on the screen.

Works only when pygui(true) and when the back end is Tk or QT.
Has been tested only with PyPlot.
"""
function set_current_fig_position(x, y, w, h)
    # if !contains(pystring(plt[:get_current_fig_manager]()), "FigureManagerQT")
    try
        if occursin("Tk", PyCall.pystring(PyPlot.get_current_fig_manager()))
            PyPlot.get_current_fig_manager().window.geometry("$(w)x$h+$x+$y")
        elseif occursin("QT", pystring(plt.get_current_fig_manager()))
            PyPlot.get_current_fig_manager().window.setGeometry(x, y, w, h)
        else
            error("Only know how to work with matplotlib graphics backends that are either Tk or QT")
        end
    catch
        error("Failed to set current figure position. Is pygui(false) or are you using a back end other than QT?")
    end
end


function __init__()
    for k in keys(stateName2Abbrev)
        abbrev2StateNameDict[stateName2Abbrev[k]] = k
    end

end




end # ====== END MODULE ========
