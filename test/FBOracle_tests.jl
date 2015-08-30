#### 
# FB Oracle tests
####

facts("suppFcnTest FB") do
	mfs     = [.1, .2]
	mbs     = [-.05, -.25]
	sigfs   = [1., 2.]
	sigbs   = [2., .5]
	w       = FBOracle(mfs, mbs, sigfs, sigbs, .1)

	zstar, ustar = suppFcn([1, 1], w, :Min)
	@fact zstar -->  roughly(-4.724022297688992)
	@fact ustar[1] --> roughly(-4.213785691942581)
	@fact ustar[2] --> roughly(-0.5102366057464114)

	zstar, ustar = suppFcn([1, 1], w, :Max)
	@fact zstar --> roughly(5.098525912188081)
	@fact ustar[1] --> roughly(1.0597051824376162)
	@fact ustar[2] --> roughly(4.038820729750465)

	zstar, ustar = suppFcn([-1,  1], w, :Min)
	@fact zstar --> roughly(-2.7492629560940403)
	@fact ustar[1] --> roughly(2.0194103648752324)
	@fact ustar[2] --> roughly(-0.7298525912188081)

	zstar, ustar = suppFcn([-1,  1], w, :Max)
	@fact zstar --> roughly(6.319708517540586)
	@fact ustar[1] --> roughly(-3.0848542587702927)
	@fact ustar[2] --> roughly(3.234854258770293)
end

facts("portTest for FB") do
	srand(8675309); data = randn(500, 2)
	w = FBOracle(data, .1, .2)
	portTest(w, -1.791121672173153, [0.5840372921578592, 0.41596270784214084],TOL=1e-2)
end
