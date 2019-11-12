# Main: generate result

"""
	$(SIGNATURES)

Count how many persons have wages at home and abroad
"""
function count_wage_gains(ctry :: Country)
    phV = make_job_histories(ctry);
    n = length(phV);

    hasHomeWageV = falses(n);
    hasForeignWageV = falses(n);
    for j = 1 : n
        ph = phV[j];
        ns = n_spells(ph);
        if ns > 0
            for i_s = 1 : ns
                spell = ph.spellV[i_s];
                if (spell.income > 0.0)
                    if spell.ctry == homeCountry
                        hasHomeWageV[j] = true;
                    elseif spell.ctry > 0
                        hasForeignWageV[j] = true;
                    end
                end
            end
        end
    end

    nHome = sum(hasHomeWageV);
    nForeign = sum(hasForeignWageV);
    nWageGain = sum(hasHomeWageV .& hasForeignWageV);
    println("N with home wage: $nHome")
    println("N with foreign wage: $nForeign")
    println("N with wage gain: $nWageGain")
end



# ----------