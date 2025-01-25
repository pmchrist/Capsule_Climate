# To Do :
# Improve Font Sizes, Changes axis names to be only on the left, change image res etc.
# Add Cut Off for x axis on Timesteps
# Investigate the error
# Transfer other variables here too for visualization


#!/usr/bin/env julia


###############################################################################
#  Load Packages
###############################################################################
using CSV
using DataFrames
using Statistics
using StatsBase
using Plots
using FileIO
using Printf
using Random
using Distributed

###############################################################################
#  Parameters & Global Variables
###############################################################################
# Adjust these as needed
const PATH                 = joinpath(pwd(), "results", "data_saved", "data") # Folder structure root
const PROCESS_HH_TIMESERIES = false  # Same as Python's toggle
const COMBINE_HH_TIMESERIES = false  # Same as Python's toggle
const HH_STEP_START       = 300
const HH_STEP_END         = 660
const SEEDS = [47816, 933015, 321434, 447288, 153725, 260147, 589087, 108127, 159454, 
               176074, 426699, 46634, 822959, 514704, 9694, 673314, 257546, 798460, 
               413516, 550286]

# # Example experiment subfolders:
# const FOLDERS = [
#     "alpha=2 beta=2 p_f=0.2 id=1",
#     "alpha=2 beta=2 p_f=0.4 id=5",
#     "alpha=2 beta=2 p_f=0.6 id=9",
#     "alpha=2 beta=24 p_f=0.2 id=3",
#     "alpha=2 beta=24 p_f=0.4 id=7",
#     "alpha=2 beta=24 p_f=0.6 id=11",
#     "alpha=24 beta=2 p_f=0.2 id=2",
#     "alpha=24 beta=2 p_f=0.4 id=6",
#     "alpha=24 beta=2 p_f=0.6 id=10",
#     "alpha=24 beta=24 p_f=0.2 id=4",
#     "alpha=24 beta=24 p_f=0.4 id=8",
#     "alpha=24 beta=24 p_f=0.6 id=12"
# ]
# # Subplot grid sizes
# const GRAPH_SIZE_DIFF_PARAM = (4, 3)
# const GRAPH_SIZE_DIFF_SEED  = (4, 5)


const FOLDERS = [
        "p_f=0.2 id=1",
        "p_f=0.4 id=2",
        "p_f=0.6 id=3"
]
# Subplot grid sizes
const GRAPH_SIZE_DIFF_PARAM = (1, 3)
const GRAPH_SIZE_DIFF_SEED  = (4, 5)

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
                    println("Processed ", subfolder, " seed=", seed)
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
function get_df_same_seed(main_folder::String, looking_for::String, seed::Int)
    dataframes = Dict{String, DataFrame}()

    for (root, dirs, files) in walkdir(main_folder)
        file_path = joinpath(root, "$seed $looking_for")
        if isfile(file_path)
            df = CSV.read(file_path, DataFrame)

            if looking_for == "model.csv"
                df."timestamp" = 1:nrow(df)
            end

            dataframes[root] = df
        end
    end

    return dataframes
end

"""
    get_df_diff_seed(main_folder, looking_for, folder) -> Dict{Int, DataFrame}

Traverse `main_folder` to find a specific `folder`, and read 
`"<seed> looking_for"` for each seed. 
Return a dictionary of DataFrames keyed by the seed.
- If `looking_for == "model.csv"`, add a `timestamp` column.
"""
function get_df_diff_seed(main_folder::String, looking_for::String, folder::String)
    dataframes = Dict{Int, DataFrame}()

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
    dataframes = Dict{String, DataFrame}()

    for folder in FOLDERS
        folder_path = joinpath(main_folder, folder)
        println(folder_path)
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
                filter!(row -> (row[:timestamp] >= HH_STEP_START && row[:timestamp] <= HH_STEP_END), df)
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
    visualize_2d_graph(num_rows, num_cols, column_name, dataframes, name; no_subfolder=false)

Create a grid of subplots (num_rows x num_cols) and plot the mean + 95% CI 
for `column_name` from each DataFrame in `dataframes` (a Dict). 
Saves the figure in a "graphs/" folder inside PATH.
"""
function visualize_2d_graph(num_rows::Int, num_cols::Int, column_name::String, 
                            dataframes::Dict, name::String; no_subfolder::Bool=false)
    # We'll create a single plot with a layout
    plt = plot(layout=(num_rows, num_cols), size=(1200, 900))
    keys_arr = collect(keys(dataframes))
    nkeys = length(keys_arr)

    plot_index = 1
    # We'll loop over each key (folder or seed)
    for i in 1:nkeys
        if plot_index > num_rows * num_cols
            break
        end
        key_ = keys_arr[i]
        df = dataframes[key_]

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
        plot!(plt[plot_index], title = string(key_),
              xlabel = "Timestamp", ylabel = "Mean $(column_name)")

        # If the column is "all_Sust_Score" or "all_Sust_Uncert", clamp y axis to [0,1]
        if column_name in ["all_Sust_Score", "all_Sust_Uncert"]
            ylims!(plt[plot_index], (0,1))
        end

        plot_index += 1
    end

    # final layout
    suptitle = column_name
    # adjust layout is automatic in Plots

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

###############################################################################
#  Main Execution / Script Flow
###############################################################################

# 1) Optionally combine HH timeseries
if COMBINE_HH_TIMESERIES
    combine_and_save_dataframes_hh(PATH)
end

println("model gloval")
# 2) Compare different parameters using seeds for CI, model-level
dataframes_model_ci = get_df_seed_for_ci_model(PATH, "model.csv")
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "green_capacity", dataframes_model_ci, "model ci green_capacity", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "dirty_capacity", dataframes_model_ci, "model ci dirty_capacity", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "GDP", dataframes_model_ci, "model ci GDP", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "s_unemp", dataframes_model_ci, "model ci s_unemp", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "bankrupt_cp", dataframes_model_ci, "model ci bankrupt_cp", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "bankrupt_kp", dataframes_model_ci, "model ci bankrupt_kp", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "sust_mean_all", dataframes_model_ci, "sust opinion mean overall", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "sust_mean_10", dataframes_model_ci, "sust opinion mean lower 10th q", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "sust_mean_100", dataframes_model_ci, "sust opinion mean upper 10th q", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "GINI_I", dataframes_model_ci, "model ci GINI_I", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "GINI_W", dataframes_model_ci, "model ci GINI_W", no_subfolder=true)
# ... and so on for all other model-level columns you want to visualize

println("cp gloval")

# 3) Compare different parameters using seeds for CI, producer-level
colnames_cp = ["Good_Emiss", "Good_Markup_mu", "Good_Prod_Q"]
dataframes_cp_ci = get_df_seed_for_ci_producer(PATH, "cp_firm.csv", colnames_cp)

# Good_Emiss
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Emiss_overall_mean", dataframes_cp_ci, "cp ci Good_Emiss", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Emiss_lower_mean",   dataframes_cp_ci, "cp ci Good_Emiss", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Emiss_upper_mean",   dataframes_cp_ci, "cp ci Good_Emiss", no_subfolder=true)
# Good_Markup_mu
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Markup_mu_overall_mean", dataframes_cp_ci, "cp ci Good_Markup_mu", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Markup_mu_lower_mean",   dataframes_cp_ci, "cp ci Good_Markup_mu", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Markup_mu_upper_mean",   dataframes_cp_ci, "cp ci Good_Markup_mu", no_subfolder=true)
# Good_Prod_Q
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Prod_Q_overall_mean", dataframes_cp_ci, "cp ci Good_Prod_Q", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Prod_Q_lower_mean",   dataframes_cp_ci, "cp ci Good_Prod_Q", no_subfolder=true)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Prod_Q_upper_mean",   dataframes_cp_ci, "cp ci Good_Prod_Q", no_subfolder=true)

# 4) Compare Different Parameters, same Seed
if PROCESS_HH_TIMESERIES
    for seed in SEEDS
        dataframes_hh = get_df_same_seed(PATH, "simple_hh.csv", seed)
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "all_Sust_Score", dataframes_hh, string(seed))
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "all_Sust_Uncert", dataframes_hh, string(seed))
    end
end

println("seed")
@distributed for seed in SEEDS
    println("cp")
    dataframes_cp = get_df_same_seed(PATH, "cp_firm.csv", seed)
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Emiss", dataframes_cp, string(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Good_Prod_Q", dataframes_cp, string(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "Profits", dataframes_cp, string(seed))
    
    println("model")
    dataframes_model = get_df_same_seed(PATH, "model.csv", seed)
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "green_capacity", dataframes_model, string(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "GDP", dataframes_model, string(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[1], GRAPH_SIZE_DIFF_PARAM[2], "s_unemp", dataframes_model, string(seed))
    # ... more model-level columns as in your Python code ...
end

# 5) Compare Different Seeds, same Parameters
if PROCESS_HH_TIMESERIES
    for folder in FOLDERS
        dataframes_hh = get_df_diff_seed(PATH, "simple_hh.csv", folder)
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "all_Sust_Score", dataframes_hh, folder)
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "all_Sust_Uncert", dataframes_hh, folder)
    end
end

println("folder")
@distributed for folder in FOLDERS
    dataframes_cp = get_df_diff_seed(PATH, "cp_firm.csv", folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "Good_Emiss", dataframes_cp, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "Good_Prod_Q", dataframes_cp, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "Profits", dataframes_cp, folder)

    dataframes_model = get_df_diff_seed(PATH, "model.csv", folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "green_capacity", dataframes_model, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "GDP", dataframes_model, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "s_unemp", dataframes_model, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "bankrupt_cp", dataframes_model, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[1], GRAPH_SIZE_DIFF_SEED[2], "bankrupt_kp", dataframes_model, folder)
    # ... more model-level columns as in your Python code ...
end

println("Analysis complete.")


