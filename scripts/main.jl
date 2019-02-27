# This script runs Moore et al's agirculture component for SSP2 with temperature input from DICE.
# It runs for all five gtap DFS (two AgMIP and low, mid, and high meta-analysis).
# 

include("../src/MooreAgModel.jl")

output_dir = joinpath(@__DIR__, "../output/AgLossGTAP/")
mkpath(output_dir)

for gtap in MooreAgModel.gtaps

    m = MooreAgModel.get_model(gtap)
    run(m)
    AgLossGTAP = m[:agriculture, :AgLossGTAP]   # this is the percent loss variable calculated across all FUND regions and time periods (currently 2005 to 2300)
    writedlm(joinpath(output_dir, "AgLossGTAP_$gtap.csv"), AgLossGTAP, ',')

end