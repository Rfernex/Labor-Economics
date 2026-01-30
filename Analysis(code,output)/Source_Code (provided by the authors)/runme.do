//Runme file for Fishback, Vickers, and Ziebarth (2023) "Labor Market Effects of Workweek Restrictions: Evidence from the Great Depression"

//Build
do "Code/Build/install_dependencies_subfolders"								//Install dependencies and create subfolders for output.
do "Code/Build/add_BR_manhours"  "CoM_workweek"								//Add manhours variable to dataset

foreach kind in establishment industry{
	foreach frequency in monthly prepost_PRA{
		do "Code/Build/build_`kind'_`frequency'"								//Build the dataset at `frequency' at `kind'-level.
	}
}
do "Code/Build/build_industry_SSNRA_monthly"									//Build the SSNRA dataset.

//Analysis
do "Code/Analyze/fig_ColeOhanian"												//Plot changes in aggregate labor inputs.
do "Code/Analyze/compare_establishment_industry" 								//Compare trends in industry vs. establishment datasets
do "Code/Analyze/compare_SSNRA_COM" 											//Compare SSNRA data to COM for overlapping industries

//Establishment-level analyses (COM Data)
do "Code/Analyze/Establishment/summary_stats"									//Summary stats of COM data
do "Code/Analyze/Establishment/compare_workweek_vars"							//Compare distributions of imputed workweek to workweek reported on schedule.
do "Code/Analyze/Establishment/missing_data_bySize"								//Plot % of missing workweek by size.
do "Code/Analyze/Establishment/plot_employment_byWorkweek"						//Plot employment variables by workweek over time.
do "Code/Analyze/Establishment/density_workweek_PRA"							//Plot density of workweeks before & after PRA.
do "Code/Analyze/Establishment/chars_at_PRA_limit_Pre"							//Characteristics of establishments around the workweek limit before PRA
do "Code/Analyze/Establishment/chars_at_PRA_limit_Pre" "at_PRA_limit_bw4"							//Characteristics of establishments around the workweek limit before PRA using 4 BW
do "Code/Analyze/Establishment/regs_bunching"									//Bunching estimator for employment effects
do "Code/Analyze/Establishment/regs_bunching" 40 25 5 "" "_check1"				//Bunching estimator Robustness Check 1 (different bandwidth)
do "Code/Analyze/Establishment/regs_bunching" 50 25	4 "" "_check2"				//Bunching estimator Robustness Check 2  (higher upper bound of treatment)
do "Code/Analyze/Establishment/regs_bunching" 40 20	4 "" "_check3"				//Bunching estimator Robustness Check 3 (lower lower bound of treatment)

//Industry-level analyses (NICB, SSNRA)
foreach data_source in "_SSNRA" "_NICB"{
	do "Code/Analyze/Industry/regs_DinD_PRA_industry" "`data_source'"			//Diff-in-diff regressions to estimate PRA effects using predetermined workweek variation.
}

do "Code/Analyze/Industry/density_workweek_PRA_industry" "_SSNRA"	//Plot density of workweeks before & after PRA.
do "Code/Analyze/Industry/regs_DinD_PRA_industry" "_SSNRA" "l_workweek_prePRA"	//Diff-in-diff regressions to estimate PRA effects using predetermined level of workweek.
do "Code/Analyze/Industry/event_study_PRA_industry" "_SSNRA" 					//Event study of effects of PRA 
do "Code/Analyze/Industry/regs_Taylor_SSNRA" 									//Taylor (2009) style regressions for PRA and NIRA effects.


// Robustness Checks - Taylor
do "Replication/Taylor/regs_Taylor_SSNRA_Checks" // Taylor regression checks (clustering + )

// Robustness Checks - Bunching (employment)
do "Replication/Bunching/Codes/regs_bunching_placebo" // Bunching Placebo (1935)
do "Replication/Bunching/Codes/regs_bunching_nosugar" // Bunching No Sugar 
do "Code/Analyze/Establishment/regs_bunching" 30 25 4 "" "_UB"	// Upper Bound (lower UB)
do "Code/Analyze/Establishment/regs_bunching" 40 30 4 "" "_LB"	// Lower Bound (Higher LB)
do "Code/Analyze/Establishment/regs_bunching" 40 25 2 "" "_Bin"	// Bin check (lower bandwidth)

// Robustness Checks - DiD (earnings)
foreach Boundary in 2 4 5 {
	do "Replication/DiD/Codes/regs_DinD_PRA_industry_Time" "_SSNRA" "" `Boundary' `Boundary' // sensitivity to time frame considered (NEEDS ADJUSTMENT FOR PRE_PRA)
}

do "Replication/DiD/Codes/regs_DinD_PRA_industry_Stute_test_CS.do" // non-linearity tests

foreach Pre_Trend in "l_hourly_earn" "l_weekly_earn" "l_payroll_ind" "l_payroll" {
	do "Replication/DiD/Codes/regs_DinD_PRA_industry_Pre_Trends" "_SSNRA" "" `Pre_Trend'  // pre-trend tests for weekly...
}

do "Replication/DiD/Codes/regs_DinD_PRA_industry_CoM" // establishment-level with CoM

// Robustness Checks - Event Study (related to earnings DiD)
foreach Dependent in "l_hourly_earn" "l_weekly_earn" "l_payroll_ind" "l_payroll" {
	do "Replication/Event_Study/Codes/event_study_PRA_industry_check" "_SSNRA" "" `Dependent' // event study for weekly...
}

