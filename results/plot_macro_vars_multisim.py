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
HH_STEP_START = 1
HH_STEP_END = 900


def combine_and_save_dataframes_hh(main_folder):

    hh_fields = ['hh_id', 'all_Sust_Score', 'all_Sust_Uncert']     # We have to read only few columns to save time

    # Traverse through all subfolders in the main folder
    for root, subfolders, files in os.walk(main_folder):
        # Look for the 'x_hh' folder in each subfolder
        for subfolder in subfolders:
            x_hh_folder = os.path.join(root, subfolder, 'x_hh')
            
            if os.path.exists(x_hh_folder):

                df_hh = pd.DataFrame()
                for timestamp in range(HH_STEP_START, HH_STEP_END):  # Change appropriately for the size of simulation range (as in the folder)
                    path = (os.path.join(x_hh_folder, 'household_'+str(timestamp)+'_hh.csv'))
                    df = pd.read_csv(path, skipinitialspace=True, usecols=hh_fields)
                    df['timestamp'] = timestamp
                    df_hh = pd.concat([df_hh, df], ignore_index=True)

                df_hh.to_csv(os.path.join(root, subfolder, "simple_hh.csv"), index=False)

def read_csv_files_in_folders(main_folder, looking_for):
    dataframes = {}

    # Walk through all directories and files
    for folder_name, subfolders, filenames in os.walk(main_folder):
        # Check if the folder has any CSV files with 'cp_firm' in their names
        for filename in filenames:
            if filename.endswith(looking_for):
                file_path = os.path.join(folder_name, filename)
                folder_base_name = os.path.basename(folder_name)

                # Read the CSV file into a DataFrame and assign it to the folder name in the dictionary
                df = pd.read_csv(file_path)
                # Model csv output does not have timesteps, so we have to add timestep manually (each line is a timestep)
                if looking_for == "_model.csv":
                    df['timestamp'] = pd.Series(range(1, len(df) + 1))
                if folder_base_name not in dataframes:
                    dataframes[folder_base_name] = df
                else:
                    # Optionally, handle if there are multiple CSVs in the same folder
                    # Here we concatenate them
                    dataframes[folder_base_name] = pd.concat([dataframes[folder_base_name], df])

    return dataframes

def visualize_2d_graph(num_rows, num_cols, column_name, dataframes):

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

            plot_index += 1

    # Adjust layout
    plt.suptitle(column_name)
    plt.tight_layout()
    # Save the figure as an image (e.g., PNG format)
    plt.savefig(os.path.join(PATH, column_name+".png"), dpi=300)
    # Optionally, close the plot to free up memory
    plt.close()


# Combine HH dataframes into one with only necessary information
#combine_and_save_dataframes_hh(main_folder)

# Read all the dataframes of interest - HH
dataframes = read_csv_files_in_folders(main_folder, "simple_hh.csv")
visualize_2d_graph(3, 3, "all_Sust_Score", dataframes)
visualize_2d_graph(3, 3, "all_Sust_Uncert", dataframes)

# Read all the dataframes of interest - CP
dataframes = read_csv_files_in_folders(main_folder, "_cp_firm.csv")
visualize_2d_graph(3, 3, "Good_Emiss", dataframes)
visualize_2d_graph(3, 3, "Good_Prod_Q", dataframes)
visualize_2d_graph(3, 3, "Profits", dataframes)
visualize_2d_graph(3, 3, "age", dataframes)

# Read all the dataframes of interest - Model
dataframes = read_csv_files_in_folders(main_folder, "_model.csv")
visualize_2d_graph(3, 3, "green_capacity", dataframes)
visualize_2d_graph(3, 3, "GDP", dataframes)
visualize_2d_graph(3, 3, "s_unemp", dataframes)