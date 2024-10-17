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
    - There is no R&D after some point? Energy prices go to zero? Are these two connected? They seemingly move together.  <- Parameter ξₑ controls the allocation of innovation budget. Innovation does not go to zero, after initial boost it hovers around 100-200 for green economy, while for brown economy it hovers around 600 from the beginning. This happens because the innovation spending is proportionate to the expected energy price, in green economy energy is cheaper, therefore it only needs an initial investment, just like in real life.
    - The issue is that when we have dirty production machines improve, meanwhile with green production they are not. So all these issues are connected. <- Yes, by design on conceptual level, according to Lamperti et al (2018) only price improves for green energy.
    - We have only one energy producer, which means that CP cannot decide which type of energy they will use. This seems like a crucial feature, needs more investigation on how it works currently. <- This will make model overcomplicated.
2) Research on to how connect opinion dynamics with reality (people are mostly interested in the sustainability when things are going good. It was mostly answered, just formulate it for the model)    <- Done, proposed questions are in the More on Sustainability Opinion Dynamics.md
3) Perform Experiments:
    - Check if there are more CP in the list of HH it might improve speed of convergence/stability.     <- No difference
    - Investigate the volatility of emission producers, with what is it connected?      <- It happens when dominant energy source is changed, or one of them goes extinct. Plausible explanation is that it changes emissions, and as a result highly sutainably households start buying previously deemed unsustainable products from the old inventory. Another possible scenario is once energy source is settled CP start competing on machine productivity, thus growing expenses and increase in production/demand (probably first though). Additional finding, companies that postpone upgrade of machinery do it in cycles sometimes. (Check it again)
    - Check GDP Growth dynamics, how to maximize it? How economy scaling works in green vs brown?       <- In general dynamics of the GDP are same, only that green is ending slightly higher, because of lower energy costs. However, we can see a slight drop in GDP at the same time points as the previous experiment.
    - Visualize Bunkruptcies based on the emissions (Companies with Age=0/1) <- Done! Good idea, it now shows average age and once there is deviance, we know who is bunkrupt and why. We can see clearer first point.
    - Experiment with sizes of economy to see improvement in the CI     <- No difference
    - At the end, we can do scatter plots of emissions, for example emissions/market_Share for CP       <- Pointless as we are losing the dynamics and we can deduce same information from the existent plots for CP
    - Add logger for the critical parameters so that we can re use experiments and organize them easier     <- Done! Hopefully helps
    - Make a Plot of tipping point for the sustainability opinion for when society goes into green production vs brown - production. How to incorporate Fossils price? <- We need to keep a track of CP emissions overall, EP green share, HH opinions. best way is to just save them and show side by side. First, added parallelization, which took some time. And finally we visualzie it all on a 2d grid with the different opinion initializations. Done!
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

3) When we change size of simulation, or some parameters are increased alone it produces very strange results some times. How were initial parameters chosen? Should just a recalibration solve this?
4) How should we implement features and perform tests? For example should I first integrate sustainability in job market or first should I integrate everything for the opinion dynamics and perform experiments with it alone?
5) Should I start comparing to the model with no opinion? Or should we do it at all?


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
