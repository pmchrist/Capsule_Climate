using PyCall

include("model/main.jl")

seed = 100

run_simulation(
    T = 600,
    t_warmup = 200,
    savedata = true,
    show_full_output = true,
    showprogress = true,
    seed = seed,
    save_firmdata = true
)

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