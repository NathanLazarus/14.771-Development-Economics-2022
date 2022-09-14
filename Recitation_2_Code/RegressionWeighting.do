clear
set obs 8
gen Y1 = 3 - 2 * inrange(_n,5,8)
gen Y0 = 0
gen treatment = 0
replace treatment = 1 if inrange(_n,1,3) | inrange(_n,5,6)


replace Y1 = . if treatment == 0
replace Y0 = . if treatment == 1
gen outcome = Y1 if treatment == 1
replace outcome = Y0 if treatment == 0

drop Y1 Y0
gen group = 1 + inrange(_n,5,8)
bys group: egen group_mean_of_treatment = mean(treatment)
gen var_component = (treatment - group_mean_of_treatment)^2
bys group: egen var_treatment = mean(var_component)
drop group_mean_of_treatment var_component
gen regression_weight = var_treatment/(var_treatment[1] + var_treatment[5])


reg outcome treatment i.group
