# using PyCall
# using Distributed
# using Random

# # start 12:00
# # num_sim_ci = 40
# # all_seeds = rand(1:10_000_000, num_sim_ci)
# # 5
# #all_seeds = [0, 17233, 378620, 692243, 938730]
# # 20
# #all_seeds = [47816, 933015, 321434, 447288, 153725, 260147, 589087, 108127, 159454, 176074, 426699, 46634, 822959, 514704, 9694, 673314, 257546, 798460, 413516, 550286]
# # 40
# # all_seeds = [3795691, 8892033, 1971425, 3931157, 827046, 9992945, 5687290, 1860807, 6021775, 9389419, 6066572, 6539943, 4743745, 2829598, 1122821, 9426103, 2977018, 5085914, 8146567, 9272398, 6902239, 5925693, 543349, 5367789, 760014, 9990084, 8801319, 3074965, 5797563, 6082730, 1619877, 8455470, 4882535, 6944750, 9570866, 5842559, 3535503, 6946695, 9330803, 6077337]
# all_seeds = [7107009, 8968977, 5151600, 2436546, 4269460, 9251552, 4492958, 6003441, 6033899, 4562678, 7698139, 1975977, 3042982, 5269969, 719027, 2813374, 3262187, 5391091, 7641139, 1712837, 5129247, 5540958, 7546105, 605019, 8978662, 6912409, 4380751, 8423068, 9589324, 5062262, 5798093, 5996428, 1607674, 6142494, 7694139, 8921840, 9489030, 4648567, 1171573, 2769073]
# # all_seeds = [755935, 1922002, 3158786, 6942586, 9638672, 4134175, 682940, 6661052, 7434192, 7952020, 6530007, 3046475, 2210667, 4411723, 7340637, 3968215, 547382, 7098501, 8789669, 8603384, 5492385, 5290892, 2005499, 8598335, 339691, 4477453, 192742, 4450332, 1131886, 1037284, 6669985, 293304, 562074, 5551515, 3836335, 4121380, 2186567, 6660311, 2621417, 9729012]
# n_proc_main = 40
# addprocs(n_proc_main)


# # Experiment alpha vs beta for opinion (how initial opinion influences the model)
# # We first distribute all the variables
# @everywhere begin
#     using PyCall
#     using Distributed
#     using Random

#     include("model/main.jl")

#     # here we declare parameters for change
#     alphas = [2, 18]
#     betas = [2, 18]
#     prices_fossils = [0.3, 0.35, 0.375, 0.4, 0.425, 0.45, 0.5]
#     combined_params = [(a, b, pf) for a in alphas, b in betas, pf in prices_fossils]     # Getting all the possible permutations
#     sims_n = length(combined_params)       # We parallelyze for each set of unique parameters
# end

# @distributed for s in all_seeds 
#     for idx=1:sims_n                      # For each target seed run the model
#         (a, b, pf) = combined_params[idx]      # Unpacking values
#         sim_id = idx
#         run_simulation(
#             T = 1000,
#             savedata = true,
#             show_full_output = false,
#             showprogress = false,
#             seed = s,
#             save_firmdata = true,
#             sim_nr = sim_id,
#             changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf)],
#             folder_name = "alpha=$a beta=$b p_f=$pf id=$sim_id"
#         )
#     end
# end

# println("Seeds: ", all_seeds)




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




using Distributed
using Random

# Launch workers
n_proc_main = 12
addprocs(n_proc_main)

# Make sure all needed packages and code are loaded on every worker
@everywhere begin
    changed_taxrates = nothing
    
    # Include or define your simulation code
    include("model/main.jl")

    # Declare any necessary parameters or global arrays
    alphas = [1]
    betas  = [1]
    prices_fossils = [0.36, 0.39, 0.40, 0.41, 0.44]

    # If we want to use no opinion too, we just add combination zero values at the end
    combined_params = vcat(
        [ (a, b, pf) for a in alphas for b in betas for pf in prices_fossils ],
    )
    const sims_n = length(combined_params)
    
    # Define a function that runs the simulation(s) for one seed
    function run_sim_for_seed(s::Int)
        for idx in 1:sims_n
            (a, b, pf) = combined_params[idx]

            # Call simulation if no taxrate changes
            run_simulation(
                T = 900,
                savedata = true,
                show_full_output = false,
                showprogress = false,
                seed = s,
                save_firmdata = false,
                sim_nr = idx,
                changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf)],
                #changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf), (:sust_upd_rule_use_wealth, true)],
                changed_taxrates = changed_taxrates,
                folder_name = "alpha=$a beta=$b p_f=$pf t_c=$(changed_taxrates[1][2])"
            )
        end
        return nothing  # or return a result if needed-
    end
end

# # Define your list of seeds on the master process
# num_sim_ci = 24     # 12 * 8
# all_seeds = rand(1:10_000_000, num_sim_ci)
# println("Simulation started for seeds: ", all_seeds)

all_seeds = [9937590, 9494897, 408387, 169105, 6612768, 9827382, 592810, 1826964, 524941, 5111625, 3580871, 7379769, 2411994,
            1250345, 1200648, 8623226, 6739373, 7707222, 9076351, 5616723, 5147647, 8676955, 9216682, 6743063]

# all_seeds = [3144844, 5350382, 3462521, 6246687, 34794, 3128292, 4501814, 8481853, 9819898, 456358, 6275293, 5762542, 4112631, 580187,
# 2392795, 6222835, 4830615, 5618569, 4884842, 9945681, 7994132, 3040165, 6808937, 6655892, 1324003, 900270, 3355661, 6180976, 2332478, 966511,
# 1816903, 7365202, 1046363, 8534176, 1838829, 4555616, 8354089, 1680089, 3769248, 555458, 8194912, 2205931, 7979678, 3582217, 938199, 3625848,
# 4441534, 3784838, 8026317, 1231958, 1049909, 2074801, 6091673, 983946, 5015862, 2066171, 3467704, 5504406, 2435910, 6672341, 5634803, 2725395,
# 1740706, 8560131, 4581419, 4667196, 9680289, 4083872, 8707007, 8590567, 7195279, 4297841, 3642648, 9475638, 7408326, 8648921, 8892920, 1365992, 5986182, 1184503,
# 937150, 4079685, 3558105, 3940712, 9456482, 7748705, 8846385, 3562407, 1548586, 5559196, 5573995, 9792463, 4512372, 1058415, 181441, 4470050]

# Distribute seeds using pmap (one seed at a time per worker)
@everywhere changed_taxrates = [(:τᶜ, 0.0)]
pmap(run_sim_for_seed, all_seeds)
println("Simulation finished for no shock: ", all_seeds)

# @everywhere changed_taxrates = [(:τᶜ, 0.2)]
# pmap(run_sim_for_seed, all_seeds)
# println("Simulation finished for low shock: ", all_seeds)

# @everywhere changed_taxrates = [(:τᶜ, 0.4)]
# pmap(run_sim_for_seed, all_seeds)
# println("Simulation finished for mid shock: ", all_seeds)

# @everywhere changed_taxrates = [(:τᶜ, 0.6)]
# pmap(run_sim_for_seed, all_seeds)
# println("Simulation finished for high shock: ", all_seeds)

# @everywhere changed_taxrates = [(:τᶜ, 0.8)]
# pmap(run_sim_for_seed, all_seeds)
# println("Simulation finished for very high shock: ", all_seeds)