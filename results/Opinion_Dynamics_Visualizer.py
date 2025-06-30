import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde
from scipy.interpolate import interp1d

# Parameters
VARIABLE_LEFT = "sust_opinion_init"
VARIABLE_RIGHT = "sust_opinion_end"
P_F = "0.40"          # "0.40" - Use string
OPINIONS_INIT = [
    [1.0, 1.0], [2.0, 2.0], [4.0, 4.0], [0.8, 0.8], [0.4, 0.4],
    [1.0, 0.8], [4.0, 2.0], [0.8, 1.0], [2.0, 4.0]
]
EXPERIMENT_TYPE = "POLITIC"     # "SCIENTIFIC" , "POLITIC"
WITH_WEALTH = True
# A case where we need to compare end of run with wealth and without
WITH_BASELINE_WEALTH = True

# Unique scaling for sides based on the experiment (to make visualizations more readable and comparable)
if (EXPERIMENT_TYPE == "SCIENTIFIC"):
    # Each must have length == len(OPINIONS_INIT)
    widths_l = [1.2, 1.4, 1.6, 1.4, 1.4, 1.2, 1.4, 1.2, 1.4]
    widths_r = [0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85]
    if (WITH_WEALTH):
        widths_l = [0.2, 0.3, 0.4, 0.4, 0.4, 0.4, 0.3, 0.4, 0.3]
        widths_r = [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
    if (WITH_BASELINE_WEALTH):
        widths_l = [0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8]
        widths_r = [0.6, 0.7, 0.9, 0.6, 0.6, 0.6, 0.8, 0.6, 0.8]
if (EXPERIMENT_TYPE == "POLITIC"):
    widths_l = [0.3, 0.8, 1.8, 0.2, 0.2, 0.3, 1.1, 0.3, 1.1]
    widths_r = [0.3, 0.5, 0.8, 0.2, 0.2, 0.3, 0.85, 0.3, 0.85]
    if (WITH_WEALTH):
        widths_l = [0.2, 0.3, 0.4, 0.2, 0.2, 0.2, 0.3, 0.2, 0.3]
        widths_r = [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
    if (WITH_BASELINE_WEALTH):
        widths_l = [0.2, 0.4, 0.8, 0.15, 0.15, 0.2, 0.7, 0.2, 0.7]
        widths_r = [0.2, 0.4, 0.9, 0.15, 0.15, 0.2, 0.9, 0.2, 0.9]
        
#labels = [f"α={α}\nβ={β}" for α, β in OPINIONS_INIT]    # X axis labels for experiment
labels = [
    "Uniform\n(α=1, β=1)\n",
    "Centered\n(α=2, β=2)\n",
    "More Centered\n(α=4, β=4)\n",
    "Polarized\n(α=0.8, β=0.8)\n",
    "More Polarized\n(α=0.4, β=0.4)\n",
    "Pro-Climate\n(α=1.0, β=0.8)\n",
    "Pro-Climate Centered\n(α=4, β=2)\n",
    "Anti-Climate\n(α=0.8, β=1.0)\n",
    "Anti-Climate Centered\n(α=2, β=4)\n",
]

#############################################################################################

init_opinions = []
final_opinions = []

# Read data
base_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "opinion_dynamics")
current_folder = os.path.join(base_folder, "csvs")
for α, β in OPINIONS_INIT:
    if WITH_BASELINE_WEALTH:
        filename_l = f"opinion_results_α={α}_β={β}_p_f={P_F}_{EXPERIMENT_TYPE}_Wealth={False}.csv"
        filepath = os.path.join(current_folder, filename_l)
        if os.path.isfile(filepath):
            df = pd.read_csv(filepath)
            init_opinions.append(df[VARIABLE_RIGHT].dropna().values)
        filename_r = f"opinion_results_α={α}_β={β}_p_f={P_F}_{EXPERIMENT_TYPE}_Wealth={True}.csv"
        filepath = os.path.join(current_folder, filename_r)
        if os.path.isfile(filepath):
            df = pd.read_csv(filepath)
            final_opinions.append(df[VARIABLE_RIGHT].dropna().values)
    else:
        filename = f"opinion_results_α={α}_β={β}_p_f={P_F}_{EXPERIMENT_TYPE}_Wealth={WITH_WEALTH}.csv"
        filepath = os.path.join(current_folder, filename)
        if os.path.isfile(filepath):
            df = pd.read_csv(filepath)
            init_opinions.append(df[VARIABLE_LEFT].dropna().values)
            final_opinions.append(df[VARIABLE_RIGHT].dropna().values)
        else:
            print(f"File not found: {filepath}")
            init_opinions.append(np.array([]))
            final_opinions.append(np.array([]))

# y-values for plotting, determined globally for axis sharing
all_vals = np.concatenate([np.concatenate(init_opinions), np.concatenate(final_opinions)])
y_vals = np.linspace(np.min(all_vals), np.max(all_vals), 200)

# Precompute KDEs and max densities for scaling
kdes_left = []
kdes_right = []
max_densities = []

for y_l, y_r in zip(init_opinions, final_opinions):
    kde_l = gaussian_kde(y_l, bw_method=0.3) if len(y_l) > 1 else None
    kde_r = gaussian_kde(y_r, bw_method=0.3) if len(y_r) > 1 else None

    d_l = kde_l(y_vals) if kde_l else np.zeros_like(y_vals)
    d_r = kde_r(y_vals) if kde_r else np.zeros_like(y_vals)

    local_max_density = max(d_l.max(), d_r.max(), 1e-8)  # Avoid division by zero

    kdes_left.append(d_l)
    kdes_right.append(d_r)
    max_densities.append(local_max_density)

# Plot
fig, ax = plt.subplots(figsize=(18, 6))  # Wider for more readable labels
positions = np.arange(1, len(labels) + 1)

for i, (x, d_l, d_r, y_l, y_r, local_max, w_l, w_r) in enumerate(zip(positions, kdes_left, kdes_right, init_opinions, final_opinions, max_densities, widths_l, widths_r)):

    scaled_l = w_l * d_l / local_max if local_max > 0 else d_l * 0
    scaled_r = w_r * d_r / local_max if local_max > 0 else d_r * 0

    # Plot left (initial)
    if WITH_BASELINE_WEALTH:
        ax.fill_betweenx(y_vals, x - scaled_l, x, facecolor='skyblue', alpha=0.7, label="Without Wealth" if i == 0 else "")
    else:
        ax.fill_betweenx(y_vals, x - scaled_l, x, facecolor='skyblue', alpha=0.7, label="Initial" if i == 0 else "")

    # Plot right (final)
    if WITH_BASELINE_WEALTH:
        ax.fill_betweenx(y_vals, x, x + scaled_r, facecolor='salmon', alpha=0.7, label="With Wealth" if i == 0 else "")
    else:
        ax.fill_betweenx(y_vals, x, x + scaled_r, facecolor='salmon', alpha=0.7, label="Final" if i == 0 else "")

    # Interpolators to get violin width at specific y (quantile/median)
    interp_l = interp1d(y_vals, scaled_l, bounds_error=False, fill_value=0.0)
    interp_r = interp1d(y_vals, scaled_r, bounds_error=False, fill_value=0.0)

    # Draw quantiles and median for initial (left)
    if len(y_l) > 0:
        q25_l, med_l, q75_l = np.percentile(y_l, [25, 50, 75])
        for y_line in [q25_l, med_l, q75_l]:
            width_at_y = float(interp_l(y_line))
            ax.plot([x - width_at_y, x], [y_line, y_line], color='blue',
                    linewidth=2 if y_line == med_l else 1,
                    linestyle='-' if y_line == med_l else '--')

    # Draw quantiles and median for final (right)
    if len(y_r) > 0:
        q25_r, med_r, q75_r = np.percentile(y_r, [25, 50, 75])
        for y_line in [q25_r, med_r, q75_r]:
            width_at_y = float(interp_r(y_line))
            ax.plot([x, x + width_at_y], [y_line, y_line], color='red',
                    linewidth=2 if y_line == med_r else 1,
                    linestyle='-' if y_line == med_r else '--')


# Final touches
ax.set_xticks(positions)
ax.set_xticklabels(labels, fontsize=10)
ax.set_xlim(0, len(labels) + 1.0)
#ax.set_title(f"Initial vs Final Opinions Distribution for ({EXPERIMENT_TYPE} Experiment, Wealth={WITH_WEALTH}", fontsize=14)
ax.set_ylabel("HH Sustainability Opinions", fontsize=14)
ax.set_xlabel("Opinion Initialization Parameters Set", fontsize=14)
ax.legend(fontsize=12)
plt.tight_layout()
plt.savefig(os.path.join(base_folder, f"violin_plot_scaled_{EXPERIMENT_TYPE}_W={WITH_WEALTH}_p_f={P_F}_Compare_Baseline={WITH_BASELINE_WEALTH}.png"), dpi=200)
plt.show()
