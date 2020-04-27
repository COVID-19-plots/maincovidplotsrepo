The code to make the plots in the [repo](../../README.md) is written in Julia and is all here in this directory.

The module [CarlosUtils](./CarlosUtils/src/CarlosUtils.jl) has some general-purpose utilities.

The module [CovidFunctions](./CovidFunctions/src/CovidFunctions.jl) has functions to load the data, and extract time series from it.

### Code structure 

The main plotting functions are in [fndefs.jl](./fndefs.jl). Then [states.jl](./states.jl), [europe.jl](europe.jl), [latinamerica.jl](./latinamerica.jl), [global.jl](./global.jl) use those functions to produce all the plots for different sets of world regions.

### fndefs.j;

Within [fndefs.jl](./fndefs.jl):

#### The workhorses:

`plotSingle()` plots a single time series.

`plotMany()` plots multiple time series and adds a legend.

As optional arguments, they take the plotting function (`plot` or `semilogy`), a function to apply to each series before plotting it, a function to generate the legend label for each series, and several others.

#### Others

Then other functions are used as convenient entryways to `plotMany()`:

`plotCumulative()` plots many cumulative case time series.

`plotNew()` first takes the diff of a time series, to plot new entries per day.

`plotAligned()` alignes series on a given point (e.g., 200 cases).

`plotGrowth()` plots percentage growth in a series.

`plotNewGrowth()` first takes the diff, to plot new entries/day, and then plots percentage growth or decay in a series, also expressing it as R (reproductive ratio).


