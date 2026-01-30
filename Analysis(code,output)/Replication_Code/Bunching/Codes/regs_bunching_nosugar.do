//Bunching estimator to estimate effects of PRA on employment

//Arguments: results_label labels the particular set of results
args upper_bound_tr lower_bound_tr bin_size workweek_bin results_label

//Set default values for arguments
if "`upper_bound_tr'" == ""{
	local upper_bound_tr =  40 	//Hours above workweek limit 
}
if "`lower_bound_tr'" == ""{ 
	local lower_bound_tr =  25	//Hours below workweek limit	
}
if "`bin_size'" == ""{
	local bin_size =  4			//Workweek bin size 
}

//Label months
label define month_labels 1 "1933m1"  2 "1933m2"  3 "1933m3"  4 "1933m4"  5 "1933m5"  6 "1933m6" ///
7 "1933m7"  8 "1933m8"  9 "1933m9"  10 "1933m10"  11 "1933m11"  12 "1933m12"  ///
13 "1935m1"  14 "1935m2"  15 "1935m3"  16 "1935m4"  17 "1935m5"  18 "1935m6" ///
19 "1935m7"  20 "1935m8"  21 "1935m9"  22 "1935m10"  23 "1935m11"  24 "1935m12", replace

//Set months to include as "around" the PRA including pre- and post-
local treatment_months_1933 "1 2 3 4 5 6 7 8 9 10 11 12"
local treatment_months_1935 "1 2 3 4 5 6 7 8 9 10 11 12"

//Include all data from 1933 & 1935
use "Data/Generated/establishment_analysis_monthly.dta" if included_industry == 1 & valid_imputed_workweek == 1 & (year == 1933 | year == 1935) & !inlist(industry_code_num, 131), clear

//Option to override actual workweek limits and use common workweek limit
if "`workweek_bin'" ~= ""{
	replace workweek_limit = `workweek_bin' 
}

//Month-year variable
egen monthyear = group(year month)
label values monthyear month_labels

//Treatment months
local treatment_months = "`treatment_months_1933'"	
foreach m in `treatment_months_1935'{
    local monthyear_to_add = `m' + 12
	local treatment_months = "`treatment_months' `monthyear_to_add'"
}
local treatment_months_str: subinstr local treatment_months " " ",", all

//Generate workweek bins & treatment indicator
gen l_b = floor( (imputed_workweek - workweek_limit) / `bin_size')
gen bin_above_pra_cutoff = l_b >= 0
gen tr = inlist(monthyear, `treatment_months_str') == 1 &  l_b*`bin_size'  > - `lower_bound_tr' & l_b*`bin_size' <= `upper_bound_tr'

//Shift l_b so minimum is 0 for processing coefficients laters 
qui sum l_b
local min_l_b = -`r(min)'
replace l_b = l_b + `min_l_b'

//Define bounds for for loop to build effect above and below the limit
local lower_bound_sc = `min_l_b' - max(floor(`lower_bound_tr'/`bin_size'), `min_l_b') 
local upper_bound_sc = `min_l_b' + min(floor(`upper_bound_tr'/`bin_size'), `r(max)')

//Calculate averages weighted by employment
gen ewemt_wgt = round(ewemt)
replace ewemt = 1
collapse (sum) ewemt (first) tr bin_above_pra_cutoff month year [fw = ewemt_wgt], by(monthyear industry_code_num l_b)

//Express effects as % of employment in basemonth
gen basemonth = 1 if month == 7 & year == 1933 //Use July 1933 value
bysort industry_code_num basemonth month year: egen ewemt_sum = sum(ewemt) if basemonth ~= .
carryforward ewemt_sum, replace
gen ewemt_normalized = ewemt / ewemt_sum

//Regress normalized employment on month-year x workweek x treatment + treatment + FEs at industry-month level
qui reghdfe ewemt_normalized i.monthyear#i.l_b#c.tr tr, vce(cluster industry_code_num) absorb(l_b##industry_code_num monthyear##industry_code_num) 

preserve
	//Generate Cengiz et al. "Fig. 2"
	regsave
	//Extract coefficients
	split var, gen(type) parse("#")
	drop if coef==0 | var == "_cons"
	rename type1 monthyear
	replace monthyear = subinstr(monthyear, "1b", "1", .)
	destring monthyear, replace ignore(".monthyear")
	rename type2 hourbin
	destring hourbin, replace ignore(".l_b")
	replace hourbin = hourbin - `min_l_b'
	drop type3
	//Total effect over all months by hourwin
	collapse (sum) coef, by(hourbin)
	qui sum hourbin
	local min = `bin_size'* `r(min)'
	local max = `bin_size'*`r(max)'
	gen id = 1
	replace hourbin = hourbin*`bin_size' - 1 //hourbin in units of hours
	bysort id (hourbin): gen sum_coef = sum(coef * (coef != coef[_n-1])) //running total of coeffs
restore

//Delta method calculation of standard errors for total effects above and below the workweek limit
gen diff_in_diff_estimator = .
gen se = .
forvalues type =0(1)1{
	local DinD_`type' = "0"
}
foreach month in `treatment_months'{
	forvalues type =0(1)1{
		local DinD_`type'_`month' = "0"
	}
 	forvalues hour = `lower_bound_sc'(1)`upper_bound_sc'{
		if `hour' > `min_l_b'{
			local type = 1
		}
		else{
			local type = 0
		}			
		local DinD_`type'_`month' ="`DinD_`type'_`month''+`month'.monthyear#`hour'.l_b#c.tr" 	
		if `month' == 7{ //Set July 1933 coeffs. to 0
 			local DinD_`type' = "`DinD_`type'' + `month'.monthyear#`hour'.l_b#c.tr"
		}
	}
}

//Test DinD coefficients
forvalues type =0(1)1{
	foreach month in `treatment_months'{	
		local DinD_`type'_`month' = "`DinD_`type'_`month'' - (`DinD_`type'')"
		qui lincom `DinD_`type'_`month''
 		replace se = 100*`r(se)' if monthyear == `month' & bin_above_pra_cutoff == `type'
 		replace diff_in_diff_estimator = 100* `r(estimate)' if monthyear == `month' & bin_above_pra_cutoff == `type'
	}
}

//Plot out DinD estimates for `treatment_months'
keep if inlist(monthyear, `treatment_months_str')
collapse (first) se diff_in_diff_estimator month year, by( monthyear bin_above_pra_cutoff )

gen plot_diff_in_diff_estimator = diff_in_diff_estimator
format plot_diff_in_diff_estimator %9.3f
gen high_se = diff_in_diff_estimator + 2 * se
gen low_se = diff_in_diff_estimator - 2 * se

//Plot coeffs around the PRA 
keep if year == 1933 & (month>=4 & month<=10)
//Fig. 6 and Appendix Figs. 8, 9, and 10
twoway (scatter diff_in_diff_estimator monthyear if bin_above_pra_cutoff == 1, mlabel(plot_diff_in_diff_estimator) mlabsize(tiny) mlabp(4) xlabel(4(1)10)) (scatter diff_in_diff_estimator monthyear if  bin_above_pra_cutoff == 0, mlabel(plot_diff_in_diff_estimator) mlabsize(tiny) mlabp(4) xlabel(4(1)10)) (rcap high_se low_se monthyear),  xtitle("Month") ytitle("Employment as % of July 1933") legend(order(1 "Above Workweek Limit" 2 "Below Workweek Limit") position(6) rows(1))  xline(7.5)
graph export "Replication/Bunching/C3_VarDrop/regs_bunching_DinD`results_label'_aroundPRA_C3.pdf", as(pdf) replace


//Save estimates for calculating the elasticities
keep monthyear bin_above_pra_cutoff diff_in_diff_estimator
save "Data/Generated/Bunching/bunching_estimates_`upper_bound_tr'_`lower_bound_tr'_`bin_size'.dta", replace
