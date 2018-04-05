# Data-Driven Uncertainty Sets (DDUS)

[![Build Status](https://travis-ci.org/vgupta1/DDUS.jl.svg?branch=master)](https://travis-ci.org/vgupta1/DDUS.jl)
[![Coverage Status](https://coveralls.io/repos/vgupta1/DDUS.jl/badge.svg)](https://coveralls.io/r/vgupta1/DDUS.jl)

In the spirit of reproducible research, **DDUS.jl** contains implementations of many of the uncertainty sets from the paper

> [Data-Driven Robust Optimization](https://link.springer.com/article/10.1007/s10107-017-1125-8) by D. Bertsimas, V. Gupta and N. Kallus, Mathematical Programming 167.2 (2018): 235-292.

This paper is available from [Mathematical Programming](https://link.springer.com/article/10.1007/s10107-017-1125-8) or the [Vishal Gupta's website](http://www-bcf.usc.edu/~guptavis/research.html).  


Uncertainty sets are implemented as "oracles" for use with [JuMPeR.jl](https://github.com/IainNZ/JuMPeR.jl). Specifically, I have implemented oracles for each of the following sets (Eq. numbers refer to previous paper):
- UM (Eq. 28) 
- UI (Eq. 18) 
- UFB (Eq. 23)
- UCS (Eq. 35)
- ULCX (Eq. 31)

More sets and additional features may be added going forward based on interest.  For the most part, our implementations closely follow the descriptions in the paper.  In a few places, we have opted for simpler, approximate formulae for improved efficiency where I felt the difference in practice was negligible.

## Citation
If you find this package useful, please consider citing the above paper as:

```bibtex
@article{bertsimas2018data,
  title={Data-driven robust optimization},
  author={Bertsimas, Dimitris and Gupta, Vishal and Kallus, Nathan},
  journal={Mathematical Programming},
  volume={167},
  number={2},
  pages={235--292},
  year={2018},
  publisher={Springer}
}
```

## Licensing
This code is available under the MIT License.  
Copyright (c) 2016 Vishal Gupta

Also, if you use any portion of the software, I'd appreciate a quick note telling me the application.  As an academic, I like hearing about when my work is used and when it (hopefully) has impact.  


## Usage

All our sets support JuMPeR's cutting plane functionality, but do not provide reformulations. Reformulation may be supported in the future based on need.  A typical invocation might be:

```julia
using JuMPeR, DDUSets
dd_oracle = UCSOracle(data, epsilon, alpha)

m = RobustModel()
# ... Build up the model #

setDefaultOracle!(m, dd_oracle)  # to uses this oracle for all constraints
```

or 
``` julia
addConstraint(m, x[1] * us[1] + xs[2] * us[2] <= 5, dd_oracle)  #only for this one constraint
```

Most oracles support a simple constructor as above, taking in the data and two parameters, `epsilon` and `alpha`.  Some oracles require additional information, such as the support of the uncertainty. (When in doubt, check the source file for the interface marked "preferred interface.") 

All oracles assume that the data are given with each example in a row, and each column representing one component of the uncertainty.  **The ordering of the columns is important** and is assumed to correspond to the index of the uncertainties in the optimization model.  (That is, u[1] is the uncertainty whose data is given by column 1.)  The parameters epsilon and alpha are described in detail the above paper, and roughly control the probability of infeasibility and the decision maker's tolerance for ambiguity, respectively.  See also below on tuning these parameters.

Although fairly robust (*punny*), the preferred constructors for oracles can sometimes be slow because they perform all of the data analysis required to construct the set.  When possible, one can reuse the same oracle for multiple constraints.  When solving different optimization problems in a loop, one can also used the specialized constructors for the oracles to customize the data analysis step.  (See the comments in the source code.)

## Examples
The examples folder contains a simple portfolio allocation demonstrating typical usage of the sets.  

## Choosing the "Right" set and Tuning Epsilon and Alpha in Practice
The cited paper proves that under certain conditions, each of the above sets satisfy a strong probabilistic guarantee.  In applications where it is important to have a provable guarantee on feasibility, those results can help guide the choice of set. 

Many applications, however, do not require provably good performance, just *practically* good performance.  In these cases, we suggest following the suggestions in Section 10 of the paper, and choosing the set, epsilon and alpha via cross-validation.  Some generic functionality to do this will (hopefully) be added soon.  In the meantime, ????? in the examples folder illustrates one possible cross-validation scheme for a particular example.  

