
cd  "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1"

//Regressions for effects of PRA using D-in-D spec with preexisting workweek variation
args type_data prePRA_variable pre_months post_months //default is SSNRA.

if "`type_data'" == ""{
	local type_data = "_SSNRA"
}

//Pre-PRA workweek variable to use: l_workweek_prePRA, above*_workweek_prePRA
if "`prePRA_variable'"==""{
	local prePRA_variable = "above35_workweek_prePRA" 
}
if "`prePRA_variable'"=="l_workweek_prePRA"{ //Adjust label for output tables and figs.
	local lab_results = "_workweek_prePRA"
}

//Only include payroll for SSNRA data
if "`type_data'" == "_SSNRA"{
	local l_payroll = "l_payroll l_payroll_ind"	
}

if "`pre_months'" == "" {
    local pre_months = 3   // months before PRA month 7 (i.e., months >= 7-3 = 4)
}

if "`post_months'" == "" {
    local post_months = 3  // months after PRA month 7 (i.e., months <= 7+3 = 10)
}

local pra_month = 7
local month_LB = `= `pra_month' - `pre_months''
local month_UB = `= `pra_month' + `post_months''

//options for outputting table and specifications
local estab_opts = `"nonotes se tex b(%12.3f) replace label varwidth(40) obslast nocon nomtitles nostar"' //star(* 0.1 ** 0.05 *** 0.01)"' [remove stars for AEA]
local cluster_var industry //cluster SE variables.
local indexed_ewemt_models "m_l_hourly_earn_noFE m_l_hourly_earn_FE m_l_weekly_earn_noFE m_l_weekly_earn_FE "		
local level_ewemt_models "m_l_hourly_earn_noFE m_l_hourly_earn_FE m_l_weekly_earn_noFE m_l_weekly_earn_FE"
if "`type_data'" == "_SSNRA"{
    local indexed_ewemt_models "`indexed_ewemt_models' m_l_payroll_ind_noFE m_l_payroll_ind_FE"
	local level_ewemt_models "`level_ewemt_models' m_l_payroll_noFE m_l_payroll_FE"
}

do "Replication/DiD/Codes/build_industry_SSNRA_monthly_C1" `pre_months' `post_months'

use "Replication/DiD/C1_Time_Window/Data/industry_SSNRA_analysis_monthly_`pre_months'.dta" if year == 1933 & inrange(month, `month_LB', `month_UB'), clear

if "`type_data'" == "_SSNRA"{ //Drop sugar beets with large seasonal pattern
	drop if tableno == "9"
	label var l_payroll_ind "Payroll"
}

//Redefine industry ID for NICB data
if "`type_data'" == "_NICB"{
	drop industry_id
	egen industry_id = group(industry)
}

//Relabel variables for outputting to tables
label var l_hourly_earn "Hourly Earnings"
label var l_weekly_earn "Weekly Earnings"
label var l_payroll "Payroll"
label var l_ewemt "Employment"
label var l_workweek "Workweek"
label var `prePRA_variable' "Pre-PRA Workweek"
if "`prePRA_variable'" == "l_workweek_prePRA"{
	label var `prePRA_variable' "Pre-PRA Workweek Length"
}
label var l_hourly_earn_prePRA "Pre-PRA Earnings"
label var belowM_hourly_earn_prePRA "Pre-PRA Earnings Below Median"
label var PRA_period "PRA"
foreach var_to_rename in l_hourly_earn_prePRA `prePRA_variable' belowM_hourly_earn_prePRA{
	local var_label: variable label `var_to_rename'
	label var PRA_`var_to_rename' "PRA \$\times\$ `var_label'"
}

//Pre-trends analysis
if "`prePRA_variable'" == "l_workweek_prePRA" {
	egen above = median(workweek_prePRA) 
	replace above = workweek_prePRA > above 
	local lab_figure1 = "Workweek Above Median"
	local lab_figure2 = "Workweek Below Median"
}
else{
	gen above = round(`prePRA_variable') //Round fraction of months above to 0 or 1
	local lab_figure1 = "Workweek Above Limit > 50%"
	local lab_figure2 = "Workweek Above Limit < 50%"
}
//Fig. 7
twoway (lpoly l_hourly_earn month if above == 1, lwidth(thick)) (lpoly l_hourly_earn month if above == 0, lwidth(thick)), legend(order(1 "`lab_figure1'" 2 "`lab_figure2'") position(6) rows(1)) ytitle("Log Hourly Earnings") xlabel(4(1)10) xline(7.5) xtitle("Month")
if "`type_data'"~="_NICB" | "`type_data'`lab_results'" ~= "SSNRA_workweek_prePRA"{
	graph export "Replication/DiD/C1_Time_Window/Output/regs_DinD_PRA_pretrends`type_data'`lab_results'_pre`pre_months'_post`post_months'.pdf", replace
}

drop if month == 7 //Exclude July, month of PRA, for regressions

//DinD Spec for Earnings Vars Using Preexisting variation in Workweek by Industry
eststo clear
local label = ""
local pattern = ""
foreach var_to_reg in l_hourly_earn l_weekly_earn `l_payroll'{
	//Specifications 1: Just DinD
	qui eststo m_`var_to_reg'_noFE: reg `var_to_reg' PRA_period PRA_`prePRA_variable' `prePRA_variable', vce(cluster `cluster_var')
	//Spec 2: Add month + industry FEs
	qui eststo m_`var_to_reg'_FE: reghdfe `var_to_reg' PRA_`prePRA_variable', absorb(month industry_id) vce(cluster `cluster_var')
	local lab_var: variable label `var_to_reg'
	local label = `"`label' "`lab_var'""'
	local pattern = "`pattern' 1 0"
}
estfe . m_*, labels(month "Month" industry_id "Industry")
//Table 2 and Appendix Tables 8, 9, and 10
esttab `indexed_ewemt_models' using "Replication/DiD/C1_Time_Window/Output/regs_DinD_PRA_industry`type_data'`lab_results'_earn_pre`pre_months'_post`post_months'", `estab_opts' indicate(`r(indicate_fe)') mgroups(`label', pattern(`pattern') prefix(\multicolumn{@span}{c}{) suffix(}) span) keep( PRA_`prePRA_variable' PRA_period `prePRA_variable') order(PRA_period `prePRA_variable' PRA_`prePRA_variable' )

//DinDinD Spec for Earnings Vars Using Preexisting variation in Workweek by Industry & Below Median Pre-PRA Earnings
eststo clear
local label = ""
local pattern = ""
foreach var_to_reg in l_hourly_earn l_weekly_earn `l_payroll'{ //Just for hourly earnings
	//Specifications 1: Just DinD
	 eststo m_`var_to_reg'_noFE: reg `var_to_reg' PRA_period belowM_hourly_earn_prePRA `prePRA_variable' PRA_belowM_hourly_earn_prePRA PRA_`prePRA_variable'  , vce(cluster `cluster_var')
	//Spec 3: Add industry + month FEs
	 eststo m_`var_to_reg'_FE: reghdfe `var_to_reg' PRA_belowM_hourly_earn_prePRA PRA_`prePRA_variable' , absorb(month industry_id) vce(cluster `cluster_var')
	local lab_var: variable label `var_to_reg'
	local label = `"`label' "`lab_var'""'
	local pattern = "`pattern' 1 0 "
}
estfe . m_*, labels(month "Month" industry_id "Industry")
//Table 3
if "`type_data'"~="_NICB"{
	esttab `indexed_ewemt_models' using "Replication/DiD/C1_Time_Window/Output/regs_DinDinD_PRA_industry`type_data'`lab_results'_earnB_pre`pre_months'_post`post_months'", `estab_opts' indicate(`r(indicate_fe)') mgroups(`label', pattern(`pattern') prefix(\multicolumn{@span}{c}{) suffix(}) span) keep( PRA_period belowM_hourly_earn_prePRA `prePRA_variable' PRA_belowM_hourly_earn_prePRA PRA_`prePRA_variable'  ) order(PRA_period belowM_hourly_earn_prePRA `prePRA_variable' PRA_belowM_hourly_earn_prePRA PRA_`prePRA_variable'  )
}

//Cleanup unused files
capture rm "Figures/regs_DinD_PRA_pretrends_NICB.pdf"
capture rm "Figures/regs_DinD_PRA_pretrends_SSNRA_workweek_prePRA.pdf"
