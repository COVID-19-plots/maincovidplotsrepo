module CarlosUtils

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


using Dates

export mydate, smooth, axisWidthChange, axisHeightChange, axisMove
export get_current_fig_position, set_current_fig_position

export stateName2AbbrevDict, abbrev2StateNameDict, abbrev2StateName,
    stateName2Abbrev

export myLinespec, findLinespecs, stashLinespecs, getLinespecs, handMeLinespec,
    saveLinespecList, loadLinespecList, nextLinespec, addToLinespecList,
    deleteFromLinespecList, replaceInLinespecList, colorOrder, markerOrder, Dict

# If we plot more than 10 lines, colors repeat; use next marker in that case
colorOrder = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"
    ]
markerOrder = ["o", "x", "P", "d", "*", "<"]


struct myLinespec
   label::String
   linewidth::Float64
   marker::String
   color::String
   alpha::Float64
end

linespecList = Array{myLinespec}(undef, 0)

"""
    axisLinespecs()

    Returns an Array of myLinespec for all the Line2D objects
    that are immediate children of the current axis
"""
function axisLinespecs()
    linespecs = Array{myLinespec}(undef, 0)

    h = gca().get_children()
    for i=1:length(h)
        if h[i].__class__.__name__ == "Line2D"
            myspec = myLinespec(h[i].get_label(), h[i].get_linewidth(),
                h[i].get_marker(), h[i].get_color(), h[i].get_alpha())
            linespecs = vcat(linespecs, myspec)
       end
   end

   return linespecs
end


"""
    stashLinespecs()

    For any line2D objects in the current axis whose label is not
    yet in the linespec list, add their linespec to the Main list
"""
function stashLinespecs()
    linespecs = axisLinespecs()
    for i=1:length(linespecs)
        if isempty(findall(x->x.label == linespecs[i].label, linespecList))
            global linespecList = vcat(linespecList, linespecs[i])
        end
    end
end


"""
    getLinespecs(;label=nothing, color=nothing, linewidth=nothing, marker=nothing)

    Return array of linespecs from the Main list matching things that were passed
    as not nothing
"""
function getLinespecs(;label=nothing, color=nothing, linewidth=nothing,
        marker=nothing, alpha=nothing)
    u = 1:length(linespecList)
    if label != nothing
        u = u[findall(x->x.label == label, linespecList[u])]
    end
    if color != nothing
        u = u[findall(x->x.color == color, linespecList[u])]
    end
    if marker != nothing
        u = u[findall(x->x.marker == marker, linespecList[u])]
    end
    if linewidth != nothing
        u = u[findall(x->x.linewidth == linewidth, linespecList[u])]
    end
    if alpha != nothing
        u = u[findall(x->x.alpha == alpha, linespecList[u])]
    end
    return linespecList[u]
end
"""
    getLinespecs(ml::myLinespec)

    Return array of linespecs from main list that match ml in all respects
"""
function getLinespecs(ml::myLinespec)
    return linespecList[findall(map(x -> x == ml, linespecList))]
end


"""
    nextLinespec()

    Using colorOrder and makerOrder, returns the next linespec that is
    not yet in the Main list. Uses linewidth=2.

    Steps through colors first, outer loop markers
"""
function nextLinespec()
    for i=1:length(markerOrder)
        for j=1:length(colorOrder)
            if isempty(getLinespecs(marker=markerOrder[i], color=colorOrder[j]))
                return myLinespec("", 2, markerOrder[i], colorOrder[j], 1)
            end
        end
    end

    error("Used up all markers and colors; add more to CarlosUtils.colorOrder or CarlosUtils.makerOrder?")
end


"""
    handMeLinespec(label)

    If a linespec for the given label already exists in the Main list, returns that.
    Otherwise, returns the next unused linespec.
"""
function handMeLinespec(label)
    ml = getLinespecs(label=label)
    if isempty(ml)
        return nextLinespec()
    else
        return ml[1]
    end
end

function handMeLinespec(label::Tuple{String,String})
    return handMeLinespec(string(label))
end

"""
    Dict(ml::myLinespec)

    returns ml in Dict format
"""
function Dict(ml::myLinespec)
    return Dict(:label=>ml.label, :linewidth=>ml.linewidth,
        :marker=>ml.marker, :color=>ml.color, :alpha=>ml.alpha)
end

using JLD
"""
    saveLinespecList(fname::String="linespeclist.jld")

    saves the Main linsepectList
"""
function saveLinespecList(fname::String="linespeclist.jld")
    save(fname, Dict("linespecList"=>linespecList))
end


"""
    loadLinespecList(fname::String="linespeclist.jld")

    loads and returns the Main linsepectList
    (overwrites previous existing Main linspecList)
"""
function loadLinespecList(fname::String="linespeclist.jld")
    global linespecList = load(fname)["linespecList"]
end

"""
    addToLinespecList(ml::myLinespec)

    If ml is not already in the Main linespec list, add it
"""
function addToLinespecList(ml::myLinespec)
    if isempty(getLinespecs(ml))
        global linespecList = vcat(linespecList, ml)
    end
end

"""
    deleteFromLinespecList(ml::myLinespec)

    If ml is in the Main linespec list, delete it
"""
function deleteFromLinespecList(ml::myLinespec)
    global linespecList = setdiff(linespecList, [ml])
end

"""
    replaceInLinespecList(ml::myLinespec)

    If there is one linespec that matches ml's label in the main linespec list
    that linespec is replaced with ml
"""
function replaceInLinespecList(ml::myLinespec)
    oldml = getLinespecs(label=ml.label)
    if length(oldml)==1
        deleteFromLinespecList(oldml[1])
        addToLinespecList(ml)
    else
        error("Did not find exactly one linespec matching label=", ml.label)
    end
end



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
    for k in keys(stateName2AbbrevDict)
        abbrev2StateNameDict[stateName2AbbrevDict[k]] = k
    end

    linespecList = Array{myLinespec}(undef, 0)
end




end # ====== END MODULE ========
