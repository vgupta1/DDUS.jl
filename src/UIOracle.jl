###
# UI Oracle 
###

export UIOracle

type UIOracle <: AbstractOracle
    lbounds::Vector{Float64}
    ubounds::Vector{Float64}
    data_sort::Matrix{Float64}
    log_eps::Float64

    # Cutting plane algorithm
    qL::Vector{Float64}
    qR::Vector{Float64}
    cut_tol::Float64  ##defaults to 1e-6

    # Other options
    debug_printcut::Bool
end

#preferred constructor
function UIOracle(data, lbounds, ubounds, eps, alpha; cut_tol = 1e-6) 
    N, d = size(data)
    data_sort = sort_data_cols(data)
    Gamma = KSGamma(alpha, N)
    qL, qR = gen_ql_qr(N, Gamma)
    UIOracle(vec(lbounds), vec(ubounds), data_sort, log(1/eps), qL, qR, 1e-6, false)
end

#returns bool, and ustar for degen case
is_degen(d, Gamma, log_eps) = d * log(1/Gamma) <= log_eps
degen_case(xs, lbounds::Vector{Float64}, ubounds::Vector{Float64}) = [xs[i] >= 0 ? ubounds[i] : lbounds[i] for i =1:length(xs)]

function gen_ql_qr(N::Int, Gamma)
    qL = zeros(Float64, N+2)
    qL[1] = Gamma
    qL[2:floor(Int, N * (1-Gamma)) + 1] = 1/N
    qL[floor(Int, N * (1-Gamma)) + 2] = 1-sum(qL)
    @assert (abs(sum(qL)-1) <= 1e-10) "QL not normalized $(sum(qL))"
    return qL, qL[N+2:-1:1]
end

function suppFcnUI(xs, data, lbounds, ubounds, log_eps, Gamma; cut_sense=:Max, lam_min=1e-8, lam_max=1e2, xtol=1e-8)
    data_sort = sort_data_cols(data)
    qL, qR = gen_ql_qr(size(data_sort, 1), Gamma)
    suppFcnUI(xs, data_sort, lbounds, ubounds, log_eps, qL, qR, cut_sense, lam_min, lam_max, xtol)
end

#returns zstar, ustar
function suppFcnUI(xs, data_sort, lbounds, ubounds, 
                   log_eps, qL::Vector{Float64}, qR::Vector{Float64}, 
                   cut_sense, lam_min=1e-8, lam_max = 1e2, xtol=1e-8)
    sgn_flip = 1
    if cut_sense == :Min
        xs = -xs
        sgn_flip = -1
    end

    const N = size(data_sort, 1)
    const d = size(data_sort, 2)
    const Gamma = qL[1]

    if is_degen(d, Gamma, log_eps)
        ustar = degen_case(xs, lbounds, ubounds)
        return sgn_flip*dot(xs, ustar), ustar
    end

    #extend data with bounds, pre-condition for stability
    xdata = [lbounds'; data_sort; ubounds']
    cnst_term = 0.0
    for i = 1:d
        shift = xs[i] > 0.0 ? ubounds[i] : lbounds[i]
        cnst_term += xs[i]*shift
        for j = 1:N+2
            xdata[j, i] = xs[i]*(xdata[j, i] - shift)
        end
    end

    #objective for line-search
    #VG should you type annotate log_eps?
    function f(lam::Float64)
        val_out = lam*log_eps + cnst_term
        for i =1:d
            q = xs[i] > 0 ? qR : qL
            log_inner = 0.0
            for j = 1:N+2
                log_inner += q[j] * exp(xdata[j, i]/lam)
            end
            val_out += lam*log(log_inner)
        end
        val_out    
    end

    res = Optim.optimize(f, lam_min, lam_max)
    !res.converged && error("Lambda linesearch did not converge")
    lamstar = res.minimum

    #reconstruct optimal sol.
    ustar = zeros(Float64, d)
    for i = 1:d
        if xs[i] >= 0
            qstar = qR .* exp(xdata[:, i]/lamstar)
        else
            qstar = qL .* exp(xdata[:, i]/lamstar)
        end
        qstar /= sum(qstar)

        #use the unconditioned data to construct sol
        for j= 2:N+1
            ustar[i] += qstar[j]*data_sort[j-1, i]
        end
        ustar[i] += qstar[1]*lbounds[i] + qstar[N+2]*ubounds[i]
    end

    #Not checked for performance, but should always be true
    # println(res.f_minimum, "\t", dot(ustar, xs))
    #@assert abs(res.f_minimum - dot(ustar, xs)) <= 1e-6

    sgn_flip*dot(ustar, xs), ustar
end

#preferred interface
suppFcn(xs, w::UIOracle, cut_sense) = suppFcnUI(xs, w.data_sort, w.lbounds, w.ubounds, w.log_eps, w.qL, w.qR, cut_sense)

function setup(w::UIOracle, rm::Model, prefs)
    # Extract preferences we care about
    w.debug_printcut = get(prefs, :debug_printcut, false)
    w.cut_tol        = get(prefs, :cut_tol, w.cut_tol)
    rd = JuMPeR.getRobust(rm)
    @assert (rd.numUncs == size(w.data_sort, 2)) "Num Uncertainties $(rd.numUncs) doesn't match columns in data $(size(w.data_sort, 2))"
    @assert (length(rd.uncertaintyset) == 0) "Auxiliary constraints on uncertainties not yet supported"
end