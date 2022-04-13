@with_kw mutable struct CapitalGoodProducer <: AbstractAgent
    # T::Int
    id::Int                               # global id
    kp_i::Int                             # kp id, used for distance matrix
    age::Int = 0                          # firm age
    
    # Technology and innovation
    A_LP::Float64 = 1.0                   # labor prod sold machines
    A_EE::Float64 = 1.0                   # energy efficiency of sold machines
    A_EF::Float64 = 1.0                   # environmental friendlines of sold machines
    B_LP::Float64 = 1.0                   # labor prod own production
    B_EE::Float64 = 1.0                   # energy efficiency of own production
    B_EF::Float64 = 1.0                   # environmental friendlines of own production
    RD::Float64 = 0.0                     # R&D expenditure
    IM::Float64 = 0.0                     # hist immitation expenditure
    IN::Float64 = 0.0                     # hist innovation expenditure

    # Price and cost data
    μ::Vector{Float64}                    # markup rates
    p::Vector{Float64} = fill(1+μ[end], 3) # hist price data
    c::Vector{Float64} = ones(Float64, 3) # hist cost data
    
    # Employment
    employees::Vector{Int} = []           # employees in company
    L::Float64 = 0.0                      # labor units in company
    ΔLᵈ::Float64 = 0.0                    # desired change in labor force
    w̄::Vector{Float64}                    # wage level
    wᴼ::Float64 = w̄[end]                  # offered wage
    wᴼ_max::Float64 = 0.0                 # maximum offered wage

    O::Float64 = 0.0                      # total amount of machines ordered
    prod_queue::Array = []                # production queue of machines
    Q::Vector{Float64} = zeros(Float64, 3)# production quantities
    D::Vector{Float64} = zeros(Float64, 3)# hist demand
    EU::Float64 = 0.0                     # energy use in the last period

    HC::Vector{Int} = []                  # hist clients
    Π::Vector{Float64} = zeros(Float64, 3)# hist profits
    Πᵀ::Vector{Float64} = zeros(Float64, 3)# hist profits after tax
    debt_installments::Vector{Float64} = zeros(Float64, 4)   # installments of debt repayments
    f::Vector{Float64}                    # market share
    brochure = []                         # brochure
    orders::Array = []                    # orders
    balance::Balance                      # balance sheet
    curracc::FirmCurrentAccount = FirmCurrentAccount() # current account
end


"""
Initializes kp agent, default is the heterogeneous state, otherwise properties are given
    as optional arguments.
"""
function initialize_kp(
    id::Int, 
    kp_i::Int,
    n_captlgood::Int;
    NW=1000,
    A_LP=1.0,
    A_EE=1.0,
    A_EF=1.0,
    B_LP=1.0,
    B_EE=1.0,
    B_EF=1.0,
    p=1.0,
    μ=0.2,
    w̄=1.0,
    wᴼ=1.0,
    Q=100,
    D=100,
    f=1/n_captlgood,
    )

    kp = CapitalGoodProducer(
        id = id,                        
        kp_i = kp_i,                               
        A_LP = A_LP,
        A_EE = A_EE,
        A_EF = A_EF,                        
        B_LP = B_LP,
        B_EE = B_EE,
        B_EF = B_EF,                       
        μ = fill(μ, 3),
        w̄ = fill(w̄, 3), 
        wᴼ = w̄,
        f = fill(f, 3),
        balance = Balance(NW=NW, EQ=NW)
    )
    return kp
end


"""
Checks if innovation is performed, then calls appropriate functions
"""
function innovate_kp!(
    kp::CapitalGoodProducer, 
    global_param, 
    all_kp::Vector{Int}, 
    kp_distance_matrix::Array{Float64},
    w̄::Float64,
    t::Int,
    ep,
    model::ABM,
    )
    
    # TODO include labor demand for researchers

    # Determine levels of R&D, and how to divide under IN and IM
    set_RD_kp!(kp, global_param.ξ, global_param.ν)
    tech_choices = [(kp.A_LP, kp.A_EE, kp.A_EF, kp.B_LP, kp.B_EE, kp.B_EF)]

    # Determine innovation of machines (Dosi et al (2010); eq. 4)
    θ_IN = 1 - exp(-global_param.ζ * kp.IN)
    if rand(Bernoulli(θ_IN))
        # A_t_in = update_At_kp(kp.A_LP, global_param)
        A_LP_t_in = update_techparam_p(kp.A_LP, global_param)
        A_EE_t_in = update_techparam_p(kp.A_EE, global_param)
        A_EF_t_in = update_techparam_p(kp.A_EF, global_param)

        B_LP_t_in = update_techparam_p(kp.B_LP, global_param)
        B_EE_t_in = update_techparam_p(kp.B_EE, global_param)
        B_EF_t_in = update_techparam_p(kp.B_EF, global_param)

        push!(tech_choices, (A_LP_t_in, A_EE_t_in, A_EF_t_in, B_LP_t_in, B_EE_t_in, B_EF_t_in))
    end

    # TODO compute real value innovation like rer98

    # Determine immitation of competitors
    θ_IM = 1 - exp(-global_param.ζ * kp.IM)
    if rand(Bernoulli(θ_IM))
        # A_LP_t_im, A_EE_t_im, A_EF_t_im, B_LP_t_im, B_EE_t_im, B_EF_t_im = imitate_technology_kp(kp, all_kp, kp_distance_matrix, model)
        # push!(tech_choices, (A_LP_t_im, A_EE_t_im, A_EF_t_im, B_LP_t_im, B_EE_t_im, B_EF_t_im))
        imitated_tech = imitate_technology_kp(kp, all_kp, kp_distance_matrix, model)
        push!(tech_choices, imitated_tech)
    end

    choose_technology_kp!(kp, w̄, global_param, tech_choices, t, ep)
end


"""
Lets kp choose technology
"""
function choose_technology_kp!(
    kp::CapitalGoodProducer,
    w̄::Float64,
    global_param::GlobalParam,
    tech_choices,
    t::Int,
    ep
    )

    # TODO: DESCRIBE
    update_μ_kp!(kp)

    # Make choice between possible technologies
    if length(tech_choices) == 1
        # If no new technologies, keep current technologies
        c_h = kp.w̄[end] / kp.B_LP + ep.pₑ[t] / kp.B_EE
        p_h = (1 + kp.μ[end]) * c_h
        shift_and_append!(kp.c, c_h)
        shift_and_append!(kp.p, p_h)
    else
        # If new technologies, update price data
        #   Lamperti et al (2018), eq 1 and 2
        c_h_cp = map(tech -> (w̄/tech[1] + ep.pₑ[t]/tech[2]), tech_choices)
        c_h_kp = map(tech -> (kp.w̄[end]/tech[4] + ep.pₑ[t]/tech[5]), tech_choices)
 
        p_h = map(c -> (1 + kp.μ[end])*c, c_h_kp)
        r_h = p_h + global_param.b * c_h_cp 
        idx = argmin(r_h)

        # Update tech parameters
        kp.A_LP = tech_choices[idx][1]
        kp.A_EE = tech_choices[idx][2]
        kp.A_EF = tech_choices[idx][3]
        kp.B_LP = tech_choices[idx][4]
        kp.B_EE = tech_choices[idx][5]
        kp.B_EF = tech_choices[idx][6]

        shift_and_append!(kp.c, c_h_kp[idx])
        shift_and_append!(kp.p, p_h[idx])
    end
end


"""
Creates brochures and sends to potential clients.
"""
function send_brochures_kp!(
    kp::CapitalGoodProducer,
    all_cp::Vector{Int}, 
    global_param,
    model::ABM;
    n_hist_clients=50::Int
    )

    # Set up brochure
    brochure = (kp.id, kp.p[end], kp.c[end], kp.A_LP, kp.A_EE, kp.A_EF)
    kp.brochure = brochure

    # Send brochure to historical clients
    for cp_id in kp.HC
        push!(model[cp_id].brochures, brochure)
    end

    # Select new clients, send brochure
    NC_potential = setdiff(all_cp, kp.HC)

    if length(kp.HC) == 0
        n_choices = n_hist_clients
    else
        n_choices = Int(round(global_param.γ * length(kp.HC)))
    end
    
    # Send brochures to new clients
    NC = sample(NC_potential, min(n_choices, length(NC_potential)); replace=false)
    for cp_id in NC
        push!(model[cp_id].brochures, brochure)
    end 

end


"""
Uses inverse distances as weights for choice competitor to immitate
"""
function imitate_technology_kp(
    kp::CapitalGoodProducer, 
    all_kp::Vector{Int}, 
    kp_distance_matrix, 
    model::ABM
    )::Tuple{Float64, Float64, Float64, Float64, Float64, Float64}

    weights = map(x -> 1/x, kp_distance_matrix[kp.kp_i,:])
    idx = sample(all_kp, Weights(weights))
    
    return model[idx].A_LP, model[idx].A_EE, model[idx].A_EF, model[idx].B_LP, model[idx].B_EE, model[idx].B_EF
end


"""
Lets kp set price
"""
function set_price_kp!(
    kp::CapitalGoodProducer, 
    μ1::Float64, 
    )

    c_t = kp.w̄[end] / kp.B_LP
    p_t = (1 + kp.μ[end]) * c_t
    shift_and_append!(kp.c, c_t)
    shift_and_append!(kp.p, p_t)
end


"""
Determines the level of R&D, and how it is divided under innovation (IN) 
and immitation (IM). based on Dosi et al (2010)
"""
function set_RD_kp!(
    kp::CapitalGoodProducer, 
    ξ::Float64, 
    ν::Float64
    )

    # Determine total R&D spending at time t, (Dosi et al, 2010; eq. 3)
    # TODO: describe change of added NW
    
    if kp.age > 1
        prev_S = kp.p[end] * kp.Q[end]
        kp.RD = prev_S > 0 ? ν * prev_S : ν * max(kp.balance.NW, 0)
    else
        kp.RD = ν * max(kp.balance.NW, 0)
    end

    # TODO: now based on prev profit to avoid large losses. If kept, describe!

    kp.curracc.TCI += kp.RD

    # Decide fractions innovation (IN) and immitation (IM), 
    #   (Dosi et al, 2010; eq. 3.5)
    kp.IN = ξ * kp.RD
    kp.IM = (1 - ξ) * kp.RD
end


"""
Lets kp receive orders, adds client as historical clients if it is not yet.
"""
function receive_order_kp!(
    kp::CapitalGoodProducer,
    cp_id::Int
    )

    push!(kp.orders, cp_id)

    # If cp not in HC yet, add as a historical client
    if cp_id ∉ kp.HC
        push!(kp.HC, cp_id)
    end
end


"""
Based on received orders, sets labor demand to fulfill production.
"""
function plan_production_kp!(
    kp::CapitalGoodProducer,
    global_param::GlobalParam,
    model::ABM
    )

    update_w̄_p!(kp, model)
    
    # Determine total amount of capital units to produce and amount of labor to hire
    kp.O = length(kp.orders) * global_param.freq_per_machine

    # Determine amount of labor to hire
    kp.ΔLᵈ = kp.O / kp.B_LP + kp.RD / kp.w̄[end] - kp.L

    update_wᴼ_max_kp!(kp)
end


"""
Lets kp add goods to the production queue, based on available labor supply
"""
function produce_goods_kp!(
    kp::CapitalGoodProducer,
    ep,
    global_param::GlobalParam,
    t::Int
    )

    # Determine what the total demand is, regardless if it can be satisfied
    D::Float64 = length(kp.orders) * global_param.freq_per_machine
    shift_and_append!(kp.D, D)

    # Determine how much labor is needed to produce a full machine
    req_L = global_param.freq_per_machine / kp.B_LP

    # Check if production is constrained
    if kp.L >= req_L * length(kp.orders)

        # Enough labor available, perform full production
        kp.prod_queue = kp.orders

    else

        # Production constrained, determine amount of production possible
        # and randomly select which machines to produce
        n_poss_prod = floor(Int, kp.L / req_L)
        kp.prod_queue = sample(kp.orders, n_poss_prod; replace=false)

    end

    # Append total production amount of capital units
    Q::Float64 = length(kp.prod_queue) * global_param.freq_per_machine
    shift_and_append!(kp.Q, Q)

    # Update energy use from production
    update_EU_TCE_kp!(kp, ep.pₑ[t])

    # Empty order queue
    kp.orders = []
end


function update_EU_TCE_kp!(
    kp::CapitalGoodProducer, 
    pₑ::Float64
    )

    kp.EU = kp.Q[end] / kp.B_EE
    kp.curracc.TCE = pₑ * kp.EU
end


"""
Sends orders from production queue to cp.
"""
function send_orders_kp!(
    kp::CapitalGoodProducer,
    global_param::GlobalParam,
    model::ABM
    )

    if length(kp.prod_queue) == 0
        return nothing
    end

    # Count how many machines each individual cp ordered
    machines_per_cp = counter(kp.prod_queue)

    for (cp_id, n_machines) in machines_per_cp

        # Produce machines in production queue, send to cp
        machines = initialize_machine_stock(
                        global_param.freq_per_machine, 
                        n_machines;
                        p = kp.p[end], 
                        A_LP = kp.A_LP,
                        A_EE = kp.A_EE,
                        A_EF = kp.A_EF
                    )
        Iₜ = n_machines * global_param.freq_per_machine * kp.p[end]
        receive_machines_cp!(model[cp_id], machines, Iₜ)
    end
    
    # Update sales
    kp.curracc.S = kp.Q[end] * kp.p[end]

    # Empty production queue
    kp.prod_queue = []
end


"""
Resets order queue
"""
function reset_order_queue_kp!(
    kp::CapitalGoodProducer
    )

    kp.orders = []
end


"""
Lets kp select cp as historical clients
"""
function select_HC_kp!(
    kp::CapitalGoodProducer, 
    all_cp::Vector{Int};
    n_hist_clients=10::Int
    )

    kp.HC = sample(all_cp, n_hist_clients; replace=false)
end


"""
Lets kp update maximum offered wage
"""
function update_wᴼ_max_kp!(
    kp::CapitalGoodProducer
    )
    # TODO: DESCRIBE IN MODEL
    kp.wᴼ_max = kp.B_LP * kp.p[end] 
    # if kp.ΔLᵈ > 0
    #     kp.wᴼ_max = (kp.O * kp.p[end] - kp.w̄[end] * kp.L) / kp.ΔLᵈ
    # else
    #     kp.wᴼ_max = 0
    # end
end


"""
Filters out historical clients if they went bankrupt
"""
function remove_bankrupt_HC_kp!(
    kp::CapitalGoodProducer,
    bankrupt_lp::Vector{Int},
    bankrupt_bp::Vector{Int}
    )

    filter!(bp_id -> bp_id ∉ bankrupt_bp, kp.HC)
    filter!(lp_id -> lp_id ∉ bankrupt_lp, kp.HC)
end


"""
Updates market share of all kp.
"""
function update_marketshare_kp!(
    all_kp::Vector{Int},
    model::ABM
    )

    kp_market = sum(kp_id -> model[kp_id].D[end], all_kp)

    for kp_id in all_kp
        if kp_market == 0
            f = 1 / length(all_kp)
        else
            f = model[kp_id].D[end] / kp_market
        end
        # push!(model[kp_id].f, f)
        shift_and_append!(model[kp_id].f, f)
    end
end


# TRIAL: DESCRIBE
"""
Updates the markup rate μ
"""
function update_μ_kp!(
    kp::CapitalGoodProducer
    )

    # b = 0.3
    # l = 2

    # if length(kp.Π) > l
    #     # mean_μ = mean(kp.μ[end-l:end-1])
    #     # Δμ = (cp.μ[end] - cp.μ[end-1]) / cp.μ[end-1]
    #     # Δμ = (kp.μ[end] - mean_μ) / mean_μ

    #     # mean_Π = mean(kp.Π[end-l:end-1])
    #     # ΔΠ = (cp.Π[end] - cp.Π[end-1]) / cp.Π[end-1]
    #     # ΔΠ = (kp.Π[end] - mean_Π) / mean_Π
    #     shock_sign = 1
    #     if kp.Π[end] <= kp.Π[end-1]
    #         shock_sign = -1
    #     end

    #     # println("$mean_μ, $mean_Π")
    #     # println("Δμ: $Δμ, $(sign(Δμ)), ΔΠ: $ΔΠ, $(sign(ΔΠ))")

    #     shock = rand(Uniform(0.0, b))

    #     new_μ = max(kp.μ[end] * (1 + shock_sign * shock), 0)
    #     push!(kp.μ, new_μ)

    # elseif kp.Π[end] == 0
    #     push!(kp.μ, kp.μ[end] * (1 + rand(Uniform(-b, 0.0))))
    # else
    #     push!(kp.μ, kp.μ[end] * (1 + rand(Uniform(-b, b))))
    # end

    # push!(kp.μ, kp.μ[end])
    shift_and_append!(kp.μ, kp.μ[end])

end


"""
Replaces bankrupt kp with new kp. Gives them a level of technology and expectations
    from another kp. 
"""
function replace_bankrupt_kp!(
    bankrupt_kp::Vector{Int},
    bankrupt_kp_i::Vector{Int},
    all_kp::Vector{Int},
    global_param::GlobalParam,
    indexfund_struct::IndexFund,
    init_param::InitParam,
    macro_struct::MacroEconomy,
    t::Int,
    model::ABM
    )

    # TODO: describe in model

    # Check if not all kp have gone bankrupt, in this case, 
    # kp with highest NW will not be removed
    if length(bankrupt_kp) == length(all_kp)
        kp_id_max_NW = all_kp[1]
        for i in 2:length(all_kp)
            if model[all_kp[i]].curracc.NW > model[kp_id_max_NW].curracc.NW
                kp_id_max_NW = all_kp[i]
            end
        end
        bankrupt_kp = bankrupt_kp[!kp_id_max_NW]
    end

    # Get all nonbankrupt kp
    nonbankrupt_kp = filter(kp_id -> kp_id ∉ bankrupt_kp, all_kp)

    # Get the technology frontier
    A_LP_max = maximum(kp_id -> model[kp_id].A_LP, nonbankrupt_kp)
    A_EE_max = maximum(kp_id -> model[kp_id].A_EE, nonbankrupt_kp)
    A_EF_max = maximum(kp_id -> model[kp_id].A_EF, nonbankrupt_kp)

    B_LP_max = maximum(kp_id -> model[kp_id].B_LP, nonbankrupt_kp)
    B_EE_max = maximum(kp_id -> model[kp_id].B_EE, nonbankrupt_kp)
    B_EF_max = maximum(kp_id -> model[kp_id].B_EF, nonbankrupt_kp)

    # Compute the average stock of liquid assets of non-bankrupt kp
    avg_NW = mean(kp_id -> model[kp_id].balance.NW, nonbankrupt_kp)
    NW_coefficients = rand(Uniform(global_param.φ3, global_param.φ4),
                           length(bankrupt_kp))

    # Compute share of investments that can be paid from the investment fund                       
    all_req_NW = sum(avg_NW .* NW_coefficients)
    frac_NW_if = decide_investments_if!(indexfund_struct, all_req_NW, t)

    # Re-use id of bankrupted company
    for (i, (kp_id, kp_i)) in enumerate(zip(bankrupt_kp, bankrupt_kp_i))
        # Sample a producer of which to take over the technologies, proportional to the 
        # quality of the technology
        tech_coeff = (global_param.φ5 + rand(Beta(global_param.α2, global_param.β2)) 
                                        * (global_param.φ6 - global_param.φ5))

        new_A_LP = max(A_LP_max * (1 + tech_coeff), init_param.A_LP_0)
        new_A_EE = max(A_EE_max * (1 + tech_coeff), init_param.A_LP_0)
        new_A_EF = max(A_EF_max * (1 + tech_coeff), init_param.A_LP_0)

        new_B_LP = max(B_LP_max * (1 + tech_coeff), init_param.B_LP_0)
        new_B_EE = max(B_EE_max * (1 + tech_coeff), init_param.B_LP_0)
        new_B_EF = max(B_EF_max * (1 + tech_coeff), init_param.B_LP_0)

        NW_stock = NW_coefficients[i] * avg_NW

        # Initialize new kp
        new_kp = initialize_kp(
            kp_id, 
            kp_i, 
            length(all_kp);
            NW = NW_stock,
            A_LP = new_A_LP,
            A_EE = new_A_EE,
            A_EF = new_A_EF,
            B_LP = new_B_LP,
            B_EE = new_B_EE,
            B_EF = new_B_EF,
            μ = macro_struct.μ_kp[t],
            w̄ = macro_struct.w̄_avg[t],
            f = 0.0
        )

        # Borrow the remaining funds
        borrow_funds_p!(new_kp, (1 - frac_NW_if) * NW_stock, global_param.b)

        add_agent!(new_kp, model)
    end
end