using Mimi

"""
MimiMooreEtAlAgricultureImpacts.get_ag_scc(gtap::String; 
    prtp::Float64 = 0.03, 
    horizon::Int = _default_horizon,
    floor_on_damages::Bool = true,
    ceiling_on_benefits::Bool = false)

Return the Agricultural SCC for a pulse in 2020 DICE temperature series and constant 
pure rate of time preference discounting with the specified keyword argument `prtp`. 
Optional keyword argument `horizon` can specify the final year of marginal damages to be 
included in the SCC calculation, with a default year of 2300.

If `floor_on_damages` = true, then the agricultural damages in each timestep will not be
allowed to exceed 100% of the size of the agricultural sector in each region.
If `ceiling_on_benefits` = true, then the agricultural benefits in each timestep will not
be allowed to exceed 100% of the size of the agricultural sector in each region.
"""
function get_ag_scc(gtap::String;
    prtp::Float64=0.03,
    horizon::Int=_default_horizon,
    floor_on_damages::Bool=true,
    ceiling_on_benefits::Bool=false)

    horizon in years ? nothing : error("Invalid value: $horizon for `horizon`, must be within the model years.")

    # Run base model
    base_m = get_model(gtap, floor_on_damages=floor_on_damages, ceiling_on_benefits=ceiling_on_benefits)
    run(base_m)

    # Run model with pulse in 2020
    pulse_m = get_model(gtap, pulse=true, floor_on_damages=floor_on_damages, ceiling_on_benefits=ceiling_on_benefits)
    run(pulse_m)

    # calculate SCC 
    base_damages = dropdims(sum(base_m[:Agriculture, :agcost], dims=2), dims=2)
    pulse_damages = dropdims(sum(pulse_m[:Agriculture, :agcost], dims=2), dims=2)
    marginal_damages = (pulse_damages - base_damages) * 10^9 / 10^9 * 12 / 44  # 10^9 for billions of dollars; /10^9 for Gt pulse; 12/44 to go from $/ton C to $/ton CO2

    start_idx = findfirst(isequal(pulse_year), years)
    end_idx = findfirst(isequal(horizon), years)

    # Implement discounting as a 10-year step function as described by Delevane
    discount_factor = [(1 + prtp)^(-1 * t * 10) for t in 0:end_idx-start_idx]
    npv = marginal_damages[start_idx:end_idx] .* 10 .* discount_factor  # multiply by 10 so that value of damages is used for all 10 years

    ag_scc = sum(npv)

    return ag_scc
end
