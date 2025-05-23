using Distributed
using Random

# Launch workers
n_proc_main = 13
addprocs(n_proc_main)

# Defining all the Functions and Initial Params for all workers
@everywhere begin
    include("model/main.jl")

    # Experiment Definitions
    changed_taxrates = nothing
    #changed_taxrates = [(:τᶜ, 0.0)] 
    
    # Init Params
    # alpha_betas = [(0.0, 0.0), (1.0e4, 9.0e4), (2.0e4, 8.0e4), (3.0e4, 7.0e4), (4.0e4, 5.0e4), (5.0e4, 5.0e4),
    #                 (6.0e4, 4.0e4), (7.0e4, 3.0e4), (8.0e4, 2.0e4), (9.0e4, 1.0e4), (1.0e5, 1.0e1)]
    # alpha_betas = [(0.0, 0.0), (1.0, 1.0), (2.0, 2.0), (4.0, 4.0), (0.8, 0.8), (0.4, 0.4),
    #                 (0.8, 1.0), (2.0, 4.0), (1.0, 0.8), (4.0, 2.0)]
    # prices_fossils = [0.36, 0.39, 0.40, 0.41, 0.44]
    
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
                #changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf)],
                changed_params_init = [(:sust_α, a), (:sust_β, b), (:p_f, pf),
                                    (:sust_upd_rule_scientific, opinion_scientific),
                                    (:sust_upd_rule_politic, opinion_politic),
                                    (:sust_upd_rule_use_wealth, opinion_wealth)],
                changed_taxrates = changed_taxrates,
                #folder_name = exp_name + " alpha=$a beta=$b p_f=$pf t_c=$(changed_taxrates[1][2])"
                folder_name = exp_name * " alpha=$a beta=$b p_f=$pf"
            )
        end
        return nothing  # or return a result if needed-
    end
end

# Define your list of seeds on the master process
# num_sim_ci = 48     # 12 * 8
# all_seeds = rand(1:10_000_000, num_sim_ci)

# all_seeds = [2571810, 9390529, 2141354, 8117981, 1029419, 6524129, 2188404, 5612874, 9603489, 4287723, 5677055, 4506482,
#             5155673, 1425357, 8290646, 1684337, 9209424, 1334281, 7768006, 6180382, 8702647, 9809029, 5054851, 7928006,
#             5812938, 5952884, 5542161, 9217744, 1862368, 4104468, 9373123, 7667192, 3435424, 9679097, 6265179, 5147301,
#             376902, 1097721, 1582135, 5905392, 8290356, 3683202, 3383379, 7830028, 6816856, 3741042, 7775786, 1765213]

all_seeds = [2571810, 9390529, 2141354, 8117981, 1029419, 6524129, 2188404, 5612874, 9603489, 4287723, 5677055, 4506482]
println("Simulation started for seeds: ", all_seeds)


# Default run
@everywhere begin
    # Define Experiment
    opinion_scientific = false
    opinion_politic = false
    opinion_wealth = false
    if opinion_scientific
        exp_name = opinion_wealth ? "Scientific Wealth" : "Scientific"
    elseif opinion_politic
        exp_name = opinion_wealth ? "Politic Wealth" : "Politic"
    else
        exp_name = opinion_wealth ? "Default Wealth" : "Default"
    end

    # Define Parameters
    alpha_betas = [(0.0, 0.0), (1.0e4, 9.0e4), (2.0e4, 8.0e4), (3.0e4, 7.0e4), (4.0e4, 5.0e4), (5.0e4, 5.0e4),
                    (6.0e4, 4.0e4), (7.0e4, 3.0e4), (8.0e4, 2.0e4), (9.0e4, 1.0e4), (1.0e5, 1.0e1)]
    prices_fossils = [0.36, 0.39, 0.40, 0.41, 0.44]

    combined_params = []
    for (α, β) in alpha_betas
        for p_f in prices_fossils
            push!(combined_params, [α, β, p_f])
        end
    end

    sims_n = length(combined_params)
end
# Distribute seeds using pmap (one seed at a time per worker)
pmap(run_sim_for_seed, all_seeds)
println("Simulation finished for run with homogenic opinion: ", all_seeds)

# Scientific
@everywhere begin
    # Define Experiment
    opinion_scientific = true
    opinion_politic = false
    opinion_wealth = false
    if opinion_scientific
        exp_name = opinion_wealth ? "Scientific Wealth" : "Scientific"
    elseif opinion_politic
        exp_name = opinion_wealth ? "Politic Wealth" : "Politic"
    else
        exp_name = opinion_wealth ? "Default Wealth" : "Default"
    end

    # Define Parameters
    alpha_betas = [(0.0, 0.0), (1.0, 1.0), (2.0, 2.0), (4.0, 4.0), (0.8, 0.8), (0.4, 0.4),
                    (0.8, 1.0), (2.0, 4.0), (1.0, 0.8), (4.0, 2.0)]
    prices_fossils = [0.36, 0.39, 0.40, 0.41, 0.44]

    combined_params = []
    for (α, β) in alpha_betas
        for p_f in prices_fossils
            push!(combined_params, [α, β, p_f])
        end
    end

    sims_n = length(combined_params)
end
# Distribute seeds using pmap (one seed at a time per worker)
pmap(run_sim_for_seed, all_seeds)
println("Simulation finished for dynamic opinion Scientific Experiment: ", all_seeds)

# Politic
@everywhere begin
    # Define Experiment
    opinion_scientific = false
    opinion_politic = true
    opinion_wealth = false
    if opinion_scientific
        exp_name = opinion_wealth ? "Scientific Wealth" : "Scientific"
    elseif opinion_politic
        exp_name = opinion_wealth ? "Politic Wealth" : "Politic"
    else
        exp_name = opinion_wealth ? "Default Wealth" : "Default"
    end

    # Define Parameters
    alpha_betas = [(0.0, 0.0), (1.0, 1.0), (2.0, 2.0), (4.0, 4.0), (0.8, 0.8), (0.4, 0.4),
                    (0.8, 1.0), (2.0, 4.0), (1.0, 0.8), (4.0, 2.0)]
    prices_fossils = [0.36, 0.39, 0.40, 0.41, 0.44]

    combined_params = []
    for (α, β) in alpha_betas
        for p_f in prices_fossils
            push!(combined_params, [α, β, p_f])
        end
    end

    sims_n = length(combined_params)
end
# Distribute seeds using pmap (one seed at a time per worker)
pmap(run_sim_for_seed, all_seeds)
println("Simulation finished for dynamic opinion Politic Experiment: ", all_seeds)