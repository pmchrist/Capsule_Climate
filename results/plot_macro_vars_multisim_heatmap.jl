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

function run_visualizations_for_experiment(EXPERIMENT_TYPE::String, USE_WEALTH::Bool, CREATE_CSV_for_VIOLIN_PLOT_OPINION::Bool, SAVE_HEATMAP_MODEL::Bool, SAVE_HEATMAP_PRODUCERS::Bool)

    SUB_FOLDER = "data_saved"               # "opinion_dynamics"
    EXPERIMENT_FOLDER = "data"
    PATH                = joinpath(@__DIR__, SUB_FOLDER, EXPERIMENT_FOLDER) # Folder structure root

    # Defining labels for Heatmap on x-axis
    tickfont_exp = 14
    guidefont_exp = 24
    if EXPERIMENT_TYPE == "POLITIC"
        xlabels = [
                #"alpha=0.0 \nbeta=0.0",
                "Uniform\n(ō=0.50)",
                "Centered\n(ō=0.50)",
                "More\nCentered\n(ō=0.50)",

                "Polarized\n(ō=0.50)",
                "More\nPolarized\n(ō=0.45)",

                "Pro-Climate\n(ō=0.58)",
                "Pro-Climate\nCentered\n(ō=0.79)",

                "Anti-Climate\n(ō=0.42)",
                "Anti-Climate\nCentered\n(ō=0.21)",
                ]
        if USE_WEALTH
            xlabels = [
                    #"alpha=0.0 \nbeta=0.0",
                    "Uniform\n(ō=0.20)",
                    "Centered\n(ō=0.20)",
                    "More\nCentered\n(ō=0.21)",

                    "Polarized\n(ō=0.21)",
                    "More\nPolarized\n(ō=0.26)",

                    "Pro-Climate\n(ō=0.23)",
                    "Pro-Climate\nCentered\n(ō=0.83)",

                    "Anti-Climate\n(ō=0.18)",
                    "Anti-Climate\nCentered\n(ō=0.17)",
                    ]
        end
    end
    if EXPERIMENT_TYPE == "SCIENTIFIC"
        xlabels = [
                #"alpha=0.0 \nbeta=0.0",
                "Uniform\n(ō=0.93)",
                "Centered\n(ō=0.81)",
                "More\nCentered\n(ō=0.64)",

                "Polarized\n(ō=0.95)",
                "More\nPolarized\n(ō=0.98)",

                "Pro-Climate\n(ō=0.96)",
                "Pro-Climate\nCentered\n(ō=0.89)",

                "Anti-Climate\n(ō=0.92)",
                "Anti-Climate\nCentered\n(ō=0.47)",
                ]
        if USE_WEALTH
            xlabels = [
                    #"alpha=0.0 \nbeta=0.0",
                    "Uniform\n(ō=0.76)",
                    "Centered\n(ō=0.58)",
                    "More\nCentered\n(ō=0.56)",

                    "Polarized\n(ō=0.84)",
                    "More\nPolarized\n(ō=0.85)",

                    "Pro-Climate\n(ō=0.85)",
                    "Pro-Climate\nCentered\n(ō=0.80)",

                    "Anti-Climate\n(ō=0.69)",
                    "Anti-Climate\nCentered\n(ō=0.31)",
                    ]
        end
    end
    if EXPERIMENT_TYPE == "DEFAULT"
        xlabels = [
                "None",
                "0.1",
                "0.2",
                "0.3",
                "0.4",
                "0.5",
                "0.6",
                "0.7",
                "0.8",
                "0.9",
                "1.0"
                ]
    end
    if EXPERIMENT_TYPE == "DEFAULT LIMITED SCIENTIFIC"
        xlabels = [
                "0.5",
                "0.8",
                "1.0"
                ]
    end
    if EXPERIMENT_TYPE == "DEFAULT LIMITED POLITIC"
        xlabels = [
                "0.2",
                "0.5",
                "0.8"
                ]
    end

    # Defining labels for Heatmap on y-axis
    p_f_to_plot = ["0.36", "0.39", "0.40", "0.41", "0.44"]
    # Defining seeds to aggregate
    SEEDS = [
            9306530, 3465618, 9609750, 5348241, 7765573, 1368160, 7203177, 7051399, 9150468, 8767209,
            1634374, 8751645, 1046358, 3557456, 5717721, 1700500, 7588531, 4072019, 999711, 5693268,
            6666175, 1079953, 3940265, 5661647, 87540, 5252603, 3705839, 4256929, 9371169, 7042693,
            3094985, 5791134, 7623378, 6033806, 3609702, 7736236, 914974, 301849, 6587281, 7463000,
            8493421, 8733655, 1890914, 412147, 704807, 145297, 7824684, 6443024, 9653123, 2290810,
    ]
    SEEDS = string.(SEEDS)

    # Defining the Folder Names in which to look for appropriate experiment
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
            # "Politic alpha=0.0 beta=0.0 p_f=0.36",
            # "Politic alpha=0.0 beta=0.0 p_f=0.39",
            # "Politic alpha=0.0 beta=0.0 p_f=0.40",
            # "Politic alpha=0.0 beta=0.0 p_f=0.41",
            # "Politic alpha=0.0 beta=0.0 p_f=0.44",

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


            "Politic alpha=0.8 beta=0.8 p_f=0.36",
            "Politic alpha=0.8 beta=0.8 p_f=0.39",
            "Politic alpha=0.8 beta=0.8 p_f=0.40",
            "Politic alpha=0.8 beta=0.8 p_f=0.41",
            "Politic alpha=0.8 beta=0.8 p_f=0.44",

            "Politic alpha=0.4 beta=0.4 p_f=0.36",
            "Politic alpha=0.4 beta=0.4 p_f=0.39",
            "Politic alpha=0.4 beta=0.4 p_f=0.40",
            "Politic alpha=0.4 beta=0.4 p_f=0.41",
            "Politic alpha=0.4 beta=0.4 p_f=0.44",


            "Politic alpha=1.0 beta=0.8 p_f=0.36",
            "Politic alpha=1.0 beta=0.8 p_f=0.39",
            "Politic alpha=1.0 beta=0.8 p_f=0.40",
            "Politic alpha=1.0 beta=0.8 p_f=0.41",
            "Politic alpha=1.0 beta=0.8 p_f=0.44",

            "Politic alpha=4.0 beta=2.0 p_f=0.36",
            "Politic alpha=4.0 beta=2.0 p_f=0.39",
            "Politic alpha=4.0 beta=2.0 p_f=0.40",
            "Politic alpha=4.0 beta=2.0 p_f=0.41",
            "Politic alpha=4.0 beta=2.0 p_f=0.44",


            "Politic alpha=0.8 beta=1.0 p_f=0.36",
            "Politic alpha=0.8 beta=1.0 p_f=0.39",
            "Politic alpha=0.8 beta=1.0 p_f=0.40",
            "Politic alpha=0.8 beta=1.0 p_f=0.41",
            "Politic alpha=0.8 beta=1.0 p_f=0.44",

            "Politic alpha=2.0 beta=4.0 p_f=0.36",
            "Politic alpha=2.0 beta=4.0 p_f=0.39",
            "Politic alpha=2.0 beta=4.0 p_f=0.40",
            "Politic alpha=2.0 beta=4.0 p_f=0.41",
            "Politic alpha=2.0 beta=4.0 p_f=0.44"
        ]
    end
    if EXPERIMENT_TYPE == "SCIENTIFIC"
        FOLDERS = [
            # "Scientific alpha=0.0 beta=0.0 p_f=0.36",
            # "Scientific alpha=0.0 beta=0.0 p_f=0.39",
            # "Scientific alpha=0.0 beta=0.0 p_f=0.40",
            # "Scientific alpha=0.0 beta=0.0 p_f=0.41",
            # "Scientific alpha=0.0 beta=0.0 p_f=0.44",

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


            "Scientific alpha=0.8 beta=0.8 p_f=0.36",
            "Scientific alpha=0.8 beta=0.8 p_f=0.39",
            "Scientific alpha=0.8 beta=0.8 p_f=0.40",
            "Scientific alpha=0.8 beta=0.8 p_f=0.41",
            "Scientific alpha=0.8 beta=0.8 p_f=0.44",

            "Scientific alpha=0.4 beta=0.4 p_f=0.36",
            "Scientific alpha=0.4 beta=0.4 p_f=0.39",
            "Scientific alpha=0.4 beta=0.4 p_f=0.40",
            "Scientific alpha=0.4 beta=0.4 p_f=0.41",
            "Scientific alpha=0.4 beta=0.4 p_f=0.44",


            "Scientific alpha=1.0 beta=0.8 p_f=0.36",
            "Scientific alpha=1.0 beta=0.8 p_f=0.39",
            "Scientific alpha=1.0 beta=0.8 p_f=0.40",
            "Scientific alpha=1.0 beta=0.8 p_f=0.41",
            "Scientific alpha=1.0 beta=0.8 p_f=0.44",

            "Scientific alpha=4.0 beta=2.0 p_f=0.36",
            "Scientific alpha=4.0 beta=2.0 p_f=0.39",
            "Scientific alpha=4.0 beta=2.0 p_f=0.40",
            "Scientific alpha=4.0 beta=2.0 p_f=0.41",
            "Scientific alpha=4.0 beta=2.0 p_f=0.44",


            "Scientific alpha=0.8 beta=1.0 p_f=0.36",
            "Scientific alpha=0.8 beta=1.0 p_f=0.39",
            "Scientific alpha=0.8 beta=1.0 p_f=0.40",
            "Scientific alpha=0.8 beta=1.0 p_f=0.41",
            "Scientific alpha=0.8 beta=1.0 p_f=0.44",

            "Scientific alpha=2.0 beta=4.0 p_f=0.36",
            "Scientific alpha=2.0 beta=4.0 p_f=0.39",
            "Scientific alpha=2.0 beta=4.0 p_f=0.40",
            "Scientific alpha=2.0 beta=4.0 p_f=0.41",
            "Scientific alpha=2.0 beta=4.0 p_f=0.44"
        ]
    end
    if EXPERIMENT_TYPE == "DEFAULT LIMITED SCIENTIFIC"
        FOLDERS = [
        "Default alpha=50000.0 beta=50000.0 p_f=0.36",
        "Default alpha=50000.0 beta=50000.0 p_f=0.39",
        "Default alpha=50000.0 beta=50000.0 p_f=0.40",
        "Default alpha=50000.0 beta=50000.0 p_f=0.41",
        "Default alpha=50000.0 beta=50000.0 p_f=0.44",
        "Default alpha=80000.0 beta=20000.0 p_f=0.36",
        "Default alpha=80000.0 beta=20000.0 p_f=0.39",
        "Default alpha=80000.0 beta=20000.0 p_f=0.40",
        "Default alpha=80000.0 beta=20000.0 p_f=0.41",
        "Default alpha=80000.0 beta=20000.0 p_f=0.44",
        "Default alpha=100000.0 beta=10.0 p_f=0.36",
        "Default alpha=100000.0 beta=10.0 p_f=0.39",
        "Default alpha=100000.0 beta=10.0 p_f=0.40",
        "Default alpha=100000.0 beta=10.0 p_f=0.41",
        "Default alpha=100000.0 beta=10.0 p_f=0.44"
        ]
    end
    if EXPERIMENT_TYPE == "DEFAULT LIMITED POLITIC"
        FOLDERS = [
        "Default alpha=20000.0 beta=80000.0 p_f=0.36",
        "Default alpha=20000.0 beta=80000.0 p_f=0.39",
        "Default alpha=20000.0 beta=80000.0 p_f=0.40",
        "Default alpha=20000.0 beta=80000.0 p_f=0.41",
        "Default alpha=20000.0 beta=80000.0 p_f=0.44",
        "Default alpha=50000.0 beta=50000.0 p_f=0.36",
        "Default alpha=50000.0 beta=50000.0 p_f=0.39",
        "Default alpha=50000.0 beta=50000.0 p_f=0.40",
        "Default alpha=50000.0 beta=50000.0 p_f=0.41",
        "Default alpha=50000.0 beta=50000.0 p_f=0.44",
        "Default alpha=80000.0 beta=20000.0 p_f=0.36",
        "Default alpha=80000.0 beta=20000.0 p_f=0.39",
        "Default alpha=80000.0 beta=20000.0 p_f=0.40",
        "Default alpha=80000.0 beta=20000.0 p_f=0.41",
        "Default alpha=80000.0 beta=20000.0 p_f=0.44"
        ]
    end
    if USE_WEALTH
        FOLDERS = map(s -> join(vcat(split(s)[1], "Wealth", split(s)[2:end]...), " "), FOLDERS)
    end


    # Defining Internal Helper Functions
    """
    Returns -> Dict{String, DataFrame}

    Gathers results from all the seeds and combines them, by finding average of last steps. Can process multiple types of generated results

    """
    function get_df_seed_for_boxplot_model_end(main_folder::String, looking_for::String, target_p_f::String, last_steps=48)

        dataframes = Dict{String, DataFrame}()

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
                        CSV.write(joinpath(PATH, "opinion_results_α=$(a)_β=$(b)_p_f=$(target_p_f)_$(EXPERIMENT_TYPE)_Wealth=$(USE_WEALTH).csv"), df)
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
    
    Behavior changes, based on the provided target string, i.e. type of generated results

    """
    function get_df_seed_for_heatmap_model_end(p_f_to_plot::Array, target::String)

        combined_dict = Dict{String, DataFrame}()

        if target == "final_income_dists.csv"
            dct = get_df_seed_for_boxplot_model_end(PATH, target, "0.40")
            merge!(combined_dict, dct)
            return combined_dict
        end

        for p_f_val in p_f_to_plot
            dct = get_df_seed_for_boxplot_model_end(PATH, target, p_f_val)
            merge!(combined_dict, dct)
        end

        return combined_dict
    end


    """
    Visualizing a heatmap of model or cp variables

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
                    # This one is to show the std as percentage of value
                    # mean_val = mean(combined_dict[folder_name][!, target_var])
                    # std_val = std(combined_dict[folder_name][!, target_var])
                    # perc_std = mean_val != 0 ? std_val / mean_val * 100 : 0.0
                    # push!(mean_row, mean_val)
                    # push!(var_row, perc_std)
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
        default(size = (Int(200*length(xlabels)),1000), dpi = 190)
        ylabels = p_f_to_plot
        x_label = "Opinions"
        y_label = "Prices of Fossil Fuel"
        yticks = (1:size(M,1), ylabels)
        if EXPERIMENT_TYPE == "DEFAULT LIMITED SCIENTIFIC" || EXPERIMENT_TYPE == "DEFAULT LIMITED POLITIC"
            y_label = ""
        end
        heatmap(
            M;
            #title = target_var,
            #titlefont = font(16),
            xticks = (1:size(M,2), xlabels),
            yticks = (1:size(M,1), ylabels),
            xlabel = x_label,
            ylabel = y_label,
            color = :viridis,
            clims = (minimum(M), maximum(M)),
            # increase tick‐label font
            guidefont = guidefont_exp,        # axis labels
            tickfont  = tickfont_exp,        # tick labels
            left_margin  = 16Plots.mm,
            right_margin = 10Plots.mm,
            top_margin   = 4Plots.mm,
            bottom_margin= 14Plots.mm
            )
        # overlay annotations: "mean ± std"
        for i in 1:size(M,1), j in 1:size(M,2)
            txt = @sprintf("%.2f \n± %.2f", M[i,j], V[i,j])
            # Black outline (draw text slightly offset in 8 directions)
            for dx in (-0.006, 0, 0.006), dy in (-0.006, 0, 0.006)
                if dx != 0 || dy != 0
                    annotate!(
                        j + dx, i + dy,
                        text(txt, font(10), :black, halign = :center, valign = :center)
                    )
                end
            end
            # Main white text in center
            annotate!(
                j, i,
                text(txt, font(10), :white, halign = :center, valign = :center)
            )
        end


        # Decide folder to save
        graph_path = joinpath(PATH, "graphs", EXPERIMENT_TYPE*"_W=$(USE_WEALTH)")
        # Make sure it exists
        mkpath(graph_path)
        outpath = joinpath(graph_path, "Heatmap $(target_var).png")
        savefig(outpath)
    end


    ###############################################################################
    #  Main Execution / Script Flow
    ###############################################################################

    vars_to_plot_model = ["carbon_emissions", "avg_pi_EE", "avg_pi_EF", "avg_pi_LP", "avg_w_pi_EE", "avg_w_pi_EF", "avg_w_pi_LP", "green_capacity", "dirty_capacity", "carbon_emissions_cp_good_avg", "carbon_emissions_cp_good_var",
    "carbon_emissions_cp_good_avg_w", "GDP", "carbon_emissions_per_GDP", "carbon_emissions_cp", "carbon_emissions_ep", "carbon_emissions_kp", "GDP_hh", "GDP_cp", "GINI_I", "GINI_W", "M", "avg_D_cp", "avg_De_cp", "avg_Du_cp", "avg_n_machines_cp",
    "bankrupt_cp", "bankrupt_kp", "cu", "debt_cp", "debt_tot", "energy_percentage", "markup_cp", "markup_kp", "p_avg_cp", "p_avg_kp", "p_ep", "s_unemp", "s_emp", "LIS", "CPI_cp", "CPI_kp", "D_ep",
    "switch_rate", "total_C", "total_C_actual", "total_I", "total_Q_cp", "total_Q_kp", "total_w", "unsat_L_demand", "unsat_demand", "unsat_invest", "unspend_C", "w_avg", "w_req_avg", "w_sat_avg", "U",
    "machines_EF_over_EE", "energy_green_mix", "carbon_emissions_overall_per_product_cp", "carbon_emissions_per_product_cp", "carbon_emissions_per_product_kp",
    "avg_A_EE", "avg_A_EF", "avg_A_LP", "avg_w_A_EE", "avg_w_A_EF", "avg_w_A_LP", "avg_B_EE", "avg_B_EF", "avg_B_LP", "avg_w_B_EE", "avg_w_B_EF", "avg_w_B_LP",
    "sust_mean_10", "sust_mean_100", "sust_mean_50", "sust_mean_90", "sust_mean_all", "sust_unc_mean_10", "sust_unc_mean_100", "sust_unc_mean_50", "sust_unc_mean_90", "sust_unc_mean_all"
    ]


    vars_to_plot_cp = [
    "all_L_cp_overall_mean", "all_L_cp_upper_0.01", "all_L_cp_upper_0.1", "all_L_cp_upper_0.2", "all_L_cp_upper_0.5",
    "all_S_cp_overall_mean", "all_S_cp_upper_0.01", "all_S_cp_upper_0.1", "all_S_cp_upper_0.2", "all_S_cp_upper_0.5",
    "all_f_cp_overall_mean", "all_f_cp_upper_0.01", "all_f_cp_upper_0.1", "all_f_cp_upper_0.2", "all_f_cp_upper_0.5",
    "all_p_cp_overall_mean", "all_p_cp_upper_0.01", "all_p_cp_upper_0.1", "all_p_cp_upper_0.2", "all_p_cp_upper_0.5",
    "all_profit_cp_overall_mean", "all_profit_cp_upper_0.01", "all_profit_cp_upper_0.1", "all_profit_cp_upper_0.2", "all_profit_cp_upper_0.5",
    "all_w_cp_overall_mean", "all_w_cp_upper_0.01", "all_w_cp_upper_0.1", "all_w_cp_upper_0.2", "all_w_cp_upper_0.5",
    "all_emiss_cp_overall_mean", "all_emiss_cp_upper_0.01", "all_emiss_cp_upper_0.1", "all_emiss_cp_upper_0.2", "all_emiss_cp_upper_0.5"
    ]


    # Saving the HH opinion data

    if CREATE_CSV_for_VIOLIN_PLOT_OPINION
        get_df_seed_for_heatmap_model_end(p_f_to_plot, "final_income_dists.csv")
    end
    println("Data for Violin Plot Saved")

    if SAVE_HEATMAP_MODEL
        combined_dict = get_df_seed_for_heatmap_model_end(p_f_to_plot, "model.csv")
        println("Data Transformed")
        begin
            for target_var in vars_to_plot_model
                comparative_heatmap(combined_dict, p_f_to_plot, target_var, xlabels)
            end
        end
    end
    println("Visualized Data Model")

    if SAVE_HEATMAP_PRODUCERS
        combined_dict = get_df_seed_for_heatmap_model_end(p_f_to_plot, "final_profit_dists_cp.csv")
        begin
            for target_var in vars_to_plot_cp
                comparative_heatmap(combined_dict, p_f_to_plot, target_var, xlabels)
            end
        end
    end
    println("Visualized Data CP")

end


# Performing visualizations

CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "DEFAULT"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = false
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)

CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "SCIENTIFIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = false
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)

CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "POLITIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = false
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)


CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "SCIENTIFIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = true
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)

CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "POLITIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = true
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)


CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "DEFAULT LIMITED SCIENTIFIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = false
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)

CREATE_CSV_for_VIOLIN_PLOT_OPINION = false       # ONLY FOR POLITIC AND SCIENTIFIC
SAVE_HEATMAP_MODEL = true
SAVE_HEATMAP_PRODUCERS = true
EXPERIMENT_TYPE = "DEFAULT LIMITED POLITIC"             # "DEFAULT", "POLITIC", "SCIENTIFIC", "DEFAULT LIMITED SCIENTIFIC", "DEFAULT LIMITED POLITIC"
USE_WEALTH = false
run_visualizations_for_experiment(EXPERIMENT_TYPE, USE_WEALTH, CREATE_CSV_for_VIOLIN_PLOT_OPINION, SAVE_HEATMAP_MODEL, SAVE_HEATMAP_PRODUCERS)

