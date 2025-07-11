@with_kw mutable struct Household <: AbstractAgent

    id :: Int64                                 # global id

    # Employment variables
    employed::Bool = false                      # is employed
    employer_id::Union{Int64} = 0               # id of employer
    L::Float64 = 100.0                          # labor units in household
    w::Vector{Float64} = ones(Float64, 4)       # wage
    wˢ::Float64 = 1.0                           # satisfying wage
    wʳ::Float64 = 1.0                           # requested wage
    T_unemp::Int64 = 0                          # time periods unemployed
    skill::Float64                              # skill level of household

    # Income and wealth variables
    total_I::Float64 = L * skill                # total income from all factors
    labor_I::Float64 = L * skill                # income from labor
    capital_I::Float64 = 0.0                    # income from capital
    UB_I::Float64 = 0.0                         # income from unemployment benefits
    socben_I::Float64 = 0.0                     # income from social benefits (outside of UB)
    s::Float64 = 0.0                            # savings rate
    W::Float64 = 200.                           # wealth or cash on hand
    W̃::Float64 = 200.                           # real wealth level

    α::Float64 = 0.8                            # Household's consumption fraction of wealth
    β::Float64 = 1.                             # Household's discount factor

    # Expected income sources
    EYL_t::Float64 = L * skill                  # expected labor income
    EYS_t::Float64 = 0.0                        # expected social benefits income
    EY_t::Float64 = EYL_t + EYS_t               # expected income from labor and social benefits
    ER_t::Float64 = 0.05                        # expected returns on capital

    # Consumption variables
    C::Float64 = 0.0                           # budget
    C_actual::Float64 = 0.0                    # actual spending on consumption goods
    cp::Vector{Int64} = Int64[]                # connected cp
    unsat_dem::Dict{Int64, Float64} = Dict()   # unsatisfied demands
    P̄::Float64 = 1.0                           # weighted average price of bp
    P̄ᵉ::Float64 = 1.0                          # expected weighted average price of bp
    #c_L::Float64 = 0.5                         # share of income used to buy luxury goods      # Never implemented
    
    Sust_Score::Float64                       # Opinion on how much environment is important [0-not important, 1-important]
    Sust_Score_Base::Float64 = Sust_Score             # Opinion from a previous step (used in opinion dynamics model)
    Sust_Score_Uncertainty::Float64            # Uncertainty in beliefs on how important sustainability is [0-not sur, 1-sure in his opinion] (used in opinion dynamics model, influences dynamics of change)
    Sust_Score_Init::Float64 = Sust_Score                                    # Just for visualization of Wealth Experiment
    Sust_Score_Uncertainty_Init::Float64 = Sust_Score_Uncertainty            # Just for visualization of Wealth Experiment
end


"""
Uniformly samples cp to be in trading network.
"""
function select_cp_hh!(
    hh::Household,
    all_cp::Vector{Int64},
    n_cp_hh::Int64
    )

    hh.cp = sample(all_cp, n_cp_hh)
    for cp_id in hh.cp
        hh.unsat_dem[cp_id] = 0.0
    end
end


"""
Sets consumption budget based on current wealth level
"""
function set_consumption_budget_hh!(
    hh::Household,
    UB::Float64,
    globalparam::GlobalParam,
    ERt::Float64,
    P_getunemployed::Float64,
    P_getemployed::Float64,
    # scale_W̃::Function,
    W̃min::Float64,
    W̃max::Float64,
    W̃med::Float64,
    # Wmedian::Float64,
    model::ABM
    )

    # Update expected income levels
    update_expected_incomes_hh!(hh, globalparam.ω, UB, P_getunemployed, P_getemployed)

    # Compute consumption budget
    compute_consumption_budget_hh!(hh, globalparam, W̃min, W̃max, W̃med, ERt)

    # Reset actual spending to zero
    hh.C_actual = 0.0
end


"""
Updates expected labor income and social benefits income
"""
function update_expected_incomes_hh!(
    hh::Household,
    ω::Float64,
    UB::Float64,
    P_getunemployed::Float64,
    P_getemployed::Float64
)

    # Update expected labor income
    hh.EYL_t = ω * hh.EYL_t + (1 - ω) * hh.labor_I

    # Update expected social benefits income
    hh.EYS_t = ω * hh.EYS_t + (1 - ω) * hh.socben_I

    # Update total expected income from labor and social benefits
    if hh.employed
        hh.EY_t = P_getunemployed * UB + (1 - P_getunemployed) * hh.EYL_t + hh.EYS_t        # Is set to 0, legacy code because there is smart allocation?
    else
        hh.EY_t = P_getemployed * hh.EYL_t + (1 - P_getemployed) * UB + hh.EYS_t
    end
end


function utility(
    C::Float64,
    ρ::Float64
    )   

    return (C ^ (1 - ρ)) / (1 - ρ)
end


"""
Computes average price level of available bp and lp
"""
function update_average_price_hh!(
    hh::Household,
    ω::Float64,
    model::ABM
    )

    hh.P̄ = mean(cp_id -> model[cp_id].p[end], hh.cp)
    hh.P̄ᵉ = ω * hh.P̄ᵉ + (1 - ω) * hh.P̄
    hh.W̃ = hh.W / hh.P̄
end


"""
Computes consumption budget, updates savings rate
"""
function compute_consumption_budget_hh!(
    hh::Household,
    # scale_W̃::Function,
    globalparam::GlobalParam,
    W̃min::Float64,
    W̃max::Float64,
    W̃med::Float64,
    ERt::Float64
    # W_scaled_min::Float64 = 0.,
    # W_scaled_max::Float64 = 100.
    )


    # if W̃max - W̃min < 1.
    #     W̃max = W̃min + 1.
    # end

    if hh.W > 0
        # Scale W between 0 and 100
        if hh.W̃ == W̃min
            hh.C = hh.W
        else
            # W_scaled = W_scaled_min + (W_scaled_max - W_scaled_min) * (hh.W̃ - W̃min) / (W̃max - W̃min)

            # Compute optimal propensity to consume
            compute_α!(hh, globalparam, ERt, W̃min, W̃med)

            # Set consumption budget
            hh.C = hh.α * hh.W
        end

        # Compute savings rate
        hh.s = hh.total_I > 0 ? ((hh.total_I + hh.capital_I + hh.socben_I) - hh.C) / (hh.total_I + hh.capital_I + hh.socben_I) : 0.0 
    else
        hh.C = 0.0
        hh.s = 0.0
    end
end


# scale_W̃(W̃, W̃min, W̃max) = 100 * (W̃ - W̃min) / (W̃max - W̃min)

function scale_W̃(
    W̃::Float64,
    W̃min::Float64,
    W̃med::Float64;
    Ŵmin::Float64=10.,
    Ŵmed::Float64=50.
)

    return Ŵmin + (W̃ - W̃min) * (Ŵmed - Ŵmin) / (W̃med - W̃min)
end


function compute_α!(
    hh::Household,
    globalparam::GlobalParam,
    ERt::Float64,
    W̃min::Float64,
    W̃med::Float64;
    T::Int64=6
)

    αrange = (LinRange(-globalparam.α_maxdev, globalparam.α_maxdev, 5)) .+ hh.α
    hh.α = argmax(αstar -> αstar <= 1. && αstar >= 0. ? computeU(hh, αstar, globalparam.ρ, W̃min, W̃med, ERt, T) : -1., αrange)
end


function computeU(
    hh::Household,
    α::Float64,
    ρ::Float64,
    W̃min::Float64,
    W̃med::Float64,
    ERt::Float64,
    T::Int64
)

    U = 0.

    # Compute the expected real income
    EỸ_t = hh.EY_t / hh.P̄ᵉ

    for k in 0:T
        # Discount expected income and wealth level at time t
        EỸ_disc = sum(m -> ((1 + ERt) * (1 - α)) ^ (k - m) * EỸ_t, 0:k)
        W̃_disc = ((1 + ERt) * (1 - α)) ^ k * hh.W̃
        
        # Compute the expected wealth level at time t+k
        EW̃_t = W̃_disc + EỸ_disc

        # Compute scaled consumption amount, given EW̃_t and α
        C_scaled = max(α * scale_W̃(EW̃_t, W̃min, W̃med), 0)

        # Compute utility based on scaled 
        U += hh.β ^ k * utility(C_scaled, ρ)
    end

    return U
end


"""
Household receives ordered cg and mutates balance
"""
function receive_ordered_goods_hh!(
    hh::Household,
    tot_sales::Float64,
    unsat_demand::Vector{Float64},
    hh_D::Vector{Float64},
    all_cp::Vector{Int64},
    n_hh::Int64
    )

    # Decrease wealth with total sold goods
    hh.W -= tot_sales
    hh.C_actual += tot_sales

    for cp_id in hh.cp
        i = cp_id - n_hh
        hh.unsat_dem[cp_id] = hh_D[i] > 0 ? unsat_demand[i] / hh_D[i] : 0.0
    end
end


"""
Updates satisfying wage wˢ and requested wage wʳ
"""
function update_sat_req_wage_hh!(
    hh::Household, 
    ϵ_w::Float64,
    # ω::Float64, 
    w_min::Float64
    )

    # Update wˢ using adaptive rule
    # hh.wˢ = ω * hh.wˢ + (1 - ω) * (hh.employed ? hh.w[end] : w_min)
    if hh.employed
        hh.wˢ = max(w_min, hh.w[end])
    else
        # hh.wˢ = max(w_min, hh.wˢ * (1 - ϵ))
        hh.wˢ = max(w_min, hh.w[end] * (1 - ϵ_w * hh.T_unemp))
    end

    if hh.employed
        hh.wʳ = max(w_min, hh.w[end] * (1 + ϵ_w))
    else
        hh.wʳ = max(w_min, hh.wˢ)
    end
end


"""
Lets households get income, either from UB or wage
"""
function receiveincome_hh!(
    hh::Household, 
    amount::Float64;
    capgains::Bool=false,
    isUB::Bool=false,
    socben::Bool=false
    )

    # Add income to total income amount
    hh.total_I += amount
    hh.W += amount

    if capgains
        # Capital gains are added directly to the wealth, as they are added
        # at the end of the period
        hh.capital_I = amount

    elseif isUB
        hh.UB_I = amount
        hh.labor_I = 0.0
        hh.T_unemp += 1
    elseif socben
        # Transfer income can come from unemployment or other social benefits
        hh.socben_I = amount
    else
        # If employed, add to labor income, else add to transfer income
        hh.labor_I = amount
        hh.UB_I = 0.0
        shift_and_append!(hh.w, hh.w[end])
    end
end


"""
Sets household to be unemployed.
"""
function set_unemployed_hh!(
    hh::Household
    )

    hh.employed = false
    hh.employer_id = 0
end


"""
Lets employee be hired when previously unemployed, saves employer id and new earned wage.
"""
function set_employed_hh!(
    hh::Household, 
    wᴼ::Float64,
    employer_id::Int64,
    )

    hh.employed = true
    hh.employer_id = employer_id
    hh.T_unemp = 0
    shift_and_append!(hh.w, wᴼ)
end


"""
Changes employer for households that were already employed.
"""
function change_employer_hh!(
    hh::Household,
    wᴼ::Float64,
    employer_id::Int64
    )

    hh.employer_id = employer_id
    shift_and_append!(hh.w, wᴼ)
end


"""
Removes bankrupt producers from set of producers.
"""
function remove_bankrupt_producers_hh!(
    hh::Household,
    bankrupt_cp::Vector{Int64}
    )

    filter!(cp_id -> cp_id ∉ bankrupt_cp, hh.cp)
    delete!(hh.unsat_dem, bankrupt_cp)
end


"""
Decides whether to switch to other cp
"""
function decide_switching_all_hh!(
    globalparam::GlobalParam,
    all_hh::Vector{Int64},
    all_cp::Vector{Int64},
    all_p::Vector{Int64},
    n_cp_hh::Int64,
    model::ABM,
    to
    )

    # Getting values for futue calculations
    # Normalized prices
    all_p = map(cp_id -> model[cp_id].p[end], minimum(all_cp):maximum(all_cp))
    norm_p = all_p ./ maximum(all_p)  
    
    # Normalized Emissions
    emiss_per_good = map(cp_id -> model[cp_id].emissions_per_item[end], minimum(all_cp):maximum(all_cp))    # Last Emissions
    if maximum(emiss_per_good) > 1e-8      # There is a case when we have a green economy and no emissions are present
        norm_emiss_per_good = emiss_per_good ./ maximum(emiss_per_good)
    else
        norm_emiss_per_good = fill(0.0, length(emiss_per_good))
    end


    for hh_id in all_hh

        # Replace producers that did not provide goods to the HH

        # Check if demand was constrained and for chance of changing cp
        if length(model[hh_id].unsat_dem) > 0 && rand() < globalparam.ψ_Q

            # Pick a supplier to change

            # First set up weights inversely proportional to supplied share of goods
            create_weights(hh::Household, cp_id::Int64)::Float64 = hh.unsat_dem[cp_id] > 0 ? 1 / hh.unsat_dem[cp_id] : 0.0
            weights = map(cp_id -> create_weights(model[hh_id], cp_id), model[hh_id].cp)

            # Sample producer to replace
            p_id_replaced = sample(model[hh_id].cp, Weights(weights))[1]
            filter!(p_id -> p_id ≠ p_id_replaced, model[hh_id].cp)

            # Add new cp if list not already too long
            if (length(model[hh_id].cp) < n_cp_hh && length(model[hh_id].cp) < length(all_cp))
                
                # p_id_new = sample(setdiff(all_cp, model[hh_id].cp))
                p_id_new = sample(all_cp)

                count = 0
                while p_id_new ∈ model[hh_id].cp
                    p_id_new = sample(all_cp)

                    # Ugly way to avoid inf loop, will change later
                    count += 1
                    if count == 500
                        break
                    end
                end

                if p_id_new ∉ model[hh_id].cp
                    push!(model[hh_id].cp, p_id_new)
                    delete!(model[hh_id].unsat_dem, p_id_replaced)
                    model[hh_id].unsat_dem[p_id_new] = 0.0
                end
            end
        end

        # Check if household will look for a better deal
        if rand() < globalparam.ψ_P
            if length(model[hh_id].cp) < length(all_cp)

                # Randomly select a supplier that may be replaced
                p_id_candidate1 = sample(model[hh_id].cp)

                # Randomly pick another candidate for compare
                p_id_candidate2 = sample(all_cp)

                count = 0
                while p_id_candidate2 ∈ model[hh_id].cp
                    p_id_candidate2 = sample(all_cp)

                    # Ugly way to avoid inf loop, will change later
                    count += 1
                    if count == 500
                        break
                    end
                end
                
                # Calculate Scores of CPs
                # CP 1:
                cp_id_model = p_id_candidate1 - length(all_hh)
                price_part = norm_p[cp_id_model] * (1 - model[hh_id].Sust_Score)             # Normalized Price is used
                emiss_part = norm_emiss_per_good[cp_id_model] * model[hh_id].Sust_Score      # Normalized emissions produced per good is used
                score_cand_1 = price_part + emiss_part
                # CP 2:
                cp_id_model = p_id_candidate2 - length(all_hh)
                price_part = norm_p[cp_id_model] * (1 - model[hh_id].Sust_Score)             # Normalized Price is used
                emiss_part = norm_emiss_per_good[cp_id_model] * model[hh_id].Sust_Score      # Normalized emissions produced per good is used
                score_cand_2 = price_part + emiss_part

                # Replace old supplier if score of new supplier is lower (i.e. price and emissions are lower)
                if score_cand_2 < score_cand_1
                    # model[hh_id].cp[findfirst(x->x==p_id_candidate1, model[hh_id].cp)] = p_id_candidate2
                    filter!(p_id -> p_id ≠ p_id_candidate1, model[hh_id].cp)
                    push!(model[hh_id].cp, p_id_candidate2)

                    delete!(model[hh_id].unsat_dem, p_id_candidate1)
                    model[hh_id].unsat_dem[p_id_candidate2] = 0.0
                end
            else
                # If all producers known, throw out producer with highest price and emission
                max_score = -1      # it is max
                max_id = -1
                for cp_id in model[hh_id].cp
                    price_part = norm_p[cp_id - length(all_hh)] * (1 - model[hh_id].Sust_Score)             # Normalized Price is used
                    emiss_part = norm_emiss_per_good[cp_id - length(all_hh)] * model[hh_id].Sust_Score      # Normalized emissions produced per good is used
                    score = price_part + emiss_part
                    if (score > max_score)
                        max_score = score
                        max_id = cp_id
                    end
                end
                
                filter!(p_id -> p_id ≠ max_id, model[hh_id].cp)
                delete!(model[hh_id].unsat_dem, max_id)
            end
        end
    end
end


"""
Refills amount of bp and lp in amount is below minimum. Randomly draws suppliers
    inversely proportional to prices.
"""
function refillsuppliers_hh!(
    hh::Household,
    all_cp::Vector{Int64},
    n_cp_hh::Int64,
    model::ABM
    )

    # Getting values for futue calculations
    # Normalized prices
    all_p = map(cp_id -> model[cp_id].p[end], minimum(all_cp):maximum(all_cp))
    norm_p = all_p ./ maximum(all_p)  
    
    # Normalized Emissions
    emiss_per_good = map(cp_id -> model[cp_id].emissions_per_item[end], minimum(all_cp):maximum(all_cp))    # Last Emissions
    if maximum(emiss_per_good) > 1e-8       # There is a case when we have a green economy and no emissions are present
        norm_emiss_per_good = emiss_per_good ./ maximum(emiss_per_good)
    else
        norm_emiss_per_good = fill(0.0, length(emiss_per_good))
    end


    if length(hh.cp) < n_cp_hh

        # Determine which bp are available
        n_add_cp = n_cp_hh - length(hh.cp)
        poss_cp = filter(p_id -> p_id ∉ hh.cp, all_cp)

        # Determine weights based on Prices and Emissions of CP, sample and add
        weights = map(cp_id -> 
                        1 / 
                        ((norm_p[cp_id - minimum(all_cp) + 1] * (1 - hh.Sust_Score)) +
                        (norm_emiss_per_good[cp_id - minimum(all_cp) + 1] * hh.Sust_Score)),
                        poss_cp)
        add_cp = sample(poss_cp, Weights(weights), n_add_cp)
        hh.cp = vcat(hh.cp, add_cp)

        for cp_id in add_cp
            hh.unsat_dem[cp_id] = 0.0
        end
    end
end


"""
Samples wage levels of households from an empirical distribution.
"""
function sample_skills_hh(
    initparam::InitParam
    )::Vector{Float64}

    skills = []
    while length(skills) < initparam.n_hh
        s = rand(LogNormal(0.0, initparam.σ_hh_I)) * initparam.scale_hh_I
        if s < 2.5e5
            push!(skills, s)
        end
    end

    # Normalize skills
    skills = initparam.n_hh .* skills ./ sum(skills)

    return skills
end


"""
    reset_incomes_hh!(hh::Household)

Resets types incomes of household back to 0.0. Capital income is reset only before
    the new capital gains are sent.
"""
function resetincomes_hh!(
    hh::Household
    )

    # Capital income and social benefits from end of last period are counted in this period
    hh.total_I = hh.capital_I + hh.socben_I
end


"""
Updates hh opinion on sustainability importance
(is used in the consumption decision)
"""
function sust_opinion_exchange_all_hh!(
    globalparam::GlobalParam,
    all_hh::Vector{Int64},
    model::ABM,
    to,
    POLITIC_UPD::Bool = false,
    SCIENTIFIC_UPD::Bool = false,
    USE_WEALTH::Bool = false
    )

    all_hh_shuffled = shuffle(all_hh)
    rate = globalparam.sust_conv_rate

    if USE_WEALTH
        # Get Wealths and Median wealth
        all_W = map(hh_id -> model[hh_id].W̃, all_hh_shuffled)

        W_min = minimum(all_W)
        W_max = maximum(all_W)
        W_norm = ((all_W .- W_min) ./ (W_max - W_min))   # Min-Max
        W_median = median(W_norm)
        
        # To map values under and over the median we have to calculate difference and transform it
        function symm_map(x::Float64, median::Float64; power::Float64=1.0)
            if x >= median
                return ((x - median) / (1 - median))^power
            else
                return -((median - x) / median)^power
            end
        end
        W_all = symm_map.(W_norm, W_median)
        # We use a modified DAF (Sigmoid func) to find the bonus value
        function get_wealth_influence(x::Float64)     
            return -0.3 + 0.4 / (1 + exp(-5 * (x + log(3)/5)))
        end
        W_all = get_wealth_influence.(W_all)
        #replace!(W_all, NaN=>0)
        if (any(isnan, W_all)) println("GOT NAN") end
        if (any(isinf, W_all)) println("GOT INF") end

    end

    # A helper for the visualization of wealth run, no need to keep a whole vector of values
    if model.t == 1
        foreach(hh_id -> (model[hh_id].Sust_Score_Init = model[hh_id].Sust_Score), all_hh_shuffled)
        foreach(hh_id -> (model[hh_id].Sust_Score_Uncertainty_Init = model[hh_id].Sust_Score_Uncertainty), all_hh_shuffled)
    end

    # Updating opinions
    for hh_id in collect(1:2:length(all_hh))

        id_1 = all_hh_shuffled[hh_id]
        id_2 = all_hh_shuffled[hh_id + 1]

        # First we incorporate Wealth into opinion
        if USE_WEALTH
            model[id_1].Sust_Score = model[id_1].Sust_Score_Base + W_all[id_1]
            if (model[id_1].Sust_Score < 0) model[id_1].Sust_Score = 0 end
            if (model[id_1].Sust_Score > 1) model[id_1].Sust_Score = 1 end

            model[id_2].Sust_Score = model[id_2].Sust_Score_Base + W_all[id_2]
            if (model[id_2].Sust_Score < 0) model[id_2].Sust_Score = 0 end
            if (model[id_2].Sust_Score > 1) model[id_2].Sust_Score = 1 end
        else
            model[id_1].Sust_Score = model[id_1].Sust_Score_Base
            model[id_2].Sust_Score = model[id_2].Sust_Score_Base
        end

        # Second we perform the DW model step
        sust_score_old_1 = model[id_1].Sust_Score
        sust_score_old_2 = model[id_2].Sust_Score
        # Update rules as per https://www.jasss.org/19/1/6.html
        if abs(sust_score_old_1 - sust_score_old_2) < model[id_1].Sust_Score_Uncertainty
            model[id_1].Sust_Score_Base = model[id_1].Sust_Score_Base + rate * (sust_score_old_2 - sust_score_old_1)
            if USE_WEALTH
                model[id_1].Sust_Score = model[id_1].Sust_Score_Base + W_all[id_1]
                if model[id_1].Sust_Score < 0 model[id_1].Sust_Score = 0 end
                if model[id_1].Sust_Score > 1 model[id_1].Sust_Score = 1 end
            else
                model[id_1].Sust_Score = model[id_1].Sust_Score_Base
            end
        end
        if abs(sust_score_old_1 - sust_score_old_2) < model[id_2].Sust_Score_Uncertainty
            model[id_2].Sust_Score_Base = model[id_2].Sust_Score_Base + rate * (sust_score_old_1 - sust_score_old_2)
            if USE_WEALTH
                model[id_2].Sust_Score = model[id_2].Sust_Score_Base + W_all[id_2]
                if model[id_2].Sust_Score < 0 model[id_2].Sust_Score = 0 end
                if model[id_2].Sust_Score > 1 model[id_2].Sust_Score = 1 end
            else
                model[id_2].Sust_Score = model[id_2].Sust_Score_Base
            end
        end

        # Finally, we update the uncertainty
        if POLITIC_UPD model[id_1].Sust_Score_Uncertainty = (0.5-abs(0.5-model[id_1].Sust_Score))*2 end
        if SCIENTIFIC_UPD model[id_1].Sust_Score_Uncertainty = (1.0 - model[id_1].Sust_Score) end

        if POLITIC_UPD model[id_2].Sust_Score_Uncertainty = (0.5-abs(0.5-model[id_2].Sust_Score))*2 end
        if SCIENTIFIC_UPD model[id_2].Sust_Score_Uncertainty = (1.0 - model[id_2].Sust_Score) end

    end

end

