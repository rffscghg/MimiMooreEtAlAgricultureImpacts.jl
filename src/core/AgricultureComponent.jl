using Interpolations
using Mimi

# Moore et al Agriculture component (with linear interpolation between gtap temperature points)
@defcomp Agriculture begin

    fund_regions = Index()

    gdp90 = Parameter(index=[fund_regions])
    income = Parameter(index=[time, fund_regions])
    pop90 = Parameter(index=[fund_regions], unit="million")
    population = Parameter(index=[time, fund_regions], unit="million")

    agrish = Variable(index=[time, fund_regions])     # agricultural share of the economy
    agrish0 = Parameter(index=[fund_regions])        # initial share 
    agel = Parameter(default=0.31)            # elasticity

    agcost = Variable(index=[time, fund_regions])     # This is the main damage variable

    temp = Parameter(index=[time], unit="degC")              # Moore et al uses global temperature (original FUND ImpactAgriculture component uses regional temperature)

    # Moore additions:

    AgLossGTAP = Variable(index=[time, fund_regions]) # Moore's fractional loss (intermediate variable for calculating agcost)

    gtap_df = Parameter(index=[fund_regions, 3])  # three temperature data points per region

    floor_on_damages = Parameter{Bool}(default=true)
    ceiling_on_benefits = Parameter{Bool}(default=false)

    function run_timestep(p, v, d, t)
        for r in d.fund_regions
            ypc = p.income[t, r] / p.population[t, r] * 1000.0
            ypc90 = p.gdp90[r] / p.pop90[r] * 1000.0

            v.agrish[t, r] = p.agrish0[r] * (ypc / ypc90)^(-p.agel)

            # Interpolate for p.temp, using the three gtap welfare points with the additional origin (0,0) point
            impact = linear_interpolate([0, p.gtap_df[r, :]...], collect(0:3), p.temp[t])
            impact = p.floor_on_damages ? max(-100, impact) : impact
            impact = p.ceiling_on_benefits ? min(100, impact) : impact
            v.AgLossGTAP[t, r] = -impact / 100 # We take the negative to go from impact to loss

            # Calculate total cost for the ag sector based on the percent loss
            v.agcost[t, r] = p.income[t, r] * v.agrish[t, r] * v.AgLossGTAP[t, r]
        end
    end
end
