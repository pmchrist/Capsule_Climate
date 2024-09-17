Initial calibration seems to take a lot of time.
    Todo: Code needs restructuring and more details.+
        Integrate Emissions into household buying activity +
        Verify Results <-
        Add variety into households sustainability scores
        Add opinion dynamics

    Should we calibrate before each addition? Or only once parameters are added. For example Social parameter.
    What is the general workflow?

    1)  Add environmental awareness/opinion score into HH               ! Done
        Add environmental punishment into the Consumermarket process    ! Done
        Run tests                                                       ? What else test to run? Probably needs multiple simulations with random seeds (how to visualize though?) Maybe motivate dirty production? just to see it works/not
        Add Initialization of environmental opinion
        Add Opinion Dynamics
    2)  Add these scores to CP and KP (not sure if viable, check structure of original model)
    3)  Create Job Market based on opinion too!


# Current Questions:
0) Why unemployed have highest savings rate???
1) What is LIS in results visualization?
2) Price of Fossils is fixed, which is problematic. As is a very sensitive parameter which defines on what energy producer will do, and it changes all the balances for producers. Should we address this? Is it worth it? Have you tried it already?

# Performed Tests:
> Re-run baseline to check for the strange behavior
    Green production is not increasing!                         -> Is correct, depends on pricing of fossils
    At some point production is too high and exceeds demand     -> Probably is correct
    Energy prices become zero after burn-in period      -> Fixed, bug in init/update
    R&D budgets are also zero after burn-in period      -> Fixed, bug in init/update
> Check if CP emissions change at all based on the consumer preferences    -> Yes, but influence is very small, only can tip balance if price on fossils is on the tip [0.41, 0.42], 0.413 fossil price is critical for the baseline
> Previous point has been fixed by normalizing the emissions part + Changed from all stock into last production. It is now quite influencial and moves market preferences. Next is to improve opinion dynamics and the initialization.

# ToDo Conceptual:
1) Social Pillar integration into the Consumermarket process linear fomula presentation     -> Finalized
2) Modify Isaak's Diagram to be in line with my Thesis

# ToDo Research/Tests:
0) Some Errors:
    Emission calculation should be based on the current production not the whole stock (Fixed)
    How are machines are bought exactly?        (We should not change it as producers operate with economic incentives only)
    Problems with Green dominance:
        There is no R&D after some point?
        Energy prices go to zero?
1) Create a graph which shows CP income and their Emissions dependency      -> Done
2) Run simulation multiple times to see if it changes results
3) Implement opinion dynamics with random initialization

# ToDo Programming:
1) These model parameter updaters are not consistent and logic of initialize_global_params() and changing_params for GlobalParam struct is ugly and works by "magic"



# Programming Notes:
How to get results of simulation? Copy the 'data' from code folder to results folder and afterwards run the analyzers

# Research Notes:
Social Pillar integration into the HH consumption decision is done by linear combination of pricing and emissions.
We keep the latest emission/good and normalize them to rank companies on the sustainability.
    We decided to keep last emission/good instead of overall emission/all items. First, because second gives boost to new companies (they start more advanced), second consumers do not remember so back in time.
    Higher the oil prices higher the dispersion in emissions. Probably motivates innovation more.