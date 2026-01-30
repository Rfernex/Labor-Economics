//Create the pre-post PRA establishment data
use "Data/Generated/establishment_analysis_monthly.dta" if month >= 4 & month <= 10 & month ~= 7, replace //Load just months in 3 month window around PRA enactment excluding July (the month of PRA enactment)

//Variables to keep for regressions
local vars_to_keep = "eql industry_code_num at_PRA_limit* over_PRA_limit* under_PRA_limit* *_quartile included_industry valid_* region d008_workweek region_str"
label var ewemt "Employment"
local labor_vars = "ewemt imputed_workweek* emh"

//Collect variable labels
foreach var_quartile of varlist *_quartile{
	local var_q = subinstr("`var_quartile'", "_quartile","", .)
	local l_`var_q': variable label `var_q'
}

foreach var_to_keep of varlist `vars_to_keep' `labor_vars'{
	local l_`var_to_keep': var label `var_to_keep'
}

//Define pre and post PRA periods where post is 3 month period Aug-Oct and pre is Apr - June
gen post_PRA = (month >= 8 & month <= 10)

//Create weighted average for workweek using employment as weight
foreach day_basis in "" "_six"{
	replace imputed_workweek`day_basis' = imputed_workweek`day_basis' * ewemt
}

//Collapse to pre-postPRA-establishment level (cannot use gcollapse because string variable is included)
collapse (sum) `labor_vars' (first) `vars_to_keep', by(year post_PRA estabid_num)

//Finish creating weighted average for workweek
foreach day_basis in "" "_six"{
	replace imputed_workweek`day_basis' = imputed_workweek`day_basis' / ewemt
}

//Create unweighted averages over 3 month period for other labor variables
replace ewemt = ewemt / 3
replace emh = emh / 3

//Relabel the variables after collapse
foreach var_to_keep of varlist `vars_to_keep' `labor_vars'{
	label var `var_to_keep' "`l_`var_to_keep''"
}

foreach var_quartile of varlist *_quartile{
	local var_q = subinstr("`var_quartile'", "_quartile","", .)
	label var `var_quartile' "`l_`var_q'' Quartile"
}

//Set the panel
gen num_time_period = post_PRA + 2*year
xtset estabid_num num_time_period, delta(1)

//Label variables before calculating changes
label var post_PRA "Post-PRA Period"

//Calculate pre-post (1) employment and (2) workweek
foreach var_to_diff of varlist `labor_vars'{
	local label_var: variable label `var_to_diff'
	gen change_l_`var_to_diff' = log(`var_to_diff' / l.`var_to_diff') if post_PRA == 1 	
	label var change_l_`var_to_diff' "Change in Log `label_var' (Post-Pre PRA)"
	gen change_`var_to_diff' = `var_to_diff' - l.`var_to_diff' if post_PRA == 1 		
	label var change_`var_to_diff' "Change in `label_var' (Post-Pre PRA)"
}	

//Define indicators for those affected by PRA
//Defn 1: At the limit after the PRA 
//Already defined in variable at_PRA_limit
//Defn 2: Not at limit before but at limit after the PRA
gen post_binding = at_PRA_limit - l.at_PRA_limit == 1
//Defn 3: Post-binding and negative adjustment in hours to get to limit
gen neg_adj = post_binding == 1 & change_l_imputed_workweek < 0

//Categorical variable corresponding to whether at PRA workweek limit
gen workweek_limit_category = 0
replace workweek_limit_category = 1 if under_PRA_limit == 1
replace workweek_limit_category = 2 if at_PRA_limit == 1
replace workweek_limit_category = 3 if over_PRA_limit == 1

//Final label adding and cleanup
label var workweek_limit_category "Workweek Length (Categorical)"
label var post_binding "Only Binding After PRA in Effect"
label var neg_adj "Negative Hours Adjustment to PRA Workweek"
label define workweek_categories 1 "Under" 2 "At PRA Limit" 3 "Over"
label values workweek_limit_category workweek_categories
label values industry_code_num industry_codes 

drop num_time_period

save "Data/Generated/establishment_analysis_prepost_PRA.dta", replace //save the dataset
