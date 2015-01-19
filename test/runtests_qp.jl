###
# DDUS tests relying on QP funcitonality
####
# Merge these into main test suite when default solver in JuMPeR supports QPs

using DDUS
using FactCheck
using JuMPeR

include("test_helpers.jl")  #loads up generic functionality


facts("portTest2  UCS bounds") do
	srand(8675309); data = randn(500, 2)
	w = UCSOracle(data, .1, .1, .1)
	portTest(w, -2.4604223389522866, [0.530985977658841, 0.46901402234115896], TOL=1e-6,
			unc_lower=[-1e6, -1e6], unc_upper=[1e6, 1e6])
end
