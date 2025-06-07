using Distributed
using Random

# Launch workers
n_proc_main = 18
addprocs(n_proc_main)
@everywhere using Printf

# Defining all the base Functions for all workers
@everywhere begin
    include("model/main.jl")

    # Experiment Definitions
    changed_taxrates = nothing      # [(:τᶜ, 0.0)] 
    
    # Define a function that runs the simulation(s) for one seed
    function run_sim_for_seed(s::Int)
        for idx in 1:sims_n
            (a, b, pf) = combined_params[idx]

            # Call simulation if no taxrate changes
            run_simulation(
                T = 660,
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
                folder_name = exp_name * (@sprintf(" alpha=%.1f beta=%.1f p_f=%.2f", a, b, pf))
            )
        end
        return nothing  # or return a result if needed-
    end
end

#################################################################
# Defining experiments set
#################################################################

# Which Experiments to perform
do_Default_Run = true
do_Scientific_Run = true
do_Politic_Run = true
do_Default_Run_with_Wealth = false      # Not Used
do_Scientific_Run_with_Wealth = true
do_Politic_Run_with_Wealth = true

# What are the initial variables
@everywhere begin
    default_run_a_b_set = [(0.0, 0.0), (1.0e4, 9.0e4), (2.0e4, 8.0e4), (3.0e4, 7.0e4), (4.0e4, 6.0e4), (5.0e4, 5.0e4),
                    (6.0e4, 4.0e4), (7.0e4, 3.0e4), (8.0e4, 2.0e4), (9.0e4, 1.0e4), (1.0e5, 1.0e1)]
    politic_scientific_run_a_b_set = [(1.0, 1.0), (2.0, 2.0), (4.0, 4.0), (0.8, 0.8), (0.4, 0.4),
                                (0.8, 1.0), (2.0, 4.0), (1.0, 0.8), (4.0, 2.0)]
    prices_fossils = [0.36, 0.39, 0.4, 0.41, 0.44]
end

# Define your list of seeds on the master process
# num_sim_ci = 50     # 18 * 3
# all_seeds = rand(1:10_000_000, num_sim_ci)
all_seeds = [
            9306530, 3465618, 9609750, 5348241, 7765573, 1368160, 7203177, 7051399, 9150468, 8767209,
            1634374, 8751645, 1046358, 3557456, 5717721, 1700500, 7588531, 4072019, 999711, 5693268,
            6666175, 1079953, 3940265, 5661647, 87540, 5252603, 3705839, 4256929, 9371169, 7042693,
            3094985, 5791134, 7623378, 6033806, 3609702, 7736236, 914974, 301849, 6587281, 7463000,
            8493421, 8733655, 1890914, 412147, 704807, 145297, 7824684, 6443024, 9653123, 2290810,
]

#################################################################
# Experiments themselves define proper parameters
#################################################################

println("Simulation started for seeds: ", all_seeds)

if do_Default_Run
    @everywhere begin
        # Define Experiment
        exp_name = "Default"
        alpha_betas = default_run_a_b_set
        opinion_scientific = false
        opinion_politic = false
        opinion_wealth = false

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
end

if do_Scientific_Run
    @everywhere begin
        # Define Experiment
        exp_name = "Scientific"
        alpha_betas = politic_scientific_run_a_b_set
        opinion_scientific = true
        opinion_politic = false
        opinion_wealth = false

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
end

if do_Politic_Run
    @everywhere begin
        # Define Experiment
        exp_name = "Politic"
        alpha_betas = politic_scientific_run_a_b_set
        opinion_scientific = false
        opinion_politic = true
        opinion_wealth = false

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
end


if do_Default_Run_with_Wealth
    @everywhere begin
        # Define Experiment
        exp_name = "Default Wealth"
        alpha_betas = default_run_a_b_set
        opinion_scientific = false
        opinion_politic = false
        opinion_wealth = true

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
    println("Simulation finished for run with homogenic opinion with Wealth: ", all_seeds)
end

if do_Scientific_Run_with_Wealth
    @everywhere begin
        # Define Experiment
        exp_name = "Scientific Wealth"
        alpha_betas = politic_scientific_run_a_b_set
        opinion_scientific = true
        opinion_politic = false
        opinion_wealth = true

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
    println("Simulation finished for dynamic opinion Scientific Experiment with Wealth: ", all_seeds)
end

if do_Politic_Run_with_Wealth
    @everywhere begin
        # Define Experiment
        exp_name = "Politic Wealth"
        alpha_betas = politic_scientific_run_a_b_set
        opinion_scientific = false
        opinion_politic = true
        opinion_wealth = true

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
    println("Simulation finished for dynamic opinion Politic Experiment with Wealth: ", all_seeds)
end
