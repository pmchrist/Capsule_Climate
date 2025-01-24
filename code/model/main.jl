using Statistics
using Distributions
using StatsBase
using Random
using Agents
using BenchmarkTools
using TimerOutputs
using DataStructures
using Parameters
using SparseArrays
using PyCall
using Dates
using StaticArrays



# Include files
include("../results/write_results.jl")
include("helpers/custom_schedulers.jl")
include("helpers/dist_matrix.jl")
include("helpers/tmpdata_storage.jl")
include("helpers/update.jl")
include("global_parameters.jl")
include("init_parameters.jl")

include("objects/accounting_firms.jl")
include("objects/accounting_govt.jl")
include("objects/machine.jl")
include("objects/powerplant.jl")
include("objects/climate.jl")
include("objects/opinions.jl")

include("agents/government.jl")
include("agents/indexfund.jl")
include("macro_markets/macro.jl")
include("agents/household.jl")
include("agents/consumer_good_producer.jl")
include("agents/capital_good_producer.jl")
include("agents/general_producer.jl")
include("agents/energy_producer.jl")

include("macro_markets/labormarket.jl")
include("macro_markets/consumermarket.jl")
include("macro_markets/firms.jl")

include("helpers/properties.jl")
include("helpers/modeldata_storage.jl")


"""
    initialize_model(T::Int64, t_warmup::Int64, changed_params::Dict)

...
# Arguments:
- `T`: total number of time steps.
- `t_warmup`: number of time steps in warmup phase
- `changed_params`: changed global parameters in case
    of run with other parameters than default parameters.
    
# Returns:
- `model`: `Agents.jl` Agent Based Model struct

...
"""
function initialize_model(
    T::Int64,
    t_warmup::Int64,
    timer::TimerOutput;
    changed_params::Union{Dict, Nothing},               # This one is for shocks            (more in global_parameters.jl)
    changed_params_ofat::Union{Dict, Nothing},          # This one for sensitivity analysis
    changed_taxrates::Union{Vector, Nothing},
    changed_params_init,                                # This one is for initial
    folder_name::String,
    seed::Int64
    )::ABM

    # Initialize scheduler
    scheduler = Agents.Schedulers.by_type(true, true)

    # Initialize struct that holds global params and initial parameters
    #print(changed_params)
    globalparam  = initialize_global_params(changed_params, changed_params_ofat, T, t_warmup, timer, folder_name, seed)
    initparam = InitParam()

    if !isnothing(changed_params_init)      # Update struct if another value was provided 
        for (field, value) in changed_params_init
            if hasfield(typeof(initparam), field)       # First check if parameter is in initial struct
                setfield!(initparam, field, value)
            else
                if hasfield(typeof(globalparam), field)   # Next check if it is in global struct
                    setfield!(globalparam, field, value)
                else
                    println("Field '$field' does not exist in the model structs.")
                end
            end
        end
    end

    # Initialize struct that holds macro variables
    macroeconomy = MacroEconomy(T=T)
    

    # Initialize empty DataFrames for cp_data (consumer producer) and kp_data (kapital producer)
    cp_data = DataFrame()  # Define appropriate columns if needed
    kp_data = DataFrame()  # Define appropriate columns if needed

    # Initialize FirmTimeSeries
    firm_time_series = FirmTimeSeries(cp_data, kp_data)     # Keeps intermediate results for firms

    # Initialize labor market struct
    labormarket = LaborMarket()

    # Initialize government struct
    government = initgovernment(T, t_warmup, changed_taxrates)

    # Initialize index fund struct
    indexfund = IndexFund(T=T)

    # Initialize energy producer
    ep = initialize_energy_producer(T, initparam, government.τᶜ, globalparam)

    # Initialize climate struct
    climate = Climate(T=T)

    # Initialize opinions of hh struct
    opinions = Opinions(T=T)

    # Initialize data structures for consumer- and capital market
    cmdata = CMData(
        n_hh = initparam.n_hh, 
        n_cp = initparam.n_cp
    )

    # Make empty dict for kp_brochures
    kp_brochures = Dict()

    # Determine ids for all agents          (this is unnecessary complicated)
    all_hh = collect(1:initparam.n_hh)
    all_cp = collect(all_hh[end] + 1: all_hh[end] + initparam.n_cp)
    all_kp = collect(all_cp[end] + 1: all_cp[end] + initparam.n_kp)
    all_p = vcat(all_cp, all_kp)

    properties = Properties(
                                1,
                                t_warmup,
                                T,

                                initparam,
                                globalparam,

                                government,
                                ep,
                                indexfund,
                                climate,
                                opinions,
                                
                                all_hh,
                                all_cp, 
                                all_kp,
                                all_p,

                                nothing,
                                nothing,
                                nothing,
                                nothing,
                                nothing,
                                nothing,
                                nothing,
                                
                                firm_time_series,
                                macroeconomy,
                                labormarket,
                                kp_brochures,
                                cmdata,
                                # zeros(Float64, initparam.n_hh, initparam.n_hh,)
                                zeros(Float64, initparam.n_hh),
                                LinRange(0, 100, initparam.n_hh)
                           )

    # Initialize model struct
    model = ABM(
                    Union{Household, CapitalGoodProducer, ConsumerGoodProducer};
                    properties = properties,
                    scheduler = scheduler, 
                    warn = false
                )

    # Initialize households
    for _ in 1:model.i_param.n_hh

        # HH with opinion
        hh = Household(
                        id = nextid(model), 
                        skill = rand(LogNormal(model.i_param.skill_mean, model.i_param.skill_var)),
                        β = rand(Uniform(model.i_param.βmin, model.i_param.βmax)),
                        Sust_Score = rand(Beta(model.i_param.sust_α, model.i_param.sust_β)),
                        Sust_Score_Uncertainty = rand(Beta(model.i_param.sust_uncert_α, model.i_param.sust_uncert_β)),
                      )
        # # HH without opinion
        # hh = Household(
        #                 id = nextid(model), 
        #                 skill = rand(LogNormal(model.i_param.skill_mean, model.i_param.skill_var)),
        #                 β = rand(Uniform(model.i_param.βmin, model.i_param.βmax)),
        #                 Sust_Score = 0.0,
        #                 Sust_Score_Uncertainty = 0.0,
        #               )
        hh.wʳ = max(model.gov.w_min, hh.wʳ)
        add_agent!(hh, model)
    end

    # Determine initial amount of employees per producer
    emp_per_producer = floor(Int64, (1 - model.i_param.init_unempl_rate) * model.i_param.n_hh / 
    (model.i_param.n_cp + model.i_param.n_kp))

    # Determine initial amount of machines per cp
    n_machines_init = ceil(Int64, 1.1 * emp_per_producer)       # Slightly more machines than employees, so that job market is running (I assume)

    # Initialize consumer good producers
    for cp_i in 1:model.i_param.n_cp

        # Initialize capital good stock
        machines = initialize_machine_stock(
                        model.g_param.freq_per_machine, 
                        n_machines_init,
                        η = model.g_param.η; 
                        A_LP = model.i_param.A_LP_0,
                        A_EE = model.i_param.A_EE_0,
                        A_EF = model.i_param.A_EF_0
                   )

        # Decide on time of markup rate update
        # t_next_update = 1
        # if cp_i > 66
        #     t_next_update += 1
        # end
        # if cp_i > 132
        #     t_next_update += 1
        # end

        cp = initialize_cp(
                nextid(model),
                cp_i,
                # t_next_update,
                machines,
                model
            )
        update_n_machines_cp!(cp, globalparam.freq_per_machine)
        add_agent!(cp, model)
    end

    # Initialize capital good producers
    for kp_i in 1:model.i_param.n_kp

        kp = initialize_kp(
                nextid(model), 
                kp_i, 
                model.i_param.n_kp,
                model.g_param.b; 
                A_LP = model.i_param.A_LP_0,
                A_EE = model.i_param.A_EE_0,
                A_EF = model.i_param.A_EF_0, 
                B_LP = model.i_param.B_LP_0,
                B_EE = model.i_param.B_EE_0,
                B_EF = model.i_param.B_EF_0
             )
        add_agent!(kp, model)

        # Initialize brochure of kp goods
        init_brochure!(kp, model)
    end

    # Initialize schedulers
    all_hh, all_cp, all_kp, all_p = schedule_per_type(model)

    # Let all capital good producers select historical clients
    for kp_id in model.all_kp
        select_HC_kp!(model[kp_id], model.all_cp)
    end

    # Let all households select cp of both types for trading network
    for hh_id in model.all_hh
        select_cp_hh!(model[hh_id], all_cp, model.i_param.n_cp_hh)
    end

    # Spread employed households over producerss
    spread_employees_lm!(
        emp_per_producer,
        labormarket,
        government,
        model
    )

    for p_id in all_p
        update_mean_skill_p!(model[p_id], model)
    end

    close_balance_all_p!(all_p, globalparam, government, indexfund, 0, model)

    return model
end


"""
    initialize_datacategories(savedata::Bool)

Initializes the data categories that should be stored during the model run.
Returns `adata` and `mdata` arrays containing tuples describing the properties
of the agents and model to be saved, respectively (see `Agents.jl` documentation).

...
# Arguments
- `savedata::Bool`: whether simulation data is saved. If not, return empty arrays.

...

"""
function initialize_datacategories(
    model::ABM,
    savedata::Bool;
    custom_adata::Bool=false,
    custom_mdata::Bool=false
)::Tuple{Vector{Tuple}, Vector{Tuple}}

    if true

        # Define boolean functions that specify correct agent type
        hh(a) = a isa Household
        cp(a) = a isa ConsumerGoodProducer
        kp(a) = a isa CapitalGoodProducer

        # Define which data of agents should be saved
        # POOR MEMORY PERFORMANCE, ONLY USE WHEN AGGREGATED MACRO VARIABLES NOT ADEQUATE
        if custom_adata
            adata = [
                        # Household data
                        (:total_I, mean, hh)
                        (:total_I, std, hh)

                        (:labor_I, mean, hh)
                        (:labor_I, std, hh)

                        (:capital_I, mean, hh)
                        (:capital_I, std, hh)

                        (:UB_I, mean, hh)
                        (:UB_I, std, hh)

                        (:socben_I, mean, hh)
                        (:socben_I, std, hh)

                        # Consumer good producer data


                        # Capital good producer data
                    ]
        else
            adata = []
        end
        
        if custom_mdata
            # Define which model-wide data should be saved
            model.mdata_tosave = [
                # GDP
                :GDP, :GDP_I, :GDP_Π_cp, :GDP_Π_kp, :GDP_growth,

                # Money supply
                :M, :M_hh, :M_cp, :M_kp, :M_ep, :M_gov, :M_if
            ]
        end

        # Define data of energy producer to save
        model.epdata_tosave = [
            :D_ep, :Qmax_ep, :green_capacity, :dirty_capacity,
            :RD_ep, :IN_g, :IN_d, :p_ep 
        ]

        # Define data of climate/emissions to save !!! SAVED DATA
        model.climatedata_tosave = [
            :em_index, :em_index_cp, :em_index_kp, :em_index_ep,
            :energy_percentage, :carbon_emissions
        ]

        # 
        model.opinionsdata_tosave = [
            :sust_mean_all, :sust_mean_10, :sust_mean_50, :sust_mean_90,
            :sust_mean_100
        ]

        # Define data of government to save
        model.governmentdata_tosave = [
            :τᴵ_ts, :τᴷ_ts, :τˢ_ts, :τᴾ_ts, :τᴱ_ts, :τᶜ_ts,
            :rev_incometax, :rev_capitaltax, :rev_salestax, 
            :rev_profittax, :rev_energytax, :rev_carbontax,
            :exp_UB, :exp_subsidies
        ]

        # model.indexfunddata_tosave = [
        #     :Assets, :funds_inv, :returns_investments #INDEX
        # ]

        mdata = []
        #save CP firm data
        model.cpdata_tosave = [
            :id, :cp_i, :age, :cu, :possible_I
        ]
        #save KP firm data
        model.kpdata_tosave = [
            :id, :kp_i, :age, :employees, :A_LP, :A_EE, :A_EF, :B_LP, :B_EE, :B_EF
        ]

        return adata, mdata
    end

    # If no data saved, return empty arrays
    return [], []
end


function model_step!(
    model::ABM
)::ABM

    timer = model.g_param.timer

    # TODO incorporate this in all the functions
    T = model.T
    t = model.t
    t_warmup = model.t_warmup
    globalparam = model.g_param 
    initparam = model.i_param 
    macroeconomy = model.macroeconomy 
    government = model.gov 
    ep = model.ep 
    labormarket = model.labormarket 
    indexfund = model.idxf 
    climate = model.climate 
    opinions = model.opinions
    cmdata = model.cmdata
    
    folder_name = globalparam.folder_name
    seed = globalparam.seed

    # Check if any global params are changed in ofat experiment
    check_changed_ofatparams(globalparam, t)

    # Update tax rates
    update_taxrates!(government, t)
    # Update parameters
    #update_global_params!(Symbol("p_f"), globalparam , t_warmup, t)    # Updates Fossil Fuel Price after warmup period

    # Update schedulers (returns shuffled agents)
    @timeit timer "schedule" all_hh, all_cp, all_kp, all_p = schedule_per_type(model)

    # Redistrubute remaining stock of dividents to households
    @timeit timer "distr div" distribute_dividends_if!(
        indexfund,
        government,
        all_hh,
        government.τᴷ,
        t,
        model
    )

    # Redistribute goverment balance
    resolve_gov_balance!(government, indexfund, globalparam, all_hh, t, model)

    # Update firm age
    for p_id in all_p
        model[p_id].age += 1
    end

    # Check if households still have enough bp and lp, otherwise sample more
    @timeit timer "hh refill" for hh_id in all_hh
        refillsuppliers_hh!(model[hh_id], all_cp, initparam.n_cp_hh, model)
        resetincomes_hh!(model[hh_id])
    end

    # Clear current account, decide how many debts to repay, reset kp brochures of all cp
    @timeit timer "clear account cp" for cp_id in all_cp
        clear_firm_currentaccount_p!(model[cp_id])
    end

    # (1) kp and ep innovate, and kp send brochures

    # Determine distance matrix between kp
    @timeit timer "dist mat" kp_distance_matrix = get_capgood_euclidian(all_kp, model)

    @timeit timer "kp innov" for kp_id in all_kp

        clear_firm_currentaccount_p!(model[kp_id])

        innovate_kp!(
            model[kp_id],
            government, 
            globalparam, 
            all_kp, 
            kp_distance_matrix,
            macroeconomy.w_avg[max(t-1,1)],
            t,
            ep,
            model
        )

        # Update cost of production and price
        compute_c_kp!(model[kp_id], government, ep.p_ep[t])
        compute_p_kp!(model[kp_id])

        # Send brochures to cp
        send_brochures_kp!(model[kp_id], all_cp, globalparam, model)
    end

    # ep innovate, only when warmup period is left
    @timeit timer "inn ep" innovate_ep!(ep, globalparam, t)

    # (2) consumer good producers estimate demand, set production and set
    # demand for L and K
    @timeit timer "plan prod cp" for cp_id in all_cp
      
        # Plan production for this period
        # μ_avg = t > 1 ? macroeconomy.μ_cp[t-1] : globalparam.μ1
        plan_production_cp!(
            model[cp_id],
            government, 
            ep,
            globalparam, 
            government.τˢ,
            length(all_hh),
            length(all_cp),
            t, 
            model
        )

        # if model[cp_id].t_next_update == t  
        #     model[cp_id].t_next_update += globalparam.update_period
        # end

        # Reset desired and ordered machines
        reset_desired_ordered_machines_cp!(model[cp_id])

        # Update machine cost of production
        update_cop_machines_cp!(model[cp_id], government, ep, t)

        # Plan investments for this period
        plan_investment_cp!(model[cp_id], government, all_kp, globalparam, ep, t, model)

        # Rank producers based on cost of acquiring machines
        # rank_producers_cp!(model[cp_id], government, globalparam.b, all_kp, ep, t, model)

        # rank_machines_cp!(model[cp_id])

        # Update expected long-term production
        update_Qᵉ_cp!(model[cp_id], globalparam.ω, globalparam.ι)
    end

    # (2) capital good producers set labor demand based on expected ordered machines
    @timeit timer "plan prod kp"  for kp_id in all_kp
        plan_production_kp!(model[kp_id], globalparam, model)
    end

    # (3) labor market matching process
    @timeit timer "labormarket" labormarket_process!(
        labormarket,
        all_hh, 
        all_p,
        globalparam,
        government,
        t, 
        model,
        timer
    )

    # Update mean skill level of employees
    for p_id in all_p
        update_mean_skill_p!(model[p_id], model)
    end

    # Update kp production capacitity
    for kp_id in all_kp
        update_prod_cap_kp!(model[kp_id], globalparam)
    end

    for cp_id in all_cp
        check_funding_restrictions_cp!(model[cp_id], government, globalparam, ep.p_ep[t])
    end

    # (4) Producers pay workers their wage. Government pays unemployment benefits
    @timeit timer "pay workers" for p_id in all_p
        pay_workers_p!(
            model[p_id],
            government,
            t, 
            model
        )
    end
    pay_unemployment_benefits_gov!(government, labormarket.unemployed, t, model)


    # (5) Production takes place for cp and kp

    # Update energy prices
    compute_pₑ_ep!(ep, t)

    @timeit timer "consumer prod" for cp_id in all_cp
        produce_goods_cp!(model[cp_id], ep, globalparam, t)
    end

    @timeit timer "capital prod" for kp_id in all_kp
        produce_goods_kp!(model[kp_id], ep, globalparam, t)
    end

    # Let energy producer meet energy demand
    produce_energy_ep!(
        ep, 
        government, 
        all_cp, 
        all_kp, 
        globalparam, 
        indexfund,
        initparam.frac_green, 
        t, 
        t_warmup,
        model
    )
    
    # We need to touch CP and KP again to calculate accurate emissions (now that we know the EP production composition)
    @timeit timer "CP emissions" for cp_id in all_cp
        update_emissions_cp!(ep, model[cp_id], globalparam, t)
    end

    @timeit timer "KP emissions" for kp_id in all_kp
        update_emissions_kp!(ep, model[kp_id], t)
    end

    # (6) Transactions take place on consumer market

    # all_W = map(hh_id -> model[hh_id].W, all_hh)

    # TODO: change to actual expected returns
    ERt = t == 1 ? 0.07 : macroeconomy.returns_investments[t-1]

    # Households set consumption budget
    for hh_id in all_hh
        # Update average price level of cp
        update_average_price_hh!(model[hh_id], globalparam.ω, model)
    end


    W̃min = minimum(hh_id -> model[hh_id].W̃, all_hh)
    W̃max = maximum(hh_id -> model[hh_id].W̃, all_hh)
    W̃med = median(map(hh_id -> model[hh_id].W̃, all_hh))

    @timeit timer "set budget" @inbounds for hh_id in all_hh
        set_consumption_budget_hh!(
            model[hh_id], 
            government.UB, 
            globalparam,
            ERt,
            labormarket.P_getunemployed,
            labormarket.P_getemployed,
            W̃min,
            W̃max,
            W̃med,
            model
        )
    end

    # Households decide to switch suppliers based on satisfied demand and prices
    @timeit timer "sust opinion exchange hh" sust_opinion_exchange_all_hh!(
        globalparam,
        all_hh,
        model,
        timer
    )

    # Gather opinions to save into the model
    collect_opinions(all_hh, t, model)

    # Consumer market process
    @timeit timer "consumermarket" consumermarket_process!(
        all_hh,
        all_cp,
        government,
        globalparam,
        cmdata,
        t,
        model,
        timer
    )

    # Households decide to switch suppliers based on satisfied demand and prices
    @timeit timer "decide switching hh" decide_switching_all_hh!(
        globalparam,
        all_hh,
        all_cp,
        all_p,
        initparam.n_cp_hh,
        model,
        timer
    )

    # println("   $t 7 start $(Dates.format(now(), "HH:MM"))")

    # (6) kp deliver goods to cp, kp make up profits
    @timeit timer "send machines kp" for kp_id in all_kp
        send_ordered_machines_kp!(model[kp_id], ep, globalparam, t, model)
    end

    # Close balances of all firms
    for cp_id in all_cp
        # Update amount of owned capital, increase machine age
        update_n_machines_cp!(model[cp_id], globalparam.freq_per_machine)
        increase_machine_age_cp!(model[cp_id])
    end 

    # Close balances of firms, if insolvent, liquidate firms
    @timeit timer "close balance" close_balance_all_p!(
        all_p, 
        globalparam,
        government,
        indexfund, 
        t, 
        model
    )

    # println("   $t 7 start $(Dates.format(now(), "HH:MM"))")

    # (7) government receives profit taxes and computes budget balance
    levy_profit_tax_gov!(government, all_p, t, model)
    compute_budget_balance(government, t)

    # Update market shares of cp and kp
    update_marketshare_p!(all_cp, model)
    update_marketshare_p!(all_kp, model)
    
    # Select producers that will be declared bankrupt and removed
    @timeit timer "check br" bankrupt_cp, bankrupt_kp, bankrupt_kp_i = check_bankrupty_all_p!(all_p, all_kp, globalparam, model)


    #update firm_time_series
    testv = model.firm_time_series
   
    update_firm_time_series!(t,  model, model.firm_time_series)
    #print if firm_time_series is updated
    if testv != model.firm_time_series
        print("firm_time_series updated \n")
    end

    # (7) macro-economic indicators are updated.
    @timeit timer "update macro ts" update_macro_timeseries(
        # macroeconomy,
        t, 
        all_hh, 
        all_cp, 
        all_kp,
        all_p,
        ep,
        bankrupt_cp,
        bankrupt_kp,
        labormarket,
        government,
        indexfund,
        globalparam,
        model,
        timer
    )

    # Update climate parameters, compute new carbon equilibria and temperature change
    collect_emissions_cl!(climate, all_cp, all_kp, ep, t, globalparam.t_warmup, model)

    # Remove bankrupt companies.
    @timeit timer "kill bankr p" kill_all_bankrupt_p!(
        bankrupt_cp,
        bankrupt_kp, 
        all_hh,
        all_kp,
        labormarket,
        indexfund, 
        model
    )
    update_unemploymentrate_lm!(labormarket)


    # Replace bankrupt kp. Do this before you replace cp, such that new cp can also choose
    # from new kp
    @timeit timer "replace kp" replace_bankrupt_kp!(
        bankrupt_kp, 
        bankrupt_kp_i, 
        all_kp,
        globalparam,
        indexfund,
        initparam,
        macroeconomy,
        t,
        model
    )

    # Replace bankrupt companies with new companies
    @timeit timer "replace cp" replace_bankrupt_cp!(
        bankrupt_cp, 
        bankrupt_kp, 
        all_hh,
        all_cp,
        all_kp,
        globalparam,
        indexfund,
        macroeconomy,
        t,
        model
    )

    #Save houhehold data if necessary.  - ToDo : it should have its own big df which is later dumped like with cp and kp (it will break the current data analysis structure tho)
    save_hh_shock_data(all_hh, model, t, t_warmup, T, globalparam.seed, folder_name)

    # Increment time by one step
    model.t += 1

    if model.t == model.T
        compute_emission_indices!(climate, t_warmup)
    end

    return model
end


#const thread_local_timer = ThreadLocal(TimerOutput())



"""
    run_simulation(T::Int64, changed_params::Bool, full_output::Bool)

## Performs a full simulation.
    - Initializes model and agent structs.
    - Runs model `T` time steps.
    - Writes simulation results to csv.
"""
function run_simulation(;
    T::Int64 = 660,
    t_warmup::Int64 = 500,      # 300 by default
    changed_params::Union{Dict,Nothing} = nothing,
    changed_params_ofat::Union{Dict,Nothing} = nothing,
    changed_taxrates::Union{Vector,Nothing} = nothing,
    changed_params_init = nothing,        # Just to change the parameters for parallel run
    show_full_output::Bool = false,
    sim_nr::Int64 = 0,
    showprogress::Bool = false,
    savedata::Bool = true,
    save_firmdata::Bool = false,
    seed::Int64 = Random.rand(1000:9999),
    folder_name::String
    )

    # Set seed of simulation
    Random.seed!(seed)

    println("sim $sim_nr has started on $(Dates.format(now(), "HH:MM"))")
    #print(changed_params)
    

    timer = TimerOutput()

    # Initialize model
    @timeit timer "init" model = initialize_model(
        T,
        t_warmup,
        timer; 
        changed_params = changed_params,
        changed_params_ofat = changed_params_ofat, 
        changed_taxrates = changed_taxrates,
        changed_params_init = changed_params_init,
        folder_name = folder_name,
        seed = seed
    )
    #initialize firm data category
    # Check for Nothing and provide empty vectors if needed
    cp_cols = isnothing(model.cpdata_tosave) ? [] : model.cpdata_tosave
    kp_cols = isnothing(model.kpdata_tosave) ? [] : model.kpdata_tosave

    
    # Initialize the FirmTimeSeries struct
    firm_time_series = FirmTimeSeries(
        DataFrame(; Dict(prop => Float64[] for prop in cp_cols)...),
        DataFrame(; Dict(prop => Float64[] for prop in kp_cols)...)
    )

    # Initialize data categories that need to be saved
    adata, mdata = initialize_datacategories(model, savedata)

    # At the beginning of the simulation
    # property_dfs = Dict()   # MULTITHREADING #TODO #once global variable
    # for prop in propertynames(model.all_hh)
    #     if prop != :id  # Exclude the id property
    #         property_dfs[prop] = DataFrame(id = collect(keys(model.all_hh)), t1 = Float64[])
    #     end
    # end

    # Run model
    # @timeit timer "runmodel" 
    agent_df, _ = run!(
        model, 
        dummystep, 
        model_step!, 
        T;
        adata = adata,
        mdata = mdata, 
        showprogress = showprogress
    )

    # Get macro variables
    model_df = get_mdata(model)

    # Firm dataframes are updated in place
    get_cp_mdata(model)
    get_kp_mdata(model)


    # Save agent dataframe and model dataframe to csv
    if savedata
        save_init_params(model.g_param , model.i_param , folder_name)          # Just save init params
        save_simdata(model_df, "$seed model.csv", folder_name)
        save_final_dist(model.all_hh, model.all_cp, model.all_kp, seed, model, folder_name)
        #save firm dataframe to csv
        if save_firmdata
            save_simdata(model.firm_time_series.cp_data, "$seed cp_firm.csv", folder_name) 
            save_simdata(model.firm_time_series.kp_data, "$seed kp_firm.csv", folder_name)
        end
    end

    # Show profiling output
    if show_full_output
        show(timer)
        println()
    end

    println("sim $sim_nr has finished on $(Dates.format(now(), "HH:MM"))")

    return agent_df, model_df
end