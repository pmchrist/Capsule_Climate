@with_kw mutable struct GlobalParam
    # Determine technical innovation process
    ν::Float64 = 0.04               # R&D inv propensity
    νₑ::Float64 = 0.01              # R&D inv propensity energy producer
    ξ::Float64 = 0.5                # R&D allocation to IN
    ξₑ::Float64 = 0.4               # R&D allocation to green tech for energy producer
    ζ::Float64 = 0.3                # firm search capabilities
    ζ_ge::Float64 = 0.3             # ep search capabilities for green tech
    ζ_de::Float64 = 0.3             # ep search capabilities for dirty tech
    α1::Float64 = 3.0               # 1st beta dist param for IN
    β1::Float64 = 3.0               # 2nd beta dist param for IN
    κ_upper::Float64 = 0.007        # 2nd beta dist support
    κ_lower::Float64 = -κ_upper     # 1st beta dist support
    
    γ::Float64 = 0.5                # new custommer sample parameter
    μ1::Float64 = 0.2               # kp markup rule
    r::Float64 = 0.0                # interest rate
    ι::Float64 = 0.2                # desired inventories
    b::Int = 3                      # payback period
    bₑ::Int = 10                    # payback period energy producer
    η::Int = 60                     # physical scrapping age
    ηₑ::Int = 80                    # physical scrapping age energy producer
    Λ::Float64 = 2.0                # max debt/sales ratio
    update_period::Int=3            # time period after which cp update prod plans

    # Determine entrant composition
    φ1::Float64 = 0.1               # 1st Uniform dist support, cp entrant cap
    φ2::Float64 = 0.9               # 2nd Uniform dist support, cp entrant cap
    φ3::Float64 = 0.1               # 1st Uniform dist support, cp entrant liq
    φ4::Float64 = 0.9               # 2nd Uniform dist support, cp entrant liq
    α2::Float64 = 2.0               # 1st beta dist param for kp entrant
    β2::Float64 = 4.0               # 2nd beta dist param for kp entrant
    φ5::Float64 = -0.04             # 1st Beta dist support for kp entrant tech
    φ6::Float64 = 0.02              # 2nd Beta dist support for kp entrant tech

    cu::Float64 = 0.75              # capacity utilization for cp
    max_NW_ratio::Float64 = 0.5     # maximum ratio p can have monthly expenses in NW
    ϵ::Float64 = 0.02               # minimum desired wage increase rate
    Kg_max::Float64 = 0.5           # maximum capital growth rate

    # Determine expectation updating cp
    ω::Float64 = 0.8                # memory parameter adaptive updating rules

    # Determine household consumption
    α_cp::Float64 = 0.85             # parameter controlling MPC of consumers

    # Determine household switching
    ψ_E::Float64 = 0.05             # chance of employed worker looking for a better paying job
    ψ_Q::Float64 = 0.05             # chance of household switching away from cp when demand constrained
    ψ_P::Float64 = 0.05             # chance of household switching to cp with better price

    freq_per_machine::Int = 50      # capital units per machine
    freq_per_powerplant::Int = 10_000 # capital units per instance

    p_f::Float64 = 0.0              # price of fossil fuels

    n_cons_market_days::Int = 4     # number of days in the consumer market process

    t_wait::Int = 4                 # number of time periods producers are not allowed to go bankrupt
end


function initialize_global_params(
    changed_params
    )

    global_param = GlobalParam()

    # Change parameters if needed before returning.
    if changed_params !== nothing
        for (key, new_param) in changed_params
            setproperty!(global_param, Symbol(key), new_param)
        end

        if haskey(changed_params, "κ_upper")
            setproperty!(global_param, Symbol("κ_lower"), -changed_params["κ_upper"])
        end
    end

    return global_param
end