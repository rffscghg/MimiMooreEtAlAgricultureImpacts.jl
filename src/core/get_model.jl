using DelimitedFiles
using Mimi

"""
    MimiMooreEtAlAgricultureImpacts.get_model(gtap::String; 
        pulse::Bool=false,
        floor_on_damages::Bool = true,
        ceiling_on_benefits::Bool = false)

Return a Mimi model with one component, the Moore Agriculture component. The user must 
specify the `gtap` input parameter as one of `["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", 
"lowDF", "midDF"]`, indicating which gtap damage function the component should use. 

The model has a time dimension of 2000:10:2300, and the fund_regions are the same as the FUND model. 

Population and income levels are set to values from the USG2 MERGE Optimistic scenario. 
Temperature is set to output from the DICE model. If the user specifies `pulse=true`, then 
temperature is set to output from the DICE model with a 1 GtC pulse of CO2 emissions in 2020.

If `floor_on_damages` = true, then the agricultural damages in each timestep will not be allowed
to exceed 100% of the size of the agricultural sector in each region.
If `ceiling_on_benefits` = true, then the agricultural benefits in each timestep will not be
allowed to exceed 100% of the size of the agricultural sector in each region.
"""
function get_model(gtap::String;
    pulse::Bool=false,
    floor_on_damages::Bool=true,
    ceiling_on_benefits::Bool=false
)

    gtap in gtaps ? nothing : error("Unknown GTAP dataframe specification: \"$gtap\". Must be one of the following: $gtaps")

    # Read in the USG2 socioeconomics data 
    usg2_population = Array{Float64,2}(readdlm(joinpath(fund_datadir, "usg2_population.csv"), ',')[2:end, 2:end])   # Saved from SCCinputs.rdata from Delavane
    usg2_income = Array{Float64,2}(readdlm(joinpath(fund_datadir, "usg2_income.csv"), ',')[2:end, 2:end])   # Saved from SCCinputs.rdata from Delavane

    # Read in DICE temperature pathway
    dice_temp_file = pulse ? "dice_temp_pulse.csv" : "dice_temp.csv"
    dice_temp = readdlm(joinpath(dice_datadir, dice_temp_file), Float64)[:]

    params = Dict{Tuple,Any}([
        (:Agriculture, :population) => usg2_population[2:end, :],     # 2000:10:2300
        (:Agriculture, :income) => usg2_income[2:end, :],         # 2000:10:2300
        (:Agriculture, :pop90) => usg2_population[1, :],         # 1990 is the first row
        (:Agriculture, :gdp90) => usg2_income[1, :],             # 1990 is the first row
        (:Agriculture, :temp) => dice_temp,
        (:Agriculture, :agrish0) => Array{Float64,1}(readdlm(joinpath(fund_datadir, "agrish0.csv"), ',', skipstart=1)[:, 2]),
        (:Agriculture, :gtap_df_all) => gtap_df_all
    ])

    m = Model()

    set_dimension!(m, :time, years)       # const `years` defined in helper.jl
    set_dimension!(m, :fund_regions, fund_regions)   # const `fund_regions` defined in helper.jl

    add_comp!(m, Agriculture)

    # Access which of the 5 possible DFs to use for the damage function
    gtap_idx = findfirst(isequal(gtap), gtaps)
    gtap_df = gtap_df_all[:, :, gtap_idx]

    update_param!(m, :Agriculture, :gtap_df, gtap_df)
    update_param!(m, :Agriculture, :floor_on_damages, floor_on_damages)
    update_param!(m, :Agriculture, :ceiling_on_benefits, ceiling_on_benefits)

    update_leftover_params!(m, params)

    return m
end
