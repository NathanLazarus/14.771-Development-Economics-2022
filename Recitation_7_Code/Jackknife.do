clear
set seed 11
global n_obs = 10
set obs $n_obs
gen settler_mortality = runiform()
gen institution_quality = runiform()
gen lgdp = runiform()
replace institution_quality = 2 in 1
replace lgdp = 10 in 1
replace settler_mortality = 0 in 1
reg institution_quality settler_mortality
reg lgdp settler_mortality
ivregress 2sls lgdp (institution_quality = settler_mortality)
replace settler_mortality = 1 in 1
reg institution_quality settler_mortality
predict institution_hat
reg lgdp settler_mortality
ivregress 2sls lgdp (institution_quality = settler_mortality)
// equivalently for point estimates, you could do
// reg lgdp institution_hat
// but you won't get the right standard errors
gen loo_institution_hat = .
forvalues i = 1/$n_obs {
	qui reg institution_quality settler_mortality if _n != `i'
	predict _loo_institution_hat
	replace loo_institution_hat = _loo_institution_hat in `i'
	drop _loo_institution_hat
}
reg lgdp loo_institution_hat


clear
global n_obs = 10
set obs $n_obs
gen judge = 1 + (_n > 5)
gen sentence_length = runiform()
gen later_earnings = 25000*runiform()
replace sentence_length = 25 in 1
replace later_earnings = 0 in 1
reg sentence_length i.judge
reg later_earnings i.judge
ivregress 2sls later_earnings (sentence_length = i.judge)

