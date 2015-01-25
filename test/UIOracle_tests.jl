#### 
# UI Oracle tests
####
facts("suppFcnTest UI") do
	srand(8675309); data = rand(200, 2)
	w = UIOracle(data, [0, 0], [1, 1], .1, .2) 

	zstar, ustar = suppFcn([1, 1], w, :Max)	
	@fact zstar => roughly(1.8772156628616448, 1e-8)
	@fact ustar[1] => roughly(0.9385081140320037, 1e-8)
	@fact ustar[2] => roughly(0.9387075488296409, 1e-8)

	zstar, ustar = suppFcn([1, -1], w, :Max)
	@fact zstar => roughly(0.8932039312511011, 1e-8)
	@fact ustar[1] => roughly(0.9492096614168394, 1e-8)
	@fact ustar[2] => roughly(0.056005730165738316, 1e-8)

	zstar, ustar = suppFcn([-1, 1], w, :Max)
	@fact zstar => roughly(0.8767942540553981, 1e-8)
	@fact ustar[1] => roughly(0.06360683171372103, 1e-8)
	@fact ustar[2] => roughly(0.9404010857691192, 1e-8)

	#extra tests for Min and 0 entries
	zstar, ustar = suppFcn([-1, 1], w, :Min)
	@fact zstar => roughly(-0.893203928668029, 1e-8)
	@fact ustar[1] => roughly(0.9492096601291875, 1e-8)
	@fact ustar[2] => roughly(0.056005731461158545, 1e-8)

	zstar, ustar = suppFcn([0, 1], w, :Min)
	@fact zstar => roughly(0.001943343938739852, 1e-8)
	@fact ustar[1] => roughly(0.5715291128670335, 1e-8)
	@fact ustar[2] => roughly(0.001943343938739852, 1e-8)

	zstar, ustar = suppFcn([0, 1], w, :Max)
	@fact zstar => roughly(0.9981094005216729, 1e-8)
	@fact ustar[1] => roughly(0.5715291128670335, 1e-8)
	@fact ustar[2] => roughly(0.9981094005216729, 1e-8)

end

facts("portTest UI") do
	srand(8675309)
	data = rand(500, 2)
	w = UIOracle(data, [0., 0.], [1., 1.], .1, .2) 
	portTest(w, 0.07068906144892116, [0.5039487187951147, 0.4960512812048853])
end
