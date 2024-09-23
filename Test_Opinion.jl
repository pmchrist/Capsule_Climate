using Agents
using Statistics: mean
using DataFrames, CairoMakie
CairoMakie.activate!() # hide
using Random # hide
Random.seed!(42) # hide
using Base.Iterators


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

function init_opinion_model(n_hh = 100, opinion_conversion_rate = 0.5, opinion_uncertainty = 0.5)
    properties = Properties(n_hh, opinion_conversion_rate)
    model = ABM(hh, scheduler = Schedulers.fastest, properties = properties)
    for i in 1:n_hh
        o = rand(model.rng)
        u = rand(model.rng)
        agent = hh(nextid(model), o, o, u)
        add_agent!(agent, model)
    end
    return model
end

# HK Opinion Function which aggregates all opinions around the Agent
function boundfilter(agent, model)
    filter(
        j -> abs(agent.old_opinion - j) < agent.opinion_uncertainty,
        [a.old_opinion for a in allagents(model)],
    )
end

# PairWise Opinion Update Function
function pair_discussion(model, id_1, id_2)

    # Update rules as per https://www.jasss.org/19/1/6.html
    if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_1].opinion_uncertainty
        model[id_1].new_opinion = model[id_1].old_opinion + model.opinion_conversion_rate * (model[id_2].old_opinion - model[id_1].old_opinion)
    elseif abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_2].opinion_uncertainty
        model[id_2].new_opinion = model[id_2].old_opinion + model.opinion_conversion_rate * (model[id_1].old_opinion - model[id_2].old_opinion)
    end
    model[id_1].old_opinion = model[id_1].new_opinion
    model[id_2].old_opinion = model[id_2].new_opinion
end

function hk_agent_step!(agent, model)
    agent.new_opinion = mean(boundfilter(agent, model))
end

function hk_model_step!(model)
    for a in allagents(model)
        a.old_opinion = a.new_opinion
    end
end

function deffuant_model_step!(model)
    ids = shuffle(1:model.n_hh)

    for a_id in collect(1:2:n_hh)
        pair_discussion(model, ids[a_id], ids[a_id+1])
    end

    # CHANGE SHOCK HERE
    stoch_shock_threshold = 0.001
    for a in allagents(model)
        if rand(model.rng) < stoch_shock_threshold
            a.opinion_uncertainty = rand(model.rng)
        end
    end

end


function model_hk_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64, opinion_uncertainty::Float64)
    model = init_opinion_model(n_hh, opinion_conversion_rate, opinion_uncertainty)

    # HK Model
    agent_data, _ = run!(model, hk_agent_step!, hk_model_step!, steps; adata = [:new_opinion])
    return agent_data
end

function model_deffuant_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64, opinion_uncertainty::Float64)
    model = init_opinion_model(n_hh, opinion_conversion_rate, opinion_uncertainty)

    agent_data, _ = run!(model, dummystep, deffuant_model_step!, steps; adata = [:new_opinion])

    return agent_data
end

const cmap = cgrad(:lightrainbow)
plotsim(ax, data) =
    for grp in groupby(data, :id)
        lines!(ax, grp.step, grp.new_opinion, color = cmap[grp.id[1]/100])
    end
# Params
n_hh = 100
steps = 500
eps = [0.5000001, 0.5, 0.500000001]
figure = Figure(resolution = (600, 600))
for (i, ϵ) in enumerate(eps)
    ax = figure[i, 1] = Axis(figure; title = "epsilon = $ϵ")
    #e_data = model_hk_run(n_hh, steps, 1.0, ϵ)
    e_data = model_deffuant_run(n_hh, steps, 0.5, ϵ)
    plotsim(ax, e_data)
end

figure