using Distributed
n_proc_main = 12
addprocs(n_proc_main)

# Packages
@everywhere begin
    using DataFrames
    using CSV
    using Agents
    using Statistics: mean
    using DataFrames, CairoMakie
    using Random
    using Base.Iterators
    using Distributions
    using Distributed
end

# Parameters and Functions
@everywhere begin

    # INITIAL PARAMETERS
    # Experiment Parameters
    OPINIONS_INIT = [[1.0, 1.0], [2.0, 2.0], [4.0, 4.0], [0.4, 0.4], [0.8, 0.8], [4.0, 2.0], [1.0, 0.8], [2.0, 4.0], [0.8, 1.0]]
    ALL_SEEDS = [9937590, 9494897, 408387, 169105, 6612768, 9827382, 592810, 1826964, 524941, 5111625, 3580871, 7379769,
            2411994, 1250345, 1200648, 8623226, 6739373, 7707222, 9076351, 5616723, 5147647, 8676955, 9216682, 6743063]

    # Global Flags for Opinion Initialization
    SCIENTIFIC_UPD = true       # Experiment 1
    POLITIC_UPD = false         # Experiment 2

    # Base Simulation Parameters (set to be the same as in the model)
    n_hh = 250
    steps = 800
    conv_rate = 0.1


    # FUNCTIONS

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

    # Model Initialization
    function init_opinion_model(n_hh, opinion_conversion_rate, opinion_α, opinion_β)
        properties = Properties(n_hh, opinion_conversion_rate)
        model = ABM(hh, scheduler = Schedulers.fastest, properties = properties)
        for i in 1:n_hh
            o = rand(Beta(opinion_α, opinion_β))
            if POLITIC_UPD agent = hh(nextid(model), o, o, (0.5-abs(0.5-o))*2) end  # Uncertainty is proportionate to how extreme is opinion (Politic)
            if SCIENTIFIC_UPD agent = hh(nextid(model), o, o, (1-o)) end            # Uncertainty is proportionate to how low/"uneducated" is opinion (Scientific)

            add_agent!(agent, model)
        end
        return model
    end

    # PairWise Opinion Update Function
    function pair_discussion(model, id_1, id_2)
        
        # Update rules as per https://www.jasss.org/19/1/6.html
        updated_1 = false
        updated_2 = false
        if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_1].opinion_uncertainty
            model[id_1].new_opinion = model[id_1].old_opinion + model.opinion_conversion_rate * (model[id_2].old_opinion - model[id_1].old_opinion)
            if (model[id_1].new_opinion < 0) model[id_1].new_opinion = 0 end
            if (model[id_1].new_opinion > 1) model[id_1].new_opinion = 1 end
            updated_1 = true
        end
        if abs(model[id_1].old_opinion - model[id_2].old_opinion) < model[id_2].opinion_uncertainty
            model[id_2].new_opinion = model[id_2].old_opinion + model.opinion_conversion_rate * (model[id_1].old_opinion - model[id_2].old_opinion)
            if (model[id_2].new_opinion < 0) model[id_2].new_opinion = 0 end
            if (model[id_2].new_opinion > 1) model[id_2].new_opinion = 1 end
            updated_2 = true
        end
        
        # Updating Uncertainty
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

        # for each pair perform discussion
        for a_id in collect(1:2:n_hh)
            id_1 = ids[a_id]
            id_2 = ids[a_id+1]

            pair_discussion(model, id_1, id_2)
        end

    end

    function model_deffuant_run(n_hh::Int64, steps::Int64, opinion_conversion_rate::Float64, opinion_α::Float64, opinion_β::Float64, seed::Int64)

        Random.seed!(seed)

        model = init_opinion_model(n_hh, opinion_conversion_rate, opinion_α, opinion_β)

        agent_data, _ = run!(model, dummystep, deffuant_model_step!, steps; adata = [:new_opinion, :opinion_uncertainty])

        return agent_data
    end


end


for opinion in OPINIONS_INIT
    all_results = DataFrame()

    α, β = opinion

    # Run seed trials in parallel
    seed_results = @distributed (vcat) for seed in ALL_SEEDS
        println("Running seed $seed on worker $(myid())")
        
        agent_data = model_deffuant_run(n_hh, steps, conv_rate, α, β, seed)

        init_op = collect(agent_data[agent_data.step .== 1, :new_opinion])
        final_op = collect(agent_data[agent_data.step .== 800, :new_opinion])
        init_unc = collect(agent_data[agent_data.step .== 1, :opinion_uncertainty])
        final_unc = collect(agent_data[agent_data.step .== 800, :opinion_uncertainty])
        n = length(init_op)

        DataFrame(
            α = fill(α, n),
            β = fill(β, n),
            seed = fill(seed, n),
            sust_opinion_init = init_op,
            sust_opinion_end = final_op,
            sust_uncert_init = init_unc,
            sust_uncert_end = final_unc
        )
    end

    # Append to the full results
    append!(all_results, seed_results)

    # Save intermediate results
    file_name = ""
    if SCIENTIFIC_UPD file_name = "opinion_results_α=$(α)_β=$(β)_Scientific_.csv" end
    if POLITIC_UPD file_name = "opinion_results_α=$(α)_β=$(β)_Politic_.csv" end

    full_path = joinpath(@__DIR__, "opinion_dynamics", file_name)
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, all_results)

end

