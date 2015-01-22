#####
# Data-Driven Portfolio Allocation Example
#####
#Solves the w.c. portfolio allocation problem
##  max t
#   s.t. r^T x >= t  for all  r in U
#        1^T x == 1
#        x >= 0
# where U is constructed from data
using JuMPeR, DDUS, Distributions

#generates some silly market data for example
function genReturnData(numAssets, numObs)
	#Single factor CAPM model
	z = .1 * randn(numObs) + .2
	betas = linspace(0, 1, numAssets)
	z * betas' + .05*randn(numObs, numAssets)
end

##########
srand(8675309)
mkt_data = genReturnData(5, 500)

##
# Other sets can be constructed by suitably changing this line
oracle = UCSOracle(mkt_data, .1, .2)


#build model
m = RobustModel()
setDefaultOracle!(m, oracle)
@defVar(m, xs[1:5] >= 0)
@defVar(m, t)
@defUnc(m, us[1:5])
@addConstraint(m, sum(xs) == 1.)
addConstraint(m, sum([us[i] * xs[i] for i =1:5]) >= t)
@setObjective(m, Max, t)

#for now, must use cuts to solve
#Notice how set construction takes advantage of the correlations tructure
#So that allocation favors higher indices
println(solveRobust(m, prefer_cuts=true))
println("Obj Value:\t", getObjectiveValue(m))
println("Portfolio:\t", getValue(xs))

