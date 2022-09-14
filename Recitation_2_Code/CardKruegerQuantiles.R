if (!require(pacman)) install.packages("pacman"); library(pacman)
p_load(tidyverse, dummies, texreg, sandwich, lmtest, magrittr, quantreg, foreach, data.table, cowplot, viridis, stringr)

white_SE_lm = function(lm_object) coeftest(lm_object, vcov = vcovHC(lm_object, type = 'HC'))

list_index = function(list_to_index, index) lapply(list_to_index, function(x) x[, index])
print_coeftest_robust = function(lm_object) {
  print(white_SE_lm(lm_object))
}
texreg_robust = function(lm_list, digits = 3) {
  if (class(lm_list) == "lm") lm_list = list(lm_list)
  coeftest_out = lapply(lm_list, white_SE_lm)
  texreg(
    lm_list,
    override.se = list_index(coeftest_out, 2),
    override.pvalues = list_index(coeftest_out, 4),
    digits = digits
  )
}
dummy_out = function(x) suppressWarnings(dummy(x)) # A dependency issue causes this to always throw a warning



data = read.table("CardKrueger.dat")

names_from_codebook =
  c("SHEET", "CHAINr", "CO_OWNED", "NJ", "SOUTHJ", "CENTRALJ", "NORTHJ",
    "PA1", "PA2", "SHORE", "NCALLS", "EMPFT", "EMPPT", "NMGRS", "WAGE_ST",
    "INCTIME", "FIRSTINC", "BONUS", "PCTAFF", "MEAL", "OPEN", "HRSOPEN",
    "PSODA", "PFRY",  "PENTREE",  "NREGS", "NREGS11",  "TYPE2", "STATUS2",
    "DATE2", "NCALLS2", "EMPFT2", "EMPPT2", "NMGRS2", "WAGE_ST2", "INCTIME2",
    "FIRSTIN2", "SPECIAL2", "MEALS2", "OPEN2R", "HRSOPEN2", "PSODA2" , "PFRY2",
    "PENTREE2", "NREGS2", "NREGS112")

names(data)[1:length(names_from_codebook)] = names_from_codebook

data[data == "."] = NA

data =
  data %>% mutate_at(
    c("EMPPT", "EMPFT", "NMGRS", "EMPPT2", "EMPFT2", "NMGRS2", "WAGE_ST", "PSODA",
      "PENTREE", "PFRY", "PSODA2", "PENTREE2", "PFRY2", "HRSOPEN", "HRSOPEN2"),
    as.numeric) %$% rbind(
      .[.$STATUS2 == 3,], # Keep closed firms to avoid bias from attrition
      drop_na(., c("WAGE_ST", "WAGE_ST2", "EMPFT", "EMPPT", "EMPFT2", "EMPPT2", "NMGRS", "NMGRS2")))




# Employment = Full time + 1/2 Part time + managers
data$EMPTOT = data$EMPPT*0.5 + data$EMPFT + data$NMGRS
data$EMPTOT2 = data$EMPPT2*0.5 + data$EMPFT2 + data$NMGRS2
#Delta in employment
data$DEMP = data$EMPTOT2 - data$EMPTOT
data$RDEMP = (data$EMPTOT2 - data$EMPTOT)/data$EMPTOT



data =
  data %>%
  group_by(NJ) %>%
  mutate(prior_emp_decile = ntile(EMPTOT, 10)) %>%
  ungroup()
emp_decile_dummy = dummy_out(data$prior_emp_decile)
colnames(emp_decile_dummy) = paste0("Q", 1:10)
prior_emp_heterogeneity = lm(DEMP ~  emp_decile_dummy[, 2:10] + NJ:emp_decile_dummy[, 1:10], data = data)
texreg_robust(list(prior_emp_heterogeneity))

df = summary(prior_emp_heterogeneity)$df[2]
all_coefs = summary(prior_emp_heterogeneity)$coefficients
treatment_coefs = all_coefs[grep("NJ:", row.names(all_coefs)), ]
results_dt =
  data.table(
    treatment_coefs
  )[
    ,
    quantile := as.numeric(str_extract(row.names(treatment_coefs), "(?<=Q)[0-9]*$"))
  ][
    ,
    `:=`(lb = Estimate + qt(0.025, df) * `Std. Error`, ub = Estimate + qt(0.975, df) * `Std. Error`)
  ]
ggplot(results_dt) +
    geom_errorbarh(aes(y=quantile, xmin=lb, xmax=ub), height=0.3, size=1, color="steelblue")+
    geom_point(aes(y=quantile, x=Estimate)) +
    theme_cowplot() +
    scale_y_continuous(n.breaks = 10) +
    # scale_y_continuous(expand = expansion(mult = c(0, .1))) +
    # scale_x_continuous(expand = expansion(mult = c(0, .1))) +
    theme(axis.title.y = element_blank(), plot.title = element_text(hjust = 0)) +
    ggtitle("Quantile of Prior Employment (CATE)") +
    xlab("Treatment (New Jersey) Effect on Change in Employment")
ggsave("CATEResults.pdf")


ggplot(data.table(data), aes(x = DEMP, fill = factor(NJ), group = factor(NJ))) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("#000050", "#56B1F7"), labels = c("Pennsylvania", "New Jersey")) +
  theme_cowplot() +
  scale_y_continuous(expand = expansion(mult = c(0, .1))) +
  scale_x_continuous(expand = expansion(mult = c(0, .1))) +
  theme(axis.title.y = element_blank(), plot.title = element_text(hjust = 0),
        legend.position = c(0.07, 0.8), legend.title = element_blank()) +
  ggtitle("Density") +
  xlab("Change in Employment")
ggsave("EmploymentChangeDists.pdf")

quantile_reg_results =
    foreach(i = seq(1, 99, by = 1), .combine = rbind) %do% {
        quantile = 0.01 * i
        model = suppressWarnings(rq(data$DEMP ~ data$NJ, tau = quantile, data = data))
        result = suppressWarnings(data.table(t(summary(model)$coefficients[2,])))
        setnames(result, c("point_estimate", "lb", "ub"))
        cbind(result, data.table(quantile = i))
    }
quantile_reg_results[abs(ub) > 1e2, ub := NA][abs(lb) > 1e2, lb := NA]
quantile_reg_results[is.na(ub), ub := max(quantile_reg_results$ub, na.rm = TRUE)][is.na(lb), lb := min(quantile_reg_results$lb, na.rm = TRUE)]
ggplot(quantile_reg_results) +
    geom_errorbarh(aes(y=quantile, xmin=lb, xmax=ub), color="steelblue")+
    geom_point(aes(y=quantile, x=point_estimate)) +
    theme_cowplot() +
    scale_y_continuous(expand = expansion(mult = c(0, .1))) +
    scale_x_continuous(expand = expansion(mult = c(0, .1))) +
    theme(axis.title.y = element_blank(), plot.title = element_text(hjust = 0)) +
    ggtitle("Quantile of Change Distribution") +
    xlab("Treatment (New Jersey) Effect on Change in Employment")
ggsave("QuantileRegressionResults.pdf")