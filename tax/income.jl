using DelimitedFiles
using Plots
using Scanf

cpi = readdlm("cpi.csv",',');
cpiD = Dict(cpi[i,1]=>cpi[i,2] for i in 1:size(cpi)[1]);

rawBrackets = readdlm("brackets.csv",',')

# I could parse last, first from brackets in future
lastYear = 2024
firstYear = 1862
Nyears = lastYear-firstYear+1


# count bracket sizes
bSizes = zeros(Int64, Nyears,5);
Nrows = size(rawBrackets)[1]
for rw = 2:Nrows
    year = rawBrackets[rw,1]
    if ~isempty(year) && isinteger(year)
        yx = year - firstYear+1
        bSizes[yx,1] = year
        for ix=0:3
            tmp = rawBrackets[rw,ix*3+2]
            if ~isempty(tmp) && ~(tmp.=="No income tax")
                bSizes[yx,ix+2] +=1
            end
        end
    end
end


# parse brackets out of raw data
brackets = Dict{Int64,Dict{Int64,Array{Float64,2}}}()
thisIx = 0
for rw = 2:Nrows
    year = rawBrackets[rw,1]
    if ~isempty(year) && isinteger(year)
        yx = year - firstYear+1
        if ~haskey(brackets,year)
            thisBracket = Dict{Int64,Array{Float64,2}}()
            push!(brackets,year=>thisBracket)
            for ix=0:3
                Nbrackets = bSizes[yx,ix+2]
                mat = fill(NaN,Nbrackets,2)
                push!(thisBracket,ix+1=>mat)
            end
            thisIx=1
        else
            thisBracket = brackets[year]
            thisIx+=1
        end
        for ix=0:3
            tmp = rawBrackets[rw,ix*3+2]
            if ~isempty(tmp) && bSizes[yx,ix+2]>0
                mat = thisBracket[ix+1]
                mat[thisIx,1] = @scanf(rawBrackets[rw,ix*3+2],"%f",Float64)[2]
                endBracket = replace(rawBrackets[rw,ix*3+4],","=>"")
                endBracket = replace(endBracket,"\$"=>"")
                mat[thisIx,2] = @scanf(endBracket,"%d",Int64)[2]
            end
        end
    end
end

function rate(income,bracket)
    if size(bracket)[1]==0
        return 0
    end
    diffb = diff(bracket[:,2])
    diffTx = diffb.* bracket[1:end-1,1]/100
    ix = findfirst(income.<bracket[:,2])
    if ~isnothing(ix)
        # income less than max bracket
        ~isinteger(ix) && ix<=0 && error("unknown error")
        if ix==1
            tax = 0
        else
            tax = sum(diffTx[1:ix-2])
            residualIncome = income-bracket[ix-1,2]
            tax += residualIncome*bracket[ix-1,1]/100
        end
    else
        # income greater than max bracket
        tax = sum(diffTx)
        residualIncome = income-bracket[end,2]
        tax += residualIncome*bracket[end,1]/100
    end
    return tax/income*100
end

function inflationCalc(price1,year1,year2,cpi)
    # Year 2 Price = Year 1 Price x (Year 2 CPI/Year 1 CPI)
    return price1 * cpi[year2]/cpi[year1]
end

function inflationLevelBrackets!(brackets,cpi,targetYear)
    for year = 1862:2024
        levelCalc(price) = inflationCalc(price,year,targetYear,cpi)
        for i = 1:4
            brackets[year][i][:,2] = levelCalc.(brackets[year][i][:,2])
        end
    end
end
inflationLevelBrackets!(brackets,cpiD,2024)


year = 2024
rate1(income) = rate(income,brackets[year][1])
rate2(income) = rate(income,brackets[year][2])
rate3(income) = rate(income,brackets[year][3])
rate4(income) = rate(income,brackets[year][4])
incomes = round.(10 .^collect(3.5:.1:7.5));
tax1 = rate1.(incomes)
tax2 = rate2.(incomes)
tax3 = rate3.(incomes)
tax4 = rate4.(incomes)

#plt = plot(xscale=:log10,legend_position=false);
plt = plot(xscale=:log10);
plot!(plt,incomes,tax1,linecolor=:blue,label="MfJ")
plot!(plt,incomes,tax2,linecolor=:red,label="MfS")
plot!(plt,incomes,tax3,linecolor=:green,label="Single")
plot!(plt,incomes,tax4,linecolor=:black,label="HoH")





function plotYearAnim(year,status)
    rate1(income) = rate(income,brackets[year][status])
    tax1 = rate1.(incomes);
    plt = plot(xscale=:log10,legend_position=false,
               xticks = xtickLabels,
               yticks = ytickLabels,
               xtickfont =font(12),
               ytickfont =font(12),
               ylims=(0,90),
               xlabel="Incomes in 2024 dollars",
               ylabel="Tax rate");
    plot!(plt,incomes,tax1,linecolor=:blue,
               linewidth=2.5)
    annotate!(plt,4e4, 80, string(year), font(48))
#    annotate!(plt,4e3, -11,"c.im/@chrisp", font(7))
end
incomes = round.(10 .^collect(3.9:.1:7.1));
    
xtickLabels = (10 .^collect(3:7), ["\$1k" "\$10k" "\$100k" "\$1M" "\$10M"])
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
anim = Animation()
for year=1862:2024
    plotYearAnim(year,1)
    frame(anim)
end
plot(legend=false,grid=false,foreground_color_subplot=:white)  
frame(anim)
frame(anim)
frame(anim)
gif(anim, "animatedBrackets.gif", fps = 6)



function plotYear(plt,year,status)
    rate1(income) = rate(income,brackets[year][status])
    tax1 = rate1.(incomes);
    plot!(plt,incomes,tax1,label=string(year),linewidth=2.5)
end

ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
plt = plot(xscale=:log10,legend_position=:topleft,
           xticks = xtickLabels,
           yticks = ytickLabels,
           legendfont =font(12),
           xtickfont =font(12),
           ytickfont =font(12),
           ylims=(-.3,90),
           xlabel="Incomes in 2024 dollars",
           ylabel="Tax rate");
incomes = round.(10 .^collect(3.9:.1:7.1));
plotYear(plt,1864,1)
plotYear(plt,1904,1)
plotYear(plt,1944,1)
plotYear(plt,1984,1)
plotYear(plt,2024,1)
savefig("fortyYearIncrements.png")




plot(bSizes[:,1],bSizes[:,2],
     legend_position=false,
     xtickfont =font(12),
     ytickfont =font(12),
     titlefont =font(12),
     xlabel="Year",
     title="Number of income tax brackets")
savefig("numberOfBrackets.png")





function getRate(year,status,incomes)
    rate1(income) = rate(income,brackets[year][status])
    return rate1.(incomes)
end
incomes = round.(10 .^collect(3:.1:8));
Nincomes = length(incomes)
statusStrs = ["mfj", "mfs", "single", "hoh"]

for status = 1:4
    io = open(statusStrs[status]*".csv","w")
    print(io,"Incomes")
    for i=1:Nincomes
        thisIncome = Int64(round(incomes[i]))
        print(io,", $thisIncome")
    end
    println(io,"")
    for year=firstYear:lastYear
        rates = getRate(year,status,incomes)
        print(io,"$year")
        for i=1:Nincomes
            thisrate = round(rates[i]*100)/100
            print(io,", $thisrate")
        end
        println(io,"")
    end
    close(io)
end
