//Create the pre-post PRA data for the NICB industry data

//This code is very similar to the build_estab_prepost_PRA code.
use "Data/Generated/industry_NICB_analysis_monthly.dta" if month >= 4 & month <= 10 & month ~= 7, replace //Load just months in 3 month window around PRA enactment excluding August (the month of PRA enactment)

//Variables to calculate unweighted average
local vars_labor_unw = "emh ewemt payroll"
//Variables to calculate weighted average
local vars_labor_w =  "workweek hourly_earn weekly_earn"

//Collect variable labels
foreach var_to_keep of varlist `vars_labor_w' `vars_labor_unw'{
	local label_`var_to_keep': var label `var_to_keep'
}

//Define pre and post PRA periods where post is 3 month period Aug-Oct and pre is April - June
gen post_PRA = (month >= 8 & month <= 10)

//Create weighted averages using employment as weight
foreach var_labor_w in `vars_labor_w'{
	replace `var_labor_w' = `var_labor_w' * ewemt
}

//Collapse to pre-postPRA-establishment level (cannot use gcollapse because string variable is included)
collapse (sum) `vars_labor_unw' `vars_labor_w', by(year post_PRA industry_id)

//Finish creating weighted average
foreach var_labor_w in `vars_labor_w'{
	replace `var_labor_w' = `var_labor_w' / ewemt
}

//Create unweighted averages over 3 month period
foreach var_labor_unw in `vars_labor_unw'{
	replace `var_labor_unw' = `var_labor_unw' / 3
}

//Set the panel
gen num_time_period = post_PRA + 2*year
xtset industry_id num_time_period, delta(1)

//Calculate pre-post change in labor variables
foreach var_to_diff in `vars_labor_unw' `vars_labor_w'{
	label var `var_to_diff' "`label_`var_to_diff''"
	gen change_l_`var_to_diff' = log(`var_to_diff' / l.`var_to_diff') if post_PRA == 1
	label var change_l_`var_to_diff' "Change in Log `label_`var_to_diff'' (Post-Pre PRA)"
	gen change_`var_to_diff' = `var_to_diff' - l.`var_to_diff' if post_PRA == 1
	label var change_`var_to_diff' "Change in `label_`var_to_diff'' (Post-Pre PRA)"
}

label var post_PRA "Post-PRA Period"
drop num_time_period

save "Data/Generated/industry_NICB_analysis_prepost_PRA.dta", replace
