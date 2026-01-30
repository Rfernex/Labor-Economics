
cd "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1"

//Event study analysis for effects of PRA

args type_data prePRA_variable Dependent

if "`type_data'" == ""{ //default is SSNRA
	local type_data = "_SSNRA"
}

//Pre-PRA workweek variable to use: l_workweek_prePRA, above*_workweek_prePRA
if "`prePRA_variable'"==""{ //Default is fraction of months above limit
	local prePRA_variable = "above35_workweek_prePRA" 
}

//weekly earn only available in SSNRA data
if "`type_data'" == "_SSNRA"{
	local weekly_earn = "l_weekly_earn l_payroll"
}

//options for outputting table and specifications
local cluster_var industry //cluster SE variables.

use "Data/Generated/industry`type_data'_analysis_monthly.dta", clear //Drop June 1933

if "`Dependent'"==""{ //Default is fraction of months above limit
	local Dependent = "l_hourly_earn" 
}

//Label pre-PRA variable
local var_label = "Pre-PRA Workweek"
if "`prePRA_variable'" == "l_workweek_prePRA"{
	local var_label = "Pre-PRA Workweek Length"
}

//Redefine industry ID for NICB data
if "`type_data'" == "_NICB"{
	drop industry_id
	egen industry_id = group(industry)
}

//Create group variable for month-by-year
sort year month
egen month_year = group(year month)

if "`Dependent'" == "l_hourly_earn"  local ytitle_str = "Log Hourly Earnings"
if "`Dependent'" == "l_weekly_earn"  local ytitle_str = "Log Weekly Earnings"
if "`Dependent'" == "l_payroll_ind"  local ytitle_str = "Payroll (Index)"
if "`Dependent'" == "l_payroll"      local ytitle_str = "Log Payroll"

qui eststo: reghdfe `Dependent' ib7.month_year#c.`prePRA_variable', absorb(industry_id) vce(cluster `cluster_var')
regsave
gen plot_these = regexm(var, ".month_year#c.`prePRA_variable'")
replace var = subinstr(var, ".month_year#c.`prePRA_variable'", "", .)
destring var, replace force
gen year = 1933+(var-1)/12
gen high_se = coef + 2 * stderr
gen low_se = coef - 2 * stderr
//Appendix Fig. 11
twoway (scatter coef year if plot_these == 1) (rcap high_se low_se year if plot_these == 1),  xtitle("Year") ytitle("Month by `var_label' Effects on `ytitle_str'") xlabel(1933(1)1936) xline(1933.6 1935.625) legend(off)

graph export "Replication/Event_Study/C1_Dependent/event_study`type_data'_`ytitle_str'.pdf", as(pdf) replace 







