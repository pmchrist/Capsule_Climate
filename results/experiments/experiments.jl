include("../../model/main.jl")


function getfilepath(
    folderpath::String,
    taxtype::Symbol
    )

    filepath = folderpath * "OFAT_experiments/"

    if taxtype == :τᴵ
        return filepath * "incometax.csv"
    elseif taxrate == :τᴷ
        return filepath * "capitaltax.csv"
    elseif taxrate == :τˢ
        return filepath * "salestax.csv"
    elseif taxrate == :τᴾ
        return filepath * "profittax.csv"
    elseif taxrate == :τᴱ
        return filepath * "energytax.csv"
    else
        return filepath * "carbontax.csv"
    end
end

"""


Runs OFAT experiment on the various tax rates
"""
function OFAT_taxrates(
    folderpath::String;
    n_per_type::Int64=10,
    n_per_rate::Int64=1,
    t_warmup::Int64=100,
    )

    # Define ranges of tax rates
    taxrates = Dict(
        :τᴵ => (0.0, 0.8),
        # :τᴷ => (0.0, 0.5),
        # :τˢ => (0.0, 0.5),
        # :τᴾ => (0.0, 0.8),
        # :τᴱ => (0.0, 1.0),
        # :τᶜ => (0.0, 1.0)
    )


    for (i, (taxtype, raterange)) in enumerate(taxrates)

        outputfilepath = getfilepath(folderpath, taxtype)

        println(taxtype, " ", raterange)

        results = nothing

        for taxrate in LinRange(raterange[1], raterange[2], n_per_type)
            changedtaxrates = [(taxtype, taxrate)]

            for i in 1:n_per_rate

                println("   $(taxtype), $(taxrate), $(i)")

                # Run the model with changed tax rate
                runoutput = run_simulation(
                    changedtaxrates=changedtaxrates,
                    full_output=false,
                    threadnr=Threads.threadid()
                )

                GDP_1st = mean(runoutput.GDP_growth[t_warmup:end])

                # Save results of run
                if results == nothing
                    results = DataFrame(
                        :taxtype => taxtype,
                        :taxrate => taxrate,
                        :GDP_1st => GDP_1st
                    )
                else
                    push!(results, [taxtype, taxrate, GDP_1st])
                end
            end
        end

        CSV.write(outputfilepath, results)
    end
end

folderpath = "results/experiments/"
OFAT_taxrates(folderpath)