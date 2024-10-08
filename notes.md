# Done:

Phase 0 - Prepartion
Made code work - Needed correct versions of Julia and to rewrite the saving paths, as they were not supported on multiple platforms
Code restructured slightly, added comments, rewrote some minor stuff. Added explanations

Phase 1 - Creating Sustainable Consumer
Integrated Emissions into Consumermarket process - by linear combination of normalized price and emissions per good. (Took a lot of iterations)
    Add environmental awareness/opinion score into HH               ! Done
    Add environmental punishment into the Consumermarket process    ! Done
    Run tests                                                       ! Done
    Add Initialization of environmental opinion                     ! Done
Added an opinion dynamics system based on https://www.jasss.org/19/1/6.html so that people can weight price and emissions dynamically
Created Graphs to showcase how emissions influence CP and how opinion influences HH
    Add Opinion Dynamics (Deffuant Model)                           ! Done
    Add Visualization of opinion dynamics                           ! Done
    Get Preliminary Results and Analyze them                        ! Done
Perform experiments and analysis, find how different opinions influence the efficient frontier and dynamics. Additionally, add different initializations for the opinion.

Phase 2 - Creating Sustainable Employee
...



# Current ToDo:
1) Check how Energy Producers work in detail. Fix the emission calcualtions, it might not account for the energy source emissions. (In green economy emissions per good are higher than in brown economy, probably the energy source used is not used in calculations. If all energy is green there should be zero emissions. But won't it destroy the consumption process or will just amplify it?)
    - Emissions per product are non comparable between simulations, as it does not take into account the energy source, only machine's productivity. Is a conceptual issue, either change name or change the way it is calculated by incorporating the emissions of EP. <- Fixed by incorporating energy source emissions
    - There is no R&D after some point? Energy prices go to zero? Are these two connected? They seemingly move together. (It was found that there is no fixed costs for the grid, only production cost is passed to the consumers of the energy, does it change results?)
    - The issue is that when we have dirty production machines improve, meanwhile with green production they are not. So all these issues are connected.
    - We have only one energy producer, which means that CP cannot decide which type of energy they will use. This seems like a crucial feature, needs more investigation on how it works currently. (We will probably leave it as it is)
2) Research on to how connect opinion dynamics with reality (people are mostly interested in the sustainability when things are going good. It was mostly answered, just formulate it for the model)
3) Perform Experiments:
    - Investigate the volatility of emission producers, with what is it connected?
    - Check GDP Growth dynamics, how to maximize it? How economy scaling works in green vs brown?
    - Make a Plot of tipping point for the sustainability opinion for when society goes into green production vs brown - production. How to incorporate Fossils price?
    - Check if there are more CP in the list of HH it might improve speed of convergence/stability.
4) Integrate Sustainabiltiy Opinion into Job Market

# Nice ToDo:
1) Migrate to the newer version of Agents.jl
2) Modify Isaak's Diagram to be in line with my Thesis Research
3) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works kinda by "magic"
4) There are some resizing of arrays, if we keep them fixed it might make code faster


# Notes:
- How to get results of simulation? Copy the 'data' from code folder to results folder and afterwards run the analyzers
- When money market/index funds start balooning it means that something is going off in the economy. Keep an eye on it!
- Stability of the system can be measured with the Coefficient of Variation
- GitHubs: debraj001, vallematteo



# Current Questions:
1) What is LIS in results visualization?
2) What is the appropriate horizon for the simulation? How to choose it?


# Answered Questions:
Q - Should we calibrate before each addition? Or only once parameters are added. For example Social parameter. What is the general workflow?
A - The system is calibrated initially, and it should not be a problem.

Q - Should we add sustainability scores to CP and KP (not sure if viable)
A - This should happen by itself, so no need to implement this. 

Q - Should we start integrating S component into companies?
A - This will become too much of a scope for the current thesis. So no further ESG integration, for now.

Q - Why unemployed have highest savings rate??? Something is fishy with the unemployment benefit, or just unemployment status. In general when people don't have money it spawns from somewhere.
A - It is verified and modeled with the Marginal Propensity to Consume. It is just that unemployed people have less money and thus savings is a bigger percentage wise. 

Q - Price of Fossils is fixed, which is problematic. As is a very sensitive parameter which defines on what energy producer will do, and it changes all the balances for producers. Should we address this? Is it worth it? Have you tried it already? I saw that in paper we just compare the results with the base case
A - It is done by design to find the Efficient Frontier, i.e. by how much the shift is made compared to nothing.

Q - I have incorporated E into the consumer's choice with a linear function. Should I also integrate a hard cut-off? Because there is a theory that we should just boycott high polluters, this should be a hard core solution. Should we also test such hypothesis? It will be problematic, as it blocks the current flow of consumption. (example: if none available, i.e. all polluters, hh will just consume, which is the case anyway)
A - No, seems to deviate too much from the research question. We should focus on different initializations, for example no opinion vs strong opinion

Q - How to initialize opinions? I just do beta distribution. Is it enough for now? Most of the research says that people have either no opinion or pollarized. Should I think about some stochastic shocks? Connect this thing to the overall emissions?
A - Current initialization seems to be ok, just try different scenarios to see how various initializations influence final results.
