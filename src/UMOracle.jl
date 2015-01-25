#####
# UM
#####
export UMOracle

#returns zstar, ustar
function suppFcnUM(xs, lquants, uquants, cut_sense=:Max)
    const d = length(lquants)

    zstar = 0.0
    for i in 1:d
        mn, mx = minmax(lquants[i] * xs[i], uquants[i] * xs[i])
        zstar += ifelse(cut_sense == :Min, mn, mx)
    end

    ustar = Array(Float64, d)
    posxopt = (cut_sense == :Min) ? lquants : uquants
    negxopt = (cut_sense == :Min) ? uquants : lquants
    for i in 1:d
       ustar[i] = xs[i] > 0 ? posxopt[i] : negxopt[i]
    end
    
    return zstar, ustar
end

function calc_s(data, eps_, alpha)
	N, d = size(data)
	if (1-eps_/d)^N  > alpha / 2d
		return N + 1
	else
		dBin = Binomial(N, 1-eps_/d)
		return quantile(dBin, 1-alpha/2d)
	end
end

######################
type UMOracle <: AbstractOracle
    lquants::Vector{Float64}
    uquants::Vector{Float64}
    cut_tol::Float64  ##defaults to 1e-6

    # Other options
    debug_printcut::Bool
end

suppFcn(xs::Vector, w::UMOracle, cut_sense) = 
        suppFcnUM(xs, w.lquants, w.uquants, cut_sense)

#Preferred Interface
function UMOracle(data, lbounds, ubounds, eps_, alpha; cut_tol=1e-6, debug_printcut=false)
	s = calc_s(data, eps_, alpha)
	N = size(data, 1)
	@assert N- s + 1 < s "UM: N not sufficiently big N: $N \t s: $s"
	if s == N + 1
		return UMOracle(lbounds, ubounds, cut_tol, debug_printcut)
	else
		data_sort = sort_data_cols(data)
		return UMOracle(vec(data_sort[N-s+1, :]), vec(data_sort[s, :]), cut_tol, debug_printcut)
	end
end

function setup(w::UMOracle, rm::Model, prefs)
    # Extract preferences we care about
    w.debug_printcut = get(prefs, :debug_printcut, false)
    w.cut_tol        = get(prefs, :cut_tol, w.cut_tol)
    rd = JuMPeR.getRobust(rm)
    @assert (rd.numUncs == length(w.lquants)) "Num Uncertainties $(rd.numUncs) doesn't match columns in lquants $(w.lquants)"
    @assert (rd.numUncs == length(w.uquants)) "Num Uncertainties $(rd.numUncs) doesn't match columns in uquants $(w.uquants)"
    @assert (length(rd.uncertaintyset) == 0) "Auxiliary constraints on uncertainties not yet supported"
end