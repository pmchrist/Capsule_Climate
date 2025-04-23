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
    This one is not happening. Because, it will add too many new research questions and broads scope too much!



# Current ToDo:
0) All suppliers replacement and sampling in HH is done based solely on price           ! Done
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
    - Verify the emissions calculation for CP and KP, in the beginning I have added EP emissions in the calculation so that we can compare emissions per good in-between green and brown runs. However this seems to change dynamics. We have to either revert or to re-calibrate.          ! Done
        - I did an exhaustive run to compare both. Results are in general the same, just that CP emissions are scaled, so seems like no problem and we can keep comparative values for good emissions for different energy regimes. However, this is probably conceptually wrong. Should ask Isaak to be sure (first check in the paper) - like what is his interpretation why the emissions of machines do not go down in greener economy compared to brown?
    - Perform final exhaustive run, find out why overall emissions go lower. Or do they?        ! Done
        - It seems that opinion clearly influences the emissions, however extreme opinions stop economic processes and slows down overall progress. Moreover we can see the improvement in pi_EE and pi_EF of machines used proportionate to the opinion (most of the time it is small but still present). It exhibits the highest effect on the highest opinion, but highest opinion slows down the economy which grinds down the technological progress and as a result we lose the emissions/gdp unit. Dig deeper after the meeting with the professor.
    - Do final run with all the changes reverted (CP and KP emissions calculation and 3 rounds for the consumermarket) and more repetitions (like a 100) for multiple shock levels.                                                                                     ! Done
        - Results are good. I have reverted all the changes to follow the original paper by Dosi. The thing is, that there are some quirks of green economy which were never documented in any of the research (like machines are not improving much). Overall, emissions go lower, proportionate with the opinion. If opinion is extreme it slows down the economy, all in line with previous experiments. Few notes on the parameters: Machines qualities are calculated as average, but not all machines are used neither not all the machines have same productivity to have this metric to work properly we need to make it weighted average. Same goes to the average emissions per good, not it is just average of all producers, however not all producers produce the same amount of good. Main metric for now is Emissions per GDP also Overall emissions of CPs both of them go down with opinion.

-> We are here ->
9) Some minor stuff with variables and visualizations:
    - Market share is called profits in the output                                            ! Done, has been Renamed
    - Some of the variables are not saved properly, for example wage of CP or Good_Emiss, it tilts the results. Also newcomer CPs have 0 emissions, which skews the aggregated average. Possible solution is to just keep stats of producers that are odler than 5, as they are stable. - Proposed solution, all the CP related variables should be weighted by production at turn, as some of them are much more influential                 ! Done, Good_Emiss are now weighted by the Q (production), other variable changed is labor produc and machine efficiency. Did not change wage. Moreover, carbon_emissions_cp is not avg it is just a sum, so left it as it is. The results are negligible, nearly non existent 1e-4 influence- Which is strange. -> INTERESTING FINDING: Emissions mainly go down because of the productivity improvement in the Labor. (Check the unemployment given the green transition and companies market sizes)
    - Add a heatmap visualization for each price level, instead of boxplot show the AVG and STD of all together.        ! In progress. Needs aggregate values througout all the folders, therefore will be a meta visualization (done by hand after gathering all results, for now)

10) Add dynamic opinions. Make mapping for opinions and how they change function, the mapping can be based on all proposed metrics. We first should try wealth(unemployment can be a sub case of low wealth, so it should cover the research)
	- Try Cubic polynomial approximation - hysterisis for opinion change dynamics.                                                      ! Done. Checked this thing, does not seem to add anything of value, should verify further though. From speaking with professor it seems that we do not need a square term. UPD: Did more testing, it once again either destroys dynamics or just moves the base point. Additionally, introduced it into the uncertainty of opinion. The results are as expected, it creates either one or few points where values concentrate, or just diverge into the extremes, i.e. there are different stable points given the parameters and initial values. It does not seem to add anything of value, as we have no idea what are the points in the society, better to just assume some variability.
	- Try sigmoid functions to be maping of different regions, for examples in EU discrepancy in opinions is lower than in US.          ! Done. The proposed idea to use Wealth with the sigmoid mapping was accepted. Integrated it to the model and it influences the results indeed, by increasing variance in Emissions per GDP.
	- Other ideas can be used for initialization of the model (political vs scientific)                                                 ! Done. We use different rules for uncertainty convergence based on opinion, the idea is given in the notes. It unfluences results, as expected.

-> We are here ->
11) Perform Experiments with the proposed dynamic opinions:
    - Comparing them all together:      There is definitely some difference between experiments based on the experiment. The setup is as: uncertainty and intial opinions are random (uniform distribution). Obviously, the most green result is with scientific experiment. However, we can see how polarized case in the politic setup is worse off than just random uniform, except in the green already economy, where polarized case is better off. Meanwhile, wealth experiment gives the most variance in results and is the worse off, and have the lowest average.
    - Comparing Politic:                Closer to the critical point the influence of the opinion is minimal, as results depend mostly on the emissions from EP transition, however we can see how the more consensus is more beneficial. Meanwhile, at the brown economy and green economy we can clearly see how the positive or negative bias in initial opinions moves the results as expected with the mean in the population. In the brown economy initialization at the center does not create strange results, only that when we give more weight to extremes we get better results on the average, meanwhile the more centralized the initialization the slightly worse we are off. However, in the green economy the more centralized consensus in the middle produces much better results than extremes.
    - Comparing Scientific:             Once again difference much lower at the critical point. In this case the more opinions are centralized in the beginning the less probability of them going up, as nobody knows about climate change to influence. Once we start introducing people at extremes opinion rapidly goes up, no matter the initial setup (brown economy). For the green economy, once again centralization hurts the positive dynamics, and the general pattern is the same.
    - Comparing Wealth:                 Not sure how to run them, there is explosion of possible setups. Just compare with baselines? As additional parameter.

Bonus on Opinioon: If I want to include opinion dynamics to showcase them. How to do it? Is there a measure of dispersion from mean? What if there are two means? Should I do something like a historgram of all the steps or show few runs together with different colors?

11) Write thesis chapter on experimens and explain the results of all the experiments (Fixed Opinion, Politic, Scientific, Wealth)      ! In Progress

11) Do experiments without the stabilized economy, when everything crashed with original params.

11) Find out why brown energy is always persistent in the economy and why it goes to 0 and bounces back in the green economy. 

QUESTION ABOUT BOXPLOT: So, I calculate mean in averages of multiple runs. I assume I need to find the variance for each run and calculate mean of it? Otherwise it is just close to zero.



# Nice ToDo:
0) Improve Graphs
1) Migrate to the newer version of Agents.jl    <- Probably not gonna happen, too many things to change
2) Modify Isaak's Diagram to be in line with my Thesis Research
3) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works kinda by "magic"          ! Abandonde. It is ok.
4) There are some resizing of arrays, if we keep them fixed it might make code faster       ! Abandoned. Does not worth the effort
5) Move all visualizations to Julia for speed improvements                                  ! Done
6) Data analysis pipeline is incosistent! Some stuff is dumped per each time step, some are aggregated inside of the model and saved into the model output. For example cp/kp production or amount of owned machines is mostly aggregated and saved into the model output as macroeconomy, which it isnt. Meanwhile for hh Income and Wealth is aggregated on the model level, but in parallel everything is dumped too. That is why we have two solutions for opinion, in one we aggregate it through the dumped files and through other we aggregate it in the model. It is definitely better to divide tasks and first run model and dump everything and analyze it later. For now most of the stuff is cramped in the model output. Better to reorganize it for consistency.                                    ! Abandoned. The granular level information is only useful for debuging. It is not computationally feasible to parse all of the company level informations. Much easier to aggregate on the model level.



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




















