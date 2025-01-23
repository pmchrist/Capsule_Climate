using PyCall
using Distributed
using Random

#num_sim_ci = 20
#all_seeds = rand(1:1_000_000, num_sim_ci)
all_seeds = [0, 17233, 378620, 692243, 938730]
n_proc_main = 12
addprocs(n_proc_main)


# Experiment alpha vs beta for opinion (how initial opinion influences the model)
# We first distribute all the variables
@everywhere begin
    include("model/main.jl")
    seeds = $all_seeds

    alphas = [2, 8, 24]
    betas = [2, 8, 24]
    sust_opinion_a_b = [(a, b) for a in alphas, b in betas]     # Getting all the possible permutations
end

sims_n = length(sust_opinion_a_b)       # We parallelyze for each set of unique parameters
@distributed for idx=1:sims_n
    (a, b) = sust_opinion_a_b[idx]      # Unpacking values
    sim_id = idx
    for s in seeds                      # For each target seed run the model
        run_simulation(
            T = 660,
            savedata = true,
            show_full_output = false,
            showprogress = false,
            seed = s,
            save_firmdata = true,
            sim_nr = sim_id,
            changed_params_init = [(:sust_α, a), (:sust_β, b)],
            folder_name = "alpha=$a beta=$b id=$sim_id"
        )
    end
end

println("Seeds: ", all_seeds)

# run_simulation(
#     T = 660,
#     savedata = true,
#     show_full_output = true,
#     showprogress = true,
#     seed = seed,
#     save_firmdata = true,
#     changed_params_init = [(:sust_α, 8), (:sust_β, 2)],
#     folder_name = "data5"
# )

# run_simulation(
#     T = 660;
#     savedata = true,
#     show_full_output = true,
#     showprogress = true,
#     seed = seed,
#     changed_taxrates = [(:τᶜ, 0.8)]
# )

# run_simulation(
#     T = 660;
#     savedata = true,
#     show_full_output = true,
#     showprogress = true,
#     seed = seed,
#     changed_params=Dict([(:p_f, 0.8)]),
# )

nothing

# @pyinclude("plotting/plot_macro_vars.py")