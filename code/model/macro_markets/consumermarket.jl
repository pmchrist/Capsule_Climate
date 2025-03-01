function consumermarket_process!(
    all_hh::Vector{Int},
    all_cp::Vector{Int}, 
    government::Government,
    globalparam::GlobalParam,
    cmdata::CMData,
    t::Int,
    model::ABM,
    to
    )

    # Reset cm data 
    @timeit to "reset matrices" reset_matrices_cp!(cmdata, all_hh, all_cp, model)

    # Market clearing process
    @timeit to "market clearing" cpmarket_matching_cp!(cmdata, model)

    @timeit to "process transac" process_transactions_cm!(all_hh, all_cp, cmdata, government, model, t, to)

end


"""
Market matching process for consumer market.
    This function needs verifications for sure - Might not work out of the box with the new Utility Function
"""
function cpmarket_matching_cp!(
    cmdata::CMData,
    model::ABM
    )

    # Variables necessary for market matching process
    sold_out = Int64[]                      # For new additions into the no stock group
    prev_inventory = sum(cmdata.all_N)      # Early break out if necessary from matching process
    counter = 1                             # We need to restrict consumption, otherwise all the orders are fulfilled

    # Normalize weights
    sum!(cmdata.weights_sum, cmdata.weights)
    cmdata.weights ./= cmdata.weights_sum
    # First find the ideal distribution of demand if no availability constraints are there (only the budgetary and emiss score of HH based)
    cmdata.C_spread .= cmdata.all_C
    cmdata.C_spread .*= cmdata.weights
    cmdata.true_D .= cmdata.C_spread

    while true      # Was originally for loop, now is based on convergence

        # Compute demand per cp and find which cp is sold out and how much demand it can cover
        sum!(cmdata.demand_per_cp, cmdata.C_spread')
        cmdata.demand_per_cp .= max.(floor.(cmdata.demand_per_cp, digits=8), 0.0)
        sold_out = findall(cmdata.all_N .<= cmdata.demand_per_cp)

        # Sell goods
        cmdata.frac_sellable .= min.(cmdata.all_N ./ cmdata.demand_per_cp, 1.0)
        replace!(cmdata.frac_sellable, -Inf=>0.0, NaN=>0.0)
        cmdata.C_spread .*= cmdata.frac_sellable'
        cmdata.transactions .+= cmdata.C_spread

        # Update how much was sold per hh and cp
        sum!(cmdata.sold_per_hh_round, cmdata.C_spread)
        sum!(cmdata.sold_per_cp_round, cmdata.C_spread')

        # Update consumption budget C and inventory N
        cmdata.all_C .-= cmdata.sold_per_hh_round
        cmdata.all_C[cmdata.all_C .<= 1e-1] .= 0.0
        cmdata.all_N .-= cmdata.sold_per_cp_round
        cmdata.all_N[cmdata.all_N .<= 1e-1] .= 0.0

        # Set weights of sold-out producers to zero
        cmdata.weights[:,sold_out] .= 0.0
        # Renormalize weights
        sum!(cmdata.weights_sum, cmdata.weights)
        cmdata.weights ./= cmdata.weights_sum
        replace!(cmdata.weights, NaN=>0.0)
        cmdata.C_spread .= cmdata.all_C     # <- cmdata.all_C Is NaN with the new Utility Function
        cmdata.C_spread .*= cmdata.weights
    
        # Reset sold goods count
        cmdata.sold_per_hh_round .= 0.0
        cmdata.sold_per_cp_round .= 0.0

    
        # Check convergence
        counter += 1
        total_inventory = sum(cmdata.all_N)
        # Once there is negligible difference in inventories between rounds we can continue
        if (abs(total_inventory - prev_inventory) / max(total_inventory, prev_inventory)) < 1e-2
            break
        end
        # Or if there is no inventory
        if (total_inventory == 0)
            break
        end 
        # Or if there have been too many rounds
        if counter > 3
            #println("WARNING: Consumer Market is not Converging")
            break
        end
        # Updating variables for the convergence check
        prev_inventory = total_inventory

    end
    
end


function process_transactions_cm!(
    all_hh::Vector{Int}, 
    all_cp::Vector{Int}, 
    cmdata::CMData,
    government::Government,
    model::ABM,
    t::Int64,
    to
    )

    # cmdata = model.cmdata

    unsat_demand = zeros(Float64, length(all_cp))
    hh_D = zeros(Float64, length(all_cp))

    # Process transactions for hh
    for (i, hh_id) in enumerate(minimum(all_hh):maximum(all_hh))

        hh_D .= @view cmdata.true_D[i,:]

        # Compute unsatisfied demand
        unsat_demand .= @view cmdata.true_D[i,:]
        unsat_demand .-= @view cmdata.transactions[i,:]
        unsat_demand .= max.(unsat_demand, 0.0)

        receive_ordered_goods_hh!(
            model[hh_id], 
            sum(@view cmdata.transactions[i,:]), 
            unsat_demand, 
            hh_D, 
            all_cp,
            length(all_hh)
        )
    end

    unsat_demand = zeros(Float64, length(all_hh))
    total_salestax = 0.0

    # Process transations for cp
    for (i, cp_id) in enumerate(minimum(all_cp):maximum(all_cp))

        # Compute unsat_demand
        unsat_demand = @view cmdata.true_D[:,i]
        unsat_demand .-= @view cmdata.transactions[:,i]
        unsat_demand .= max.(unsat_demand, 0.0)

        # TODO decide whether it makes sense if producers know unsatisfied demand

        model[cp_id].curracc.S = sum(@view cmdata.transactions[:,i])

        total_salestax += model[cp_id].curracc.S * (government.τˢ / (1 + government.τˢ))
        model[cp_id].curracc.S = model[cp_id].curracc.S * (1 / (1 + government.τˢ))

        N_goods_sold = model[cp_id].curracc.S / model[cp_id].p[end]
        if isnan(N_goods_sold)
            println("Goods Sold Nan")
            println(model[cp_id].p[end])
            #N_goods_sold = 0
        end
        shift_and_append!(model[cp_id].D, N_goods_sold)
        shift_and_append!(model[cp_id].Dᵁ, sum(unsat_demand))
        model[cp_id].N_goods = abs(model[cp_id].N_goods - N_goods_sold) > 1e-1 ? model[cp_id].N_goods - N_goods_sold : 0.0
    end

    #display(cmdata.true_D)

    receive_salestax_gov!(government, total_salestax, t)
end


# """
# Pushes demanded goods of hh to cp.
# """
# function write_demand_hh_to_cp!(
#     all_cp::Vector{Int}, 
#     all_hh::Vector{Int}, 
#     transactions::Matrix{Float64}, 
#     model::ABM
#     )

#     for (cp_id, order_col) in zip(all_cp, eachcol(transactions))
#         for (hh_id, qp) in zip(all_hh, order_col)
#             push!(model[cp_id].order_queue, (hh_id, qp / model[cp_id].p[end]))
#         end
#     end
# end


# """
# Updates market share f of cp
# """
# function update_marketshares_cm!(
#     all_cp::Vector{Int}, 
#     model::ABM
#     )

#     total_D = sum(cp_id -> model[cp_id].D[end], all_cp)

#     for cp_id in all_cp
#         cp = model[cp_id]
#         f = cp.D[end] / total_D
#         push!(model[cp_id].f, f)
#     end
# end


# function fill_in_weights_cm!(
#     cmdata::CMData, 
#     all_cp::Vector{Int}, 
#     all_hh::Vector{Int},
#     model::ABM
#     )

#     # First fill in a
# end