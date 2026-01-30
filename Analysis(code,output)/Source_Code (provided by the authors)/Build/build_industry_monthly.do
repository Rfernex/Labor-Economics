//Build NICB industry by month data. Spreadsheet contains detailed description of the variables
import excel "Data/Source/mfghee2.xlsx", sheet("final") firstrow allstring clear

//Rename for consistency with CoM data
rename id industry_id
rename industrynicb industry
rename codeno nracodeno
rename industrynra industry_nra
rename weekhoursn workweek
rename empindn2036 ewemt
rename hourearnn hourly_earn
rename indprod output
rename weekearnn weekly_earn
rename payrollind payroll

destring year month output hourly_earn weekly_earn ewemt payroll workweek industry_id, replace force

//Drop unneeded variables
drop pracode tableben weekearnneth empindb empindn3237 empindn3439 hoursavg2325 weekhoursnind hourearnn2325 hourearnnind2325 tothourindbn hourearnnind tothourindn2036 weekearnindneth rat2036t3439

//Label variables
label var nracode "NRA Code in place"
label var industry "Industry Name"
label var industry_id "Industry ID (Conference Board)"
label var industry_nra "NRA Industry Name"
label var nracodmonth "Month NRA Code in place"
label var nracodeno "NRA Code Number"
label var year "Year"
label var month "Month"
label var output "Output"
label var hourly_earn "Hourly Earnings"
label var weekly_earn "Weekly Earnings"
label var ewemt "Employment"
label var workweek "Workweek"
label var payroll "Payroll"

//PRA period for 1933
gen PRA_period  = (year==1933 & month >= 8 & month <= 10)
label var PRA_period "PRA (August-October 1933)"

//Generate predetermined before PRA variables
gen above40_workweek = workweek > 40
label var above40_workweek "Workweek Above 40 Hours (April-June 1933)"
gen above35_workweek = workweek > 35
label var above35_workweek "Workweek Above 35 Hours (April-June 1933)"

foreach var_to_ave of varlist workweek hourly_earn above*_workweek{
	bysort industry: egen `var_to_ave'_prePRA = sum(`var_to_ave'*(year==1933 & month >= 4 & month <= 6))
	replace `var_to_ave'_prePRA = `var_to_ave'_prePRA / 3
	replace `var_to_ave'_prePRA = . if `var_to_ave'_prePRA == 0
	local var_label: variable label `var_to_ave'
	label var `var_to_ave'_prePRA "Predetermined `var_label' (May-July 1933)"
}

//Generate and label labor variables
gen emh = ewemt * workweek
label var emh "Total Manhours (Unindexed)"
foreach var_to_log of varlist output weekly_earn hourly_earn ewemt emh workweek payroll workweek_prePRA hourly_earn_prePRA{
	local var_label: variable label `var_to_log'
	gen l_`var_to_log' = ln(`var_to_log')
	label var l_`var_to_log'  "Log `var_label'"
	gen PRA_l_`var_to_log' = PRA_period * l_`var_to_log'
	label var PRA_l_`var_to_log' "PRA * Log `var_label'"
}

//Above median prePRA hourly earnings
egen med_hourly_earn_prePRA = median(hourly_earn_prePRA)
gen aboveM_hourly_earn_prePRA = hourly_earn_prePRA > med_hourly_earn_prePRA
gen belowM_hourly_earn_prePRA = hourly_earn_prePRA < med_hourly_earn_prePRA
label var aboveM_hourly_earn_prePRA "Above Median Pre-PRA Earnings"
label var belowM_hourly_earn_prePRA "Below Median Pre-PRA Earnings"
drop med_hourly_earn_prePRA

//Generate interact with above limit
foreach var_to_log of varlist above*_workweek_prePRA aboveM_hourly_earn_prePRA belowM_hourly_earn_prePRA{
	local var_label: variable label `var_to_log'
	gen PRA_`var_to_log' = PRA_period * `var_to_log'
	label var PRA_`var_to_log' "PRA * `var_label'"
}

save "Data/Generated/industry_NICB_analysis_monthly", replace
