#! /bin/tcsh


pushd ../../../COVID-19 ; git pull ; popd

curl http://covidtracking.com/api/states/daily.csv -o ../../data/covidtracking.com/api/states/daily.csv

# curl https://github.com/datasets/population/blob/master/data/population.csv  -o ../../data/datasets/population/blob/master/data/popularion.csv
