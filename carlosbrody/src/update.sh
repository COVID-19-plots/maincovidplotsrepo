#! /bin/tcsh


pushd ../../../COVID-19 ; git pull ; popd

curl http://covidtracking.com/api/states/daily.csv -o ../../data/covidtracking.com/api/states/daily.csv
