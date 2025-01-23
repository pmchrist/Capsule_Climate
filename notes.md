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
Perform experiments and analysis, find how different opinions influence the efficient frontier and dynamics. Additionally, add different initializations for the opinion.       ! Done
    We have performed various tests and found chaotic dynamics, mostly opinion influences the frontier to be lower (p_f=0.38)                       ! Done
    Various initialization parameters have been found for opinion, and there seems to be an influence. Needs stochastic uncert quantif              ! Done
    Additionally opinion dynamics have been researched. We know how it is connected with model params (More on Sustainability Opinion Dynamics.md)  ! Done
    Add Multiple simulations support                                                                                                                ! Done
    Make a Plot of tipping point for the sustainability opinion for when society goes into green production vs brown - production.                  ! Done
Fix the emission calcualtions                                       ! Done
    It was not accounting for the emissions of the energy source for the CP and KP calculation. Fixed by passing EP emissions per energy unit       ! Done
    Add logger for the critical parameters so that we can re use experiments and organize them easier                                               ! Done


Phase 2 - Creating Sustainable Employee (Integrate Sustainabiltiy Opinion into Job Market)
...



# Current ToDo:
1) Make sure that everything is calibrated to the initial original parameters           ! Done
2) Change visualization of Bunkruptcies from age to the global counter from model       ! Done
3) Make main HH variables duplicated in the model for easier access                     ! Done

5) We now must have 3 types of visualizations: one sim same seed (Granular - Done), multiple sims same seed (Comparative - Done), multiple sims multiple seeds (Aggregate of the previous one - To Do)                                                  ! Done
6) Provided plots make sense but it seems there is a chaos region introduced. To quantify it we should expand plot to a phase plot, Heatmap for Opinion vs p_f, check size of chaotic region. Heatmaps can be probabiltiies of green adoption based on initial parameters.      ! Technical Support Exist. ADD MORE INDICATORS FOR THE ANALYSIS (aggregate cp data), run it more and show preliminary results to professor.
	- Quantify stochasticity in the simulation with multiple runs.
	- Check without opinion how smaller the chaos regions is.
    - Create a heatmap of initial opinion and probability of getting green economy.

7) Add dynamic opinions. Make mapping for opinions and how they change function, the mapping can be based on all proposed metrics. But first we should try wealth, unemployment can be a sub case of low wealth, so it should cover the research.
	- Try Cubic polynomial approximation - hysterisis for opinion change dynamics.
	- Try sigmoid functions to be maping of different regions, for examples in EU discrepancy in opinions is lower than in US.
	- Other ideas can be used for initialization of the model (political vs scientific)

4) Find out why brown energy is always persistent in the economy and why it goes to 0 and bounces back in the green economy. 
8) Perform test on taxation of CP with high Emissions, progressive tax should work and introduce feeding loops.
    


# Nice ToDo:
1) Migrate to the newer version of Agents.jl
2) Modify Isaak's Diagram to be in line with my Thesis Research
3) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works kinda by "magic"
4) There are some resizing of arrays, if we keep them fixed it might make code faster
5) Move all visualizations to Julia for speed improvements



# Notes:
- How to get results of simulation? Copy the 'data' from code folder to results folder and afterwards run the analyzers
- When money market/index funds start balooning it means that something is going off in the economy. Keep an eye on it!
- Stability of the system can be measured with the Coefficient of Variation
- GitHubs: debraj001, vallematteo

- Check if there are more CP in the list of HH it might improve speed of convergence/stability.     <- No difference
- Experiment with sizes of economy to see improvement in the CI                                     <- No difference
- Check GDP Growth dynamics, how to maximize it? How economy scaling works in green vs brown?       <- In general dynamics of the GDP are same, only that green is ending slightly higher, because of lower energy costs. However, we can see a slight drop in GDP at the same time points as the previous experiment.
- Investigate the volatility of emission producers, with what is it connected?                      <- It happens when dominant energy source is changed, or one of them goes extinct. Plausible explanation is that it changes emissions, and as a result highly sutainably households start buying previously deemed unsustainable products from the old inventory. Another possible scenario is once energy source is settled CP start competing on machine productivity, thus growing expenses and increase in production/demand (probably first though). Additional finding, companies that postpone upgrade of machinery do it in cycles sometimes.



# Current Questions:
-



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

Q - What is LIS in results visualization?
A - Labor Income Share

Q - What is the appropriate horizon for the simulation? How to choose it?
A - It is calibrated for the size of economy and warmup period (which can be discarded for visualization)

Q - When we change size of simulation, or some parameters are increased alone it produces very strange results some times. How were initial parameters chosen? Should just a recalibration solve this?
A - It is calibrated originally for the given size, both money market, government intervention etc.

Q - How should we implement features and perform tests? For example should I first integrate sustainability in job market or first should I integrate everything for the opinion dynamics and perform experiments with it alone?
A - First exhaustive test should be performed on the existent features, later we can compare them all

Q - Should I start comparing to the model with no opinion? Or should we do it at all?
A - We compare all, but build up features one by one.