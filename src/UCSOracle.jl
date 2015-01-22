###
# UCS Oracle 
###
# At the moment only supports cutting planes
import JuMP.UnsetSolver  #remove this dependence

export UCSOracle
export suppFcn

type UCSOracle <: AbstractOracle
    eps_kappa::Float64
    Gamma1::Float64
    Gamma2::Float64

    # Cutting plane algorithm
    muhat::Vector{Float64}
    covbar::Array{Float64, 2}
    C::Array{Float64, 2}  #C'C = covbar
    cut_tol::Float64  ##defaults to 1e-6
    cut_model::Model
    cut_vars::Vector{Variable}
    unbounded_support::Bool   #True if no support bounds on any uncertainties

    # Other options
    debug_printcut::Bool
end

function UCSOracle(muhat, covhat, Gamma1, Gamma2, eps_)
    covbar = covhat + Gamma2 * eye(size(covhat)...)
    C = chol(covbar, :U)   #C'C = covbar
    UCSOracle(  eps_, Gamma1, Gamma2, muhat, covbar, C, 
                1e-6, Model(), Variable[], true, false)  
end

function UCSOracle(data, eps_, alpha1, alpha2; numBoots=10000)
    muhat  = vec(mean(data, 1))
    covhat = cov(data)
    Gamma1 = boot_mu(data, alpha1, numBoots)
    Gamma2 = boot_sigma(data, alpha2, numBoots)
    UCSOracle(muhat, covhat, Gamma1, Gamma2, eps_)
end

#preferred interface
UCSOracle(data, eps_, alpha; numBoots=10000) = UCSOracle(data, eps_, alpha/2, alpha/2, numBoots=numBoots)

#the supp fcn when support = Rd
function suppFcnUCSRd(xs, muhat, Gamma1, covbar, eps_k, cut_sense=:Max)
    toggle = 1.
    if cut_sense == :Min
        xs = copy(-xs)
        toggle = -1.
    end
    norm_x = norm(xs)
    sig_term = sqrt(xs' * covbar * xs)[1]
    ustar =  muhat + Gamma1/norm_x * xs 
    ustar += kappa(eps_k) * sig_term / norm_x / norm_x * xs
    dot(ustar, xs)*toggle, ustar
end

function suppFcn(xs, w::UCSOracle, cut_sense)
    if w.unbounded_support
        return suppFcnUCSRd(xs, w.muhat, w.Gamma1, w.covbar, w.eps_kappa, cut_sense)
    else
        setObjective(w.cut_model, cut_sense, sum([xs[ix] * w.cut_vars[ix] for ix=1:length(w.cut_vars)]))

        cut_solve_status = solve(w.cut_model, suppress_warnings=true)
        cut_solve_status != :Optimal && error("Cutting plane problem failed: $cut_solve_status")
        ustar = getValue(w.cut_vars)
        zstar = getObjectiveValue(w.cut_model)
        return zstar, ustar
    end
end

function setup(w::UCSOracle, rm::Model, prefs)
    # Extract preferences we care about
    w.debug_printcut = get(prefs, :debug_printcut, false)
    w.cut_tol        = get(prefs, :cut_tol, w.cut_tol)

    rd = JuMPeR.getRobust(rm)
    w.cut_model.solver   = isa(rd.cutsolver, UnsetSolver) ? rm.solver : rd.cutsolver

    d = size(w.covbar, 1)
    @assert (rd.numUncs == d) "Num Uncertainties doesn't match columns in data"
    @assert (length(rd.uncertaintyset) == 0) #does not support additional cnsts on unctertainties for now
    #w.cut_model.colCat   = rd.uncCat  #only supports continuous variables for now

    #if there are no bounds, can use the simpler support function
    w.unbounded_support = true
    for i = 1:d
        if (rd.uncLower[i] > -Inf) || (rd.uncUpper[i] < Inf )
            w.unbounded_support=false
            break
        end
    end

    #else build an SOCP for separation
    if ! w.unbounded_support
        @defVar(w.cut_model, rd.uncLower[i] <= us[i=1:d] <= rd.uncUpper[i])
        @defVar(w.cut_model, z1[1:d])
        @defVar(w.cut_model, z2[1:d])
        for i = 1:d
            setName(us[i], rd.uncNames[i])
            addConstraint(w.cut_model, us[i] == w.muhat[i] + z1[i] + dot(w.C[:, i], z2))
        end

        addConstraint(w.cut_model, dot(z1, z1) <= w.Gamma1^2 )
        addConstraint(w.cut_model, dot(z2, z2) <= kappa(w.eps_kappa)^2)
        w.cut_vars = us[:]
    end
end