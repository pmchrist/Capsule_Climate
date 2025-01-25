
# HH
# all_Sust_Score
# all_Sust_Uncert

# CP
# Good_Emiss
# Good_Prod_Q
# Profits
# age
# size

# Model
# Qmax_ep               # Overall Energy
# green_capacity        # Overall Green Energy
# carbon_emissions      # Overall Emissions
# GDP
# s_unemp               # Unemployed
# switch_rate           # Work place changes


import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

PATH = os.path.join(os.path.curdir, 'results', 'data_saved', 'data')      # Replace folder name here
main_folder = PATH
PROCESS_HH_TIMESERIES = False
COMBINE_HH_TIMESERIES = False
HH_STEP_START = 500
HH_STEP_END = 660
SEEDS = [47816, 933015, 321434, 447288, 153725, 260147, 589087, 108127, 159454, 176074, 426699, 46634, 822959, 514704, 9694, 673314, 257546, 798460, 413516, 550286]
#SEEDS = [0, 17233, 378620, 692243, 938730]
#FOLDERS = ["alpha=2 beta=2 id=1", "alpha=2 beta=8 id=4", "alpha=2 beta=24 id=7", "alpha=8 beta=2 id=2", "alpha=8 beta=8 id=5", "alpha=8 beta=24 id=8", "alpha=24 beta=2 id=3", "alpha=24 beta=8 id=6", "alpha=24 beta=24 id=9"]

# With opinion experiment
FOLDERS = ["alpha=2 beta=2 p_f=0.2 id=1",
           "alpha=2 beta=2 p_f=0.4 id=5",
           "alpha=2 beta=2 p_f=0.6 id=9",
           "alpha=2 beta=24 p_f=0.2 id=3",
           "alpha=2 beta=24 p_f=0.4 id=7",
           "alpha=2 beta=24 p_f=0.6 id=11",
           "alpha=24 beta=2 p_f=0.2 id=2",
           "alpha=24 beta=2 p_f=0.4 id=6",
           "alpha=24 beta=2 p_f=0.6 id=10",
           "alpha=24 beta=24 p_f=0.2 id=4",
           "alpha=24 beta=24 p_f=0.4 id=8",
           "alpha=24 beta=24 p_f=0.6 id=12"]
GRAPH_SIZE_DIFF_PARAM = [4,3]
GRAPH_SIZE_DIFF_SEED = [4,5]


# # Without opinion experiment
# FOLDERS = ["p_f=0.2 id=1",
#            "p_f=0.4 id=2",
#            "p_f=0.6 id=3"]
# GRAPH_SIZE_DIFF_PARAM = [1,3]
# GRAPH_SIZE_DIFF_SEED = [4,5]


def combine_and_save_dataframes_hh(main_folder):
    """
    Used to combine outputs of different hh into one df from the simulations
    """
    hh_fields = ['hh_id', 'all_Sust_Score', 'all_Sust_Uncert']      # We have to read only few columns to save time
    timestamp_range = range(HH_STEP_START, HH_STEP_END)             # Change appropriately for the visualization of simulation range (warmup-finish)

    # Traverse through all subfolders in the main "data" folder
    for root, subfolders, _ in os.walk(main_folder):
        for subfolder in subfolders:
            folder_path = os.path.join(root, subfolder)

            for seed in SEEDS:
                df_hh_list = []

                x_hh_folder = os.path.join(folder_path, f"{seed} x_hh")
                # Skip if the folder doesn't exist
                if not os.path.exists(x_hh_folder):
                    continue
                
                for timestamp in timestamp_range:
                    file_path = os.path.join(x_hh_folder, f'household_{timestamp}_hh.csv')
                    df = pd.read_csv(file_path, skipinitialspace=True, usecols=hh_fields)
                    df['timestamp'] = timestamp
                    df_hh_list.append(df)

                final_df = pd.concat(df_hh_list, ignore_index=True)
                output_path = os.path.join(folder_path, str(seed) + " simple_hh.csv")
                final_df.to_csv(output_path, index=False)

                print("Processed ", subfolder)

# To check across parameters
def get_df_same_seed(main_folder, looking_for, seed):
    """
    Reads CSV from Experiment and Returns multiple DataFrames corresponding to each set of Parameters tested, given the seed.

    This method is used to compare Parameters across multiple Same Seed Runs.    
    
    """
    dataframes = {}     # All the Dataframes for the target type of Agent (or whole Model) per experiment with each seed

    # Walk through all directories and look for proper files
    for folder_name, _, _ in os.walk(main_folder):
        file_path = os.path.join(folder_name, str(seed) + ' ' + looking_for)
        
        # Skip if the file doesn't exist
        if not os.path.exists(file_path):
            continue

        # Read the CSV file into a DataFrame and assign it to the folder name in the dictionary
        df = pd.read_csv(file_path)

        # Model csv output does not have timesteps, so we have to add timestep manually (each line is a timestep)
        if looking_for == "model.csv":
            df['timestamp'] = pd.Series(range(1, len(df) + 1))

        dataframes[folder_name] = df

    return dataframes

# To check across seeds
def get_df_diff_seed(main_folder, looking_for, folder):
    """
    Reads CSV from Experiment and Returns multiple DataFrames corresponding to one set of Parameters with varying seed.

    This method is used to result of different seeds for the same set of Parameters.  
    
    """
    dataframes = {}     # All the Dataframes for the target type of Agent (or whole Model) per experiment with each seed

    # Walk through all directories and look for proper files
    for folder_name, a, _ in os.walk(main_folder):

        if folder_name != os.path.join(main_folder, folder):
            continue
        
        for seed in SEEDS:
            file_path = os.path.join(folder_name, str(seed) + ' ' + looking_for)
            
            # Skip if the file doesn't exist
            if not os.path.exists(file_path):
                continue

            # Read the CSV file into a DataFrame and assign it to the folder name in the dictionary
            df = pd.read_csv(file_path)

            # Model csv output does not have timesteps, so we have to add timestep manually (each line is a timestep)
            if looking_for == "model.csv":
                df['timestamp'] = pd.Series(range(1, len(df) + 1))

            dataframes[seed] = df

    return dataframes

# To check across experiments for model level results
def get_df_seed_for_ci_model(main_folder, looking_for):
    """
    Used for combining outputs of different runs (different seeds) for the model parameters into one, to obtain the CI.
    
    """
    dataframes = {}     # All the Dataframes for the target type of Agent (or whole Model) per experiment with each seed

    # Walk through all directories and look for proper files
    for folder in FOLDERS:
        for folder_name, _, _ in os.walk(main_folder):      # just tries all the folders until a target one for the experiment is found

            if folder_name != os.path.join(main_folder, folder):
                continue

            df_models_experiment = []
            for seed in SEEDS:
                file_path = os.path.join(folder_name, str(seed) + ' ' + looking_for)
                
                # Skip if the file doesn't exist
                if not os.path.exists(file_path):
                    continue

                # Read the CSV file into a DataFrame and assign it to the folder name in the dictionary
                df = pd.read_csv(file_path)

                # Model csv output does not have timesteps, so we have to add timestep manually (each line is a timestep)
                if looking_for == "model.csv":                                  # We can only look for this one in this case
                    df['timestamp'] = pd.Series(range(1, len(df) + 1))
                df = df[(df['timestamp'] >= HH_STEP_START) & (df['timestamp'] <= HH_STEP_END)]

                df_models_experiment.append(df)
            
        dataframes[folder] = pd.concat(df_models_experiment, ignore_index=True)

    return dataframes


def get_df_seed_for_ci_producer(main_folder, looking_for, column_names):

    # Just like the same as ci_model

    # Gather all the dfs but instead of just combining them we calculate the aggregate metrics and combine them and then combine
    # Experiment -> For Each seed together ->
    # Get aggregate stats (mean of emiss per product for each timestep across all companies) and save into new df ->
    # aggregate all dfs and return dfs the same way as for ci_model for vuisualization

    dataframes = {}     # All the Dataframes for the target type of Agent (or whole Model) per experiment with each seed

    # Walk through all directories and look for proper files
    for folder in FOLDERS:
        for folder_name, _, _ in os.walk(main_folder):      # just tries all the folders until a target one for the experiment is found

            if folder_name != os.path.join(main_folder, folder):
                continue

            df_models_experiment = []
            for seed in SEEDS:
                file_path = os.path.join(folder_name, str(seed) + ' ' + looking_for)
                
                # Skip if the file doesn't exist
                if not os.path.exists(file_path):
                    continue

                # Read the CSV file into a DataFrame and assign it to the folder name in the dictionary
                df = pd.read_csv(file_path)
                df = df[(df['timestamp'] >= HH_STEP_START) & (df['timestamp'] <= HH_STEP_END)]

                # Here we aggregate data in the new dataframe for the meta variables

                combined_stats = pd.DataFrame()
                for column_name in column_names:
                    # Group by timestamp and aggregate the column
                    grouped_overall = (
                        df.groupby("timestamp")[column_name]
                        .agg(overall_mean='mean', overall_std='std')
                        .rename(columns={'overall_mean': f'{column_name}_overall_mean', 'overall_std': f'{column_name}_overall_std'})
                    )
                    # Group by timestamp and calculate the desired statistics for upper and lower 10th quantiles
                    grouped_lower = (
                        df.groupby("timestamp")[column_name]
                        .apply(lambda group: group[group <= group.quantile(0.1)])           # QUANTILES ARE HARDCODED FOR NOW
                        .groupby("timestamp")
                        .agg(lower_mean=('mean'))
                        .rename(columns={'lower_mean': f'{column_name}_lower_mean'})
                    )
                    grouped_upper = (
                        df.groupby("timestamp")[column_name]
                        .apply(lambda group: group[group >= group.quantile(0.9)])
                        .groupby("timestamp")
                        .agg(upper_mean=('mean'))
                        .rename(columns={'upper_mean': f'{column_name}_upper_mean'})
                    )
                    # Concatenate the stats for the current column along the columns axis
                    stats_for_column = pd.concat([grouped_overall, grouped_lower, grouped_upper], axis=1)

                    # Concatenate into the combined_stats dataframe, aligning on the index
                    combined_stats = pd.concat([combined_stats, stats_for_column], axis=1)        

                combined_stats = combined_stats.reset_index()
                df_models_experiment.append(combined_stats)
            
        dataframes[folder] = pd.concat(df_models_experiment, ignore_index=True)

    return dataframes


def visualize_2d_graph(num_rows, num_cols, column_name, dataframes, name, no_subfolder=False):
    """
    Visualizes a 2D grid of graphs.
    num_rows and num_cols specify the visualization grid size.
    column_name specifies the column to visualize.
    dataframes is a dictionary where each key is the folder name and value is the DataFrame.
    name specifies the output graph name.
    """

    fig, axes = plt.subplots(nrows=num_rows, ncols=num_cols, figsize=(20, 15))

    # Ensure axes is a 2D array, even if num_rows or num_cols is 1
    if num_rows == 1 and num_cols == 1:
        axes = np.array([[axes]])
    elif num_rows == 1 or num_cols == 1:
        axes = np.expand_dims(axes, axis=0 if num_rows == 1 else 1)

    dataframe_items = list(dataframes.items())
    plot_index = 0

    for row in range(num_rows):
        for col in range(num_cols):
            # Ensure we don't go out of bounds of the provided data
            if plot_index >= len(dataframe_items):
                axes[row, col].axis('off')  # Hide unused subplots
                continue

            folder, df = dataframe_items[plot_index]

            # Group by timestamp and aggregate the column
            df = df[(df['timestamp'] >= HH_STEP_START) & (df['timestamp'] <= HH_STEP_END)]
            grouped = df.groupby("timestamp")[column_name].agg(['mean', 'count', 'std'])

            # Calculate confidence interval
            grouped['sem'] = grouped['std'] / np.sqrt(grouped['count'])  # Standard error
            ci95 = 1.96 * grouped['sem']  # 95% confidence interval

            # Plot the mean line
            axes[row, col].plot(grouped.index, grouped['mean'], label='Mean', color='blue')

            # Fill between the confidence intervals
            axes[row, col].fill_between(grouped.index, grouped['mean'] - ci95, grouped['mean'] + ci95,
                                        color='lightblue', alpha=0.5, label='95% CI')

            # Set titles and labels
            axes[row, col].set_title(f"{folder}")
            axes[row, col].set_xlabel('Timestamp')
            axes[row, col].set_ylabel('Mean')
            if column_name in ["all_Sust_Score", "all_Sust_Uncert"]:
                axes[row, col].set_ylim([0, 1])

            plot_index += 1

    # Hide any unused subplots in the grid
    for idx in range(plot_index, num_rows * num_cols):
        row, col = divmod(idx, num_cols)
        axes[row, col].axis('off')

    # Adjust layout and save the figure
    plt.suptitle(column_name)
    plt.tight_layout()

    # Define the path
    if no_subfolder:
        path = os.path.join(PATH, "graphs")  # Adjusted for example, replace with your PATH variable
    else:
        path = os.path.join(PATH, "graphs", str(name))  # Adjusted for example, replace with your PATH variable

    os.makedirs(path, exist_ok=True)
    plt.savefig(os.path.join(path, name + ' ' + column_name + ".png"), dpi=300)
    plt.close()




# Combine HH dataframes into one with only necessary information
if COMBINE_HH_TIMESERIES: combine_and_save_dataframes_hh(main_folder)        # Make it to check if file exists, instead of manual change


# Compare different parameters and use seeds for CI

# Model
dataframes = get_df_seed_for_ci_model(main_folder, "model.csv")
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "green_capacity", dataframes, "model ci green_capacity", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "dirty_capacity", dataframes, "model ci dirty_capacity", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "GDP", dataframes, "model ci GDP", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "s_unemp", dataframes, "model ci s_unemp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_cp", dataframes, "model ci bankrupt_cp", no_subfolder=True)     # <- explicit bankr rate
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_kp", dataframes, "model ci bankrupt_kp", no_subfolder=True)     # <- explicit bankr rateer)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_all", dataframes, "sust opinion mean overall", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_10", dataframes, "sust opinion mean lower 10th q", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_100", dataframes, "sust opinion mean upper 10th q", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "GINI_I", dataframes, "model ci GINI_I", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "GINI_W", dataframes, "model ci GINI_W", no_subfolder=True)
# More for debugging
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "LIS", dataframes, "model ci LIS", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M", dataframes, "model ci M", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_gov", dataframes, "model ci M_gov", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_hh", dataframes, "model ci M_hh", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_cp", dataframes, "model ci M_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "N_goods", dataframes, "model ci N_goods", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_N_goods", dataframes, "model ci avg_N_goods", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unspend_C", dataframes, "model ci unspend_C", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_L_demand", dataframes, "model ci unsat_L_demand", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_invest", dataframes, "model ci unsat_invest", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_demand", dataframes, "model ci unsat_demand", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "CPI_cp", dataframes, "model ci CPI_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "CPI_kp", dataframes, "model ci CPI_kp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "markup_cp", dataframes, "model ci markup_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "p_avg_cp", dataframes, "model ci p_avg_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "returns_investments", dataframes, "model ci returns_investments", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_C", dataframes, "model ci total_C", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_C_actual", dataframes, "model ci total_C_actual", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_I", dataframes, "model ci total_I", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_w", dataframes, "model ci total_w", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_tot", dataframes, "model ci debt_tot", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_cp", dataframes, "model ci debt_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_unpaid_cp", dataframes, "model ci debt_unpaid_cp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "RD_total", dataframes, "model ci RD_total", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "EI_avg", dataframes, "model ci EI_avg", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "RS_avg", dataframes, "model ci RS_avg", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_LP", dataframes, "model ci avg_pi_LP", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_EE", dataframes, "model ci avg_pi_EE", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_EF", dataframes, "model ci avg_pi_EF", no_subfolder=True)


# CP
# For now we are not loking for KP, only CP: Good_Markup_mu, Good_Prod_Q, Good_Emiss (markup and prod_q is also avaialable in model)
dataframes = get_df_seed_for_ci_producer(main_folder, "cp_firm.csv", ["Good_Emiss", "Good_Markup_mu", "Good_Prod_Q"])
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Emiss_overall_mean", dataframes, "cp ci Good_Emiss", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Emiss_lower_mean", dataframes, "cp ci Good_Emiss", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Emiss_upper_mean", dataframes, "cp ci Good_Emiss", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Markup_mu_overall_mean", dataframes, "cp ci Good_Markup_mu", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Markup_mu_lower_mean", dataframes, "cp ci Good_Markup_mu", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Markup_mu_upper_mean", dataframes, "cp ci Good_Markup_mu", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Prod_Q_overall_mean", dataframes, "cp ci Good_Prod_Q", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Prod_Q_lower_mean", dataframes, "cp ci Good_Prod_Q", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Prod_Q_upper_mean", dataframes, "cp ci Good_Prod_Q", no_subfolder=True)


# Compare Different Parameters, same Seed

# Read all the dataframes of interest - HH
if PROCESS_HH_TIMESERIES:
    for seed in SEEDS:
        dataframes = get_df_same_seed(main_folder, "simple_hh.csv", seed)
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "all_Sust_Score", dataframes, str(seed))
        visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "all_Sust_Uncert", dataframes, str(seed))

# Read all the dataframes of interest - CP
for seed in SEEDS:
    dataframes = get_df_same_seed(main_folder, "cp_firm.csv", seed)
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Emiss", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Good_Prod_Q", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "Profits", dataframes, str(seed))
    #visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "age", dataframes, seed)

# Read all the dataframes of interest - Model
for seed in SEEDS:
    dataframes = get_df_same_seed(main_folder, "model.csv", seed)
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "green_capacity", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "GDP", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "s_unemp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_kp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "W_20", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "W_80", dataframes, str(seed))
    # More for debugging
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "LIS", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_gov", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_hh", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "M_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "N_goods", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_N_goods", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unspend_C", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_L_demand", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_invest", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "unsat_demand", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "CPI_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "CPI_kp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "markup_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "p_avg_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "returns_investments", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_C", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_C_actual", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_I", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "total_w", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_tot", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "debt_unpaid_cp", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "RD_total", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "EI_avg", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "RS_avg", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_LP", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_EE", dataframes, str(seed))
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "avg_pi_EF", dataframes, str(seed))


# Compare Different Seeds, same Parameters

if PROCESS_HH_TIMESERIES:
    for folder in FOLDERS:
        dataframes = get_df_diff_seed(main_folder, "simple_hh.csv", folder)
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "all_Sust_Score", dataframes, folder)
        visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "all_Sust_Uncert", dataframes, folder)

for folder in FOLDERS:
    dataframes = get_df_diff_seed(main_folder, "cp_firm.csv", folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "Good_Emiss", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "Good_Prod_Q", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "Profits", dataframes, folder)
    #visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], folder, "age", dataframes, seed)

for folder in FOLDERS:
    dataframes = get_df_diff_seed(main_folder, "model.csv", folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "green_capacity", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "GDP", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "s_unemp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "bankrupt_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "bankrupt_kp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "W_20", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "W_80", dataframes, folder)
    # More for debugging
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "LIS", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "M", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "M_gov", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "M_hh", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "M_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "N_goods", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "avg_N_goods", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "unspend_C", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "unsat_L_demand", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "unsat_invest", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "unsat_demand", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "CPI_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "CPI_kp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "markup_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "p_avg_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "returns_investments", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "total_C", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "total_C_actual", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "total_I", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "total_w", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "debt_tot", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "debt_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "debt_unpaid_cp", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "RD_total", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "EI_avg", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "RS_avg", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "avg_pi_LP", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "avg_pi_EE", dataframes, folder)
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "avg_pi_EF", dataframes, folder)