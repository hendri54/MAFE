using Documenter, MAFE

makedocs(
    modules = [MAFE],
    format = :html,
    checkdocs = :exports,
    sitename = "MAFE.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/hendri54/MAFE.jl.git",
)
