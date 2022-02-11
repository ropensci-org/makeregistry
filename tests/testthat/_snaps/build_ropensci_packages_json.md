# get_hosted_packages works

    Code
      unique(lapply(pkgs, names))
    Output
      [[1]]
      [1] "package" "url"     "branch" 
      

# get_other_packages works

    Code
      unique(lapply(pkgs, names))
    Output
      [[1]]
      [1] "package" "url"     "branch"  "subdir" 
      

