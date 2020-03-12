# COVID-19-plots

I was curious as to what these plots would look like. Thanks to the open availability of the [database](https://github.com/CSSEGISandData/COVID-19) for the [Johns Hopkins COVID-19 dashboard](https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6) (their [mobile version here](https://www.arcgis.com/apps/opsdashboard/index.html#/85320e2ea5424dfaaa75ae62e5c06e61)), I was able to make the plots myself. Thank you Johns Hopkins.

### Daily percentile growth rates in confirmed cases per country

The first plot shows the percentage daily growth in number of confirmed cases for a selected set of countries. For each country, the data plot starts after 50 cases were reached (it is too noisy before that). Note that net number of confirmed cases can change over time due to many factors, including test availability, test applications, reporting accuracy, etc. These plots simply show the available data as is.

Notable trends include South Korea's gradual slowing of it's growth rate, and the fact that although Japan's growth rate has been much smaller than most other countries, it has held steady. Caseloads growing at a contsant exponential rate  correspond to a horizontal line in this plot. In other words, although growth rate in Japan is comparatively slower than others, it is still exponential growth. Mainland China is the orange line at the bottom, near zero.


<img src="src/multiplicative_factor_1.jpg" width="1200"> 


### Cumulative number of confirmed cases per country

This plot shows total number of confirmed cases, for the same countries as the first plot (same color code also). Since the vertical axis is logarithmic, percentage daily growth (in the first plot) is proportional to the slope of the lines in this plot. China is the orange line at the top. As of 2020-March-08, China has both by far the largest caseload and by far the slowest growth rate.

<img src="src/confirmed.jpg" width="1000">

#### 2020-March-09 : Signs of a trend?

~Spain had a terrible day, Italy continues to rage unabated, but in the rest of Europe... noise? changes in testing? Or the beginning signs of a possibly encouraging trend?~ Update: downwards trend went away after one day. Meant nothing.  :(

#### 2020-March-06 : One possible conclusion

Three of the countries with the largest caseloads as of 6-March-2020, namely China, South Korea, and Italy, are also countries with some of the smallest growth rates, specially China and South Korea. Their experience has clearly led them to learn something about how to deal with COVID-19. But the rest of the world hasn't learned from *them*: almost everyone starts at growth rates much higher than the current growth rates in those countries.

Perhaps the problem is political: perhaps it takes 500+ cases within your own borders before the measures needed to contain growth become politically feasible, even if your neighbor already went through it. And even if limiting growth would be of course far easier at the start, when you have fewer cases.

### Update frequency

Although the [Johns Hopkins COVID-19 dashboard](https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6) is updated frequently, they update their [database](https://github.com/CSSEGISandData/COVID-19) with the time series only once a day. I will likely update these once a day also.

