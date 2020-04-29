dname = "../../data/covidtracking.com/api/states"
fname = "daily.csv"

C = readdlm("$dname/$fname", ',');
PV = covid2JHParsing(C, "positive./(positive + negative)")

region = ("California", "US")

d = country2conf(D, region)
pv = country2conf(PV, region)
pg = smooth(percentileGrowth(smooth(diff(d), smkernel), assessDelta=14, expressDelta=7),
   [0.5, 1, 0.5])

dp=20
clf()
subplot(2,1,1)
plot(pg[end-dp:end])

subplot(2,1,2)
n=length(pg)
plot(pv[end-n+1:end][end-dp:end])
