# Same idea as kwdef struct like macroeconomy! - Probablyt wrong location


@Base.kwdef mutable struct sust_pref
    T::Int=T                                                # number of timesteps

    sust_mean_all::Vector{Float64} = zeros(Float64, T)     # Average across a whole population of hh
    sust_mean_10::Vector{Float64} = zeros(Float64, T)      # 0-10th percentile
    sust_mean_50::Vector{Float64}  = zeros(Float64, T)     # 10-50th percentile
    sust_mean_90::Vector{Float64} = zeros(Float64, T)      # 50-90th percentile
    sust_mean_100::Vector{Float64} = zeros(Float64, T)     # 90-100th percentile

end



function compute_sust_pref(
    all_hh::Vector{Int64},
    # model.macroeconomy::MacroEconomy,
    t::Int64,
    model::ABM
    )
    
    quantile_bins = [0, 0.1, 0.5, 0.9, 1.0]     # Hardcoded to support only this amount of quantiles
    sust_sorted = sort(map(hh_id -> model[hh_id].Sust_Score, all_hh))       # Sort to calculate statistics

    # Establish boundaries for Quantiles
    start_q = round(Int64, quantile_bins[2] * length(all_hh))
    mid_q = round(Int64, quantile_bins[3] * length(all_hh))
    end_q = round(Int64, quantile_bins[4] * length(all_hh))

    # # Sort incomes and select income at 20th and 80th percent   - might be useful later
    # model.sust_pref.sust_min[t] = sust_sorted[begin]
    # model.sust_pref.sust_10[t] = sust_sorted[start_q]
    # model.sust_pref.sust_50[t] = sust_sorted[mid_q]
    # model.sust_pref.sust_90[t] = sust_sorted[end_q]
    # model.sust_pref.sust_max[t] = sust_sorted[end]

    # Assign mean values to percentile variables
    model.sust_pref.sust_mean_all[t] = mean(sust_sorted)
    model.sust_pref.sust_mean_10[t] = mean(sust_sorted[1:start_q])
    model.sust_pref.sust_mean_50[t] = mean(sust_sorted[start_q:mid_q])
    model.sust_pref.sust_mean_90[t] = mean(sust_sorted[mid_q:end_q])
    model.sust_pref.sust_mean_100[t] = mean(sust_sorted[end_q:round(Int64, length(all_hh))])

    # Do same for Uncertainty!

end