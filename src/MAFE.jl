module MAFE

using DataFrames, DocStringExtensions, StatFiles


# Types
export Country, Congo, Ghana, Senegal
export Spell, SpellHistory, n_spells, get_spell, start_year, end_year, spell_years, spell_from_year_range
export MigrationHistory, Migration
export JobHistory, Job

# Stata files
export read_activity_file, read_migration_file, read_person_file, read_stata_file, clean_spells

# Making histories
export make_migration_history, make_job_history, make_job_histories, find_country

# Main
export count_wage_gains

include("constants.jl")
include("types.jl")
include("stata_files.jl")
include("main.jl")

end # module
