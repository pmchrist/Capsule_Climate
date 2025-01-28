# To Do :
# Improve Font Sizes, Changes axis names to be only on the left and bottom. FIX THE STRANGE SPACING ISSUES


# Launch workers
using Distributed
n_proc_main = 12
addprocs(n_proc_main)

# PARAMETERS AND FUNCTIONS ARE SHARED
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
    using Plots

    ###############################################################################
    #  Parameters & Global Variables
    ###############################################################################
    # Adjust these as needed
    const PATH                = joinpath(pwd(), "results", "data_saved", "data") # Folder structure root
    const HH_STEP_START       = 300
    const HH_STEP_END         = 1000
    # SEEDS = [7107009, 8968977, 5151600, 2436546, 4269460, 9251552, 4492958, 
    #         6003441, 6033899, 4562678, 7698139, 1975977, 3042982, 5269969, 
    #         719027, 2813374, 3262187, 5391091, 7641139, 1712837, 5129247, 
    #         5540958, 7546105, 605019, 8978662, 6912409, 4380751, 8423068, 
    #         9589324, 5062262, 5798093, 5996428]
    SEEDS = [5996428, 5062262, 5798093, 8423068, 9589324, 4380751, 6912409, 8978662, 5129247, 7641139, 7546105, 5540958, 1712837, 605019, 5391091, 3262187, 2813374, 719027, 5269969, 3042982, 4492958,
            7698139, 7107009, 8968977, 6003441, 1975977, 4269460, 5151600, 9251552, 2436546, 4562678, 6033899]
    SEEDS = string.(SEEDS)

    # without opinion
    # const FOLDERS = [
    #         "alpha=1 beta=1 p_f=0.3 id=1",
    #         "alpha=1 beta=1 p_f=0.35 id=2",
    #         "alpha=1 beta=1 p_f=0.375 id=3",
    #         "alpha=1 beta=1 p_f=0.4 id=4",
    #         "alpha=1 beta=1 p_f=0.425 id=5",
    #         "alpha=1 beta=1 p_f=0.45 id=6",
    #         "alpha=1 beta=1 p_f=0.5 id=7"
    # ]
    # with opinion
    const FOLDERS = [
            "alpha=2 beta=2 p_f=0.3 id=1",
            "alpha=2 beta=2 p_f=0.35 id=5",
            "alpha=2 beta=2 p_f=0.375 id=9",
            "alpha=2 beta=2 p_f=0.4 id=13",
            "alpha=2 beta=2 p_f=0.425 id=17",
            "alpha=2 beta=2 p_f=0.45 id=21",
            "alpha=2 beta=2 p_f=0.5 id=25",
            "alpha=2 beta=18 p_f=0.3 id=3",
            "alpha=2 beta=18 p_f=0.35 id=7",
            "alpha=2 beta=18 p_f=0.375 id=11",
            "alpha=2 beta=18 p_f=0.4 id=15",
            "alpha=2 beta=18 p_f=0.425 id=19",
            "alpha=2 beta=18 p_f=0.45 id=23",
            "alpha=2 beta=18 p_f=0.5 id=27",
            "alpha=18 beta=2 p_f=0.3 id=2",
            "alpha=18 beta=2 p_f=0.35 id=6",
            "alpha=18 beta=2 p_f=0.375 id=10",
            "alpha=18 beta=2 p_f=0.4 id=14",
            "alpha=18 beta=2 p_f=0.425 id=18",
            "alpha=18 beta=2 p_f=0.45 id=22",
            "alpha=18 beta=2 p_f=0.5 id=26",
            "alpha=18 beta=18 p_f=0.3 id=4",
            "alpha=18 beta=18 p_f=0.35 id=8",
            "alpha=18 beta=18 p_f=0.375 id=12",
            "alpha=18 beta=18 p_f=0.4 id=16",
            "alpha=18 beta=18 p_f=0.425 id=20",
            "alpha=18 beta=18 p_f=0.45 id=24",
            "alpha=18 beta=18 p_f=0.5 id=28"
    ]
    # Subplot grid sizes
    const GRAPH_SIZE_DIFF_PARAM = (Int(length(FOLDERS)/7), 7)        # by default we have 7 values for p_f (used to compare results for same seed)
    const GRAPH_SIZE_DIFF_SEED  = (Int(length(SEEDS)/8), 8)          # By default 32 values for seeds

    # Parameters of the model to visualize
    MODEL_LEVEL_COLS = [
        "green_capacity",
        "dirty_capacity",
        "GDP",
        "U",
        "bankrupt_cp",
        "bankrupt_kp",
        "sust_mean_all",
        "sust_mean_10",
        "sust_mean_100", 
        "GINI_I",
        "GINI_W",
        "LIS",
        "M",
        "M_gov",
        "M_hh",
        "M_cp",
        "N_goods",
        "avg_N_goods",
        "unspend_C",
        "unsat_L_demand",
        "unsat_invest",
        "unsat_demand",
        "CPI_cp",
        "CPI_kp",
        "markup_cp",
        "p_avg_cp",
        "p_avg_kp",
        "returns_investments",
        "total_C",
        "total_C_actual",
        "total_I",
        "total_w",
        "debt_tot",
        "debt_cp",
        "debt_unpaid_cp",
        "RD_total",
        "EI_avg",
        "RS_avg",
        "avg_pi_LP",
        "avg_pi_EE",
        "avg_pi_EF"
    ]
    colnames_cp =   [
        "Good_Emiss",
        "Good_Markup_mu",
        "Good_Prod_Q"
    ]
    colnames_cp_agg =   [
        "Good_Emiss_overall_mean",
        "Good_Emiss_lower_mean",
        "Good_Emiss_upper_mean",
        "Good_Markup_mu_overall_mean",
        "Good_Markup_mu_lower_mean",
        "Good_Markup_mu_upper_mean",
        "Good_Prod_Q_overall_mean",
        "Good_Prod_Q_lower_mean",
        "Good_Prod_Q_upper_mean"
    ]



    ###############################################################################
    #  Utility Functions
    ###############################################################################

    """
    combine_and_save_dataframes_hh(main_folder)

    Combines CSVs of household-level data (e.g., household_500_hh.csv, etc.)
    into a single DataFrame, per seed and subfolder, and saves a simpler CSV.
    """
    function combine_and_save_dataframes_hh(main_folder::String)
        hh_fields = ["hh_id", "all_Sust_Score", "all_Sust_Uncert"] # columns to read
        timestamp_range = HH_STEP_START:HH_STEP_END

        # walkdir returns a tuple (root, dirs, files)
        for (root, dirs, files) in walkdir(main_folder)
            for subfolder in dirs
                folder_path = joinpath(root, subfolder)
                for seed in SEEDS
                    df_hh_list = DataFrame[]
                    
                    # e.g., "path/to/subfolder/(seed) x_hh"
                    x_hh_folder = joinpath(folder_path, "$seed x_hh")
                    if !isdir(x_hh_folder)
                        continue
                    end
                    
                    # read each timestamp CSV
                    for t in timestamp_range
                        file_path = joinpath(x_hh_folder, "household_$(t)_hh.csv")
                        if isfile(file_path)
                            # read only the needed columns
                            df = CSV.read(file_path, DataFrame; select=hh_fields)
                            df."timestamp" = fill(t, nrow(df))
                            push!(df_hh_list, df)
                        end
                    end
                    
                    if !isempty(df_hh_list)
                        final_df = reduce(vcat, df_hh_list)
                        output_path = joinpath(folder_path, "$seed simple_hh.csv")
                        CSV.write(output_path, final_df)
                    end
                end
            end
        end
    end

    """
    get_df_same_seed(main_folder, looking_for, seed) -> Dict{String, DataFrame}

    Traverse all subfolders in `main_folder`, looking for a file named `"<seed> looking_for"`.
    Return a dictionary of DataFrames keyed by the folder path.
    - If `looking_for == "model.csv"`, add a `timestamp` column to each line.
    """
    function get_df_same_seed(main_folder::String, looking_for::String, seed::String)
        dataframes = Dict{String, DataFrame}()

        for sub_folder in FOLDERS
        #for (root, dirs, files) in walkdir(main_folder)
            file_path = joinpath(main_folder, sub_folder, "$seed $looking_for")
            if isfile(file_path)
                df = CSV.read(file_path, DataFrame)

                if looking_for == "model.csv"
                    df."timestamp" = 1:nrow(df)
                end

                dataframes[sub_folder] = df
            end
        end

        return dataframes
    end

    """
    get_df_diff_seed(main_folder, looking_for, folder) -> Dict{String, DataFrame}

    Traverse `main_folder` to find a specific `folder`, and read 
    `"<seed> looking_for"` for each seed. 
    Return a dictionary of DataFrames keyed by the seed.
    - If `looking_for == "model.csv"`, add a `timestamp` column.
    """
    function get_df_diff_seed(main_folder::String, looking_for::String, folder::String)
        dataframes = Dict{String, DataFrame}()

        target_folder = joinpath(main_folder, folder)

        # We only care about that specific folder
        if isdir(target_folder)
            for seed in SEEDS
                file_path = joinpath(target_folder, "$seed $looking_for")
                if isfile(file_path)
                    df = CSV.read(file_path, DataFrame)
                    if looking_for == "model.csv"
                        df."timestamp" = 1:nrow(df)
                    end
                    dataframes[seed] = df
                end
            end
        end
        return dataframes
    end

    """
    get_df_seed_for_ci_model(main_folder, looking_for) -> Dict{String, DataFrame}

    Gathers model-level data (e.g., "model.csv") across multiple seeds for each folder 
    in FOLDERS, concatenates, and returns a Dict {folder => DataFrame}.
    Filters data to timesteps in [HH_STEP_START, HH_STEP_END].
    """
    function get_df_seed_for_ci_model(main_folder::String, looking_for::String)
        dataframes = Dict{String, DataFrame}()          # Change this shit to array

        for folder in FOLDERS
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
                    end
                    # filter based on HH_STEP_START and HH_STEP_END
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
    get_df_seed_for_ci_producer(main_folder, looking_for, column_names) -> Dict{String,DataFrame}

    Similar to `get_df_seed_for_ci_model`, but for producer-level data (e.g. "cp_firm.csv").
    We compute aggregate statistics per timestamp (overall mean, std, lower 10% mean, upper 10% mean)
    for each column in `column_names`, then combine them into a single DataFrame for each seed.
    Finally, we vcat them across seeds for each folder.
    """
    function get_df_seed_for_ci_producer(main_folder::String, looking_for::String, column_names::Vector{String})
        dataframes = Dict{String, DataFrame}()

        for folder in FOLDERS
            folder_path = joinpath(main_folder, folder)
            if !isdir(folder_path)
                continue
            end

            df_models_experiment = DataFrame[]
            for seed in SEEDS
                file_path = joinpath(folder_path, "$seed $looking_for")
                if !isfile(file_path)
                    continue
                end

                df = CSV.read(file_path, DataFrame)
                
                # For each seed, we gather aggregated stats by timestamp:
                combined_stats = DataFrame()
                groupby_timestamp = groupby(df, :timestamp)

                # We'll iteratively build combined_stats with needed columns
                for colname in column_names
                    # overall mean & std
                    agg_overall = combine(groupby_timestamp) do sdf
                        meanval = mean(sdf[!, colname])
                        stdval  = std(sdf[!, colname])
                        (overall_mean = meanval, overall_std = stdval)
                    end

                    rename!(agg_overall, :overall_mean => "$(colname)_overall_mean")
                    rename!(agg_overall, :overall_std  => "$(colname)_overall_std")

                    # lower 10%
                    agg_lower = combine(groupby_timestamp) do sdf
                        # filter by 10th quantile
                        cutoff = quantile(sdf[!, colname], 0.1)
                        subvals = sdf[findall(x->x<=cutoff, sdf[!, colname]), colname]
                        if isempty(subvals)
                            (lower_mean = missing,)
                        else
                            (lower_mean = mean(subvals),)
                        end
                    end
                    rename!(agg_lower, :lower_mean => "$(colname)_lower_mean")

                    # upper 10%
                    agg_upper = combine(groupby_timestamp) do sdf
                        cutoff = quantile(sdf[!, colname], 0.9)
                        subvals = sdf[findall(x->x>=cutoff, sdf[!, colname]), colname]
                        if isempty(subvals)
                            (upper_mean = missing,)
                        else
                            (upper_mean = mean(subvals),)
                        end
                    end
                    rename!(agg_upper, :upper_mean => "$(colname)_upper_mean")

                    # merge them
                    merged_temp = innerjoin(agg_overall, agg_lower, on=:timestamp)
                    merged_temp = innerjoin(merged_temp, agg_upper, on=:timestamp)

                    # combine all stats side by side
                    if ncol(combined_stats) == 0
                        combined_stats = merged_temp
                    else
                        combined_stats = innerjoin(combined_stats, merged_temp, on=:timestamp)
                    end
                end

                push!(df_models_experiment, combined_stats)
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
    visualize_2d_graph(num_rows, num_cols, column_name, dataframes, name; false)

    Create a grid of subplots (num_rows x num_cols) and plot the mean + 95% CI 
    for `column_name` from each DataFrame in `dataframes` (a Dict). 
    Saves the figure in a "graphs/" folder inside PATH.
    """
    function visualize_2d_graph(num_rows::Int, num_cols::Int, column_name::String, 
                                dataframes::Dict, name::String, no_subfolder::Bool=false, keys::Vector{String}=FOLDERS)
        # We'll create a single plot with a layout
        plt = plot(layout=(num_rows, num_cols), size=(num_cols*700, num_rows*700), dpi=200)

        plot_index = 1
        # We'll loop over each key (folder or seed)
        for key in keys
            if plot_index > num_rows * num_cols
                break
            end
            df = dataframes[key]
            # Filter in case we want to focus on only some part
            filter!(row -> (row[:timestamp] >= HH_STEP_START && row[:timestamp] <= HH_STEP_END), df)

            # If df is empty or does not contain the column, skip
            if nrow(df) == 0 || !(column_name in names(df))
                plot!(plt[plot_index], legend=false)
                continue
            end
    
            grouped_df = groupby(df, :timestamp)

            # compute mean, count, std
            stats_df = combine(grouped_df) do sdf
                m = mean((sdf[!, column_name]))
                c = length((sdf[!, column_name]))
                s = std((sdf[!, column_name]))
                (mean = m, count = c, std = s)
            end
            # compute sem and 95% CI
            stats_df."sem" = stats_df."std" ./ sqrt.(stats_df."count")
            ci95 = 1.96 .* stats_df."sem"

            ymean = stats_df."mean"
            xvals = stats_df."timestamp"
            lower = ymean .- ci95
            upper = ymean .+ ci95

            # We use `ribbon` in a single call:
            plot!(plt[plot_index],
                xvals, ymean,
                ribbon = ci95,
                label  = "Mean ± 95% CI",
                color  = :blue,
                fillalpha = 0.3,
                legend = :topright)
            
            # Title, axes
            plot!(plt[plot_index], title = key,
                xlabel = "Timestamp", ylabel = "Mean $column_name")

            # If the column is "all_Sust_Score" or "all_Sust_Uncert", clamp y axis to [0,1]
            if column_name in ["all_Sust_Score", "all_Sust_Uncert"]
                ylims!(plt[plot_index], (0, 1))
            end

            plot_index += 1
        end
        # Annotate is not working for some reason

        # Decide folder to save
        if no_subfolder
            graph_path = joinpath(PATH, "graphs")
        else
            graph_path = joinpath(PATH, "graphs", name)
        end
        # Make sure it exists
        mkpath(graph_path)

        outpath = joinpath(graph_path, "$name $column_name.png")
        savefig(plt, outpath)
    end

end

###############################################################################
#  Main Execution / Script Flow
###############################################################################


# Compare different parameters using seeds for CI, model-level
@distributed for col_name in MODEL_LEVEL_COLS
    dataframes_model_ci = get_df_seed_for_ci_model(PATH, "model.csv")
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], col_name, dataframes_model_ci, "model ci ", true)
end


# Compare different parameters using seeds for CI, producer-level
@distributed for col_name in colnames_cp_agg
    dataframes_cp_ci = get_df_seed_for_ci_producer(PATH, "cp_firm.csv", colnames_cp)
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], col_name, dataframes_cp_ci, "cp ci ", true)
end


# Compare results for each Seed
@distributed for seed in SEEDS
    dataframes_cp_seeds = get_df_same_seed(PATH, "cp_firm.csv", seed)
    for col_name in colnames_cp
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], col_name, dataframes_cp_seeds, string(seed))
    end
    dataframes_model_seeds = get_df_same_seed(PATH, "model.csv", seed)
    for col_name in MODEL_LEVEL_COLS
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], col_name, dataframes_model_seeds, string(seed))
    end
end


# Compare results for each Folder (Parameter set)
@distributed for folder in FOLDERS
    dataframes_cp_folders = get_df_diff_seed(PATH, "cp_firm.csv", folder)
    for col_name in colnames_cp
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], col_name, dataframes_cp_folders, folder, false, SEEDS)
    end
    dataframes_model_folders = get_df_diff_seed(PATH, "model.csv", folder)
    for col_name in MODEL_LEVEL_COLS
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], col_name, dataframes_model_folders, folder, false, SEEDS)
    end
end
