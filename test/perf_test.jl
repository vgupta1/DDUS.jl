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

test_fb()