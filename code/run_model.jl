using PyCall
using Distributed

seed = 100
n_proc = 12
addprocs(n_proc)

@everywhere begin
    include("model/main.jl")
    seed = 100
    n_proc = 12

    alphas = [2, 8, 24]
    betas = [2, 8, 24]
    pairs = [(a, b) for a in alphas, b in betas]
end

sims_n = length(pairs)
@distributed for idx=1:sims_n
    (a, b) = pairs[idx]
    sim_id = idx
    run_simulation(
        T = 900,
        t_warmup = 300,
        savedata = true,
        show_full_output = false,
        showprogress = false,
        seed = seed,
        save_firmdata = true,
        sim_nr = sim_id,
        changed_params_init = [(:sust_α, a), (:sust_β, b)],
        folder_name = "seed $seed alpha=$a beta=$b id=$sim_id"
    )
end

# run_simulation(
#     T = 900,
#     t_warmup = 300,
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