prefix = "http://bvisionweb1.cs.unc.edu/licheng/referit/data/"
datasets = ("refclef","refcoco","refcoco+","refcocog")
datadir = Pkg.dir("ReferringExpressions", "data")
isdir(datadir) || mkdir(datadir)
cd(datadir)
for dataset in datasets
    filename = dataset*".zip"
    download(prefix*filename, joinpath(datadir,filename))
    run(`unzip $filename`)
end
