function get_probdists_gtap_df(gtap, n=1000)

    highDF = gtap_df_all[:, :, 3]
    lowDF = gtap_df_all[:, :, 4]
    midDF = gtap_df_all[:, :, 5]

    # For each region and temperature point we construct an interpolation where the x values are between 0 and 1
    # and the y values are the values from the three scenarios.
    dists = [LinearInterpolation([0., 0.5, 1.], [lowDF[r, temp], midDF[r, temp], highDF[r, temp]]) for r in 1:16, temp in 1:3]

    # We only sample one set of random numbers, as we want perfect correlation between all the individual
    # parameter values.
    samples = rand(TriangularDist(0., 1., 0.5), n)

    # Now evaluate the interpolated function we created above with the samples from the triangular distributions
    sample_stores = [Mimi.SampleStore(dists[r, temp].(samples)) for r in 1:16, temp in 1:3]

    if gtap in ["highDF", "midDF", "lowDF"]
        return sample_stores
    else
        @warn "No probability distributions available for gtap damage function entered ($gtap), returning `nothing`."
        return nothing
    end
end
