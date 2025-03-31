using Agents
using Statistics: mean
using DataFrames, CairoMakie
CairoMakie.activate!() # hide
using Random # hide
#Random.seed!(42) # hide
using Base.Iterators
using Distributions
using Distributed

# Params Sets:
# Opinion = (.2, .2) Uncertainty = (1.8, 1.8) - Middle opinion with moderate extremes
# Opinion = (.4, .2) Uncertainty = (1.2, 1.6) - Modern Society with slightly Positive Bias and small clustering
# When we have Uncertainty reverse proportionate to the extremes: Opinion = (.8, .8) Similar to earlier cases
# When we have Uncertainty reverse proportionate to the extremes: Opinion = (.2, .2) We get uniform opinions, if we update uncertainty on each step we get extremes only
OPINION_ALPHA = .8
OPINION_BETA = .8
UNCERTAINTY_ALPHA = 1
UNCERTAINRY_BETA = 1
# How do we update uncertainty?
RANDOM_UPD = true
POLITIC_UPD = false
SCIENTIFIC_UPD = false
# Are there any shocks? We give probability of shock on personal level here, if 0 no shock
SHOCKS_O = 0.0
SHOCKS_U = 0.0

# Agent Properties
mutable struct hh <: AbstractAgent
    id::Int
    old_opinion::Float64
    new_opinion::Float64
    opinion_uncertainty::Float64
end

# Model Properties
mutable struct Properties
    n_hh
    opinion_conversion_rate
end

# Should we update uncertainty during the run??? Any point?
function init_opinion_model(n_hh, opinion_conversion_rate)
    properties = Properties(n_hh, opinion_conversion_rate)
    model = ABM(hh, scheduler = Schedulers.fastest, properties = properties)
    for i in 1:n_hh
        o = rand(Beta(OPINION_ALPHA, OPINION_BETA))
        u = rand(Beta(UNCERTAINTY_ALPHA, UNCERTAINRY_BETA))
        if RANDOM_UPD agent = hh(nextid(model), o, o, u) end                    # Uncertainty is random
        if POLITIC_UPD agent = hh(nextid(model), o, o, (0.5-abs(0.5-o))*2) end  # Uncertainty is proportionate to how extreme is opinion (Politic)
        if SCIENTIFIC_UPD agent = hh(nextid(model), o, o, (1-o)) end            # Uncertainty is proportionate to how low/"uneducated" is opinion (Scientific)

        add_agent!(agent, model)
    end
    return model
end

# PairWise Opinion Update Function
function pair_discussion(model, id_1, id_2)
    
    # Positive just goes to the upper limit, Negative just goes to some lower value
    a = -0.5
    b = 0.0
    c = 0.1
    d = 0.1
    
    # Update rules as per https://www.jasss.org/19/1/6.html
    updated_1 = false
    updated_2 = false
    if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_1].opinion_uncertainty
        model[id_1].new_opinion = model[id_1].old_opinion + model.opinion_conversion_rate * (model[id_2].old_opinion - model[id_1].old_opinion)
        #model[id_1].new_opinion += a * (model[id_1].old_opinion ^ 3) + b * (model[id_1].old_opinion ^ 2) + c * (model[id_1].old_opinion) + d
        #model[id_1].opinion_uncertainty += a * (model[id_1].opinion_uncertainty ^ 3) + b * (model[id_1].opinion_uncertainty ^ 2) + c * (model[id_1].opinion_uncertainty) + d
        if (model[id_1].new_opinion < 0) model[id_1].new_opinion = 0 end
        if (model[id_1].new_opinion > 1) model[id_1].new_opinion = 1 end
        updated_1 = true
    end
    if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_2].opinion_uncertainty
        model[id_2].new_opinion = model[id_2].old_opinion + model.opinion_conversion_rate * (model[id_1].old_opinion - model[id_2].old_opinion)
        #model[id_2].new_opinion += a * (model[id_2].old_opinion ^ 3) + b * (model[id_2].old_opinion ^ 2) + c * (model[id_2].old_opinion) + d
        #model[id_2].opinion_uncertainty += a * (model[id_2].opinion_uncertainty ^ 3) + b * (model[id_2].opinion_uncertainty ^ 2) + c * (model[id_2].opinion_uncertainty) + d
        if (model[id_2].new_opinion < 0) model[id_2].new_opinion = 0 end
        if (model[id_2].new_opinion > 1) model[id_2].new_opinion = 1 end
        updated_2 = true
    end
    
    if (updated_1)
        if POLITIC_UPD model[id_1].opinion_uncertainty = (0.5-abs(0.5-model[id_1].new_opinion))*2 end
        if SCIENTIFIC_UPD model[id_1].opinion_uncertainty = (1.0 - model[id_1].new_opinion) end
        model[id_1].old_opinion = model[id_1].new_opinion
    end 
    if (updated_2)
        if POLITIC_UPD model[id_2].opinion_uncertainty = (0.5-abs(0.5-model[id_2].new_opinion))*2 end
        if SCIENTIFIC_UPD model[id_2].opinion_uncertainty = (1.0 - model[id_2].new_opinion) end
        model[id_2].old_opinion = model[id_2].new_opinion
    end
end


function deffuant_model_step!(model)
    ids = shuffle(1:model.n_hh)

    # We use a modified DAF (Sigmoid func) to find the bonus value
    function get_wealth_influence(id_1)
        # norm Agent's Wealth - median
        w = 1
        return (0.4 / (1 + exp(-1-5*w)) - 0.3)
    end

    # Normalize Wealth of agents and get median here for all calculations
    for a_id in collect(1:2:n_hh)
        id_1 = ids[a_id]
        id_2 = ids[a_id+1]

        # Shock the individual opinion (personal shock, probability per each person)
        if (SHOCKS_O > 0.0)
            if (rand() < SHOCKS_O)
                model[id_1].old_opinion += 0.2
                model[id_2].new_opinion += 0.2
                if (model[id_1].old_opinion > 1) model[id_1].old_opinion = 1 end
                if (model[id_1].new_opinion > 1) model[id_1].new_opinion = 1 end
            end
            if (rand() < SHOCKS_O)
                model[id_2].old_opinion += 0.2
                model[id_2].new_opinion += 0.2
                if (model[id_2].old_opinion > 1) model[id_2].old_opinion = 1 end
                if (model[id_2].new_opinion > 1) model[id_2].new_opinion = 1 end
            end
        end

        # Shock the individual uncertainty (personal shock, probability per each person)
        if (SHOCKS_U > 0.0)
            if (rand() < SHOCKS_U)
                model[id_1].opinion_uncertainty += 0.2
                if (model[id_1].opinion_uncertainty > 1) model[id_1].opinion_uncertainty = 1 end
            end
            if (rand() < SHOCKS_U)
                model[id_2].opinion_uncertainty += 0.2
                if (model[id_2].opinion_uncertainty > 1) model[id_2].opinion_uncertainty = 1 end
            end
        end

        # calculate the wealth bonus for each id and pass it into old func
        pair_discussion(model, id_1, id_2)
    end


    # # CHANGE SHOCK HERE
    # stoch_shock_threshold = 0.001
    # for a in allagents(model)
    #     if rand(model.rng) < stoch_shock_threshold
    #         a.opinion_uncertainty = rand(Beta(UNCERTAINTY_ALPHA, UNCERTAINRY_BETA))
    #     end
    # end

end

function model_deffuant_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64)
    model = init_opinion_model(n_hh, opinion_conversion_rate)

    agent_data, _ = run!(model, dummystep, deffuant_model_step!, steps; adata = [:new_opinion, :opinion_uncertainty])

    return agent_data
end


# # HK Opinion Function which aggregates all opinions around the Agent
# function boundfilter(agent, model)
#     filter(
#         j -> abs(agent.old_opinion - j) < agent.opinion_uncertainty,
#         [a.old_opinion for a in allagents(model)],
#     )
# end

# function hk_agent_step!(agent, model)
#     agent.new_opinion = mean(boundfilter(agent, model))
# end

# function hk_model_step!(model)
#     for a in allagents(model)
#         a.old_opinion = a.new_opinion
#     end
# end

# function model_hk_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64, opinion_uncertainty::Float64)
#     model = init_opinion_model(n_hh, opinion_conversion_rate, opinion_uncertainty)

#     # HK Model
#     agent_data, _ = run!(model, hk_agent_step!, hk_model_step!, steps; adata = [:new_opinion])
#     return agent_data
# end




### Main ###

const cmap = cgrad(:lightrainbow)
plotsim_o(ax, data) =
    for grp in groupby(data, :id)
        lines!(ax, grp.step, grp.new_opinion, color = cmap[grp.id[1]/100])
        ylims!(ax, 0, 1)  # Set y-axis range from 0 to 1
    end
plotsim_u(ax, data) =
    for grp in groupby(data, :id)
        lines!(ax, grp.step, grp.opinion_uncertainty, color = cmap[grp.id[1]/100])
        ylims!(ax, 0, 1)  # Set y-axis range from 0 to 1
    end
# Params
n_hh = 250
steps = 800
conv_rate = 0.1
figure = Figure(resolution = (800, 500))
    
e_data = model_deffuant_run(n_hh, steps, conv_rate)
ax = figure[1, 1] = Axis(figure; title = "Opinion α = $OPINION_ALPHA, β = $OPINION_BETA")
plotsim_o(ax, e_data)
title = "Uncertainty α = $UNCERTAINTY_ALPHA, β = $UNCERTAINRY_BETA"
if SCIENTIFIC_UPD title = "Uncertainty 'Scientific'" end
if POLITIC_UPD title = "Uncertainty 'Politic'" end
ax = figure[1, 2] = Axis(figure; title = title)
plotsim_u(ax, e_data)

figure


