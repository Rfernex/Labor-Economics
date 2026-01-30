//Taylor style regressions 
args SSNRA
if "`SSNRA'" == "" { //Default to SSNRA
	local SSNRA = 1 //SSNRA or COM data
}

local estab_opts = `"nonotes nostar se tex b(%12.3f) replace label varwidth(40) obslast nocon nomtitles"'	// star(* 0.1 ** 0.05 *** 0.01) [remove stars for AEA]
local absorb_vars industry_id year month  //variables to absorb in all specs
local cluster_var industry_id //cluster SE variables
local employment_vars = "workweek ewemt emh ewemt_ind emh_ind" //Employment variables
local wage_vars = "hourly_earn weekly_earn" //Wage variables
local indexed_ewemt_models "m_workweek m_ewemt_ind m_emh_ind m_hourly_earn m_weekly_earn m_payroll_ind"		
local level_ewemt_models "m_workweek m_ewemt m_emh m_hourly_earn m_weekly_earn m_payroll"
local indexed_ewemt_models_noearn "m_workweek m_ewemt_ind m_emh_ind"
local mgroups_list `" "Workweek" "Employment" "Manhours" "Hourly Earnings" "Weekly Earnings" "Payroll" "'
local pattern_6 "1 1 1 1 1 1"

if `SSNRA' == 1 {
	use "Data/Generated/industry_SSNRA_analysis_monthly" if tableno ~= "9", replace
***eliminates beet sugar which has a huge seasonal pattern
	local wage_vars = "`wage_vars' payroll payroll_ind"
	local vars_to_reg = "`employment_vars' `wage_vars'"
	label var l_hourly_earn "Hourly Earnings"
	label var l_weekly_earn "Weekly Earnings"
	label var l_payroll_ind "Payroll"
	label var l_ewemt_ind "Employment"
	label var l_emh_ind "Manhours"
}
else{
	use "Data/Generated/establishment_analysis_monthly.dta", replace
	rename l_imputed_workweek l_workweek
	rename industry_code_num industry_id
	local vars_to_reg = "`employment_vars'" //don't have monthly wage data in COM data
}

//Relabel dependent variables for output to tables
label var NRAcompcrisis "CCNRA"
label var PRAcompcrisis "CCPRA" 
label var NRAearly "ENRA" 
label var PRAearly "EPRA" 
label var l_workweek "Workweek"
label var l_payroll "Payroll"
label var l_ewemt "Employment"
label var l_emh "Manhours"
label var ipfrbnsa97 "IP"
label var spstock3539 "S\&P Stock Index"
label var ricustloan "Interest Rates"

//Prepare labels
local mtitles = ""
local pattern = ""
foreach var_to_reg in `vars_to_reg'{
	local var_label: variable label l_`var_to_reg'
	local mtitles = `"`mtitles' "`var_label'""'
	local pattern = "`pattern' 1"
}

//Log transform business cycle variables
foreach var_to_log in ipfrbnsa97 spstock3539{
	local var_lab: variable label `var_to_log'
	gen l_`var_to_log' = log(`var_to_log')
	label var l_`var_to_log' "`var_lab'"
}

//Aggregate industrial production control
eststo clear
foreach var_to_reg in `vars_to_reg' {
	qui eststo  m_`var_to_reg': reghdfe l_`var_to_reg' NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97, absorb(`absorb_vars') vce(cluster `cluster_var')
	if "`var_to_reg'"=="workweek"{
		gen sample = e(sample)
	}
	if "`var_to_reg'"=="ewemt"{
		gen sample_ewemt = e(sample)
	} 
}
//Table 1
esttab `indexed_ewemt_models' using "Tables/regs_Taylor_SSNRA`SSNRA'_IP", `estab_opts' keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)

//Appendix Table 5
esttab `level_ewemt_models' using "Tables/regs_Taylor_SSNRA`SSNRA'_IP_level_ewemt", `estab_opts' keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)

//"Balanced" panel results
eststo clear
foreach var_to_reg in `vars_to_reg' {
	qui eststo m_`var_to_reg':  reghdfe l_`var_to_reg' NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 if sample == 1, absorb(`absorb_vars') vce(cluster `cluster_var')
}
//Appendix Table 4
esttab `indexed_ewemt_models' using "Tables/regs_Taylor_SSNRA`SSNRA'_IP_balanced", `estab_opts' keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)

//Fully "Balanced" panel results
eststo clear
foreach var_to_reg in `vars_to_reg' {
	qui eststo m_`var_to_reg': reghdfe l_`var_to_reg' NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 if sample_ewemt == 1 & sample == 1, absorb(`absorb_vars') vce(cluster `cluster_var')
}
//Appendix Table 6
esttab `indexed_ewemt_models' using "Tables/regs_Taylor_SSNRA`SSNRA'_IP_fullyBalanced", `estab_opts' keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)

//Include wage as control for regs with employment vars as dependent variables
if `SSNRA' == 1{
	eststo clear
	foreach var_to_reg in `employment_vars' {
		qui eststo m_`var_to_reg':  reghdfe l_`var_to_reg' l_hourly_earn NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97, absorb(`absorb_vars') vce(cluster `cluster_var')
	}
	//Appendix Table 7
	esttab `indexed_ewemt_models_noearn' using "Tables/regs_Taylor_SSNRA`SSNRA'_IP_wage", `estab_opts' keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_hourly_earn) order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_hourly_earn) mgroups("Workweek" "Employment" "Manhours", pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span)
}
