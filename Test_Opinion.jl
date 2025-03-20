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
OPINION_ALPHA = .2
OPINION_BETA = .2
UNCERTAINTY_ALPHA = 1.2
UNCERTAINRY_BETA = 1.2

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
function init_opinion_model(n_hh = 2500, opinion_conversion_rate = 0.1, opinion_uncertainty = 0.5)
    properties = Properties(n_hh, opinion_conversion_rate)
    model = ABM(hh, scheduler = Schedulers.fastest, properties = properties)
    for i in 1:n_hh
        o1 = o2 = rand(Beta(OPINION_ALPHA, OPINION_BETA))
        u = rand(Beta(UNCERTAINTY_ALPHA, UNCERTAINRY_BETA))
        agent = hh(nextid(model), o1, o2, (0.5-abs(0.5-o1))*2)  # Uncertainty is proportionate to how extreme is opinion
        #agent = hh(nextid(model), o1, o2, u)                   # Uncertainty is random
        add_agent!(agent, model)
    end
    return model
end

# PairWise Opinion Update Function
function pair_discussion(model, id_1, id_2)
    
    # Positive just goes to the upper limit, Negative just goes to some lower value
    a = 0.02        
    b = -0.01
    c = 0.0
    d = 0.0
    
    # Update rules as per https://www.jasss.org/19/1/6.html
    updated_1 = false
    updated_2 = false
    if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_1].opinion_uncertainty
        model[id_1].new_opinion = model[id_1].old_opinion + model.opinion_conversion_rate * (model[id_2].old_opinion - model[id_1].old_opinion)
        #model[id_1].new_opinion += a * (model[id_1].old_opinion ^ 3) + b * (model[id_1].old_opinion ^ 2) + c * (model[id_1].old_opinion) + d
        if (model[id_1].new_opinion < 0) model[id_1].new_opinion = 0 end
        if (model[id_1].new_opinion > 1) model[id_1].new_opinion = 1 end
        updated_1 = true
    end
    if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_2].opinion_uncertainty
        model[id_2].new_opinion = model[id_2].old_opinion + model.opinion_conversion_rate * (model[id_1].old_opinion - model[id_2].old_opinion)
        #model[id_2].new_opinion += a * (model[id_2].old_opinion ^ 3) + b * (model[id_2].old_opinion ^ 2) + c * (model[id_2].old_opinion) + d
        if (model[id_2].new_opinion < 0) model[id_2].new_opinion = 0 end
        if (model[id_2].new_opinion > 1) model[id_2].new_opinion = 1 end
        updated_2 = true
    end
    if (updated_1)
        #model[id_1].opinion_uncertainty = (0.5-abs(0.5- model[id_1].new_opinion))*2
        model[id_1].old_opinion = model[id_1].new_opinion
    end 
    if (updated_2)
        #model[id_2].opinion_uncertainty = (0.5-abs(0.5- model[id_2].new_opinion))*2
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

        # # Shock the individual opinion (personal shock, 1% of 1% probability per each person)
        # if (rand() < 1e-4)
        #     model[id_1].old_opinion += 0.2
        #     model[id_2].new_opinion += 0.2
        #     if (model[id_1].old_opinion > 1) model[id_1].old_opinion = 1 end
        #     if (model[id_1].new_opinion > 1) model[id_1].new_opinion = 1 end
        # end
        # if (rand() < 1e-4)
        #     model[id_2].old_opinion += 0.2
        #     model[id_2].new_opinion += 0.2
        #     if (model[id_2].old_opinion > 1) model[id_2].old_opinion = 1 end
        #     if (model[id_2].new_opinion > 1) model[id_2].new_opinion = 1 end
        # end

        # # Shock the individual uncertainty (personal shock, 1% probability per each person)
        # if (rand() < 1e-4)
        #     model[id_1].opinion_uncertainty += 0.2
        #     if (model[id_1].opinion_uncertainty > 1) model[id_1].opinion_uncertainty = 1 end
        # end
        # if (rand() < 1e-4)
        #     model[id_2].opinion_uncertainty += 0.2
        #     if (model[id_2].opinion_uncertainty > 1) model[id_2].opinion_uncertainty = 1 end
        # end


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

function model_deffuant_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64, opinion_uncertainty::Float64)
    model = init_opinion_model(n_hh, opinion_conversion_rate, opinion_uncertainty)

    agent_data, _ = run!(model, dummystep, deffuant_model_step!, steps; adata = [:new_opinion])

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
plotsim(ax, data) =
    for grp in groupby(data, :id)
        lines!(ax, grp.step, grp.new_opinion, color = cmap[grp.id[1]/100])
    end
# Params
n_hh = 250
steps = 500
conv_rates = [0.1]
figure = Figure(resolution = (600, 400))
for (i, conv_rate) in enumerate(conv_rates)
    ax = figure[i, 1] = Axis(figure; title = "Convergence Rate = $conv_rate")
    #e_data = model_hk_run(n_hh, steps, 1.0, ϵ)
    e_data = model_deffuant_run(n_hh, steps, conv_rate, -1.0)
    plotsim(ax, e_data)
end

figure