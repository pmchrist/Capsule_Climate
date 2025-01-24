using PyCall
using Distributed
using Random

#num_sim_ci = 20
#all_seeds = rand(1:1_000_000, num_sim_ci)
#all_seeds = [0, 17233, 378620, 692243, 938730]
all_seeds = [47816, 933015, 321434, 447288, 153725, 260147, 589087, 108127, 159454, 176074, 426699, 46634, 822959, 514704, 9694, 673314, 257546, 798460, 413516, 550286]

n_proc_main = 12
addprocs(n_proc_main)


# Experiment alpha vs beta for opinion (how initial opinion influences the model)
# We first distribute all the variables
@everywhere begin
    include("model/main.jl")
    seeds = $all_seeds

    # here we declare parameters for change
    alphas = [2, 24]
    betas = [2, 24]
    prices_fossils = [0.2, 0.4, 0.6]
    combined_params = [(a, b, pf) for a in alphas, b in betas, pf in prices_fossils]     # Getting all the possible permutations
end

sims_n = length(combined_params)       # We parallelyze for each set of unique parameters
@distributed for idx=1:sims_n
    (a, b, pf) = combined_params[idx]      # Unpacking values
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
            changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf)],
            folder_name = "alpha=$a beta=$b p_f=$pf id=$sim_id"
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