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

# Note: How to get results of simulation
Copy the 'data' from code folder to results folder and afterwards run the analyzers

# Current Questions:
1) What is LIS in results

# Current ToDo:
1) Investigate results obtained from plot_macro_var
2) Make sense of the hh_tracking
3) Run simulation multiple times to see if it changes results