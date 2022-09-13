clear

set obs 14
gen alpha_candidate = _n -1
gen data_value = alpha_candidate if (alpha_candidate == 1 | alpha_candidate == 4 | alpha_candidate == 6 | alpha_candidate == 10 | alpha_candidate == 12)
order data_value

// cap drop loss_function abs_diff_with_data_value
gen loss_function = .
gen abs_diff_with_data_value = .
local n_obs = _N
forvalues row_num=1/`n_obs' {
	replace abs_diff_with_data_value = abs(data_value - alpha_candidate[`row_num'])
	sum abs_diff_with_data_value
	replace loss_function = `r(sum)' in `row_num'
}
drop abs_diff_with_data_value
