# This script runs the model with the Moore Agriculture for both the base and pulsed DICE 
# temperature series, then calculates the resulting SCC for a discount rate of 3%.
# Does this for all 5 gtaps and saves to `ouput/AgSCC/ag_scc.csv`

using MimiMooreEtAlAgricultureImpacts

discount_rate = 0.03
horizon = 2300

output_dir = joinpath(@__DIR__, "../output/AgSCC/")
isdir(output_dir) || mkpath(output_dir)

f = open(joinpath(output_dir, "ag_scc_$horizon.csv"), "w")

for gtap in MimiMooreEtAlAgricultureImpacts.gtaps
    ag_scc = MimiMooreEtAlAgricultureImpacts.get_ag_scc(gtap, prtp=discount_rate, horizon=horizon)
    println(gtap, ": \$", ag_scc)
    write(f, "$gtap,$ag_scc\n")
end

close(f)
