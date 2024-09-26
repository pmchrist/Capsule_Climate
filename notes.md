# Done:

Phase 0 - Prepartion
Made code work - Needed correct versions of Julia and to rewrite the saving paths, as they were not supported on multiple platforms
Code restructured slightly, added comments, rewrote some minor stuff. Added explanations

Phase 1 - Creating Sustainable Consumer
Integrated Emissions into Consumermarket process - by linear combination of normalized price and emissions per good. (Took a lot of iterations)
Added an opinion dynamics system based on https://www.jasss.org/19/1/6.html so that people can weight price and emissions dynamically
Created Graphs to showcase how emissions influence CP and how opinion influences HH

Phase 2 - ???


# Current ToDo:
1)  Add environmental awareness/opinion score into HH               ! Done
    Add environmental punishment into the Consumermarket process    ! Done
    Run tests                                                       ! Done
    Add Initialization of environmental opinion                     ! Done
    Add Opinion Dynamics (Deffuant Model)                           ! Done
    Add Visualization of opinion dynamics                           ! Done
    Get Preliminary Results and Analyze them                        ! Done
2)  Add these scores to CP and KP (not sure if viable, check structure of original model)   -> Not sure if makes sense, but we can try
3)  Create Job Market based on opinion too!                                                 -> Probably a next stage
4)  Or is it better to start integrating S component into companies?                        -> Might be a next stage

# ToDo Conceptual:
1) Modify Isaak's Diagram to be in line with my Thesis Research

# To Fix:
1) In green economy emissions per good are higher than in brown economy, probably the energy source used is not used in calculations. If all energy is green there should be zero emissions. But won't it destroy the consumption process or will just amplify it? (This should also be an issue in Isaak's model)

# Nice ToDo:
1) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works by "magic"




# Done Research/Tests:
1) Emission calculation for the opinion should be based on the current production not the whole stock

# ToDo Research/Tests:
1) Problems with Green dominant economies: There is no R&D after some point? Energy prices go to zero? Are these two conected? They seemingly move together. INVESTIGATE!
2) Check if there are more CP in the list of HH it might improve speed of convergence/stability.
3) We have only one energy producer, which means that CP cannot decide which type of energy they will use. This seems like a crucial feture, needs more investigation on how it works currently. <- The issue is that when we have dirty production machines improve, meanwhile with green production they are not. So all these issues are connected. INVESTIGATE ASAP!



# Answered Questions:
Q - Should we calibrate before each addition? Or only once parameters are added. For example Social parameter. What is the general workflow?
A - The system is calibrated initially, and it should not be a problem.

# Current Questions:
0) Why unemployed have highest savings rate??? Something is fishy with the unemployment benefit, or just unemployment status. In general when people don't have money it spawns from somewhere.
1) What is LIS in results visualization?
2) Price of Fossils is fixed, which is problematic. As is a very sensitive parameter which defines on what energy producer will do, and it changes all the balances for producers. Should we address this? Is it worth it? Have you tried it already? I saw that in paper we just compare the results with the base case
3) I have incorporated E into the consumer's choice with a linear function. Should I also integrate a hard cut-off? Because there is a theory that we should just boycott high polluters, this should be a hard core solution. Should we also test such hypothesis? It will be problematic, as it blocks the current flow of consumption. (example: if none available, i.e. all polluters, hh will just consume, which is the case anyway)
4) How to initialize opinions? I just do beta distribution. Is it enough for now? Most of the research says that people have either no opinion or pollarized. Should I think about some stochastic shocks? Connect this thing to the overall emissions?
5) What is the appropriate horizon for the simulation? How to choose it?



# Programming Notes:
How to get results of simulation? Copy the 'data' from code folder to results folder and afterwards run the analyzers
