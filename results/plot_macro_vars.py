from matplotlib.gridspec import GridSpec
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import os

folder = "alpha=18 beta=2 p_f=0.45 id=22"
SEED = "4492958"
PATH = os.path.join(os.path.curdir, 'results', 'data_saved', 'data', 'plots', folder, SEED)      # Replace folder name here
if not os.path.exists(PATH):
    os.makedirs(PATH)
PERIOD_WARMUP = 100     # To show vertical line
HH_STEP_START = 1
HH_STEP_END = 500

def plot_macro_vars(df:pd.DataFrame):
    """
    Plots macro statistics
    """
    
    _, ax = plt.subplots(3, 2, figsize=(10, 10))

    T = range(len(df.GDP))

    # Plot real GDP
    ax[0,0].plot(T, 100 * df.GDP / df.CPI_cp, label='total GDP')
    ax[0,0].plot(T, 100 * df.GDP_hh / df.CPI_cp, label='hh share')
    ax[0,0].plot(T, 100 * df.GDP_cp / df.CPI_cp, label='cp share')
    ax[0,0].plot(T, 100 * df.GDP_kp / df.CPI_cp, label='kp share')
    ax[0,0].plot(T, 100 * df.Exp_UB / df.CPI_cp, label='UB exp')
    ax[0,0].plot(T, 100 * df.total_I / df.CPI_cp, label='I')
    ax[0,0].plot(T, 100 * df.total_C / df.CPI_cp, label='C')
    ax[0,0].set_title("GDP")
    ax[0,0].legend()

    # Unemployment rate
    ax[0,1].plot(T, df.U, label='unemployment rate')
    ax[0,1].plot(T, df.switch_rate, label='switching rate')
    ax[0,1].set_title("Unemployment rate")
    ax[0,1].set_ylim(0,1)
    ax[0,1].legend()

    # Money Supply 
    ax[1,0].plot(T, df.M - df.debt_tot, 
                 label='total', zorder=5, linestyle='dashed')
    ax[1,0].plot(T, df.M_hh, label='hh')
    ax[1,0].plot(T, df.M_cp, label='cp')
    ax[1,0].plot(T, df.M_kp, label='kp')
    ax[1,0].plot(T, df.M_ep, label='ep')
    ax[1,0].plot(T, df.M_gov, label='gov')
    ax[1,0].plot(T, df.debt_tot, label='total debts')
    ax[1,0].hlines(df.M[0], 0, len(df.M), linestyle='dotted', alpha=0.5, color='black')
    ax[1,0].plot(T, df.M_if, label='if')
    ax[1,0].set_title('Money supply')
    ax[1,0].legend()

    # Inflation
    ax[1,1].plot(T, df.CPI_cp, label='cp')
    ax[1,1].plot(T, df.CPI_kp, label='kp')
    ax[1,1].set_title('CPI')
    ax[1,1].legend()

    # Aggregate consumption and investments
    ax[2,0].plot(T, df.total_C, label="$C$")
    ax[2,0].plot(T, df.total_C_actual, label="$C$ actual")
    ax[2,0].plot(T, df.total_I, label="$investments$")
    ax[2,0].plot(T, df.total_w, label="$wages$")
    ax[2,0].set_title('Aggregate C and I')
    ax[2,0].legend()

    ax[2,1].plot(T, df.GDP_growth, label='GDP')
    ax[2,1].set_title('growth rates')
    ax[2,1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'macro_ts.png'), bbox_inches='tight')


def plot_household_vars(df:pd.DataFrame):
    """
    Plots household variables

    Args:
        df (DataFrame): _description_
    """

    _, ax = plt.subplots(2, 2, figsize=(10, 8))

    T = range(len(df.GDP))

    # Wage levels
    real_w_avg = 100 * df.w_avg / df.CPI_cp
    ax[0,0].plot(T, real_w_avg, color='green', label='real $\\bar{w}$')
    ax[0,0].plot(T, df.w_avg, color='blue', label='$\\bar{w}$')
    ax[0,0].set_title('Real wage level')
    ax[0,0].legend()

    # Real income
    real_Y = 100 * df.Y_avg / df.CPI_cp
    real_YL = 100 * df.YL_avg / df.CPI_cp
    real_YK = 100 * df.YK_avg / df.CPI_cp
    real_YUB = 100 * df.YUB_avg / df.CPI_cp
    real_YSB = 100 * df.YSB_avg / df.CPI_cp

    ax[0,1].plot(T, real_YL / real_Y, color='blue', label='labor')
    ax[0,1].plot(T, real_YK / real_Y, color='red', label='capital')
    ax[0,1].plot(T, real_YUB / real_Y, color='green', label='UB')
    ax[0,1].plot(T, real_YSB / real_Y, color='orange', label='socben')
    ax[0,1].hlines(0, max(T), 0, linestyle='dashed', color='black')
    ax[0,1].legend()
    ax[0,1].set_title('Real income of households')

    # Savings rate
    ax[1,0].hlines(0, 0, T[-1], linestyle='dashed', color='black')
    ax[1,0].plot(T, df.s_emp, color='red', label='employed')
    ax[1,0].plot(T, df.s_unemp, color='blue', label='unemployed')
    ax[1,0].plot(T, df.returns_investments, color='green', label='$r_t$')
    ax[1,0].set_title("Savings rate")
    ax[1,0].set_ylim(-0.5, 0.5)
    ax[1,0].legend()

    # Unsatisfied demand
    ax[1,1].plot(T, df.unsat_demand, label='unsatisfied D')
    ax[1,1].plot(T, df.unspend_C, label='unspend C')
    ax[1,1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'household_ts.png'), bbox_inches='tight')


def plot_producer_vars(df:pd.DataFrame):
    """
    Plots producer variables

    Args:
        df_macro (DataFrame): _description_
    """

    _, ax = plt.subplots(4, 2, figsize=(10, 15))

    T = range(len(df.GDP))

    # Labor demand
    ax[0,0].hlines(0, 0, T[-1], linestyle='dashed', color='black')
    ax[0,0].plot(T, df.dL_cp_avg, color='green', label='cp', alpha=0.5)
    ax[0,0].plot(T, df.dL_kp_avg, color='orange', label='kp', alpha=0.5)
    ax[0,0].set_title('$\Delta L^d$')
    ax[0,0].legend()

    # Producer debt
    ax[0,1].plot(T, df.debt_tot, label='total')
    ax[0,1].plot(T, df.debt_cp, label='cp', color='green')
    ax[0,1].plot(T, df.debt_kp, label='kp', color='red')
    ax[0,1].set_title('Debt levels')
    ax[0,1].legend()

    # Number of ordered machines
    ax[1,0].plot(T, df.n_mach_EI_avg, label='n EI')
    ax[1,0].plot(T, df.n_mach_RS_avg, label='n RS')
    ax[1,0].legend()

    # Production quantities
    ax[1,1].plot(T, df.avg_Q_kp, label='kp Q')
    ax[1,1].plot(T, df.avg_Q_cp, label='cp Q', color='green')
    ax[1,1].plot(T, df.avg_Qs_cp, label='cp $Q^s$', color='green', linestyle='dashed')
    ax[1,1].plot(T, df.avg_Qe_cp, label='cp $Q^e$', color='green', linestyle='dotted')
    ax[1,1].plot(T, df.avg_n_machines_cp, 
                 label='cp n machines', color='blue', linestyle='dashed')
    ax[1,1].plot(T, df.avg_D_cp, label='cp $D$', color='red')
    ax[1,1].plot(T, df.avg_De_cp, label='cp $D^e$', color='red', linestyle='dashed')
    ax[1,1].plot(T, df.avg_Du_cp, label='cp $D^U$', color='red', linestyle='dotted', alpha=0.7)
    ax[1,1].plot(T, df.avg_N_goods, label='avg $N$', color='orange')
    ax[1,1].set_title('Average production quantity')
    ax[1,1].legend()

    # Bankrupties
    ax[2,0].plot(T, df.bankrupt_kp, label='kp')
    ax[2,0].plot(T, df.bankrupt_cp, label='cp')
    ax[2,0].legend()
    ax[2,0].set_title('Bankrupty rate')

    # Markup rates
    ax[2,1].plot(T, df.markup_cp, label='cp')
    ax[2,1].plot(T, df.markup_kp, label='kp')
    ax[2,1].legend()
    ax[2,1].set_title('Markup rates $\mu$')

    # Technology levels
    ax[3,0].plot(T, df.avg_pi_LP, label='$\\bar{\pi}_{LP}$')
    ax[3,0].plot(T, df.avg_pi_EE, label='$\\bar{\pi}_{EE}$')
    ax[3,0].plot(T, df.avg_pi_EF, label='$\\bar{\pi}_{EF}$')
    ax[3,0].plot(T, df.avg_A_LP, label='$\\bar{A}_{LP}$')
    ax[3,0].plot(T, df.avg_A_EE, label='$\\bar{A}_{EE}$')
    ax[3,0].plot(T, df.avg_A_EF, label='$\\bar{A}_{EF}$')
    ax[3,0].plot(T, df.avg_B_LP, label='$\\bar{B}_{LP}$')
    ax[3,0].plot(T, df.avg_B_EE, label='$\\bar{B}_{EE}$')
    ax[3,0].plot(T, df.avg_B_EF, label='$\\bar{B}_{EF}$')
    ax[3,0].set_title('Productivity')
    ax[3,0].legend()

    # Unsatisfied labor and investments demand
    ax[3,1].plot(T, df.unsat_invest, label='unsatisfied I')
    ax[3,1].plot(T, df.unsat_L_demand, label='unsatisfied L')
    ax[3,1].plot(T, df.cu, label='cu')
    ax[3,1].set_title('Unsatisfied demand and unspend C')
    ax[3,1].set_ylim(0, 1)
    ax[3,1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'producer_ts.png'), bbox_inches='tight')


def plot_government_vars(df:pd.DataFrame):

    fig, ax = plt.subplots(2, 2, figsize=(10, 8))
    fig.suptitle("Government")

    T = range(len(df.GDP))

    # Government tax revenues
    ax[0,0].set_title('tax revenues')
    ax[0,0].plot(T, df.rev_incometax, label='income')
    ax[0,0].plot(T, df.rev_capitaltax, label='capital')
    ax[0,0].plot(T, df.rev_salestax, label='sales')
    ax[0,0].plot(T, df.rev_profittax, label='profit')
    ax[0,0].plot(T, df.rev_energytax, label='energy')
    ax[0,0].plot(T, df.rev_carbontax, label='carbon')
    ax[0,0].legend()

    # Government expenditures
    ax[0,1].set_title('expenditures')
    ax[0,1].plot(T, df.exp_UB, label='UB')
    ax[0,1].plot(T, df.exp_subsidies, label='subsidies')
    ax[0,1].legend()

    # Government budget deficit

    # Tax rates
    ax[1,1].set_title('tax rates')
    ax[1,1].plot(T, df['τᴵ_ts'], label='income')
    ax[1,1].plot(T, df['τᴷ_ts'], label='capital')
    ax[1,1].plot(T, df['τˢ_ts'], label='sales')
    ax[1,1].plot(T, df['τᴾ_ts'], label='profits')
    ax[1,1].plot(T, df['τᴱ_ts'], label='energy')
    ax[1,1].plot(T, df['τᶜ_ts'], label='carbon')
    ax[1,1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'government.png'))


def plot_cons_vars(df:pd.DataFrame):
    """
    Plots consumption figures
    """

    fig = plt.figure(figsize=(6, 12))

    gs = GridSpec(6, 2, figure=fig)
    
    ax0 = fig.add_subplot(gs[0,:])
    ax1 = fig.add_subplot(gs[1,:])
    ax2 = fig.add_subplot(gs[2,:])
    ax3 = fig.add_subplot(gs[3,:])
    ax4 = fig.add_subplot(gs[4,:])
    ax5 = fig.add_subplot(gs[5,0])
    ax6 = fig.add_subplot(gs[5,1])

    
    if len(df.GDP) <= 100:
        return

    # Plot real GDP growth rates
    real_GDP = 100 * df.GDP.to_numpy()[100:] / df.CPI_cp.to_numpy()[100:]
    delta_GDP = 100 * (real_GDP[1:] - real_GDP[:-1]) / real_GDP[:-1]

    T = np.arange(100, 100+len(real_GDP)-1)
    

    ax0.hlines(0, min(T), max(T), linestyle='dashed', color='black')
    ax0.set_title('Monhtly changes in real GDP')
    ax0.fill_between(T, [max(i, 0) for i in delta_GDP], 
                        [0 for _ in delta_GDP], color='green')
    ax0.fill_between(T, [min(i, 0) for i in delta_GDP], 
                        [0 for _ in delta_GDP], color='red')
    ax0.set_xlabel('time')
    ax0.set_ylabel('growth rate (%)')
    ax0.set_ylim(-7.5,7.5)


    # Plot consumption growth rates
    C_t = 100 * df.total_C.to_numpy()[100:] / df.CPI_cp.to_numpy()[100:]
    delta_C = 100 * (C_t[1:] - C_t[:-1]) / C_t[:-1]

    ax1.hlines(0, min(T), max(T), linestyle='dashed', color='black')
    ax1.set_title('Monhtly changes in real consumption')
    ax1.fill_between(T, [max(i, 0) for i in delta_C], 
                        [0 for _ in delta_C], color='green')
    ax1.fill_between(T, [min(i, 0) for i in delta_C], 
                        [0 for _ in delta_C], color='red')
    ax1.set_ylabel('growth rate (%)')
    ax1.set_xlabel('time')
    ax1.set_ylim(-7.5,7.5)

    # Plot hh GDP rowth rates
    real_GDP_hh = 100 * df.GDP_hh.to_numpy()[100:] / df.CPI_cp.to_numpy()[100:]
    delta_GDP_hh = 100 * (real_GDP_hh[1:] - real_GDP_hh[:-1]) / real_GDP_hh[:-1]

    ax2.hlines(0, min(T), max(T), linestyle='dashed', color='black')
    ax2.set_title('Monthly changes in real GDP of hh')
    ax2.fill_between(T, [max(i, 0) for i in delta_GDP_hh], 
                        [0 for _ in delta_GDP_hh], color='green')
    ax2.fill_between(T, [min(i, 0) for i in delta_GDP_hh], 
                        [0 for _ in delta_GDP_hh], color='red')
    ax2.set_xlabel('time')
    ax2.set_ylabel('growth rate (%)')
    ax2.set_ylim(-7.5,7.5)

    # Plot cp GDP growth rates
    real_GDP_cp = 100 * df.GDP_cp.to_numpy()[100:] / df.CPI_cp.to_numpy()[100:]
    delta_GDP_cp = 100 * (real_GDP_cp[1:] - real_GDP_cp[:-1]) / real_GDP_cp[:-1]

    ax3.hlines(0, min(T), max(T), linestyle='dashed', color='black')
    ax3.set_title('Monthly changes in real GDP of cp')
    ax3.fill_between(T, [max(i, 0) for i in delta_GDP_cp], 
                        [0 for _ in delta_GDP_cp], color='green')
    ax3.fill_between(T, [min(i, 0) for i in delta_GDP_cp], 
                        [0 for _ in delta_GDP_cp], color='red')
    ax3.set_xlabel('time')
    ax3.set_ylabel('growth rate (%)')
    ax3.set_ylim(-7.5,7.5)

    # Plot kp GDP growth rates
    real_GDP_kp = 100 * df.GDP_kp.to_numpy()[100:] / df.CPI_cp.to_numpy()[100:]
    delta_GDP_kp = 100 * (real_GDP_kp[1:] - real_GDP_kp[:-1]) / real_GDP_kp[:-1]

    ax4.hlines(0, min(T), max(T), linestyle='dashed', color='black')
    ax4.set_title('Monthly changes in real GDP of kp')
    ax4.fill_between(T, [max(i, 0) for i in delta_GDP_kp], 
                        [0 for _ in delta_GDP_kp], color='green')
    ax4.fill_between(T, [min(i, 0) for i in delta_GDP_kp], 
                        [0 for _ in delta_GDP_kp], color='red')
    ax4.set_xlabel('time')
    ax4.set_ylabel('growth rate (%)')
    ax4.set_ylim(-7.5,7.5)

    # Compute quarterly GDP growth rates and plot
    Q_delta_GDP = 100 * (real_GDP[3:] - real_GDP[:-3]) / real_GDP[:-3]

    ax5.set_title('Quarterly GDP growth')
    ax5.hist(Q_delta_GDP, bins=100, density=True)
    ax5.set_xlabel('growth rate (%)')
    ax5.set_xlim(-7.5, 7.5)

    # Compute quarterly C growth rates and plot
    Q_delta_C = 100 * (C_t[3:] - C_t[:-3]) / C_t[:-3]
    ax6.set_title('Quarterly $C$ growth')
    ax6.hist(Q_delta_C, bins=100, density=True)
    ax6.set_xlabel('growth rate (%)')
    ax6.set_xlim(-7.5, 7.5)


    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'consumption.png'))


def plot_income_dist(df:pd.DataFrame):
    """
    Plots hh income, wage and wealth distributions at end of simulation
    """
    start_60 = round(20/100 * 2500)
    end_60 = round(80/100 * 2500)

    I_sorted = np.sort(df.all_I.to_numpy())
    I_share = sum(I_sorted[start_60:end_60]) / sum(I_sorted)
    print("I share:", I_share)

    W_sorted = np.sort(df.all_W.to_numpy())
    W_share = sum(W_sorted[start_60:end_60]) / sum(W_sorted)
    print("W share:", W_share)

    fig, [ax1, ax2] = plt.subplots(1,2, figsize=(10, 4))

    ax1.hist(df.all_I, bins=50, density=True)
    ax1.set_title('(a) Income ($I_{i,t}$)')
    ax1.set_yscale('log')
    ax1.axvline(I_sorted[start_60], c='red')
    ax1.axvline(I_sorted[end_60], c='red')
    ax1.set_ylim(0, 0.1)
    ax1.set_ylabel('log density')
    ax1.set_xlabel('income')
    ax1.fill_between([I_sorted[start_60], I_sorted[end_60]], 0, 1, 
                     color='red', alpha=0.3, label='middle $60\\%$')
    ax1.legend()

    ax2.hist(df.all_W, bins=50, density=True)
    ax2.set_yscale('log')
    ax2.set_title('(b) Wealth ($W_{i,t}$)')
    ax2.set_xlim(0, max(df.all_W))
    ax2.set_ylim(0, 0.1)
    ax2.axvline(W_sorted[start_60], c='red')
    ax2.axvline(W_sorted[end_60], c='red')
    ax2.set_ylabel('log density')
    ax2.set_xlabel('wealth')
    ax2.fill_between([W_sorted[start_60], W_sorted[end_60]], 0, 1, 
                     color='red', alpha=0.3, label='middle $60\\%$')
    ax2.legend()


    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'final_income_dist.png'))


def plot_sales_dist(df_cp:pd.DataFrame, df_kp:pd.DataFrame):
    """
    Plots cp and kp sales and profit distributions at end of simulation.
    """
    
    fig, ax = plt.subplots(5, 2, figsize=(8,12))

    ax[0,0].hist(df_cp.all_S_cp, bins=30)
    ax[0,0].set_title('$S$ of cp')
    
    ax[1,0].hist(df_cp.all_profit_cp, bins=30)
    ax[1,0].set_title('$\Pi$ of cp')

    ax[2,0].hist(df_cp.all_f_cp, bins=60)
    ax[2,0].set_title('$f$ of cp')
    ax[2,0].set_xlim(0, max(df_cp.all_f_cp))

    ax[3,0].hist(df_cp.all_L_cp, bins=30)
    ax[3,0].set_title("$L$ of cp")

    ax[0,1].hist(df_kp.all_S_kp, bins=30)
    ax[0,1].set_title('$S$ of kp')
    
    ax[1,1].hist(df_kp.all_profit_kp, bins=30)
    ax[1,1].set_title('$\Pi$ of kp')

    ax[2,1].hist(df_kp.all_f_kp, bins=30)
    ax[2,1].set_title('$f$ of kp')
    ax[2,1].set_xlim(0, max(df_kp.all_f_kp))

    ax[3,1].hist(df_kp.all_L_kp, bins=30)
    ax[3,1].set_title("$L$ of kp")

    ax[4,0].scatter(df_cp.all_p_cp, df_cp.all_profit_cp, s=3)
    ax[4,0].set_title("$p$ to $\\Pi$")

    ax[4,1].scatter(df_cp.all_p_cp, df_cp.all_f_cp, s=3)
    ax[4,1].set_xlabel('p')
    ax[4,1].set_ylabel('f')
    ax[4,1].set_title("$p$ to $f$")

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'final_dist_profit.png'))


def plot_inequality(df_macro):
    """
    Plot GINI coefficients for income and wealth over time
    """

    fig, ax = plt.subplots(1, 2, figsize=(8,4))

    T = range(len(df_macro.GINI_I))

    ax[0].plot(T, df_macro.GINI_I, label='model output')
    ax[0].hlines(0.282, 0, len(df_macro.GINI_I), linestyle='dashed', color='black', 
                 label='Netherlands (2018)')
    ax[0].set_ylim(0,1)
    ax[0].set_title("Income inequality")
    ax[0].legend()

    ax[1].plot(T, df_macro.GINI_W, label='model output')
    ax[1].hlines(0.789, 0, len(df_macro.GINI_W), linestyle='dashed', color='black', 
                 label='Netherlands (2018)')
    ax[1].set_title("Wealth inequality")
    ax[1].set_ylim(0,1)
    ax[1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'inequality.png'))


def plot_energy(df:pd.DataFrame):

    fig, ax = plt.subplots(2, 2, figsize=(8,6))

    T = range(len(df.D_ep))

    # Plot energy use and capacities
    ax[0,0].plot(T, df.D_ep, label='$D_{e}(t)$', color='red')
    ax[0,0].plot(T, df.Qmax_ep, label='$\\bar{Q}_e$', 
               color='blue', linestyle='dashed')
    ax[0,0].plot(T, df.green_capacity, label='green capacity', 
               color='green')
    ax[0,0].plot(T, df.Qmax_ep - df.green_capacity, 
               label='dirty capacity', color='brown')
    ax[0,0].set_title('Energy demand and consumption')
    ax[0,0].set_xlabel('Time')
    ax[0,0].set_ylabel('Units of energy')
    ax[0,0].ticklabel_format(axis='y', style='sci')
    ax[0,0].legend()

    # Plot energy intensity
    ax[0,1].plot(T, df.D_ep / (df_macro.GDP / df_macro.CPI_cp))
    ax[0,1].set_title('Energy intensity per unit of real GDP')
    ax[0,1].set_xlabel('Time')
    ax[0,1].set_ylabel('Energy intensity')
    
    # Plot innovation spending
    ax[1,0].plot(T, df.RD_ep, label='total R&D spending', color='blue', linestyle='dashed')
    ax[1,0].plot(T, df.IN_g, label='green R&D spending', color='green')
    ax[1,0].plot(T, df.IN_d, label='dirty R&D spending', color='brown')
    ax[1,0].legend()

    ax[1,1].plot(T, df.p_ep, label='energy prices')
    ax[1,1].set_title('Energy prices')
    ax[1,1].legend()

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'energy.png'))

def get_indexnumbers(timeseries):
    return timeseries / timeseries[0] * 100

def get_share(timeseries, tottimeseries, tot_index):
    return tot_index * timeseries / tottimeseries

def plot_emissions(df:pd.DataFrame):

    T = range(len(df.em_index))

    fig, ax = plt.subplots(1, 2, figsize=(8,4))
    fig.suptitle('Carbon Emissions')

    ax[0].set_title('CO$_2$ emissions index')       # These indexes use as baseline value at warmup's end
    ax[0].plot(T, df.em_index, label='$c^{total}_t$')
    ax[0].plot(T, df.em_index_cp, label='$c^{cp}_t$')
    ax[0].plot(T, df.em_index_ep, label='$c^{ep}_t$')
    ax[0].axvline(PERIOD_WARMUP, color='black', linestyle='dotted')
    ax[0].set_xlabel('time')
    ax[0].set_ylabel('index ($t_{warmup}=100$)')
    ax[0].legend()

    ax[1].set_title('percentage CO$_2$ emissions from EP')
    ax[1].plot(T, df.energy_percentage)
    

    plt.tight_layout()
    plt.savefig(os.path.join(PATH, 'emissions.png'))

def plot_LIS(df_macro):

    x = np.arange(300, 661, 60)
    years = np.arange(2020, 2051, 5)

    plt.figure(figsize=(6,4))
    plt.plot(df_macro.LIS.iloc[300:])
    plt.xticks(x, years)
    plt.savefig(os.path.join(PATH, 'LIS.png'))

def plot_cp_emissions(df:pd.DataFrame):

    plot_aggreg_quantiles(df, 'Good_Emiss', ["Good_Emiss", "Profits", "size", "Good_Prod_Q", "Good_Price_p", "Good_Markup_mu", "age"], 'cp_dynamics_production_profits')
    plot_aggreg_quantiles(df, 'Good_Emiss', ["Good_Emiss", "TCI", "TCL", "TCE"], 'cp_dynamics_total_cost')

    return

def plot_aggreg_quantiles(df:pd.DataFrame, col_aggregate, cols_to_compare, plot_name, quantile_bins = [0, 0.1, 0.5, 0.9, 1.0], smooth_window = 50):
    """
    This function saves a plot of cols_to_compare respected to the quantiles of col_aggregate. How value of another column changes aggregated by the quantiles of the another column

    col_aggregate - str - name of the column which we aggregate in quantiles and group other values based on it
    cols_to_compare - array str - array of strings where we say which columns we want to visualize
    plot_name - str - a name of the image to be saved
    quantile_bins - values on which we aggregate
    smooth_window - Smoothing Results for better visibility of trend

    """
    data = df.copy()

    # Define quantile bins and labels
    quantile_labels = []
    for i in range(len(quantile_bins)-1):
        quantile_labels.append(str(quantile_bins[i]) + '-' + str(quantile_bins[i+1]))

    _, ax = plt.subplots(len(cols_to_compare), 1, figsize=(10, 10*int(len(cols_to_compare)*0.65)))
    for i, col in enumerate(cols_to_compare):
        # Initialize a list to store results
        results = []

        # Group the data by 'timestamp'
        grouped = data.groupby('timestamp')

        # Process each group (timestamp)
        for timestamp, group in grouped:
            group = group.copy()  # To avoid SettingWithCopyWarning
            
            # Get the 'Good_Emiss' values
            emiss = group[col_aggregate]
            
            # Check if there are enough unique values to calculate quantiles
            if emiss.nunique() >= len(quantile_bins) - 1:
                # Assign quantiles within this timestamp
                try:
                    group['quantile'] = pd.qcut(
                        emiss, q=quantile_bins, labels=quantile_labels, duplicates='drop'
                    )
                except ValueError:
                    # Handle cases where quantiles cannot be assigned
                    group['quantile'] = np.nan
            else:
                group['quantile'] = np.nan
            
            # Calculate statistics for each quantile
            stats = group.groupby('quantile', observed=False)[col].agg(['mean', 'var', 'count'])
            
            # Reindex stats to include all quantiles
            stats = stats.reindex(quantile_labels)
            
            # Calculate standard error and confidence intervals
            stats['sem'] = np.sqrt(stats['var']) / np.sqrt(stats['count'])
            stats['ci_lower'] = stats['mean'] - 1.96 * stats['sem']
            stats['ci_upper'] = stats['mean'] + 1.96 * stats['sem']
            
            # Add timestamp to stats
            stats['timestamp'] = timestamp
            
            # Reset index to turn 'quantile' into a column
            stats = stats.reset_index()
            
            # Append stats to results
            results.append(stats)
            
        # Concatenate all results into a single DataFrame
        results_df = pd.concat(results, ignore_index=True)

        # Map timestamps to time steps
        results_df = results_df.sort_values(by='timestamp')
        unique_timestamps = results_df['timestamp'].unique()
        time_steps = np.arange(len(unique_timestamps))
        timestamp_to_timestep = dict(zip(unique_timestamps, time_steps))
        results_df['time_step'] = results_df['timestamp'].map(timestamp_to_timestep)

        # Pivot the DataFrame for plotting
        pivot_mean = results_df.pivot(index='time_step', columns='quantile', values='mean')
        pivot_ci_lower = results_df.pivot(index='time_step', columns='quantile', values='ci_lower')
        pivot_ci_upper = results_df.pivot(index='time_step', columns='quantile', values='ci_upper')
        # Smoothing of values
        pivot_mean = pivot_mean.rolling(window=smooth_window, min_periods=1, center=True).mean()
        pivot_ci_lower = pivot_ci_lower.rolling(window=smooth_window, min_periods=1, center=True).mean()
        pivot_ci_upper = pivot_ci_upper.rolling(window=smooth_window, min_periods=1, center=True).mean()

        for quantile in quantile_labels:
            if quantile in pivot_mean.columns:
                
                ax[i].plot(pivot_mean.index, pivot_mean[quantile], label=f'{quantile}')
                ax[i].fill_between(pivot_mean.index,
                                pivot_ci_lower[quantile],
                                pivot_ci_upper[quantile],
                                alpha=0.2)
        ax[i].set_xlabel('Time Step')
        ax[i].set_ylabel(col)
        ax[i].set_title(col + ' by Quantiles of ' + col_aggregate + ' with CI (Smoothed)')
        ax[i].axvline(PERIOD_WARMUP, color='black', linestyle='dotted')
        ax[i].legend(title='Quantiles')
    plt.tight_layout()
    plt.savefig(os.path.join(PATH, plot_name + '.png'))


    return

# def plot_climate(df_climate_energy, df_macro):

#     _, ax = plt.subplots(2, 2, figsize=(8,6))

#     T = range(len(df_climate_energy.emissions_total))

#     ax[0,0].plot(T, df_climate_energy.emissions_total, label='$c^{total}_t$')
#     ax[0,0].plot(T, df_climate_energy.emissions_kp, label='$c^{kp}_t$')
#     ax[0,0].plot(T, df_climate_energy.emissions_cp, label='$c^{cp}_t$')
#     ax[0,0].plot(T, df_climate_energy.emissions_ep, label='$c^{ep}_t$')
#     ax[0,0].set_title('CO$_2$ emissions')
#     ax[0,0].set_xlabel('time')
#     ax[0,0].set_ylabel('total CO$_2$ emission')
#     ax[0,0].legend()

#     real_GDP = 100 * df_macro.GDP / df_macro.CPI
#     ax[0,1].plot(T, df_climate_energy.emissions_total / real_GDP, label='total emissions')
#     ax[0,1].plot(T, df_climate_energy.emissions_kp / real_GDP, label='kp emissions')
#     ax[0,1].plot(T, df_climate_energy.emissions_cp / real_GDP, label='cp emissions')
#     ax[0,1].plot(T, df_climate_energy.emissions_ep / real_GDP, label='ep emissions')
#     ax[0,1].set_title('CO$_2$ emissions per unit of real GDP')
#     ax[0,1].set_xlabel('time')
#     ax[0,1].set_ylabel('CO$_2$ / GDP')
#     ax[0,1].legend()


#     # ax[1,0].plot(T, df_climate_energy.C_a, label='CO$_2$ in atmosphere')
#     # ax[1,0].plot(T, df_climate_energy.C_m, label='CO$_2$ in mixed ocean layer')
#     # ax[1,0].plot(T, df_climate_energy.C_d, label='CO$_2$ in deep ocean layer')
#     # # ax[1,0].plot(T, df_climate_energy.NPP, label='NPP$_t$')
#     # ax[1,0].set_title('CO$_2$ concentrations')
#     # ax[1,0].set_xlabel('time')
#     # ax[1,0].set_ylabel('Total CO$_2$ concentration')
#     # # ax[1,0].set_yscale('log')
#     # ax[1,0].legend()

#     # ax[1,1].plot(T, df_climate_energy.dT_m, label='$\delta T_{m,t}$')
#     # ax[1,1].plot(T, df_climate_energy.dT_d, label='$\delta T_{d,t}$')
#     # ax[1,1].set_title('Temperatures')
#     # ax[1,1].set_xlabel('time')
#     # ax[1,1].set_ylabel('Temperature anomaly')
#     # ax[1,1].legend()

#     plt.tight_layout()
#     plt.savefig(os.path.join(PATH, 'climate.png'))


def plot_hh_opinion_dynamics(df:pd.DataFrame):

    # Get the list of unique 'hh_id's
    hh_ids = df['hh_id'].unique()

    # Show Sustainability Score
    plt.figure(figsize=(12, 6))
    # Loop through each 'hh_id' and plot its data
    for hh_id in hh_ids:
        hh_data = df[df['hh_id'] == hh_id]
        plt.plot(hh_data['timestamp'], hh_data['all_Sust_Score'], label=f'hh_id {hh_id}')
    plt.xlabel('Step')
    plt.ylabel('HH Sustainability Score')
    plt.title('Sustainability Score Over Time by hh_id')
    plt.tight_layout()
    plt.axvline(PERIOD_WARMUP, color = 'b', linestyle='dotted')
    plt.savefig(os.path.join(PATH, 'hh_sustainability_score.png'))

    # Show Uncertainty in Sustainability
    plt.figure(figsize=(12, 6))
    # Loop through each 'hh_id' and plot its data
    for hh_id in hh_ids:
        hh_data = df[df['hh_id'] == hh_id]
        plt.plot(hh_data['timestamp'], hh_data['all_Sust_Uncert'], label=f'hh_id {hh_id}')
    plt.xlabel('Step')
    plt.ylabel('HH Uncertainty in Sustainability Opinion')
    plt.title('Uncertainty in Sustainability Over Time by hh_id')
    plt.tight_layout()
    plt.axvline(PERIOD_WARMUP, color = 'b', linestyle='dotted')
    plt.savefig(os.path.join(PATH, 'hh_sustainability_uncertainty.png'))

    # Aggregate of other parameter based on opinion quantile (same as with cp)
    plot_aggreg_quantiles(df, 'all_Sust_Score', ['all_Sust_Score', 'all_W'], 'hh_W_to_Sustainability', smooth_window = 10)

    return


if __name__=="__main__":


    df_macro = pd.read_csv(os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', folder), str(SEED)+' model.csv'))   # Replace folder name and model csv name here
    plot_macro_vars(df_macro)
    plot_household_vars(df_macro)
    plot_producer_vars(df_macro)
    plot_government_vars(df_macro)
    plot_cons_vars(df_macro)
    plot_energy(df_macro)
    plot_emissions(df_macro)
    plot_LIS(df_macro)

    df_cp = pd.read_csv(os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', folder), str(SEED)+' cp_firm.csv'))   # Replace folder name and model csv name here
    plot_cp_emissions(df_cp)

    df_income_distr = pd.read_csv(os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', folder), str(SEED)+' final_income_dists.csv'))   # Replace folder name and model csv name here
    plot_income_dist(df_income_distr)
    plot_inequality(df_macro)

    df_profit_distr_cp = pd.read_csv(os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', folder), str(SEED)+' final_profit_dists_cp.csv'))   # Replace folder name and model csv name here
    df_profit_distr_kp = pd.read_csv(os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', folder), str(SEED)+' final_profit_dists_kp.csv'))   # Replace folder name and model csv name here
    plot_sales_dist(df_profit_distr_cp, df_profit_distr_kp)

    # df_climate_energy = pd.read_csv('../results/result_data/climate_and_energy.csv')
    # plot_climate(df_climate_energy, df_macro)

    # hh_fields = ['hh_id', 'all_Sust_Score', 'all_Sust_Uncert', 'all_W']     # We have to read only few columns to save time
    # df_hh = pd.DataFrame()
    # for timestamp in range(HH_STEP_START, HH_STEP_END):  # Change appropriately for the size of simulation range (as in the folder)
    #     path = (os.path.join(os.path.join(os.path.curdir, 'results', 'data_saved', 'data', 'x_hh'), 'household_'+str(timestamp)+'_hh.csv'))
    #     df = pd.read_csv(path, skipinitialspace=True, usecols=hh_fields)
    #     df['timestamp'] = timestamp
    #     df_hh = pd.concat([df_hh, df], ignore_index=True)
    # plot_hh_opinion_dynamics(df_hh)