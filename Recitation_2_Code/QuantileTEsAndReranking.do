set scheme s2color
clear
set obs 8
gen Y0 = mod(_n - 1, 4) * 2
gen Y1 = Y0 - 1
replace Y1 = 7 if (_n == 1 | _n == 5)
order Y1 Y0
gen treatment = inrange(_n,1,4)
gen outcome = Y1 if treatment == 1
replace outcome = Y0 if treatment == 0

qreg outcome treatment, quantile(0.5)

clear
set obs 4
gen quantile = _n * 0.2
gen TE = -1
replace TE = 7 in 4
gen QTE = 1
gen lb = 0.5
gen ub = 1.5


twoway (rcap lb ub quantile, lwidth(thin) lpattern(dash) lcolor(blue)) (scatter QTE quantile, mcolor(blue)), ///
yscale(range(-1.1, 7.1)) xtitle(" " "Quantile") ytitle("")  graphregion(color(white))  legend(off) ylabel(-1(2)7) title("Estimated Quantile TEs", position(11))
graph export "QuantileTEs.pdf", replace


twoway (scatter TE quantile, mcolor(blue)), ///
yscale(range(-1.1, 7.1)) xtitle(" " "Quantile") ytitle("")  graphregion(color(white))  legend(off) ylabel(-1(2)7) title("True TEs", position(11))
graph export "QuantilesofTEs.pdf", replace

