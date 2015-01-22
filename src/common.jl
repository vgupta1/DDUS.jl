#=
Generalized versions of the JuMPeR interface
Delegates to correct cutting plane algorithm via suppFcn
=#

typealias DDUSOracles Union(UMOracle, UIOracle, FBOracle, LCXOracle, UCSOracle)

# JuMPeR alerting us that we're handling this contraint
registerConstraint(w::DDUSOracles, rm::Model, ind::Int, prefs) =
    !get(prefs, :prefer_cuts, true) && error("Only cutting plane supported")

# JuMPeR wants us to generate a constraint for every uncertain constraint in inds
function generateCut(w::DDUSOracles, m::Model, rm::Model, inds::Vector{Int}, active=false)
    new_cons = {}
    rd = JuMPeR.getRobust(rm)
    for ind in inds
        con = JuMPeR.get_uncertain_constraint(rm, ind)
        cut_sense, xs, lhs_const = JuMPeR.build_cut_objective(rm, con, m.colVal)
        zstar, ustar = suppFcn(xs, w, cut_sense)
        lhs_of_cut = zstar + lhs_const

        # SUBJECT TO CHANGE: active cut detection
        if active
            push!(rd.activecuts[ind], 
                JuMPeR.cut_to_scen(ustar, 
                    JuMPeR.check_cut_status(con, lhs_of_cut, w.cut_tol) == :Active))
            continue
        end

        # Check violation
        if JuMPeR.check_cut_status(con, lhs_of_cut, w.cut_tol) != :Violate
            w.debug_printcut && JuMPeR.debug_printcut(rm ,m,w,lhs_of_cut,con,nothing)
            continue  # No violation, no new cut
        end
        
        # Create and add the new constraint
        new_con = JuMPeR.build_certain_constraint(m, con, ustar)
        w.debug_printcut && JuMPeR.debug_printcut(rm, m, w, lhs_of_cut, con, new_con)
        push!(new_cons, new_con)
    end
    return new_cons
end

# JuMPeR asking us for any reformulations we might want to make - we make none
generateReform(w::DDUSOracles, m::Model, rm::Model, inds::Vector{Int}) = 0