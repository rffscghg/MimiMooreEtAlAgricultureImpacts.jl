"""
    MooreAg.get_model(gtap::String; 
        pulse::Bool=false,
        floor_on_damages::Bool = true,
        ceiling_on_benefits::Bool = false)

Return a Mimi model with one component, the Moore Agriculture component. The user must 
specify the `gtap` input parameter as one of `["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", 
"lowDF", "midDF"]`, indicating which gtap damage function the component should use. 

The model has a time dimension of 2000:10:2300, and the regions are the same as the FUND model. 

Population and income levels are set to values from the USG2 MERGE Optimistic scenario. 
Temperature is set to output from the DICE model. If the user specifies `pulse=true`, then 
temperature is set to output from the DICE model with a 1 GtC pulse of CO2 emissions in 2020.

If `floor_on_damages` = true, then the agricultural damages (negative values of the 
`agcost` variable) in each timestep will not be allowed to exceed 100% of the size of the 
agricultural sector in each region.
If `ceiling_on_benefits` = true, then the agricultural benefits (positive values of the
`agcost` variable) in each timestep will not be allowed to exceed 100% of the size of the 
agricultural sector in each region.
"""
function get_model(gtap::String; 
    pulse::Bool=false,
    floor_on_damages::Bool = true,
    ceiling_on_benefits::Bool = false)

    gtap in gtaps ? nothing : error("Unknown GTAP dataframe specification: \"$gtap\". Must be one of the following: $gtaps")

    # Read in the USG2 socioeconomics data 
    usg2_population = Array{Float64, 2}(readdlm(joinpath(fund_datadir, "usg2_population.csv"),',')[2:end, 2:end])   # Saved from SCCinputs.rdata from Delavane
    usg2_income = Array{Float64, 2}(readdlm(joinpath(fund_datadir, "usg2_income.csv"),',')[2:end, 2:end])   # Saved from SCCinputs.rdata from Delavane
    
    # Read in DICE temperature pathway
    dice_temp_file = pulse ? "dice_temp_pulse.csv" : "dice_temp.csv"
    dice_temp = readdlm(joinpath(dice_datadir, dice_temp_file), Float64)[:]      

    params = Dict{String, Any}([
        "population" =>  usg2_population[2:end, :],     # 2000:10:2300
        "income" =>      usg2_income[2:end, :],         # 2000:10:2300
        "pop90" =>       usg2_population[1, :],         # 1990 is the first row
        "gdp90" =>       usg2_income[1, :],             # 1990 is the first row
        "temp" =>        dice_temp,
        "agrish0" =>     Array{Float64, 1}(readdlm(joinpath(fund_datadir, "agrish0.csv"), ',', skipstart=1)[:,2]),
        "gtap_df_all" => gtap_df_all
    ])

    m = Model()
    set_dimension!(m, :time, years)       # const `years` defined in helper.jl
    set_dimension!(m, :regions, fund_regions)   # const `fund_regions` defined in helper.jl
    add_comp!(m, Agriculture)
    set_param!(m, :Agriculture, :gtap_spec, gtap)
    set_param!(m, :Agriculture, :floor_on_damages, floor_on_damages)
    set_param!(m, :Agriculture, :ceiling_on_benefits, ceiling_on_benefits)
    set_leftover_params!(m, params)
    return m
end
