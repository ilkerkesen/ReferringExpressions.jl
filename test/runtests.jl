using ReferringExpressions
using Base.Test

@test try
    refexp = RefExpData("refclef", "unc")
    true
catch err
    println("ERROR: $(err.msg)")
    catch_stacktrace()
end
