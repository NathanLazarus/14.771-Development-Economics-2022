library(ggplot2)
library(ritest)
library(cowplot)
library(doSNOW)

timestamp()

clusters = makeCluster(7)
registerDoSNOW(clusters)

pvalues = foreach(outer_seed = 1:10000, .combine = rbind, .packages = c("ggplot2", "cowplot", "foreach")) %dopar% {
  untreated_variance = 0.1
  treated_variance = 1
  constant_treatment_effect = 0
  N_treated = 100
  N_untreated = 200
  const = 0
  set.seed(outer_seed)
  data = rbind(
    data.table(
      id = 1:N_treated,
      treatment_status = 1,
      treatment_effect = constant_treatment_effect,
      epsilon = rnorm(N_treated, 0, treated_variance)
    ),
    data.table(
      id = (N_treated + 1):(N_treated + N_untreated),
      treatment_status = 0,
      treatment_effect = constant_treatment_effect,
      epsilon = rnorm(N_untreated, 0, untreated_variance)
    )
  )
  data[, outcome := const + treatment_status * treatment_effect + epsilon]
  
  # ggplot(data, aes(x = treatment_status, y = outcome)) +
  #   geom_point(alpha = 0.3) +
  #   theme_cowplot() +
  #   ggtitle('Outcome') +
  #   theme(plot.title = element_text(hjust = 0), axis.title.y = element_blank())
  # 
  # ggsave("RIdistribution.pdf")
  # reg = lm(outcome ~ treatment_status, data = data)
  # 
  # summary(reg)
  
  
  estimate = data[treatment_status == 1, mean(outcome)] - data[treatment_status == 0, mean(outcome)]
  
  
  RIestimates = foreach(this_seed = 5000:5999, .combine = rbind) %do% {
    random_indices = sample(nrow(data))
    estimateRI = data[treatment_status[random_indices] == 1, mean(outcome)] - data[treatment_status[random_indices] == 0, mean(outcome)]
    data.table(seed = this_seed, estimate = estimateRI)
  }
  
  pvalue = 1 - 2 * abs(ecdf(RIestimates$estimate)(estimate) - 0.5)
  
  data.table(estimate = estimate, pvalue = pvalue)

}
stopCluster(clusters)

pvalues[, `P Value` := round(pvalue, 2)]

ggplot(aes(x = `P Value`), data = pvalues) +
  geom_bar()

pvalues[, `Share of Simulations` := .N/nrow(pvalues), `P Value`]
pvalues_to_plot = pvalues[, .(`Share of Simulations` = .N/nrow(pvalues)), `P Value`]
timestamp()

ggplot(data = pvalues_to_plot, aes(x = `P Value`, y = `Share of Simulations`)) +
  geom_bar(stat="identity") +
  theme_cowplot() +
  ggtitle('Share of Simulations') +
  theme(plot.title = element_text(hjust = 0), axis.title.y = element_blank())

ggsave("RIrejections.pdf")
