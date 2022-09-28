// Credit to Ed Davenport for this code


clear

local N = 4000
local T = 10
local firstYear = 3 
local lastYear = 7

set obs `N'

set seed 1900

gen i = _n 
gen epsN = rnormal()
gen E = round(runiform(`firstYear',`lastYear'))

set seed 49898

gen control = runiform() > 0.9

replace E = . if control == 1 

expand `T'

bysort i : gen t = _n 

gen K = t - E 

preserve 
	egen tag = tag(t)
	keep if tag == 1 
	keep t 
	set seed 399
	gen epsT = rnormal()
	tempfile toMerge
	save `toMerge'
restore 

merge m:1 t using `toMerge'

drop _merge 

sort i t 

set seed 9000

gen epsNT = rnormal()

gen D = K >= 0
replace D = 0 if K == . 

gen y = epsN + epsT + 3*D + epsNT 

local maxLag = (1 - `lastYear')*(-1)
local maxLead = `T' - `firstYear'

forvalues j = 1/`maxLag' {
	gen L_`j' = K == -`maxLag'+`j'-1
}

forvalues j = 0/`maxLead' {
	gen F_`j' = K == `j'
}

forvalues j = 1/`T' {
	gen t_`j' = t == `j'
}

*reghdfe y o.L_1 L_2-L_`maxLag' F_*, absorb(i t) cluster(i)

local temp = `maxLead' - 1 

reghdfe y L_* F_1-F_`temp' o.F_`maxLead', absorb(i t) cluster(i)

/*
event_plot ., shift(-1) stub_lag(L_#) stub_lead(F_#) plottype(scatter) default_look ///
                graph_opt(xtitle("Relative Periods") ytitle("Coefficients") xlabel(-6(1)7) )
*/

clear 

local temp = `maxLag' + `maxLead' + 1 

mat temp = J(`temp',3,.)

forvalues i = 1/`temp' {
	mat temp[`i',1] = e(b)[1,`i']
	mat temp[`i',2] = e(b)[1,`i'] - 1.96*sqrt(e(V)[`i',`i'])
	mat temp[`i',3] = e(b)[1,`i'] + 1.96*sqrt(e(V)[`i',`i'])
}

*mat temp = e(b)'

svmat temp

drop if _n == _N 

gen t = _n 

gen period = t - `maxLag' - 1
drop t 

summ period, d 
local min = r(min)
local max = r(max)

twoway scatter temp1 period || rcap temp2 temp3 period, color(blue%50) xline(-0.5, lcolor(red%50) lpattern(dash)) ytitle("Coefficients") xtitle("Relative Periods") xlabel(`min'(1)`max') ///
	plotregion(fcolor(white)) graphregion(fcolor(white)) legend(off)










