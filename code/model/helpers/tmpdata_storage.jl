

"""
CMDATA - DATA STRUCT FOR CONSUMER MARKET DATA
"""

"""
Mutable struct that holds the data structures used to save data from the consumer
    market process.
"""
@with_kw mutable struct CMData
    n_hh::Int
    n_cp::Int

    true_D::Matrix{Float64} = spzeros(Float64, n_hh, n_cp)
    all_C::Vector{Float64} = zeros(Float64, n_hh)               # Monetary capacity of hh
    all_N::Vector{Float64} = zeros(Float64, n_cp)               # Monetary capacity of cp, i.e. How much they can sell in $ (inventory*price)
    all_Sust_Score::Vector{Float64} = zeros(Float64, n_hh)      # How much emissions bother a hh (for consumption decision)
    all_Sust_Penalty::Vector{Float64} = zeros(Float64, n_hh)    # Penalty of the household imposed onto the producer (score and emissions per unit)

    sold_per_hh::Vector{Float64} = spzeros(Float64, n_hh)
    sold_per_hh_round::Vector{Float64} = zeros(Float64, n_hh)
    sold_per_cp::Vector{Float64} = zeros(Float64, n_cp)
    sold_per_cp_round::Vector{Float64} = zeros(Float64, n_cp)

    weights::Matrix{Float64} = spzeros(Float64, n_hh, n_cp)
    weights_sum::Vector{Float64} = zeros(Float64, n_hh)

    transactions::Matrix{Float64} = spzeros(Float64, n_hh, n_cp)
    frac_sellable::Vector{Float64} = ones(Float64, n_cp)
    C_spread::Matrix{Float64} = spzeros(Float64, n_hh, n_cp)
    demand_per_cp::Vector{Float64} = zeros(Float64, n_cp)
end


"""
Resets fields in cm data struct before cm market process is initiated
"""
function reset_matrices_cp!(
    cmdata::CMData,
    all_hh::Vector{Int},
    all_cp::Vector{Int},
    model::ABM
    )

    # CP variables
    # Set to order of small to large id (minimum(all_cp):max(all_cp)
    #println()
    all_p = map(cp_id -> model[cp_id].p[end], minimum(all_cp):maximum(all_cp))              # Last Price
    norm_p = all_p ./ maximum(all_p)                                                        # Normalized Prices (Maybe we need MINMAX? Not just percentage from top value)
    #println(var(all_p) / mean(all_p))                                                       # Dispersion of prices
    if maximum(all_p) <= 0      # If there were some emissions in the last step
        # Should never happen
        println("WARNING: Price is zero or negative")
    end



    all_N_goods = map(cp_id -> model[cp_id].N_goods, minimum(all_cp):maximum(all_cp))       # Inventory Size
    # Emission aware value of good
    emiss_per_good = map(cp_id -> model[cp_id].emissions_per_item[end], minimum(all_cp):maximum(all_cp))    # Last Emissions
    #println(var(emiss_per_good) / mean(emiss_per_good))                                               # Dispersion of emissions
    # If Economy is all green, there is no point to take emissions in a decision process.
    only_price = false
    if maximum(emiss_per_good) > 0      # If there were some emissions in the last step
        norm_emiss_per_good = emiss_per_good ./ maximum(emiss_per_good)
    else
        # Can happen easily
        #println("WARNING: No Production or Clean Economy (second one)")
        only_price = true
        # set norm_emiss_per_good to be the same value for every entry
        norm_emiss_per_good = fill(0.0, length(emiss_per_good))  # Uniform distribution summing to 1
    end

    # price_score = []
    # env_score = []

    @inbounds for (i,hh_id) ∈ enumerate(minimum(all_hh):maximum(all_hh))

        # HH Variables
        cmdata.all_C[i] = model[hh_id].C        # C is budget, C for Capacity of HH
        cmdata.all_Sust_Score[i] = model[hh_id].Sust_Score
        cmdata.weights[i,:] .= 0.0

        # For each household there is a list of cp, we need to assign preferences in weights (shapr(i:hh, j:cp))
        for cp_id in model[hh_id].cp

            # cp are initiated after hh and cp_id will thus correspond to col + len(hh), 
            # so subtract len(hh) to get index
            j = cp_id - length(all_hh)

            cmdata.all_N[j] = all_N_goods[j] * all_p[j]     # Maximum amount of money that can be generated by cp (how much can be sold)
            # if (cmdata.all_N[j] <= 0 || isnan(cmdata.all_N[j]))
            #     cmdata.weights[i,j] = 0
            #     cmdata.all_N[j] = 0
            #     continue
            # end

            # # Cobb Douglas utility Price vs Emissions
            # # NOTE: Had a problem with simple Cobb Douglas, when emiss is 0 (no production) the emission part went to zero making weight 0, which is incorrect (0^0.3=0)
            # price_part = norm_p[j] ^ (1-cmdata.all_Sust_Score[i])           # Normalized Price is used
            # emiss_part = emiss_per_good[j] ^ cmdata.all_Sust_Score[i]       # Normalized emissions produced per good is used
            # cmdata.weights[i,j] = (price_part * emiss_part) ^ -1            # We return inverse, as these are weights for the decision process

            # Linear Combination utility Price and Emissions
            # NOTE: For now we just use a Linear Combination
            price_part = norm_p[j] * (1-cmdata.all_Sust_Score[i])           # Normalized Price is used
            emiss_part = norm_emiss_per_good[j] * cmdata.all_Sust_Score[i]       # Normalized emissions produced per good is used
            # # There is always a possibility of emiss part being zero
            if only_price
                cmdata.weights[i,j] = (norm_p[j]) ^ -1
            else
                cmdata.weights[i,j] = (price_part + emiss_part) ^ -1            # We return inverse, as these are weights for the decision process
            end

            #cmdata.weights[i,j] = (price_part + emiss_part) ^ -1
            # push!(price_score, price_part)
            # push!(env_score, emiss_part)

            #println(price_part, " | " , emiss_part, " | ", cmdata.weights[i,j])
            if (isnan(cmdata.weights[i,j]) || (cmdata.weights[i,j] <= 1e-3) || (cmdata.weights[i,j] == Inf) || (cmdata.weights[i,j] == -Inf))
                # Should never happen
                println("Incorrect Weight")
                #cmdata.weights[i,j] = 0     # Value can become nan because of zero divison, either zero inventory or zero emissions, in which case no point of using this producer
            end
        end
        #println(minimum(cmdata.weights[i]), " " , maximum(cmdata.weights[i]))       # Some values are problematic (like all zeros), find out the reason!!!
    end

    # ToDo: Verify it works correctly! - seems it is, values are compatible
    # println()
    # println("Price Utility Value: ", mean(price_score))
    # println("Sustainability Utility Value: ", mean(env_score))
    # println()

    cmdata.transactions .= 0.0
end


"""
GINIDATA - DATA STRUCT FOR CONSUMER MARKET DATA
"""

"""
Struct that holds intermediate data for GINI computations
"""
@with_kw mutable struct GINIData{D}
    I::Matrix{Float64} = Matrix{Float64}(undef, D, D)
    W::Matrix{Float64} = Matrix{Float64}(undef, D, D)
end