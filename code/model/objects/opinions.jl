# Same idea as kwdef struct like macroeconomy oe climate! - Probablyt wrong location

@with_kw mutable struct Opinions{V<:Vector{Float64}}

    T::Int64

    # Emissions
    sust_mean_all::V = zeros(Float64, T)  # Average opinion on Sustainability across all hh
    sust_mean_10::V = zeros(Float64, T)   # Average opinion on Sustainability across 0-10th percentile hh
    sust_mean_50::V = zeros(Float64, T)   # Average opinion on Sustainability across 10-50th percentile hh
    sust_mean_90::V = zeros(Float64, T)   # Average opinion on Sustainability across 50-90th percentile hh
    sust_mean_100::V = zeros(Float64, T)  # Average opinion on Sustainability across 90-100th percentile hh

    # Emissions
    sust_unc_mean_all::V = zeros(Float64, T)  # Average opinion on Sustainability across all hh
    sust_unc_mean_10::V = zeros(Float64, T)   # Average opinion on Sustainability across 0-10th percentile hh
    sust_unc_mean_50::V = zeros(Float64, T)   # Average opinion on Sustainability across 10-50th percentile hh
    sust_unc_mean_90::V = zeros(Float64, T)   # Average opinion on Sustainability across 50-90th percentile hh
    sust_unc_mean_100::V = zeros(Float64, T)  # Average opinion on Sustainability across 90-100th percentile hh

end


function collect_opinions(
    all_hh::Vector{Int64},
    t::Int64,
    model::ABM
    )
    
    quantile_bins = [0, 0.1, 0.5, 0.9, 1.0]     # Hardcoded to support only this amount of quantiles
    sust_sorted = sort(map(hh_id -> model[hh_id].Sust_Score, all_hh))       # Sort to calculate statistics
    sust_unc_sorted = sort(map(hh_id -> model[hh_id].Sust_Score_Uncertainty, all_hh))       # Sort to calculate statistics

    # Establish boundaries for Quantiles
    start_q = round(Int64, quantile_bins[2] * length(all_hh))
    mid_q = round(Int64, quantile_bins[3] * length(all_hh))
    end_q = round(Int64, quantile_bins[4] * length(all_hh))

    # # Sort incomes and select income at 20th and 80th percent   - might be useful later
    # model.opinions.sust_min[t] = sust_sorted[begin]
    # model.opinions.sust_10[t] = sust_sorted[start_q]
    # model.opinions.sust_50[t] = sust_sorted[mid_q]
    # model.opinions.sust_90[t] = sust_sorted[end_q]
    # model.opinions.sust_max[t] = sust_sorted[end]

    # Assign mean values to percentile variables
    model.opinions.sust_mean_all[t] = mean(sust_sorted)
    model.opinions.sust_mean_10[t] = mean(sust_sorted[1:start_q])
    model.opinions.sust_mean_50[t] = mean(sust_sorted[start_q:mid_q])
    model.opinions.sust_mean_90[t] = mean(sust_sorted[mid_q:end_q])
    model.opinions.sust_mean_100[t] = mean(sust_sorted[end_q:round(Int64, length(all_hh))])

    # Assign mean values to percentile variables for Uncertainty
    model.opinions.sust_unc_mean_all[t] = mean(sust_unc_sorted)
    model.opinions.sust_unc_mean_10[t] = mean(sust_unc_sorted[1:start_q])
    model.opinions.sust_unc_mean_50[t] = mean(sust_unc_sorted[start_q:mid_q])
    model.opinions.sust_unc_mean_90[t] = mean(sust_unc_sorted[mid_q:end_q])
    model.opinions.sust_unc_mean_100[t] = mean(sust_unc_sorted[end_q:round(Int64, length(all_hh))])

end