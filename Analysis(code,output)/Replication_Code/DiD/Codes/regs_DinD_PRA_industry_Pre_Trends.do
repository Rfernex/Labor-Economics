
//Regressions for effects of PRA using D-in-D spec with preexisting workweek variation

args type_data prePRA_variable Pre_Trend //default is SSNRA.

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

use "Data/Generated/industry`type_data'_analysis_monthly.dta" if year == 1933 & month>=4 & month<=10, clear

if "`type_data'" == "_SSNRA"{ //Drop sugar beets with large seasonal pattern
	drop if tableno == "9"
	label var l_payroll_ind "Payroll"
}

if "`Pre_Trend'" == ""{
	local Pre_Trend = l_hourly_earn
}

//Redefine industry ID for NICB data
if "`type_data'" == "_NICB"{
	drop industry_id
	egen industry_id = group(industry)
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

local ytitle_str = "Dependent Variable"
if "`Pre_Trend'" == "l_hourly_earn"  local ytitle_str = "Log Hourly Earnings"
if "`Pre_Trend'" == "l_weekly_earn"  local ytitle_str = "Log Weekly Earnings"
if "`Pre_Trend'" == "l_payroll_ind"  local ytitle_str = "Payroll (Index)"
if "`Pre_Trend'" == "l_payroll"      local ytitle_str = "Log Payroll"


//Fig. 7
twoway (lpoly `Pre_Trend' month if above == 1, lwidth(thick)) (lpoly `Pre_Trend' month if above == 0, lwidth(thick)), legend(order(1 "`lab_figure1'" 2 "`lab_figure2'") position(6) rows(1)) ytitle("`ytitle_str'") xlabel(4(1)10) xline(7.5) xtitle("Month")
if "`type_data'"~="_NICB" | "`type_data'`lab_results'" ~= "SSNRA_workweek_prePRA"{
	graph export "Replication/DiD/C3_Pre_Trends/regs_DinD_PRA_pretrends`type_data'`lab_results'_`Pre_Trend'.pdf", replace
}

