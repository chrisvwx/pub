println("loading packages...")

using DelimitedFiles
using Plots
using Dates
using HTTP

# Lotsa hacks going on in this file. Julia and it's ecosystem have many
# other tools; All of this could be done faster and cleaner than is done
# below

println("Downloading NYT data...")
r = HTTP.get(
    "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv");
write("us-states.csv",r.body)
stateData = readdlm("us-states.csv",',');

r = HTTP.get(
    "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv");
write("us-counties.csv",r.body)
countyData = readdlm("us-counties.csv",',');

# yes, I'm sure other tools can do this faster
function selectRows(data,colToMatch,valueToMatch,colValue,startRow)
    ix = findall(x -> x==valueToMatch,data[:,colToMatch])
    dates = Date.(data[ix[startRow:end],1]);
    values = data[ix[startRow:end],colValue];
    return dates,values
end

function ms(valuesIn)
    values = convert(Array{Any,1},valuesIn[:])
    values[findall(x -> x==0,values)] .= missing
    return values
end

println("Processing...")

datesNY,deathsNY=selectRows(stateData,2,"New York",5,3);
datesCA,deathsCA=selectRows(stateData,2,"California",5,39);

datesSCC,deathsSCC=selectRows(countyData,2,"Santa Clara",6,33);
datesSM,deathsSM=selectRows(countyData,2,"San Mateo",6,2);
datesSF,deathsSF=selectRows(countyData,2,"San Francisco",6,31);
datesA,deathsA=selectRows(countyData,2,"Alameda",6,3);
datesCC,deathsCC=selectRows(countyData,2,"Contra Costa",6,1);
datesSL,deathsSL=selectRows(countyData,2,"Solano",6,9);
datesN,deathsN=selectRows(countyData,2,"Napa",6,7);
datesSN,deathsSN=selectRows(countyData,2,"Sonoma",6,7);
datesMN,deathsMN=selectRows(countyData,2,"Marin",6,7);
datesSC,deathsSC=selectRows(countyData,4,06087,6,1);# Santa Cruz County
deathsSC = [zeros(Int64,4,1); deathsSC];

# Minor modifications to NY Times data for Santa Clara County
deathsSCCchris = copy(deathsSCC)
deathsSCCchris[21] = 16 # Mar 23 https://twitter.com/HealthySCC/status/1242573317065904128
deathsSCCchris[23] = 19 # Mar 25 https://twitter.com/HealthySCC/status/1243295617176272896
deathsSCCchris[25] = 25 # Mar 27 http://archive.vn/d4OCi
deathsSCCchris[26] = 25 # Mar 28 http://archive.vn/7rERj
deathsSCCchris[27] = 28 # Mar 29 https://archive.is/jYswh
deathsSCCchris[28] = 30 # Mar 30
deathsSCCchris[29] = 32 # Mar 31
##[datesSCC deathsSCC deathsSCCchris]
deathsSCC = copy(deathsSCCchris)

deathsBay = deathsSCC .+ deathsSM  .+ deathsSF  .+ deathsA .+ deathsSL .+ deathsN .+ deathsSN .+ deathsMN .+ deathsSC;
#[datesSCC
#  deathsSCC deathsSM deathsSF deathsA deathsSL deathsN deathsSN deathsMN deathsSC]

# deathsCA[end] = 135;
# deathsNY[end] = 0;


println("Plotting...")

plot(datesCA,ms(deathsNY),label="New York (NY Times)" ,linewidth=4)
plot!(datesCA,ms(deathsCA),label="California (NY Times)" ,linewidth=4)
plot!(datesSCC,ms(deathsSCC),label="Santa Clara County (PubHealthDept)" ,linewidth=4)

yaxis!(:log10)
#yTickV = [1 2 5 10 20 50 100]
yTickV = [1 2 5 10 20 50 100 200 500 1000] 
datesX = datesSCC[2:2:end];
plot!(yticks = (yTickV, [string(ix) for ix ∈ yTickV]),
      xticks = (datesX, [Dates.format(ix,"u d") for ix ∈ datesX]),
      xtickfontsize=12,ytickfontsize=12,
      legend=:topleft,legendfontsize=12,
      xrotation=30,
      )
#      size=(1000,750),
title!("Total Deaths from COVID-19")
savefig("santaClaraCountyDeaths.png")


# datesLA,deathsLA=selectRows(countyData,2,"Los Angeles",6,38);
# datesK,deathsK=selectRows(countyData,2,"King",6,5);
# plot(datesCA,ms(deathsCA),label="California (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(deathsBay),label="SF Bay Area (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(deathsLA),label="Los Angeles County (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(deathsK),label="King County WA (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(deathsSCC),label="Santa Clara County (PubHealthDept)" ,linewidth=4)

# yaxis!(:log10)
# yTickV = [1 2 5 10 20 50 100] 
# datesX = datesSCC[2:2:end];
# plot!(yticks = (yTickV, [string(ix) for ix ∈ yTickV]),
#       xticks = (datesX, [Dates.format(ix,"u d") for ix ∈ datesX]),
#       xtickfontsize=12,ytickfontsize=12,
#       legend=:topleft,legendfontsize=12,
#       xrotation=30,
#       )
# #      size=(1000,750),
# title!("Total Deaths from COVID-19")
# savefig("sccSFbayLAandCA.png")



# datesCA,casesCA=selectRows(stateData,2,"California",4,34);
# datesUT,casesUT=selectRows(stateData,2,"Utah",4,3);
# datesSCC,casesSCC=selectRows(countyData,2,"Santa Clara",5,28);
# plot(datesCA,ms(casesCA),label="California (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(casesSCC),label="Santa Clara County (NY Times)" ,linewidth=4)
# plot!(datesSCC,ms(casesUT),label="Utah (NY Times)" ,linewidth=4)

# yaxis!(:log10)
# yTickV = [1 2 5 10 20 50 100 200 500 1000 2000 5000] 
# datesX = datesSCC[2:2:end];
# plot!(yticks = (yTickV, [string(ix) for ix ∈ yTickV]),
#       xticks = (datesX, [Dates.format(ix,"u d") for ix ∈ datesX]),
#       xtickfontsize=12,ytickfontsize=12,
#       legend=:topleft,legendfontsize=12,
#       xrotation=30,
#       )
# #      size=(1000,750),
# title!("Confirmed COVID-19 cases")
# savefig("sccVut.png")


