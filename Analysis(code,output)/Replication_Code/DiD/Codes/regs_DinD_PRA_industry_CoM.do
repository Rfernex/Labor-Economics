

cd "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1"

* Employment file
use "Replication/DiD/C4_CoM_Alt/Data/establishment_1933_hourly_dataset.dta"

//Regressions for effects of PRA using D-in-D spec with preexisting workweek variation

//options for outputting table and specifications
local estab_opts = `"nonotes se tex b(%12.3f) replace label varwidth(40) obslast nocon nomtitles nostar"' //star(* 0.1 ** 0.05 *** 0.01)"' [remove stars for AEA]
local cluster_var establishment_ID //cluster SE variables.
local indexed_ewemt_models "m_l_hourly_wage_noFE m_l_hourly_wage_FE m_l_weekly_wage_noFE m_l_weekly_wage_FE "		

//Relabel variables for outputting to tables
label var l_hourly_wage "Hourly wage"
label var l_weekly_wage "Weekly wage"
label var l_ewemt "Employment"
label var l_workweek "Workweek"
label var prePRA_above "Pre-PRA Workweek"
local var_label : variable label prePRA_above
label var PRA_prePRA_above "PRA \$\times\$ `var_label'"
label var belowM_hourly_wage_prePRA "Pre-PRA wage Below Median"
foreach var_to_rename in prePRA_above belowM_hourly_wage_prePRA{
	local var_label: variable label `var_to_rename'
	label var PRA_`var_to_rename' "PRA \$\times\$ `var_label'"
}


//Pre-trends analysis
gen above = round(prePRA_above) //Round fraction of months above to 0 or 1
local lab_figure1 = "Workweek Above Limit > 50%"
local lab_figure2 = "Workweek Above Limit < 50%"

//Fig. 7
twoway (lpoly l_hourly_wage month if above == 1, lwidth(thick)) (lpoly l_hourly_wage month if above == 0, lwidth(thick)), legend(order(1 "`lab_figure1'" 2 "`lab_figure2'") position(6) rows(1)) ytitle("Log Hourly Wage") xlabel(4(1)10) xline(7.5) xtitle("Month")
graph export "Replication/DiD/C4_CoM_Alt/Output/regs_DinD_PRA_CoM_pretrends_prePRA_above.pdf", replace

drop if month == 7 //Exclude July, month of PRA, for regressions

//DinD Spec for wage Vars Using Preexisting variation in Workweek by Establishment
eststo clear
local label = ""
local pattern = ""
foreach var_to_reg in l_hourly_wage l_weekly_wage {
	//Specifications 1: Just DinD (weighted by employment)
	qui eststo m_`var_to_reg'_noFE: reg `var_to_reg' PRA_period PRA_prePRA_above prePRA_above [aw=ewemt], vce(cluster `cluster_var')
	//Spec 2: Add month + industry FEs (weighted by employment)
	qui eststo m_`var_to_reg'_FE: reghdfe `var_to_reg' PRA_prePRA_above [aw=ewemt], absorb(month establishment_ID) vce(cluster `cluster_var')
	local lab_var: variable label `var_to_reg'
	local label = `"`label' "`lab_var'""'
	local pattern = "`pattern' 1 0"
}
estfe . m_*, labels(month "Month" establishment_ID "Establishment")

//Table 2 and Appendix Tables 8, 9, and 10
esttab `indexed_ewemt_models' using "Replication/DiD/C4_CoM_Alt/Output/regs_DinD_PRA_industry_CoM_prePRA_above_wage", `estab_opts' indicate(`r(indicate_fe)') mgroups(`label', pattern(`pattern') prefix(\multicolumn{@span}{c}{) suffix(}) span) keep( PRA_prePRA_above PRA_period prePRA_above) order(PRA_period prePRA_above PRA_prePRA_above )

//DinDinD Spec for wage Vars Using Preexisting variation in Workweek by Establishment & Below Median Pre-PRA wage
eststo clear
local label = ""
local pattern = ""
foreach var_to_reg in l_hourly_wage l_weekly_wage { //Just for hourly wageings
	//Specifications 1: Just DinD
	 eststo m_`var_to_reg'_noFE: reg `var_to_reg' PRA_period belowM_hourly_wage_prePRA prePRA_above PRA_belowM_hourly_wage_prePRA PRA_prePRA_above [aw=ewemt] , vce(cluster `cluster_var')
	//Spec 3: Add industry + month FEs
	 eststo m_`var_to_reg'_FE: reghdfe `var_to_reg' PRA_belowM_hourly_wage_prePRA PRA_prePRA_above [aw=ewemt], absorb(month establishment_ID) vce(cluster `cluster_var')
	local lab_var: variable label `var_to_reg'
	local label = `"`label' "`lab_var'""'
	local pattern = "`pattern' 1 0 "
}
estfe . m_*, labels(month "Month" establishment_ID "Establishment")
//Table 3
esttab `indexed_ewemt_models' using "Replication/DiD/C4_CoM_Alt/Output/regs_DinDinD_PRA_industry_CoM_prePRA_above_wageB", `estab_opts' indicate(`r(indicate_fe)') mgroups(`label', pattern(`pattern') prefix(\multicolumn{@span}{c}{) suffix(}) span) keep( PRA_period belowM_hourly_wage_prePRA prePRA_above PRA_belowM_hourly_wage_prePRA PRA_prePRA_above  ) order(PRA_period belowM_hourly_wage_prePRA prePRA_above PRA_belowM_hourly_wage_prePRA PRA_prePRA_above  )


