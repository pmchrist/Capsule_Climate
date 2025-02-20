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
0) All suppliers replacement and sampling in HH is done based solely on price           ! Fixed, now takes into account emissions too
1) Make sure that everything is calibrated to the initial original parameters           ! Done
2) Change visualization of Bunkruptcies from age to the global counter from model       ! Done
3) Make main HH variables duplicated in the model for easier access                     ! Done
4) Fixed the bug of "chaotic" crash of economy, from high cp bankruptcies               ! Done
    At the end, the issue boiled down to the fact that there was overborrowing. It occured because all of the Expected Demand was counted into the projected sales. It is the case for the properly working CP, but this assumption fails for the newcomers. As they do not have labor or in some cases machines to produce all the stuff to satisfy the demand. As a result they overextend credit line, get machines + some workers, produce few products and go bankrupt being not able to cover the first credit payment.
    Additionally, most of the time the CP got machines but not workers, to get workers they hiked salaries, to cover them they hiked prices, given old information. They did not manage to sell anything, payed elevated wages and went bankrupt, throwing economy into the inflationary loop. There were a lot of wages and no production with high bankruptcy rates. It was fixed by restricting financing for the CP in check_funding_restrictions_cp!
    Addition: The fix did not work for the shock case, as system's averages were too off. However, the issue is indeed the same. Now it is fixed. So, the problem was in the borrowing, but now instead of just limiting Demand Expected we go straight to the Demand Unsatisfied. It produces by far better results. Obviously, producers might not know their unsatisfied demand, but we can argue that creditors do. Additionally, the earliest try at fix where I just improved the convergence of the consumermarket, seems to work for many cases as it improved the Demand part, leaving unsatisfied Demand empty thereforew making additional borrowing restricted. Therefore, we either set market to a lot of steps or use Unsatisfied Demand. Btw, there is still the variable for lowering the borrowing, but it is higher now.
5) We now must have 3 types of visualizations: one sim same seed (Granular - Done), multiple sims same seed (Comparative - Done), multiple sims multiple seeds (Aggregate of the previous one - Done)                                                  ! Done
6) Provided plots make sense but it seems there is a chaos region introduced. To quantify it we should expand plot to a phase plot, Heatmap for Opinion vs p_f, check size of chaotic region. Heatmaps can be probabiltiies of green adoption based on initial parameters.      ! Done
	- Quantify stochasticity in the simulation with multiple runs.                          ! Done - Nearly zero
	- Check without opinion how smaller the chaos regions is.                               ! Done - It does not exist, was part of a bug on excessive borrowing
    - Create a heatmap of initial opinion and probability of getting green economy.         ! Done
    - Add Boxplot visualization of final steps and compare opinion for diff p_f             ! Done
7) Minor Fixes for Code:
    - Move new parameter which balances the borrowing into the global variables             ! Done
    - Clean up code                                                                         ! Done
    - Make all the demand functions more consistent (we normalize when there are zero emissions, do not do it)      # Done
    - Put average emiss per good in the model level (why is not there already?)             ! Done - Added through the index of climate metrics in the model
8) Perform shocks with taxation
    - There is a bug of a very low expected demand producers to be still alive after a lot of turns. (Fix it, probably some of the survivability params from Isaak changed are at blame)                                                             ! Done, it was not it, it is still about artifacts from point 4
    - The shocks seems to be working and do not crash the model. The issue seemed to be that some initial agents had too bad conditions, initial values were based on average in the society, but once economy is shocked they go down together. Solution is that now it is mandated that at least some machine are ordered for new CP (globalparam). And the projected production for the newcomers is done with average machine efficiency (this one is negligible)       ! Done
    - Very interesting results. It seems that consumer decisions indeed have influece, but a limited one. Shocks indeed amplify them, by a lot. In general, there is more variance in emissions when there is more opinion on sustainability, in general CP emissions are lower and Machiens are more effective. There is a better consensus towards the optimal production. The thing that I did not expect is that there is slower adoption of green energy by EP. It might be just by chance, as ther are only 24 repetitions.                                                   ! Done
    - To verify the CP emiss contributions a new metric should be added, percentage of CP Emissions to All Emiss        ! Done, still seamingly no difference
    - EE is supposed to be higher, and EF lower, currently we introduce EP emissions into CP and KP emissions calculations so that green and brown runs are compatible. But what if we do not do this and only compare on the same p_f levels?                  ! Done - this seems to be the biggest culprit of the no change in results. Now there is definitely lower carbon emissions. However, no idea why they are lower, as EE and EF are seemingly the same.
    - Perform tests with restrictions on the consumermarket process, people just consume everything     ! Done - there is an effect, but a very small one, more than everything with very high restrictions GDP drops
    - Fix the boxplot, it show strange stuff                             ! Done, I was passing labels wrong and it visualized multiple things at once.
    - Change em_index_cp_good to be just avg and mean.                   ! Done

    - Verify the emissions calculation for CP and KP, in the beginning I have added EP emissions in the calculation so that we can compare emissions per good in-between green and brown runs. However this seems to change dynamics. We have to either revert or to re-calibrate.          ! Kinda Done
        - I did an exhaustive run to compare both. Results are in general the same, just that CP emissions are scaled, so seems like no problem and we can keep comparative values for good emissions for different energy regimes. However, this is probably conceptually wrong. Should ask Isaak to be sure - like what is his interpretation why the emissions of machines do not go down in greener economy compared to brown?
    - Perform final exhaustive run, find out why overall emissions go lower. Or do they?        ! Kinda Done, it seems that opinion influences well the emissions, however extreme opinions stop economic processes and slows down overall progress. Moreover we can see the improvement in pi_EE and pi_EF of machines used proportionate to the opinion. It is small but still present. It exhibits the highest effect on the highest opinion, but highest opinion slows down the economy which grinds down the technological progress. Dig deeper after the meeting with the professor.
    - Do final run with all the changes reverted (CP and KP emissions calculation and 3 rounds for the consumermarket) and more repetitions (like a 100) for multiple shock levels.

9) Add dynamic opinions. Make mapping for opinions and how they change function, the mapping can be based on all proposed metrics. But first we should try wealth, unemployment can be a sub case of low wealth, so it should cover the research.
	- Try Cubic polynomial approximation - hysterisis for opinion change dynamics.
	- Try sigmoid functions to be maping of different regions, for examples in EU discrepancy in opinions is lower than in US.
	- Other ideas can be used for initialization of the model (political vs scientific)

10) Find out why brown energy is always persistent in the economy and why it goes to 0 and bounces back in the green economy. 
11) Perform test on taxation of CP with high Emissions, progressive tax should work and introduce feeding loops.
12) Some minor stuff with variables:
    - Market share is called profits in the output                                            ! Done, has been Renamed
    - Some of the variables are not saved properly, for example wage of CP or Good_Emiss, it tilts the results. Possible solution is to just keep stats of producers that are odler than 5, as they are stable.



# Nice ToDo:
0) Improve Graphs
1) Migrate to the newer version of Agents.jl    <- Probably not gonna happen, too many things to change
2) Modify Isaak's Diagram to be in line with my Thesis Research
3) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works kinda by "magic"
4) There are some resizing of arrays, if we keep them fixed it might make code faster
5) Move all visualizations to Julia for speed improvements
6) Data analysis pipeline is incosistent! Some stuff is dumped per each time step, some are aggregated inside of the model and saved into the model output. For example cp/kp production or amount of owned machines is mostly aggregated and saved into the model output as macroeconomy, which it isnt. Meanwhile for hh Income and Wealth is aggregated on the model level, but in parallel everything is dumped too. That is why we have two solutions for opinion, in one we aggregate it through the dumped files and through other we aggregate it in the model. It is definitely better to divide tasks and first run model and dump everything and analyze it later. For now most of the stuff is cramped in the model output. Better to reorganize it for consistency.



# Notes:
- How to get results of simulation? Copy the 'data' from code folder to results folder and afterwards run the analyzers
- When money market/index funds start balooning it means that something is going off in the economy. Keep an eye on it!
- Stability of the system can be measured with the Coefficient of Variation
- GitHubs: debraj001, vallematteo
- Agents@5.6.5 is used

- Check if there are more CP in the list of HH it might improve speed of convergence/stability.     <- No difference
- Experiment with sizes of economy to see improvement in the CI                                     <- No difference
- Check GDP Growth dynamics, how to maximize it? How economy scaling works in green vs brown?       <- In general dynamics of the GDP are same, only that green is ending slightly higher, because of lower energy costs. However, we can see a slight drop in GDP at the same time points as the previous experiment.
- Investigate the volatility of emission producers, with what is it connected?                      <- It happens when dominant energy source is changed, or one of them goes extinct. Plausible explanation is that it changes emissions, and as a result highly sutainably households start buying previously deemed unsustainable products from the old inventory. Another possible scenario is once energy source is settled CP start competing on machine productivity, thus growing expenses and increase in production/demand (probably first though). Additional finding, companies that postpone upgrade of machinery do it in cycles sometimes.



# Current Questions:
Q - I have changed intial NW parameters for CP, as they spawned with 0 machines and stayed idle for the simulation. Moreover, I found why increased convergence in the consumermarket helped. It just impoved the real difference between Demand Exp and Demand while minimizing the Demand Unexpected. As a result I know try to use the Demand Unsatisfied as it is without increasing steps. What is more correct?
A - 

Q - I have integrated the opinion everywhere now, it seems to not change anything, tho.
A - Shocks might help, otherwise we need an utility function too. Or try ignoring high polluters.

Q - So, sometimes when consumermarket process does not have a lot of steps, it falls into monopolies. This process seems to be more frequent with the sustainability opinion. Does it make sense?
A - It has been fixed, issue was in overborrowing and calculating of expected Demand



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




















