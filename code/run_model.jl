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
n_proc_main = 10
addprocs(n_proc_main)

# Make sure all needed packages and code are loaded on every worker
@everywhere begin

    # Include or define your simulation code
    include("model/main.jl")

    # Declare any necessary parameters or global arrays
    alphas = [2, 12]
    betas  = [2, 12]
    prices_fossils = [0.35, 0.37, 0.39, 0.40, 0.41, 0.43, 0.45]
    combined_params = [(a, b, pf) for a in alphas, b in betas, pf in prices_fossils]
    const sims_n = length(combined_params)

    # Define a function that runs the simulation(s) for one seed
    function run_sim_for_seed(s::Int)
        for idx in 1:sims_n
            (a, b, pf) = combined_params[idx]

            # Call your simulation (replace with your real function signature)
            run_simulation(
                T = 1200,
                savedata = true,
                show_full_output = false,
                showprogress = false,
                seed = s,
                save_firmdata = true,
                sim_nr = idx,
                changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf)],
                folder_name = "alpha=$a beta=$b p_f=$pf"
            )
        end
        return nothing  # or return a result if needed
    end
end

# Define your list of seeds on the master process
# num_sim_ci = 48
# all_seeds = rand(1:10_000_000, num_sim_ci)
# println("Simulation started for seeds: ", all_seeds)

all_seeds = [7573706, 817298, 5015995, 7372452, 2700498, 9996918, 3495231, 3327595, 7666357, 7194651, 2110350,
2314701, 6076284, 493882, 4846528, 3574769, 4625989, 8707792, 7074644, 3980917, 9294657, 3486417,
7685624, 4288856, 5916162, 7355592, 3710378, 3801667, 6954119, 9529040, 6072593, 4085919, 3602909, 6415290, 1171631, 7390976, 3307371,
5079054, 4553034, 821390, 2036270, 5147823, 9264518, 6485874, 9136572, 5373138, 2772102, 4883998]

# Distribute seeds using pmap (one seed at a time per worker)
pmap(run_sim_for_seed, all_seeds)
println("Simulation finished for seeds: ", all_seeds)
println(all_seeds)
