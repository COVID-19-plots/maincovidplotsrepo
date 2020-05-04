#! /bin/tcsh


pushd ../../../COVID-19 ; git pull ; popd

# curl https://covidtracking.com/api/v1/states/daily.csv -o ../../data/covidtracking.com/api/v1/states/daily.csv
curl https://covidtracking.com/api/v1/states/daily.csv -o ../../data/covidtracking.com/api/v1/states/daily.csv

# curl https://github.com/datasets/population/blob/master/data/population.csv  -o ../../data/datasets/population/blob/master/data/popularion.csv
