using DelimitedFiles
using Plots
using Dates
using HTTP

# Lotsa hacks going on in this file. Julia and it's ecosystem have many
# other tools; All of this could be done faster and cleaner.  

r = HTTP.get(
    "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv");
write("us-states.csv",r.body)
stateData = readdlm("us-states.csv",',');

r = HTTP.get(
    "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv");
write("us-counties.csv",r.body)
countyData = readdlm("us-counties.csv",',');

# yes, I'm sure other tools can do this faster. 
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
deathsSC = [zeros(Int64,4,1); deathsSC]

deathsSCCchris = copy(deathsSCC)
deathsSCCchris[21] = 16 # Mar 23 https://twitter.com/HealthySCC/status/1242573317065904128
deathsSCCchris[23] = 19 # Mar 25 https://twitter.com/HealthySCC/status/1243295617176272896
#[datesSCC deathsSCC deathsSCCchris]
deathsSCC = copy(deathsSCCchris)

deathsBay = deathsSCC .+ deathsSM  .+ deathsSF  .+ deathsA .+ deathsSL .+ deathsN .+ deathsSN .+ deathsMN .+ deathsSC

#[datesSCC
#  deathsSCC deathsSM deathsSF deathsA deathsSL deathsN deathsSN deathsMN deathsSC]


plot(datesCA,ms(deathsCA),label="California (NY Times)" ,linewidth=4)
plot!(datesSCC,ms(deathsBay),label="SF Bay Area (NY Times)" ,linewidth=4)
plot!(datesSCC,ms(deathsSCC),label="Santa Clara County (PubHealthDept)" ,linewidth=4)

yaxis!(:log10)
yTickV = [1 2 5 10 20 50 100]
datesX = datesSCC[2:2:end];
plot!(yticks = (yTickV, [string(ix) for ix ∈ yTickV]),
      xticks = (datesX, [Dates.format(ix,"u d") for ix ∈ datesX]),
      xtickfontsize=12,ytickfontsize=12,
      legend=:topleft,legendfontsize=12,
      xrotation=30,
      )
title!("Deaths from COVID-19")
savefig("santaClaraCountyDeaths.png")
