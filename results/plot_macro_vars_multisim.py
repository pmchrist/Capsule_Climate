# THIS FILE GENERATES COMPARISONS BETWEEN PARAMETERS FOR SAME SEED

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
HH_STEP_START = 1
HH_STEP_END = 660
SEEDS = [0, 17233, 378620, 692243, 938730]
#FOLDERS = ["alpha=2 beta=2 id=1", "alpha=2 beta=8 id=4", "alpha=2 beta=24 id=7", "alpha=8 beta=2 id=2", "alpha=8 beta=8 id=5", "alpha=8 beta=24 id=8", "alpha=24 beta=2 id=3", "alpha=24 beta=8 id=6", "alpha=24 beta=24 id=9"]
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
GRAPH_SIZE_DIFF_SEED = [2,2]

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
                if looking_for == "model.csv":
                    df['timestamp'] = pd.Series(range(1, len(df) + 1))

                df_models_experiment.append(df)
            
        dataframes[folder] = pd.concat(df_models_experiment, ignore_index=True)

    return dataframes


def get_df_seed_for_ci_producer(main_folder, looking_for):

    # Just like the same as ci_model

    # Gather all the dfs but instead of just combining them we calculate the aggregate metrics and combine them and then combine
    # Experiment -> For Each seed together ->
    # Get aggregate stats (mean of emiss per product for each timestep across all companies) and save into new df ->
    # aggregate all dfs and return dfs the same way as for ci_model for vuisualization

    return



def visualize_2d_graph(num_rows, num_cols, column_name, dataframes, name, no_subfolder=False):
    """
    num_rows and num_cols are for the visualization. It should correspond to the size of the test performed. (variables changed)

    """

    fig, axes = plt.subplots(nrows=num_rows, ncols=num_cols, figsize=(20, 15))

    dataframe_items = list(dataframes.items())

    # Nested loop to iterate over the 2D axes array
    plot_index = 0
    for row in range(num_rows):
        for col in range(num_cols):
            folder, df = dataframe_items[plot_index]

            # Group by timestamp and aggregate the column
            grouped = df.groupby("timestamp")[column_name].agg(['mean', 'count', 'std'])

            # Calculate confidence interval
            grouped['sem'] = grouped['std'] / np.sqrt(grouped['count'])  # Standard error
            ci95 = 1.96 * grouped['sem']  # 95% confidence interval

            # Plot the mean line
            axes[row, col].plot(grouped.index, grouped['mean'], label='Mean', color='blue')

            # Fill between the confidence intervals
            axes[row, col].fill_between(grouped.index, grouped['mean'] - ci95, grouped['mean'] + ci95, 
                                        color='lightblue', alpha=0.5, label='95% CI')

            axes[row, col].set_title(f"{folder}")
            axes[row, col].set_xlabel('Timestamp')
            axes[row, col].set_ylabel('Mean')
            if column_name == "all_Sust_Score" or column_name == "all_Sust_Uncert":
                axes[row, col].set_ylim([0, 1])
            plot_index += 1

    # Adjust layout
    plt.suptitle(column_name)
    plt.tight_layout()
    if no_subfolder:
        path = os.path.join(PATH, "graphs")
    else:
        path = os.path.join(PATH, "graphs", str(name))
    if not os.path.exists(path):
        os.makedirs(path)
    # Save the figure as an image (e.g., PNG format)
    plt.savefig(os.path.join(path, name + ' ' + column_name + ".png"), dpi=300)
    # Optionally, close the plot to free up memory
    plt.close()




# Combine HH dataframes into one with only necessary information

if COMBINE_HH_TIMESERIES: combine_and_save_dataframes_hh(main_folder)        # Make it to check if file exists, instead of manual change


# Compare different parameters and use seeds for CI
dataframes = get_df_seed_for_ci_model(main_folder, "model.csv")
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "green_capacity", dataframes, "model ci green_capacity", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "GDP", dataframes, "model ci GDP", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "s_unemp", dataframes, "model ci s_unemp", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_cp", dataframes, "model ci bankrupt_cp", no_subfolder=True)     # <- explicit bankr rate
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_kp", dataframes, "model ci bankrupt_kp", no_subfolder=True)     # <- explicit bankr rateer)

visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_all", dataframes, "sust opinion mean overall", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_90", dataframes, "sust opinion mean lower 10th q", no_subfolder=True)
visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "sust_mean_100", dataframes, "sust opinion mean upper 10th q", no_subfolder=True)



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
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_cp", dataframes, str(seed))     # <- explicit bankr rate
    visualize_2d_graph(GRAPH_SIZE_DIFF_PARAM[0], GRAPH_SIZE_DIFF_PARAM[1], "bankrupt_kp", dataframes, str(seed))     # <- explicit bankr rate


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
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "bankrupt_cp", dataframes, folder)     # <- explicit bankr rate
    visualize_2d_graph(GRAPH_SIZE_DIFF_SEED[0], GRAPH_SIZE_DIFF_SEED[1], "bankrupt_kp", dataframes, folder)     # <- explicit bankr rate


# -> add opinion and uncertainty of the hh into the model values output (like wages probably)
