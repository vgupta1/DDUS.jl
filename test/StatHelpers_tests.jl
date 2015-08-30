###
# Helper Tests
###
include("../src/helpers.jl")

facts("bootstrapping tests") do
	#single variate data
	srand(8765309)
	data = randn(1000)
	@fact boot(data, mean, .9, 10000) --> roughly(0.108, 1e-3)

	#multivariate data
	srand(8765309)
	data = randn(1000, 3)
	f= x->mean(minimum(x, 1)) # a nonsense function
	@fact boot(data, f, .9, 10000) --> roughly(-2.8777884239388682, 1e-8)
end

facts("t-approximations") do
	srand(8765309)
	data = randn(1000, 3)
	out = calcMeansT(data, .1)
	@fact out[1] --> roughly(0.004451891728022329, 1e-8)
	@fact out[2] --> roughly(0.06592683689569365, 1e-8)

	out = calcMeansT(data, .1, joint=false)
	@fact out[1] --> roughly(0.011243060792593858, 1e-8)
	@fact out[2] --> roughly(0.05913566783112214, 1e-8)
end

facts("fwdBackSigsTest") do
	srand(8675309); data = randn(100)
	sigfwd, sigback = calcSigsBoot(data, .1, 10000)
	@fact sigfwd  --> roughly(1.09, 1e-2)
	@fact sigback --> roughly(1.09, 1e-2)
end

facts("KSGammaTest") do
	@fact KSGamma(.1, 1000) --> roughly(0.0385517413380297)
end

facts("boot_mu_test") do
	srand(8675309); data = randn(100)
	@fact boot_mu(data, .1, 100) --> roughly(0.15,1e-2)
end

facts("boot_sigma_test") do
	srand(8675309); data = randn(100)
	@fact boot_sigma(data, .1, 100) --> roughly(0.20,1e-2)
end

facts("ab_thresh_test") do
	srand(8675309); data = randn(100, 3)
	@fact calc_ab_thresh(data, .2, 100, 100) --> roughly(0.177,1e-3)
end