# Launch workers
using Distributed
n_proc_main = 20
addprocs(n_proc_main)

# PARAMETERS
@everywhere begin
    ###############################################################################
    #  Load Packages
    ###############################################################################
    using CSV
    using DataFrames
    using Statistics
    using StatsBase
    using FileIO
    using Printf
    using Random
    using StatsPlots

    ###############################################################################
    #  Parameters & Global Variables
    ###############################################################################
    # Adjust these as needed
    EXPERIMENT_TYPE = "POLITIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC"
    USE_WEALTH = true
    SUB_FOLDER = "data"
    #const PATH                = joinpath(@__DIR__, "data_saved", SUB_FOLDER) # Folder structure root
    const PATH                = joinpath(@__DIR__, "opinion_dynamics", SUB_FOLDER) # Folder structure root

    const HH_STEP_START       = 200
    const HH_STEP_END         = 900

    # SEEDS = [
    #         7037729, 3056271, 5276478, 9966343, 5033711, 9550621, 3255722, 6004412, 7860851, 2154647, 2382506, 1517787, 4193039, 6827896, 168548, 6258674,
    #         1985660, 4664124, 880208, 6695154, 7285728, 8045833, 3450557, 4411763, 5484498, 3533143, 4259935, 2294235, 3247623, 606869, 5933908, 2001805,
    #         1078872, 7162668, 3705171, 3876635, 5188929, 6450600, 7613907, 7755798, 7470811, 2495445, 8836219, 7184376, 3074564, 7286562, 7372053, 2171950]
    SEEDS = [
            9306530, 3465618, 9609750, 5348241, 7765573, 1368160, 7203177, 7051399, 9150468, 8767209,
            1634374, 8751645, 1046358, 3557456, 5717721, 1700500, 7588531, 4072019, 999711, 5693268,
            #6666175, 1079953, 3940265, 5661647, 87540, 5252603, 3705839, 4256929, 9371169, 7042693,
            #3094985, 5791134, 7623378, 6033806, 3609702, 7736236, 914974, 301849, 6587281, 7463000,
            #8493421, 8733655, 1890914, 412147, 704807, 145297, 7824684, 6443024, 9653123, 2290810
    ]
    SEEDS = string.(SEEDS)

    if EXPERIMENT_TYPE == "DEFAULT"
        FOLDERS = [
        "Default alpha=0.0 beta=0.0 p_f=0.36",
        "Default alpha=0.0 beta=0.0 p_f=0.39",
        "Default alpha=0.0 beta=0.0 p_f=0.40",
        "Default alpha=0.0 beta=0.0 p_f=0.41",
        "Default alpha=0.0 beta=0.0 p_f=0.44",
        "Default alpha=10000.0 beta=90000.0 p_f=0.36",
        "Default alpha=10000.0 beta=90000.0 p_f=0.39",
        "Default alpha=10000.0 beta=90000.0 p_f=0.40",
        "Default alpha=10000.0 beta=90000.0 p_f=0.41",
        "Default alpha=10000.0 beta=90000.0 p_f=0.44",
        "Default alpha=20000.0 beta=80000.0 p_f=0.36",
        "Default alpha=20000.0 beta=80000.0 p_f=0.39",
        "Default alpha=20000.0 beta=80000.0 p_f=0.40",
        "Default alpha=20000.0 beta=80000.0 p_f=0.41",
        "Default alpha=20000.0 beta=80000.0 p_f=0.44",
        "Default alpha=30000.0 beta=70000.0 p_f=0.36",
        "Default alpha=30000.0 beta=70000.0 p_f=0.39",
        "Default alpha=30000.0 beta=70000.0 p_f=0.40",
        "Default alpha=30000.0 beta=70000.0 p_f=0.41",
        "Default alpha=30000.0 beta=70000.0 p_f=0.44",
        "Default alpha=40000.0 beta=60000.0 p_f=0.36",
        "Default alpha=40000.0 beta=60000.0 p_f=0.39",
        "Default alpha=40000.0 beta=60000.0 p_f=0.40",
        "Default alpha=40000.0 beta=60000.0 p_f=0.41",
        "Default alpha=40000.0 beta=60000.0 p_f=0.44",
        "Default alpha=50000.0 beta=50000.0 p_f=0.36",
        "Default alpha=50000.0 beta=50000.0 p_f=0.39",
        "Default alpha=50000.0 beta=50000.0 p_f=0.40",
        "Default alpha=50000.0 beta=50000.0 p_f=0.41",
        "Default alpha=50000.0 beta=50000.0 p_f=0.44",
        "Default alpha=60000.0 beta=40000.0 p_f=0.36",
        "Default alpha=60000.0 beta=40000.0 p_f=0.39",
        "Default alpha=60000.0 beta=40000.0 p_f=0.40",
        "Default alpha=60000.0 beta=40000.0 p_f=0.41",
        "Default alpha=60000.0 beta=40000.0 p_f=0.44",
        "Default alpha=70000.0 beta=30000.0 p_f=0.36",
        "Default alpha=70000.0 beta=30000.0 p_f=0.39",
        "Default alpha=70000.0 beta=30000.0 p_f=0.40",
        "Default alpha=70000.0 beta=30000.0 p_f=0.41",
        "Default alpha=70000.0 beta=30000.0 p_f=0.44",
        "Default alpha=80000.0 beta=20000.0 p_f=0.36",
        "Default alpha=80000.0 beta=20000.0 p_f=0.39",
        "Default alpha=80000.0 beta=20000.0 p_f=0.40",
        "Default alpha=80000.0 beta=20000.0 p_f=0.41",
        "Default alpha=80000.0 beta=20000.0 p_f=0.44",
        "Default alpha=90000.0 beta=10000.0 p_f=0.36",
        "Default alpha=90000.0 beta=10000.0 p_f=0.39",
        "Default alpha=90000.0 beta=10000.0 p_f=0.40",
        "Default alpha=90000.0 beta=10000.0 p_f=0.41",
        "Default alpha=90000.0 beta=10000.0 p_f=0.44",
        "Default alpha=100000.0 beta=10.0 p_f=0.36",
        "Default alpha=100000.0 beta=10.0 p_f=0.39",
        "Default alpha=100000.0 beta=10.0 p_f=0.40",
        "Default alpha=100000.0 beta=10.0 p_f=0.41",
        "Default alpha=100000.0 beta=10.0 p_f=0.44"
        ]
    end
    if EXPERIMENT_TYPE == "POLITIC"
        FOLDERS = [
            "Politic alpha=0.0 beta=0.0 p_f=0.36",
            "Politic alpha=0.0 beta=0.0 p_f=0.39",
            "Politic alpha=0.0 beta=0.0 p_f=0.40",
            "Politic alpha=0.0 beta=0.0 p_f=0.41",
            "Politic alpha=0.0 beta=0.0 p_f=0.44",

            "Politic alpha=1.0 beta=1.0 p_f=0.36",
            "Politic alpha=1.0 beta=1.0 p_f=0.39",
            "Politic alpha=1.0 beta=1.0 p_f=0.40",
            "Politic alpha=1.0 beta=1.0 p_f=0.41",
            "Politic alpha=1.0 beta=1.0 p_f=0.44",

            "Politic alpha=2.0 beta=2.0 p_f=0.36",
            "Politic alpha=2.0 beta=2.0 p_f=0.39",
            "Politic alpha=2.0 beta=2.0 p_f=0.40",
            "Politic alpha=2.0 beta=2.0 p_f=0.41",
            "Politic alpha=2.0 beta=2.0 p_f=0.44",

            "Politic alpha=4.0 beta=4.0 p_f=0.36",
            "Politic alpha=4.0 beta=4.0 p_f=0.39",
            "Politic alpha=4.0 beta=4.0 p_f=0.40",
            "Politic alpha=4.0 beta=4.0 p_f=0.41",
            "Politic alpha=4.0 beta=4.0 p_f=0.44",

            "Politic alpha=0.4 beta=0.4 p_f=0.36",
            "Politic alpha=0.4 beta=0.4 p_f=0.39",
            "Politic alpha=0.4 beta=0.4 p_f=0.40",
            "Politic alpha=0.4 beta=0.4 p_f=0.41",
            "Politic alpha=0.4 beta=0.4 p_f=0.44",

            "Politic alpha=0.8 beta=0.8 p_f=0.36",
            "Politic alpha=0.8 beta=0.8 p_f=0.39",
            "Politic alpha=0.8 beta=0.8 p_f=0.40",
            "Politic alpha=0.8 beta=0.8 p_f=0.41",
            "Politic alpha=0.8 beta=0.8 p_f=0.44",

            "Politic alpha=0.8 beta=1.0 p_f=0.36",
            "Politic alpha=0.8 beta=1.0 p_f=0.39",
            "Politic alpha=0.8 beta=1.0 p_f=0.40",
            "Politic alpha=0.8 beta=1.0 p_f=0.41",
            "Politic alpha=0.8 beta=1.0 p_f=0.44",

            "Politic alpha=2.0 beta=4.0 p_f=0.36",
            "Politic alpha=2.0 beta=4.0 p_f=0.39",
            "Politic alpha=2.0 beta=4.0 p_f=0.40",
            "Politic alpha=2.0 beta=4.0 p_f=0.41",
            "Politic alpha=2.0 beta=4.0 p_f=0.44",

            "Politic alpha=1.0 beta=0.8 p_f=0.36",
            "Politic alpha=1.0 beta=0.8 p_f=0.39",
            "Politic alpha=1.0 beta=0.8 p_f=0.40",
            "Politic alpha=1.0 beta=0.8 p_f=0.41",
            "Politic alpha=1.0 beta=0.8 p_f=0.44",

            "Politic alpha=4.0 beta=2.0 p_f=0.36",
            "Politic alpha=4.0 beta=2.0 p_f=0.39",
            "Politic alpha=4.0 beta=2.0 p_f=0.40",
            "Politic alpha=4.0 beta=2.0 p_f=0.41",
            "Politic alpha=4.0 beta=2.0 p_f=0.44"
        ]
    end
    if EXPERIMENT_TYPE == "SCIENTIFIC"
        FOLDERS = [
            "Scientific alpha=0.0 beta=0.0 p_f=0.36",
            "Scientific alpha=0.0 beta=0.0 p_f=0.39",
            "Scientific alpha=0.0 beta=0.0 p_f=0.40",
            "Scientific alpha=0.0 beta=0.0 p_f=0.41",
            "Scientific alpha=0.0 beta=0.0 p_f=0.44",

            "Scientific alpha=1.0 beta=1.0 p_f=0.36",
            "Scientific alpha=1.0 beta=1.0 p_f=0.39",
            "Scientific alpha=1.0 beta=1.0 p_f=0.40",
            "Scientific alpha=1.0 beta=1.0 p_f=0.41",
            "Scientific alpha=1.0 beta=1.0 p_f=0.44",

            "Scientific alpha=2.0 beta=2.0 p_f=0.36",
            "Scientific alpha=2.0 beta=2.0 p_f=0.39",
            "Scientific alpha=2.0 beta=2.0 p_f=0.40",
            "Scientific alpha=2.0 beta=2.0 p_f=0.41",
            "Scientific alpha=2.0 beta=2.0 p_f=0.44",

            "Scientific alpha=4.0 beta=4.0 p_f=0.36",
            "Scientific alpha=4.0 beta=4.0 p_f=0.39",
            "Scientific alpha=4.0 beta=4.0 p_f=0.40",
            "Scientific alpha=4.0 beta=4.0 p_f=0.41",
            "Scientific alpha=4.0 beta=4.0 p_f=0.44",

            "Scientific alpha=0.4 beta=0.4 p_f=0.36",
            "Scientific alpha=0.4 beta=0.4 p_f=0.39",
            "Scientific alpha=0.4 beta=0.4 p_f=0.40",
            "Scientific alpha=0.4 beta=0.4 p_f=0.41",
            "Scientific alpha=0.4 beta=0.4 p_f=0.44",

            "Scientific alpha=0.8 beta=0.8 p_f=0.36",
            "Scientific alpha=0.8 beta=0.8 p_f=0.39",
            "Scientific alpha=0.8 beta=0.8 p_f=0.40",
            "Scientific alpha=0.8 beta=0.8 p_f=0.41",
            "Scientific alpha=0.8 beta=0.8 p_f=0.44",

            "Scientific alpha=0.8 beta=1.0 p_f=0.36",
            "Scientific alpha=0.8 beta=1.0 p_f=0.39",
            "Scientific alpha=0.8 beta=1.0 p_f=0.40",
            "Scientific alpha=0.8 beta=1.0 p_f=0.41",
            "Scientific alpha=0.8 beta=1.0 p_f=0.44",

            "Scientific alpha=2.0 beta=4.0 p_f=0.36",
            "Scientific alpha=2.0 beta=4.0 p_f=0.39",
            "Scientific alpha=2.0 beta=4.0 p_f=0.40",
            "Scientific alpha=2.0 beta=4.0 p_f=0.41",
            "Scientific alpha=2.0 beta=4.0 p_f=0.44",

            "Scientific alpha=1.0 beta=0.8 p_f=0.36",
            "Scientific alpha=1.0 beta=0.8 p_f=0.39",
            "Scientific alpha=1.0 beta=0.8 p_f=0.40",
            "Scientific alpha=1.0 beta=0.8 p_f=0.41",
            "Scientific alpha=1.0 beta=0.8 p_f=0.44",

            "Scientific alpha=4.0 beta=2.0 p_f=0.36",
            "Scientific alpha=4.0 beta=2.0 p_f=0.39",
            "Scientific alpha=4.0 beta=2.0 p_f=0.40",
            "Scientific alpha=4.0 beta=2.0 p_f=0.41",
            "Scientific alpha=4.0 beta=2.0 p_f=0.44"
        ]
    end
    if USE_WEALTH
        FOLDERS = map(s -> join(vcat(split(s)[1], "Wealth", split(s)[2:end]...), " "), FOLDERS)
    end
end

# FUNCTIONS
@everywhere begin
    """
    get_df_seed_for_ci_model(main_folder, looking_for) -> Dict{String, DataFrame}

    Gathers model-level data (e.g., "model.csv") across multiple seeds for each folder 
    in FOLDERS, concatenates, and returns a Dict {folder => DataFrame}.
    Filters data to timesteps in [HH_STEP_START, HH_STEP_END].
    """
    function get_df_seed_for_boxplot_model_end(main_folder::String, looking_for::String, target_p_f::String, last_steps=50)

        dataframes = Dict{String, DataFrame}()          # Change this shit to array\

        # Filter the overall list of folders to include only the target p_f experiments
        p_f_Folders = filter(f -> occursin(target_p_f, f), FOLDERS)

        for folder in p_f_Folders
            folder_path = joinpath(main_folder, folder)
            if !isdir(folder_path)
                # skip if not found
                continue
            end
            df_models_experiment = DataFrame[]  # array of DataFrames for each seed

            for seed in SEEDS
                file_path = joinpath(folder_path, "$seed $looking_for")
                if isfile(file_path)
                    df = CSV.read(file_path, DataFrame)
                    if looking_for == "model.csv"
                        df."timestamp" = 1:nrow(df)
                        df."carbon_emissions_cp_proportion" = df."carbon_emissions_cp" ./ df."carbon_emissions"
                        df."carbon_emissions_ep_proportion" = df."carbon_emissions_ep" ./ df."carbon_emissions"
                        df."carbon_emissions_kp_proportion" = df."carbon_emissions_kp" ./ df."carbon_emissions"
                        df."carbon_emissions_per_GDP" = df."carbon_emissions" ./ df."GDP"

                        df."machines_EF_over_EE" = df."avg_pi_EF" ./ df."avg_pi_EE"
                        df."energy_green_mix" = df."green_capacity" ./ (df."green_capacity" .+ df."dirty_capacity")
                        df."carbon_emissions_overall_per_product_cp" = df."carbon_emissions" ./ df."total_Q_cp"
                        df."carbon_emissions_per_product_cp" = df."carbon_emissions_cp" ./ df."total_Q_cp"
                        df."carbon_emissions_per_product_kp" = df."carbon_emissions_kp" ./ df."total_Q_kp"

                        replace!(df."carbon_emissions_cp_proportion", NaN => 0)
                        replace!(df."carbon_emissions_ep_proportion", NaN => 0)
                        replace!(df."carbon_emissions_kp_proportion", NaN => 0)
                        replace!(df."carbon_emissions_per_GDP", NaN => 0)
                        
                        # Keeping only the man of last 50 rows
                        last50 = df[end-last_steps:end, :]
                        row_means = [mean(last50[!, col]) for col in names(df)]
                        df[end, :] .= row_means
                        df = df[end:end, :]

                    end

                    if looking_for == "final_profit_dists_cp.csv"

                        df_sorted = sort(df, :all_f_cp, rev=true)
                        n = nrow(df_sorted)
                        quantiles = [0.01, 0.1, 0.2, 0.5]
                        quantile_labels = ["upper_0.01", "upper_0.1", "upper_0.2", "upper_0.5"]
                        numcols = names(df, Number)

                        # Dictionary to store results
                        all_means = Dict{String, Float64}()

                        # Means for quantiles
                        for (q, label) in zip(quantiles, quantile_labels)
                            top_n = max(1, round(Int, n * q))
                            top_rows = df_sorted[1:top_n, :]
                            for col in numcols
                                all_means["$(col)_$(label)"] = mean(top_rows[!, col])
                            end
                        end

                        # Means for all data
                        for col in numcols
                            all_means["$(col)_overall_mean"] = mean(df[!, col])
                        end

                        # Create one-row DataFrame
                        result_df = DataFrame(all_means)

                        df = result_df

                    end

                    if looking_for == "final_income_dists.csv"
                        df = select(df, [:sust_opinion_init, :sust_opinion_end, :sust_uncert_init, :sust_uncert_end])
                        # Extracting name of experiment from Folder name
                        captures = collect(eachmatch(r"=([+-]?\d*\.?\d+)", folder))
                        a = parse(Float64, captures[1].captures[1])
                        b = parse(Float64, captures[2].captures[1])
                        CSV.write(joinpath(PATH, "opinion_results_α=$(a)_β=$(b)_$(EXPERIMENT_TYPE).csv"), df)
                    end
                    df[:, :seed] .= seed          

                    push!(df_models_experiment, df)
                end
            end

            if !isempty(df_models_experiment)
                dataframes[folder] = reduce(vcat, df_models_experiment)
            else
                dataframes[folder] = DataFrame()
            end
        end

        return dataframes
    end

    
    """
    Combines all the repetitions with different runs to the corresponding columns in the dataframe, accessible by the dictionary with the name of experiment
    
    Behavior changes, based on the provided target string.
    """
    function get_df_seed_for_heatmap_model_end(p_f_to_plot::Array, target::String)

        combined_dict = Dict{String, DataFrame}()

        for p_f_val in p_f_to_plot
            dct = get_df_seed_for_boxplot_model_end(PATH, target, p_f_val)
            merge!(combined_dict, dct)  # merge! adds/overwrites keys from dct into combined_dict
        end

        return combined_dict
    end



    """
    Visualizer
    """
    function comparative_heatmap(experiments_dict::Dict, p_f_to_plot::Array, target_var::String, xlabels::Array)

        # First we pre calculate all the values of interest
        means = []
        vars = []
        min = []
        max = []
        for p_f in p_f_to_plot
            mean_row = []
            var_row = []
            min_row = []
            max_row = []
            for folder_name in FOLDERS
                if occursin(p_f, folder_name)
                    push!(mean_row, mean(combined_dict[folder_name][!, target_var]))
                    push!(var_row, std(combined_dict[folder_name][!, target_var]))
                    push!(min_row, minimum(combined_dict[folder_name][!, target_var]))
                    push!(max_row, maximum(combined_dict[folder_name][!, target_var]))
                end
            end
            push!(means, mean_row)
            push!(vars, var_row)
        end

        # Plot them
        # convert Array-of-Arrays to a regular matrix
        M = reduce(hcat, means)'
        V = reduce(hcat, vars)'

        default(size = (2000,1000), dpi = 200)
        ylabels = p_f_to_plot
        heatmap(
            M;
            title = target_var,
            titlefont = font(16),
            xticks = (1:size(M,2), xlabels),
            yticks = (1:size(M,1), ylabels),
            xlabel = "Opinion",
            ylabel = "p_f",
            color = :viridis,
            clims = (minimum(M), maximum(M)),
            # increase tick‐label font
            guidefont = font(12),        # axis labels
            tickfont  = font(10),        # tick labels
            left_margin  = 25Plots.mm,
            right_margin = 25Plots.mm,
            top_margin   = 5Plots.mm,
            bottom_margin= 20Plots.mm
            )
        # overlay annotations: "mean ± std"
        for i in 1:size(M,1), j in 1:size(M,2)
            txt = @sprintf("%.2f ± %.2f", M[i,j], V[i,j])
            annotate!(
            j, i,
            text(txt, font(4), halign = :center, valign = :center)
            )
        end

        # Decide folder to save
        graph_path = joinpath(PATH, "graphs")
        # Make sure it exists
        mkpath(graph_path)
        outpath = joinpath(graph_path, "Heatmap $(target_var).png")
        savefig(outpath)
    end



end

###############################################################################
#  Main Execution / Script Flow
###############################################################################

#vars_to_plot = ["carbon_emissions", "avg_pi_EE", "avg_pi_EF", "avg_pi_LP", "green_capacity", "dirty_capacity", "GDP", "carbon_emissions_per_GDP", "carbon_emissions_cp"]      # THESE ARE COLUMNS OF INTEREST IN DF
vars_to_plot_model = ["carbon_emissions", "avg_pi_EE", "avg_pi_EF", "avg_pi_LP", "avg_w_pi_EE", "avg_w_pi_EF", "avg_w_pi_LP", "green_capacity", "dirty_capacity", "carbon_emissions_cp_good_avg", "carbon_emissions_cp_good_var",
"carbon_emissions_cp_good_avg_w", "GDP", "carbon_emissions_per_GDP", "carbon_emissions_cp", "carbon_emissions_ep", "carbon_emissions_kp", "GDP_hh", "GDP_cp", "GINI_I", "GINI_W", "M", "avg_D_cp", "avg_De_cp", "avg_Du_cp", "avg_n_machines_cp",
"bankrupt_cp", "bankrupt_kp", "cu", "debt_cp", "debt_tot", "energy_percentage", "markup_cp", "markup_kp", "p_avg_cp", "p_avg_kp", "p_ep", "s_unemp", "s_emp", "LIS", "CPI_cp", "CPI_kp", "D_ep",
"switch_rate", "total_C", "total_C_actual", "total_I", "total_Q_cp", "total_Q_kp", "total_w", "unsat_L_demand", "unsat_demand", "unsat_invest", "unspend_C", "w_avg", "w_req_avg", "w_sat_avg", "U",
"machines_EF_over_EE", "energy_green_mix", "carbon_emissions_overall_per_product_cp", "carbon_emissions_per_product_cp", "carbon_emissions_per_product_kp",
"avg_A_EE", "avg_A_EF", "avg_A_LP", "avg_w_A_EE", "avg_w_A_EF", "avg_w_A_LP", "avg_B_EE", "avg_B_EF", "avg_B_LP", "avg_w_B_EE", "avg_w_B_EF", "avg_w_B_LP",
"sust_mean_10", "sust_mean_100", "sust_mean_50", "sust_mean_90", "sust_mean_all", "sust_unc_mean_10", "sust_unc_mean_100", "sust_unc_mean_50", "sust_unc_mean_90", "sust_unc_mean_all"
]

#vars_to_plot_model = ["GDP", "U", "M", "debt_tot"]

vars_to_plot_cp = [
"all_L_cp_overall_mean", "all_L_cp_upper_0.01", "all_L_cp_upper_0.1", "all_L_cp_upper_0.2", "all_L_cp_upper_0.5",
"all_S_cp_overall_mean", "all_S_cp_upper_0.01", "all_S_cp_upper_0.1", "all_S_cp_upper_0.2", "all_S_cp_upper_0.5",
"all_f_cp_overall_mean", "all_f_cp_upper_0.01", "all_f_cp_upper_0.1", "all_f_cp_upper_0.2", "all_f_cp_upper_0.5",
"all_p_cp_overall_mean", "all_p_cp_upper_0.01", "all_p_cp_upper_0.1", "all_p_cp_upper_0.2", "all_p_cp_upper_0.5",
"all_profit_cp_overall_mean", "all_profit_cp_upper_0.01", "all_profit_cp_upper_0.1", "all_profit_cp_upper_0.2", "all_profit_cp_upper_0.5",
"all_w_cp_overall_mean", "all_w_cp_upper_0.01", "all_w_cp_upper_0.1", "all_w_cp_upper_0.2", "all_w_cp_upper_0.5",
"all_emiss_cp_overall_mean", "all_emiss_cp_upper_0.01", "all_emiss_cp_upper_0.1", "all_emiss_cp_upper_0.2", "all_emiss_cp_upper_0.5"
]


# Goes to x-axis, is name of experiment, i.e. init params
if EXPERIMENT_TYPE == "POLITIC" || EXPERIMENT_TYPE == "SCIENTIFIC"
    xlabels = [
            "alpha=0.0 \nbeta=0.0",
            "alpha=1.0 \nbeta=1.0",
            "alpha=2.0 \nbeta=2.0",
            "alpha=4.0 \nbeta=4.0",
            "alpha=0.4 \nbeta=0.4",
            "alpha=0.8 \nbeta=0.8",
            "alpha=0.8 \nbeta=1.0",
            "alpha=2.0 \nbeta=4.0",
            "alpha=1.0 \nbeta=0.8",
            "alpha=4.0 \nbeta=2.0"
            ]
end

if EXPERIMENT_TYPE == "DEFAULT"
    xlabels = [
            "Opinion = 0.0",
            "Opinion = 0.1",
            "Opinion = 0.2",
            "Opinion = 0.3",
            "Opinion = 0.4",
            "Opinion = 0.5",
            "Opinion = 0.6",
            "Opinion = 0.7",
            "Opinion = 0.8",
            "Opinion = 0.9",
            "Opinion = 1.0"
            ]
end

# Goes to y-axis
p_f_to_plot = ["p_f=0.36", "p_f=0.39", "p_f=0.40", "p_f=0.41", "p_f=0.44"]


# Saving the HH opinion data
get_df_seed_for_heatmap_model_end(p_f_to_plot, "final_income_dists.csv")


# combined_dict = get_df_seed_for_heatmap_model_end(p_f_to_plot, "model.csv")
# println("Data Transformed")

# @sync begin
#     for target_var in vars_to_plot_model
#         @spawn comparative_heatmap(combined_dict, p_f_to_plot, target_var, xlabels)
#     end
# end
# println("Visualized Data Model")


# combined_dict = get_df_seed_for_heatmap_model_end_cp(p_f_to_plot, "final_profit_dists_cp.csv")
# @sync begin
#     for target_var in vars_to_plot_cp
#         @spawn comparative_heatmap(combined_dict, p_f_to_plot, target_var, xlabels)
#     end
# end
# println("Visualized Data CP")