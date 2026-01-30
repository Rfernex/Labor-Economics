//Prepare time variables at quarterly frequency

//Variable labels
local label_ewemt "Employment"
local label_emh "Manhours"
local label_imputed_workweek "Workweek"

//Average workweek by quarter
gen quarter = . 
forvalues quarter = 1(1)4{
	local start = 3*(`quarter'-1)+1
	local end = `start' + 2
	replace quarter = `quarter' if month >= `start' & month <= `end'
}

//Collapse to quarter-establishment-level (Can't use gcollapse because a string variable is being collapsed.)
collapse (mean) ewemt imputed_workweek emh (first) eql industry_code_num at_workweek_PRA_limit revenue_quartile included_industry valid_* region region_str d008_workweek, by(year quarter estabid_num)

//Set the panel
gen num_quarters = quarter + 4*year
label var num_quarters "Number of Quarters"
xtset estabid_num num_quarters, delta(1)

//Calculate time differences in (1) employment and (2) workweek relative to Q3
foreach var_to_diff in ewemt imputed_workweek emh{
	foreach quarter_lag in 1 2{
		local Q = 3 - `quarter_lag'
		//Log change
		gen change`Q'_l_`var_to_diff' = log(`var_to_diff' / l`quarter_lag'.`var_to_diff') if quarter == 3 //Only assign values for 3rd quarter
		label var change`Q'_l_`var_to_diff' "Change in Log `label_`var_to_diff'' (Q3-Q`Q')"
		//Level change
		gen change`Q'_`var_to_diff' = `var_to_diff' - l`quarter_lag'.`var_to_diff' if quarter == 3  //Only assign values for 4th quarter
		label var change`Q'_`var_to_diff' "Change in `label_`var_to_diff'' (Q3-Q`Q')"
	}	
}
