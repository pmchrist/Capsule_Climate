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
    using StatsPlots

    ###############################################################################
    #  Parameters & Global Variables
    ###############################################################################
    # Adjust these as needed
    const PATH                = joinpath(@__DIR__, "data_saved", "data") # Folder structure root
    const HH_STEP_START       = 200
    const HH_STEP_END         = 900

    SEEDS = [9937590, 9494897, 408387, 169105, 6612768, 9827382, 592810, 1826964, 524941, 5111625, 3580871, 7379769, 2411994,
    1250345, 1200648, 8623226, 6739373, 7707222, 9076351, 5616723, 5147647, 8676955, 9216682, 6743063]
    SEEDS = string.(SEEDS)

    const FOLDERS = [
            "alpha=0.0 beta=0.0 p_f=0.36 t_c=0.0",
            "alpha=0.0 beta=0.0 p_f=0.39 t_c=0.0",
            "alpha=0.0 beta=0.0 p_f=0.4 t_c=0.0",
            "alpha=0.0 beta=0.0 p_f=0.41 t_c=0.0",
            "alpha=0.0 beta=0.0 p_f=0.44 t_c=0.0",

            "alpha=1.0 beta=1.0 p_f=0.36 t_c=0.0",
            "alpha=1.0 beta=1.0 p_f=0.39 t_c=0.0",
            "alpha=1.0 beta=1.0 p_f=0.4 t_c=0.0",
            "alpha=1.0 beta=1.0 p_f=0.41 t_c=0.0",
            "alpha=1.0 beta=1.0 p_f=0.44 t_c=0.0",

            "alpha=2.0 beta=2.0 p_f=0.36 t_c=0.0",
            "alpha=2.0 beta=2.0 p_f=0.39 t_c=0.0",
            "alpha=2.0 beta=2.0 p_f=0.4 t_c=0.0",
            "alpha=2.0 beta=2.0 p_f=0.41 t_c=0.0",
            "alpha=2.0 beta=2.0 p_f=0.44 t_c=0.0",

            "alpha=4.0 beta=4.0 p_f=0.36 t_c=0.0",
            "alpha=4.0 beta=4.0 p_f=0.39 t_c=0.0",
            "alpha=4.0 beta=4.0 p_f=0.4 t_c=0.0",
            "alpha=4.0 beta=4.0 p_f=0.41 t_c=0.0",
            "alpha=4.0 beta=4.0 p_f=0.44 t_c=0.0",

            "alpha=0.4 beta=0.4 p_f=0.36 t_c=0.0",
            "alpha=0.4 beta=0.4 p_f=0.39 t_c=0.0",
            "alpha=0.4 beta=0.4 p_f=0.4 t_c=0.0",
            "alpha=0.4 beta=0.4 p_f=0.41 t_c=0.0",
            "alpha=0.4 beta=0.4 p_f=0.44 t_c=0.0",

            "alpha=0.8 beta=0.8 p_f=0.36 t_c=0.0",
            "alpha=0.8 beta=0.8 p_f=0.39 t_c=0.0",
            "alpha=0.8 beta=0.8 p_f=0.4 t_c=0.0",
            "alpha=0.8 beta=0.8 p_f=0.41 t_c=0.0",
            "alpha=0.8 beta=0.8 p_f=0.44 t_c=0.0",

            "alpha=0.8 beta=1.0 p_f=0.36 t_c=0.0",
            "alpha=0.8 beta=1.0 p_f=0.39 t_c=0.0",
            "alpha=0.8 beta=1.0 p_f=0.4 t_c=0.0",
            "alpha=0.8 beta=1.0 p_f=0.41 t_c=0.0",
            "alpha=0.8 beta=1.0 p_f=0.44 t_c=0.0",

            "alpha=2.0 beta=4.0 p_f=0.36 t_c=0.0",
            "alpha=2.0 beta=4.0 p_f=0.39 t_c=0.0",
            "alpha=2.0 beta=4.0 p_f=0.4 t_c=0.0",
            "alpha=2.0 beta=4.0 p_f=0.41 t_c=0.0",
            "alpha=2.0 beta=4.0 p_f=0.44 t_c=0.0",

            "alpha=1.0 beta=0.8 p_f=0.36 t_c=0.0",
            "alpha=1.0 beta=0.8 p_f=0.39 t_c=0.0",
            "alpha=1.0 beta=0.8 p_f=0.4 t_c=0.0",
            "alpha=1.0 beta=0.8 p_f=0.41 t_c=0.0",
            "alpha=1.0 beta=0.8 p_f=0.44 t_c=0.0",
    
            "alpha=4.0 beta=2.0 p_f=0.36 t_c=0.0",
            "alpha=4.0 beta=2.0 p_f=0.39 t_c=0.0",
            "alpha=4.0 beta=2.0 p_f=0.4 t_c=0.0",
            "alpha=4.0 beta=2.0 p_f=0.41 t_c=0.0",
            "alpha=4.0 beta=2.0 p_f=0.44 t_c=0.0",
    ]

    """
    get_df_seed_for_ci_model(main_folder, looking_for) -> Dict{String, DataFrame}

    Gathers model-level data (e.g., "model.csv") across multiple seeds for each folder 
    in FOLDERS, concatenates, and returns a Dict {folder => DataFrame}.
    Filters data to timesteps in [HH_STEP_START, HH_STEP_END].

    TODO: No need to drag all the unused columns, just keep the necessary ones
    """
    function get_df_seed_for_boxplot_model_end(main_folder::String, looking_for::String, target_p_f::String)

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
                        replace!(df."carbon_emissions_cp_proportion", NaN => 0)
                        replace!(df."carbon_emissions_ep_proportion", NaN => 0)
                        replace!(df."carbon_emissions_kp_proportion", NaN => 0)
                        replace!(df."carbon_emissions_per_GDP", NaN => 0)
                    end
                    df[:, :seed] .= seed
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


end

###############################################################################
#  Main Execution / Script Flow
###############################################################################


#vars_to_plot = ["em_index", "em_index_cp", "em_index_kp", "em_index_ep", "em_index_cp_good_avg", "em_index_cp_good_var", "GDP", "U", "bankrupt_cp", "carbon_emissions", "avg_pi_EE", "avg_pi_EF", "GINI_W", "GDP_hh", "green_capacity", "unsat_demand", "unspend_C"]

# FOLDERS VARIABLE CONTAINS ALL THE KEYS IN THE DF VARIABLE RETURNED


@everywhere begin

vars_to_plot = ["carbon_emissions", "avg_pi_EE", "avg_pi_EF", "avg_pi_LP", "green_capacity", "dirty_capacity", "GDP", "carbon_emissions_per_GDP", "carbon_emissions_cp"]      # THESE ARE COLUMNS OF INTEREST IN DF
p_f_to_plot = ["p_f=0.36 ", "p_f=0.39 ", "p_f=0.4 ", "p_f=0.41 ", "p_f=0.44 "]

"""

Combines all the repetitions with different runs to the corresponding columns in the dataframe, accessible by the dictionary with the name of experiment

"""
function get_df_seed_for_heatmap_model_end(p_f_to_plot::Array)


    combined_dict = Dict{String, DataFrame}()

    for p_f_val in p_f_to_plot
        dct = get_df_seed_for_boxplot_model_end(PATH, "model.csv", p_f_val)
        merge!(combined_dict, dct)  # merge! adds/overwrites keys from dct into combined_dict
    end

    return combined_dict

end



function comparative_heatmap(experiments_dict::Dict, p_f_to_plot::Array, target_var::String)

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
    M = reduce(hcat, means)'   # now a 3×3 matrix
    V = reduce(hcat, vars)'    # same dimensions

    default(size = (2000,1000), dpi = 200)

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

    # overlay annotations: “mean ± var”
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

combined_dict = get_df_seed_for_heatmap_model_end(p_f_to_plot)
println("Combined Data")
@distributed for target_var in vars_to_plot
    comparative_heatmap(combined_dict, p_f_to_plot, target_var)
end
println("Visualized Data")


