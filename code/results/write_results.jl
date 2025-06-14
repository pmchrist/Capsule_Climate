"""
File used to write simulation results to data files

"""

using DataFrames
using CSV

function save_init_params(
    globalparam,
    initparam,
    folder_name::String
)
    # Economy Size
    initparam.n_cp
    initparam.n_hh
    initparam.n_cp_hh
    # HH Sustainability Opinions
    initparam.sust_α
    initparam.sust_β
    initparam.sust_uncert_α
    initparam.sust_uncert_β
    # Other Params
    globalparam.p_f
    globalparam.t_warmup
    globalparam.seed

    par = ["n_kp", "n_cp", "n_hh", "n_cp_hh", "sust_α", "sust_β", "sust_uncert_α", "sust_uncert_β", "p_f", "t_warmup", "seed"]
    val = [initparam.n_kp, initparam.n_cp, initparam.n_hh, initparam.n_cp_hh,
            initparam.sust_α, initparam.sust_β, initparam.sust_uncert_α, initparam.sust_uncert_β,
            globalparam.p_f, globalparam.t_warmup, globalparam.seed]
    df = DataFrame(Parameters = par, Values= val)

    seed = globalparam.seed

    full_path = joinpath(@__DIR__, "data", folder_name, "$seed Sim_Init_Parameters.csv")     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, df)

end

function save_simdata(
    firm_df::DataFrame,
    file_name::String,
    folder_name::String
)
    full_path = joinpath(@__DIR__, "data", folder_name, file_name)     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, firm_df)

end

function save_hh_shock_data(
    all_hh::Vector{Int},
    model::ABM,
    t::Int64,
    t_warmup::Int64,
    T::Int64,
    seed::Int64,
    folder_name::String
)
    df = DataFrame(
        hh_id = map(hh_id -> hh_id, all_hh),
        all_I = map(hh_id -> model[hh_id].total_I, all_hh),
        C_actual = map(hh_id -> model[hh_id].C_actual, all_hh),
        all_w = map(hh_id -> model[hh_id].w[end], all_hh),
        all_labor = map(hh_id -> model[hh_id].labor_I, all_hh),
        all_captial = map(hh_id -> model[hh_id].capital_I, all_hh),
        all_UB_I = map(hh_id -> model[hh_id].UB_I, all_hh),
        all_socben_I = map(hh_id -> model[hh_id].socben_I, all_hh),
        all_W = map(hh_id -> model[hh_id].W, all_hh),
        #same with P̄
        real_I = map(hh_id -> model[hh_id].total_I/model[hh_id].P̄, all_hh),
        #same with hh.C 
        all_C = map(hh_id -> model[hh_id].C, all_hh),
        all_Sust_Score = map(hh_id -> model[hh_id].Sust_Score, all_hh),
        all_Sust_Uncert = map(hh_id -> model[hh_id].Sust_Score_Uncertainty, all_hh)

    )
    full_path = joinpath(@__DIR__, "data", folder_name, "$seed x_hh", "household_$(t)_hh.csv")     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, df)
end

function save_final_dist(
    all_hh::Vector{Int},
    all_cp::Vector{Int},
    all_kp::Vector{Int},
    seed::Int64, 
    model::ABM,
    folder_name::String
)
    # Save income data of households and Opinion data
    df = DataFrame(
        all_I = map(hh_id -> model[hh_id].total_I, all_hh),
        all_w = map(hh_id -> model[hh_id].w[end], all_hh),
        all_W = map(hh_id -> model[hh_id].W, all_hh),
        skills = map(hh_id -> model[hh_id].skill, all_hh),

        sust_opinion_init = map(hh_id -> model[hh_id].Sust_Score_Init, all_hh),
        sust_uncert_init = map(hh_id -> model[hh_id].Sust_Score_Uncertainty_Init, all_hh),
        sust_opinion_end = map(hh_id -> model[hh_id].Sust_Score, all_hh),
        sust_uncert_end = map(hh_id -> model[hh_id].Sust_Score_Uncertainty, all_hh)
    )

    full_path = joinpath(@__DIR__, "data", folder_name, "$seed final_income_dists.csv")     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, df)

    # Save sales, profits and market share of cp
    df = DataFrame(
        all_S_cp = map(cp_id -> model[cp_id].curracc.S, all_cp),        # Total Sales
        all_profit_cp = map(cp_id -> model[cp_id].Π[end], all_cp),      # Profit
        all_f_cp = map(cp_id -> model[cp_id].f[end], all_cp),           # Market Share
        all_L_cp = map(cp_id -> model[cp_id].L, all_cp),                # Labor Units (Workers amount)
        all_p_cp = map(cp_id -> model[cp_id].p[end], all_cp),           # Price of Good
        all_w_cp = map(cp_id -> model[cp_id].w̄[end], all_cp),           # Wage Level
        all_emiss_cp = map(cp_id -> model[cp_id].emissions_per_item[end], all_cp),           # Wage Level
    )
    full_path = joinpath(@__DIR__, "data", folder_name, "$seed final_profit_dists_cp.csv")     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, df)

    # Save sales, profits and market share of kp
    df = DataFrame(
        all_S_kp = map(kp_id -> model[kp_id].curracc.S, all_kp),
        all_profit_kp = map(kp_id -> model[kp_id].Π[end], all_kp),
        all_f_kp = map(kp_id -> model[kp_id].f[end], all_kp),
        all_L_kp = map(kp_id -> model[kp_id].L, all_kp)
    )
    full_path = joinpath(@__DIR__, "data", folder_name, "$seed final_profit_dists_kp.csv")     # Each time has its own snapshot saved
    mkpath(dirname(full_path))      # Ensure the directory exists
    CSV.write(full_path, df)

end


# Following was mostly been integrated into the model.csv

# function save_climate_data(
#     model::ABM
# )
#     energy_producer = model.ep
#     climate = model.climate

#     df = DataFrame(
#         energy_demand = energy_producer.Dₑ,
#         total_capacity = energy_producer.Q̄ₑ,
#         green_capacity = energy_producer.green_capacity,
#         dirty_capacity = energy_producer.dirty_capacity,

#         p_e = energy_producer.p_ep,

#         RD = energy_producer.RDₑ,
#         IN_g = energy_producer.IN_g,
#         IN_d = energy_producer.IN_d,

#         IC_g = energy_producer.IC_g,
#         A_d = energy_producer.Aᵀ_d,
#         em_d = energy_producer.emᵀ_d,
#         c_d = energy_producer.c_d,

#         emissions_total = climate.carbon_emissions,
#         emissions_kp = climate.carbon_emissions_kp,
#         emissions_cp = climate.carbon_emissions_cp,
#         emissions_ep = energy_producer.emissions,
#     )
#     CSV.write(joinpath(@__DIR__, "results", "result_data", "climate_and_energy.csv"), df)
# end


# """
# Saves macro variables of interest to csv

# Receives:
#     macroeconomy: mut struct with macro variables of interest
# """
# function save_macro_data(macroeconomy)

#     df = DataFrame(
#         GDP = macroeconomy.GDP,
#         GDP_I = macroeconomy.GDP_I,
#         GDP_cp = macroeconomy.GDP_Π_cp,
#         GDP_kp = macroeconomy.GDP_Π_kp,
#         GDP_growth = macroeconomy.GDP_growth,

#         total_C = macroeconomy.total_C,
#         total_C_actual = macroeconomy.total_C_actual,
#         total_I = macroeconomy.total_I,
#         total_w = macroeconomy.total_w,

#         LIS = macroeconomy.LIS,

#         returns_investments = macroeconomy.returns_investments,

#         unsat_demand = macroeconomy.unsat_demand,
#         unspend_C = macroeconomy.unspend_C,
#         unsat_invest = macroeconomy.unsat_invest,
#         unsat_L_demand = macroeconomy.unsat_L_demand,
#         avg_N_goods = macroeconomy.avg_N_goods,

#         p_avg_cp=macroeconomy.p̄,
#         CPI=macroeconomy.CPI,
#         CPI_kp = macroeconomy.CPI_kp,

#         mu_cp = macroeconomy.μ_cp,
#         mu_kp = macroeconomy.μ_kp,

#         M = macroeconomy.M,
#         M_hh = macroeconomy.M_hh,
#         M_cp = macroeconomy.M_cp,
#         M_kp = macroeconomy.M_kp,
#         M_ep = macroeconomy.M_ep,
#         M_gov = macroeconomy.M_gov,
#         M_if = macroeconomy.M_if,

#         debt_tot = macroeconomy.debt_tot,
#         debt_cp = macroeconomy.debt_cp,
#         debt_cp_allowed = macroeconomy.debt_cp_allowed,
#         debt_kp = macroeconomy.debt_kp,
#         debt_kp_allowed = macroeconomy.debt_kp_allowed,
#         debt_unpaid_kp = macroeconomy.debt_unpaid_kp,
#         debt_unpaid_cp = macroeconomy.debt_unpaid_cp,

#         UR = macroeconomy.U,
#         switch_rate = macroeconomy.switch_rate,
#         Exp_UB=macroeconomy.Exp_UB,

#         s_emp = macroeconomy.s̄_emp,
#         s_unemp = macroeconomy.s̄_unemp,

#         w_avg = macroeconomy.w̄_avg,
#         wr_avg = macroeconomy.wʳ_avg,
#         ws_avg = macroeconomy.wˢ_avg,
#         wo_max_avg = macroeconomy.wᴼ_max_mean,

#         I_avg = macroeconomy.Ī_avg,
#         I_labor_avg = macroeconomy.I_labor_avg,
#         I_capital_avg = macroeconomy.I_capital_avg,
#         I_UB_avg = macroeconomy.I_UB_avg,
#         I_socben_avg = macroeconomy.I_socben_avg,

#         dL_avg = macroeconomy.ΔL̄_avg,
#         dL_std = macroeconomy.ΔL̄_std,
#         dL_cp_avg = macroeconomy.ΔL̄_cp_avg,
#         dL_kp_avg = macroeconomy.ΔL̄_kp_avg,

#         EI_avg = macroeconomy.EI_avg,
#         n_mach_EI = macroeconomy.n_mach_EI_avg,
#         RS_avg = macroeconomy.RS_avg,
#         n_mach_RS = macroeconomy.n_mach_RS_avg,

#         avg_pi_LP = macroeconomy.avg_π_LP,
#         avg_pi_EE = macroeconomy.avg_π_EE,
#         avg_pi_EF = macroeconomy.avg_π_EF,

#         avg_A_LP = macroeconomy.avg_A_LP,
#         avg_A_EE = macroeconomy.avg_A_EE,
#         avg_A_EF = macroeconomy.avg_A_EF,

#         avg_B_LP = macroeconomy.avg_B_LP,
#         avg_B_EE = macroeconomy.avg_B_EE,
#         avg_B_EF = macroeconomy.avg_B_EF,

#         total_Q_cp = macroeconomy.total_Q_cp,
#         total_Q_kp = macroeconomy.total_Q_kp,

#         avg_Q_cp = macroeconomy.avg_Q_cp,
#         avg_Qs_cp = macroeconomy.avg_Qˢ_cp,
#         avg_Qe_cp = macroeconomy.avg_Qᵉ_cp,
#         avg_Q_kp = macroeconomy.avg_Q_kp,
#         avg_D_cp = macroeconomy.avg_D_cp,
#         avg_Du_cp = macroeconomy.avg_Dᵁ_cp,
#         avg_De_cp = macroeconomy.avg_Dᵉ_cp,

#         bankrupt_cp = macroeconomy.bankrupt_cp,
#         bankrupt_kp = macroeconomy.bankrupt_kp,

#         cu = macroeconomy.cu,
#         avg_n_machines_cp = macroeconomy.avg_n_machines_cp,

#         gini_I = macroeconomy.GINI_I,
#         gini_W = macroeconomy.GINI_W,

#         I_min = macroeconomy.I_min,
#         I_20 = macroeconomy.I_20,
#         I_80 = macroeconomy.I_80,
#         I_max = macroeconomy.I_max,

#         W_min = macroeconomy.W_min,
#         W_20 = macroeconomy.W_20,
#         W_80 = macroeconomy.W_80,
#         W_max = macroeconomy.W_max
#     )
#     CSV.write("results/result_data/first.csv", df)

#     CSV.write("results/result_data/alpha_W_quantiles.csv", DataFrame(macroeconomy.α_W_quantiles, :auto))
# end

# function save_household_quartiles(
#     householddata::Array
# )

#     CSV.write(joinpath(@__DIR__, "results", "result_data", "household_quantiles.csv"), householddata[2])
# end