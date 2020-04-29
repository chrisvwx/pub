"""
    irsPublicSupport501c3(v::Vector)

Given a vector of donations `v`, check whether the donations pass the IRS'
"one-third" or "one-tenth" tests. 

# Examples
```jldoctest
julia> v = [10000, 10000, 10000, 10000, 460000]; 

julia> irsPublicSupport501c3(v)
The donations do not pass the IRS' "one-third test" but do pass the "ten-percent" test. An applicationwith the IRS for an exception on "Facts and circumstances will need to be filed.

julia> v = [1000*ones(20); 8000*ones(20); 320000]; sum(v)
500000.0

julia> irsPublicSupport501c3(v)
The donations pass the IRS' "one-third test." 
This means that no special legal machinations are needed.
```
"""
function irsPublicSupport501c3(v::Vector)
    # First calculate the total donations
    total = sum(v)
    # Then calculate the threshold for public donations
    threshold = .02*total
    # Find the amounts which the IRS calls "public".  
    public = min.(v,threshold) # public is a vector, just like v
    pctPublic = sum(public)/total
    if pctPublic>=1/3
        println("The donations pass the IRS' \"one-third test.\" ")
        println("This means that no special legal machinations are needed.")
    elseif pctPublic>=.1
        println("The donations do not pass the IRS' \"one-third test\" "*
                "but do pass the \"ten-percent\" test. An application "*
                "with the IRS for an exception on \"facts and "*
                "circumstances will need to be filed.")
    else
        println("The donations do not pass either the \"one-third test,\"")
        println("or the \"ten-percent\" test.")
    end
end

