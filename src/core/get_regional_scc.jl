using Mimi

# """
# MimiMooreEtAlAgricultureImpacts.get_regional_scc(gtap::String; 
#     prtp::Float64 = 0.03, 
#     horizon::Int = _default_horizon,
#     floor_on_damages::Bool = true,
#     ceiling_on_benefits::Bool = false)

# Return the Agricultural SCC for a pulse in 2020 DICE temperature series and constant 
# pure rate of time preference discounting with the specified keyword argument `prtp`. 
# Optional keyword argument `horizon` can specify the final year of marginal damages to be 
# included in the SCC calculation, with a default year of 2300.

# If `floor_on_damages` = true, then the agricultural damages in each timestep will not be
# allowed to exceed 100% of the size of the agricultural sector in each region.
# If `ceiling_on_benefits` = true, then the agricultural benefits in each timestep will not
# be allowed to exceed 100% of the size of the agricultural sector in each region.
# """

function get_regional_scc(gtap::String;
    region_names::Union{Vector{String}, Nothing}=nothing,
    prtp::Float64=0.03, 
    horizon::Int=_default_horizon,
    floor_on_damages::Bool = true,
    ceiling_on_benefits::Bool = false)

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

    # normalize marginal damages to be (n_regions, n_years)
    n_years = length(years)
    if ndims(marginal_damages) == 1
        # single-region: turn into 1 x n_years
        marginal_damages = reshape(marginal_damages, 1, :)
    elseif ndims(marginal_damages) == 2
        # ensure second dimension is years; if it's transposed, fix it
        if size(marginal_damages, 2) != n_years && size(marginal_damages, 1) == n_years
            marginal_damages = transpose(marginal_damages)
        end
    else
        error("Unexpected dimensionality for marginal_damages: ndims=$(ndims(marginal_damages)), expected second dimesion should equal the number of model years")
    end

    # Determine region names: prefer the explicit argument, then fund_regions if available, else generate.
    if region_names !== nothing
        names_vec = region_names
    else
        if isdefined(Main, :fund_regions)
            names_vec = Main.fund_regions
        else
            names_vec = ["region_$(i)" for i in 1:size(marginal_damages, 1)]
        end
    end

    # Ensure names length matches number of regions
    if length(names_vec) != size(marginal_damages, 1)
        names_vec = ["region_$(i)" for i in 1:size(marginal_damages, 1)]
    end

    # Determine indices for the SCC horizon (same logic as get_ag_scc)
    start_idx = findfirst(isequal(pulse_year), years)
    end_idx = findfirst(isequal(horizon), years)
    start_idx === nothing && error("pulse_year $(pulse_year) not found in years.")
    end_idx === nothing && error("horizon $(horizon) not found in years.")

    # Implement discounting as a 10-year step function as described by Delevane
    discount_factor = [(1 + prtp) ^ (-1 * t * 10) for t in 0:end_idx-start_idx]

    # Take the relevant year slice
    marginal_subset = marginal_damages[:, start_idx:end_idx]   # regions x years_in_range

    # Build NPV matrix (regions x years_in_range)
    npv_matrix = marginal_subset .* 10 .* reshape(discount_factor, (1, length(discount_factor)))

    # Sum across years to get per-region NPV (SCC-like contribution)
    regional_scc_vec = vec(sum(npv_matrix, dims=2))

    # Map to names
    npv_by_region = Dict{String, Float64}()
    for (i, nm) in enumerate(names_vec)
        npv_by_region[string(nm)] = regional_scc_vec[i]
    end

    regional_scc = npv_by_region

    return regional_scc
    # return (
    #     years = years,
    #     region_names = names_vec,
    #     marginal_damages = marginal_damages,
    #     npv_matrix = npv_matrix,
    #     npv_by_region = npv_by_region,
    # )
end
