import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde
from scipy.interpolate import interp1d

# Parameters
VARIABLE_LEFT = "sust_opinion_init"
VARIABLE_RIGHT = "sust_opinion_end"
OPINIONS_INIT = [
    [1.0, 1.0], [2.0, 2.0], [4.0, 4.0], [0.8, 0.8], [0.4, 0.4],
    [1.0, 0.8], [4.0, 2.0], [0.8, 1.0], [2.0, 4.0]
]
EXPERIMENT_TYPE = "POLITIC"     # "SCIENTIFIC" , "POLITIC"
WEALTH = True

# Unique scaling for sides based on the experiment (to make visualizations nicer)
if (EXPERIMENT_TYPE == "SCIENTIFIC"):
    # Each must have length == len(OPINIONS_INIT)
    widths_l = [1.2, 1.2, 1.2, 1.6, 1.6, 1.2, 1.2, 1.2, 1.2]
    widths_r = [0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8]
if (EXPERIMENT_TYPE == "POLITIC"):
    widths_l = [0.5, 0.5, 0.5, 0.3, 0.3, 0.6, 0.7, 0.6, 0.7]
    widths_r = [0.5, 0.5, 0.5, 0.3, 0.3, 0.6, 0.7, 0.6, 0.7]
if (WEALTH):
    widths_l = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    widths_r = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]

labels = [f"α={α}\nβ={β}" for α, β in OPINIONS_INIT]    # X axis labels for experiment

init_opinions = []
final_opinions = []

# Read data
current_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "opinion_dynamics")
print(current_folder)
for α, β in OPINIONS_INIT:
    filename = f"opinion_results_α={α}_β={β}_{EXPERIMENT_TYPE}.csv"
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
fig, ax = plt.subplots(figsize=(12, 4))  # Wider for more readable labels
positions = np.arange(1, len(labels) + 1)

for i, (x, d_l, d_r, y_l, y_r, local_max, w_l, w_r) in enumerate(zip(positions, kdes_left, kdes_right, init_opinions, final_opinions, max_densities, widths_l, widths_r)):

    scaled_l = w_l * d_l / local_max if local_max > 0 else d_l * 0
    scaled_r = w_r * d_r / local_max if local_max > 0 else d_r * 0

    # Plot left (initial)
    ax.fill_betweenx(y_vals, x - scaled_l, x, facecolor='skyblue', alpha=0.7, label="Initial" if i == 0 else "")

    # Plot right (final)
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
ax.set_xticklabels(labels)
ax.set_xlim(0, len(labels) + 1.0)
ax.set_title(f"Initial vs Final Opinions Distribution for ({EXPERIMENT_TYPE} Experiment", fontsize=14)
ax.set_ylabel("Opinion")
ax.legend()
plt.tight_layout()
plt.savefig(os.path.join(current_folder, f"violin_plot_scaled_{EXPERIMENT_TYPE}.png"), dpi=200)
plt.show()
