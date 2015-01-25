using DDUS

function test_fb()
    mfs     = [.1, .2]
    mbs     = [-.05, -.25]
    sigfs   = [1., 2.]
    sigbs   = [2., .5]
    w       = FBOracle(mfs, mbs, sigfs, sigbs, .1)

    # Warmup
    zstar, ustar = suppFcn([1.0, 1.0], w, :Min)
    # Benchmark Min
    @time for i in 1:1000000
        zstar, ustar = suppFcn([1.0, 1.0], w, :Min)
    end
    # Benchmark Max
    @time for i in 1:1000000
        zstar, ustar = suppFcn([1.0, 1.0], w, :Max)
    end
end

function test_um()
    lquants = [-.05, -.25]
    uquants = [.1, .2]
    w = UMOracle(lquants, uquants, 1e-6, false)

    # Warmup
    zstar, ustar = suppFcn([1, 1], w, :Min)
    # Benchmark Min
    @time for i in 1:1000000
        zstar, ustar = suppFcn([1, 1], w, :Min)
    end
    # Benchmark Min
    @time for i in 1:1000000
        zstar, ustar = suppFcn([1, -1], w, :Max)
    end
end

function test_ui()
    srand(8675309); data = rand(200, 2)
    w = UIOracle(data, [0, 0], [1, 1], .1, .2) 

    # Warmup
    zstar, ustar = suppFcn([1, 1], w, :Min)
    # Benchmark Min
    @time for i in 1:10000
        zstar, ustar = suppFcn([1, 1], w, :Min) 
    end
    #Profile.print(format=:flat)
    # Benchmark Max
    @time for i in 1:10000
        zstar, ustar = suppFcn([1, -1], w, :Max) 
    end
end

#test_fb()
#test_um()
test_ui()