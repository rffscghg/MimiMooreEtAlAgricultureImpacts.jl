using Documenter, MimiMooreEtAlAgricultureImpacts

makedocs(
    modules=[MimiMooreEtAlAgricultureImpacts],
    sitename="Moore et al. Agriculture Documentation",
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md"
    ],
    format=Documenter.HTML(prettyurls=get(ENV, "JULIA_NO_LOCAL_PRETTY_URLS", nothing) === nothing)
)

deploydocs(
    repo="github.com/rffscghg/MimiMooreEtAlAgricultureImpacts.jl.git",
)
