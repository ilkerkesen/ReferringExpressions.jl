# ReferringExpressions

[![Build Status](https://travis-ci.org/ilkerkesen/ReferringExpressions.jl.svg?branch=master)](https://travis-ci.org/ilkerkesen/ReferringExpressions.jl)

[![Coverage Status](https://coveralls.io/repos/ilkerkesen/ReferringExpressions.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ilkerkesen/ReferringExpressions.jl?branch=master)

[![codecov.io](http://codecov.io/github/ilkerkesen/ReferringExpressions.jl/coverage.svg?branch=master)](http://codecov.io/github/ilkerkesen/ReferringExpressions.jl?branch=master)

This package is Julia port of [this Python package](https://github.com/lichengunc/refer). First, you need to add and build the package,

```julia
julia> Pkg.clone("git@github.com:ilkerkesen/ReferringExpressions.jl.git")
julia> Pkg.build("ReferringExpressions")
```

To start with, initialize a ```RefExpData``` instance,

```julia
using ReferringExpressions
refexp = RefExpData("refclef", "unc")
refexp = RefExpData("refclef", "berkeley") # 2 training and 1 testing images missed
refexp = RefExpData("refcoco", "unc")
refexp = RefExpData("refcoco", "google")
refexp = RefExpData("refcoco+", "unc")
refexp = RefExpData("refcocog", "google") # testing data haven't been released yet
refexp = RefExpData("refcocog", "umd") # train/val/test split provided by UMD
```

You need to download images manually and link them to ```Pkg.dir("ReferringExpressions")```. See [src/ReferringExpressions.jl](src/ReferringExpressions.jl) for much more information about usage.
