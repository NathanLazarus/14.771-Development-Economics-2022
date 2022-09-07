args = commandArgs(TRUE)
print(paste0("Job number is, ", args[1]))
install.packages("data.table", lib="/home/nlazarus/R/libs/", repos = "http://lib.stat.cmu.edu/R/CRAN/")
library(data.table)
for (i in 1:10) {
  n_groups = 10
  n_values = 2e8
  big_dt = data.table(grp = sample(1:n_groups), value = runif(n_values))
  group_sums = big_dt[, .(value_sum = sum(value)), grp]
  print(group_sums)
}