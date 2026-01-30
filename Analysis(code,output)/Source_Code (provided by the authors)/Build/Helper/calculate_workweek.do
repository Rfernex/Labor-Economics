//Calculate workweek assuming a 5 or 6 day workweek

//Tempvars with number of workdays per week
tempvar workdays_per_week
tempvar workdays_per_week_six

gen `workdays_per_week' = 5 
gen `workdays_per_week_six' = 6
replace  `workdays_per_week' = d006 if d006 ~= . //Use workdays / week var in 1935 when available.
replace  `workdays_per_week_six' = d006 if d006 ~= . //Use workdays / week var in 1935 when available.
		
//Tempvars defining M-F days in each month in 1933 and 1935
forvalues month = 1(1)12{
	tempvar days_`month'
	tempvar days_`month'_six
}

//These are 5 day workweeks
gen `days_1' = 22 if year == 1933
replace `days_1' = 23 if year == 1935
gen `days_2' = 20
gen `days_3' = 23 if year == 1933
replace `days_3' = 21 if year == 1935
gen `days_4' = 20 if year == 1933
replace `days_4' = 22 if year == 1935
gen `days_5' = 23
gen `days_6' = 22 if year == 1933
replace `days_6' = 20 if year == 1935
gen `days_7' = 21 if year == 1933
replace `days_7' = 23 if year == 1935
gen `days_8' = 23 if year == 1933
replace `days_8' = 22 if year == 1935
gen `days_9' = 21
gen `days_10' = 22 if year == 1933
replace `days_10' = 23 if year == 1935
gen `days_11' = 22 if year == 1933
replace `days_11' = 21 if year == 1935
gen `days_12' = 21 if year == 1933
replace `days_12' = 22 if year == 1935

//These are six day workweeks
gen `days_1_six' = 26 if year == 1933
replace `days_1_six' = 27 if year == 1935
gen `days_2_six' = 24
gen `days_3_six' = 27 if year == 1933
replace `days_3_six' = 26 if year == 1935
gen `days_4_six' = 25 if year == 1933
replace `days_4_six' = 26 if year == 1935
gen `days_5_six' = 27
gen `days_6_six' = 26 if year == 1933
replace `days_6_six' = 25 if year == 1935
gen `days_7_six' = 26 if year == 1933
replace `days_7_six' = 27 if year == 1935
gen `days_8_six' = 27 if year == 1933
replace `days_8_six' = 27 if year == 1935
gen `days_9_six' = 26
replace `days_9_six' = 25 if year == 1935
gen `days_10_six' = 26 if year == 1933
replace `days_10_six' = 27 if year == 1935
gen `days_11_six' = 26 if year == 1933
replace `days_11_six' = 26 if year == 1935
gen `days_12_six' = 26 if year == 1933
replace `days_12_six' = 26 if year == 1935

//Construct workweek and related variables
foreach num_days in five six{
	//Set labels for five or six day based workweeks
	local days_label = ""
	if "`num_days'" == "six"{
		local days_label = "_six"
	}
	forvalues month =1/12{
		gen imputed_workweek`days_label'`month' = .
		replace imputed_workweek`days_label'`month' =	(emh`month'/ `days_`month'`days_label'' * `workdays_per_week`days_label'') / (ewemt`month')	
		gen valid_imputed_workweek`days_label'`month' = 1
		replace valid_imputed_workweek`days_label'`month' = 0 if (imputed_workweek`days_label'`month' < 10 | imputed_workweek`days_label'`month' > 100) & imputed_workweek`days_label'`month' ~= . //Invalid if workweek > 100 hrs or less than 10 hrs
		replace valid_imputed_workweek`days_label'`month' = . if imputed_workweek`days_label'`month' == .
		gen missing_imputed_workweek`days_label'`month' = valid_imputed_workweek`days_label'`month' == .
	}
}

//Workweek variable on CoM schedule
rename d008 d008_workweek 
gen valid_d008_workweek = 1 
replace valid_d008_workweek = 0 if (d008_workweek < 10 | d008_ workweek > 100) & d008_workweek ~= . 
