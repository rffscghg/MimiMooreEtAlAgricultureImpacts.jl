using DelimitedFiles
using Interpolations

const years = 2000:10:2300  # years used by Moore et al
const gtaps = ["AgMIP_AllDF", "AgMIP_NoNDF", "highDF", "lowDF", "midDF"]    # names of the five different welfare dataframes
const _default_horizon = 2300   # default end of SCC calculation

const pulse_year = 2020

const USD2005to1995 = 0.819710818   # from Delavane

const fund_datadir = joinpath(@__DIR__, "../../data/FUND params")
const dice_datadir = joinpath(@__DIR__, "../../data/DICE climate output")

# Moore et al uses regions in alphabetical order; need to be conscious of switching the regional ordering for running with FUND parameters
alpha_order = ["ANZ", "CAM", "CAN", "CEE", "CHI", "FSU", "JPK", "MDE", "NAF", "SAM", "SAS", "SEA", "SIS", "SSA", "USA", "WEU"]
alpha_order[[4, 9, 10]] = ["EEU", "MAF", "LAM"]     # three regions named slightly different: CEU, NAF, CAM --> EEU, MAF, LAM
const fund_regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
const switch_region_indices = [findfirst(isequal(region), alpha_order) for region in fund_regions]

# Returns the Moore gtap data points (16 regions x 3 points) in the FUND regional order
function get_gtap_df(gtap::String)
    gtap in gtaps ? nothing : error("Unknown gtap dataframe specification: $gtap.") # check that the provided gtap name is a valid name
    gtap_dir = joinpath(@__DIR__, "../../data/GTAP DFs")   # The five welfare dataframes from Fran Moore are in this folder
    gtap_data = Array(readdlm(joinpath(gtap_dir, "$gtap.csv"), ',', skipstart=1)')
    return gtap_data[switch_region_indices, :]
end

const gtap_df_all = reshape(reduce(hcat, [get_gtap_df(gtap) for gtap in gtaps]), (16, 3, 5))

# helper function for linear interpolation
function linear_interpolate(values::AbstractArray, original_domain::AbstractArray, new_domain::Union{AbstractArray,Number})
    # Build the interpolation object with linear interpolation between the provided points, and extrapolation beyond the points
    itp = extrapolate(interpolate((original_domain,), values, Gridded(Linear())), Line())

    # Get the interpolated values for the point(s) in new_domain
    if new_domain isa Number
        return itp(convert(Float64, new_domain)) # itp(x) returns a Ratios.SimpleRatio is x is just a single number, needs to be converted to a Float
    elseif new_domain isa Array
        return itp(new_domain)   # itp([x1, x2, etc]) returns an Array
    end
end

# TODO: implement quadratic interpolation correctly
# function quadratic_interpolate(values, original_domain, new_domain)
# itp = interpolate(values, BSpline(Quadratic(Free())), OnGrid()) # TODO: only works if original x values are 1,2,3,etc.
# return [itp[i] for i in new_domain]
# end
