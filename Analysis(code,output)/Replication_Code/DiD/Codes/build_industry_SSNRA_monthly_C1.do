//Build dataset for 115 industries between 1933 and 1935. See the spreadsheet for the underlying data source

args pre_months post_months

local pra_month = 7
local month_LB = `= `pra_month' - `pre_months''
local month_UB = `= `pra_month' + `post_months''

//Import 1933 CoM Employment data
import excel "Data/Source/link_HEE115_CoM.xls", sheet("Employment") firstrow clear

//Construct CoM groups 
tostring CoMIndustryNumber, gen(CoMIndustryNumberString)
gen CoMIndustryGroup = ""
replace CoMIndustryGroup = substr(CoMIndustryNumberString,1,1) if length(CoMIndustryNumberString) == 3
replace CoMIndustryGroup = substr(CoMIndustryNumberString,1,2) if length(CoMIndustryNumberString) == 4
destring CoMIndustryGroup, replace
drop CoMIndustryNumberString

collapse (sum) AverageWageEarners (first) CoMIndustryGroup, by(HEE115Industry)
rename HEE115Industry industry
rename AverageWageEarners ewemt_1933

tempfile 1933_emp
save `1933_emp'

//Import HEE115 data
import excel "Data/Source/hee115.xlsx", sheet("data")  firstrow clear

//Drop unneeded variables
drop N-S

//Label variables
label var tableno "table number in source"
label var codeno "NRA Code Number"
label var Industry "Industry name"
label var Year "year"
label var Month "month"
label var empind "employment index, 1933=100"
label var weekhours "average hours per week"
label var hourearn "average hourly earnings"
label var weekearn "average weekly earnings, different source not= to weekhours*hour earn"
label var NRAdateapp "date NRA code approved"
label var NRAdateeffect "date NRA code went into effect"

//Rename for consistency with CoM data
rename Industry industry
rename codeno nracodeno
rename weekhours workweek //Note no "imputation" of workweek like CoM
rename empind ewemt
rename hourearn hourly_earn
rename weekearn weekly_earn
rename Year year
rename Month month

//numerical version of industry
egen industry_id = group(industry)

//Merge 1933 employment data from CoM
merge m:1 industry using `1933_emp', gen(merge_1933)
label var CoMIndustryGroup "COM Industry Group"
replace ewemt_1933 = . if ewemt_1933 == 0
gen ewemt_level = ewemt * ewemt_1933
label var ewemt_level "Employment (Level)"
replace merge_1933 = merge_1933 == 3
label var merge_1933 "Merged to 1933 CoM?"

//Note: Original ewemt variable is indexed
rename ewemt ewemt_ind
rename ewemt_level ewemt
gen emh = ewemt * workweek
gen emh_ind = ewemt_ind * workweek
label var emh "Total Manhours"
label var emh_ind "Total Manhours (Index)"

//Total weekly payroll
gen payroll = ewemt * weekly_earn
gen payroll_ind = ewemt_ind * weekly_earn
label var payroll "Total Payroll"
label var payroll_ind "Total Payroll (Index)"

//Generate PRA & NRA Period variables
do "Code/Build/Helper/nra_variables"

//Generate variables predetermined before PRA 
label var hourly_earn "Hourly Earnings"
label var workweek "Workweek"
gen above40_workweek = workweek > 40
label var above40_workweek "Workweek Above 40 Hours (April-June 1933)"
gen above35_workweek = workweek > 35
label var above35_workweek "Workweek Above 35 Hours (April-June 1933)"

foreach var_to_ave of varlist workweek hourly_earn above*_workweek{
	bysort industry_id: egen `var_to_ave'_prePRA = sum(`var_to_ave'*(year==1933 & month >= `month_LB' & month <=`month_UB')) //Pre-period REDEFINED
	replace `var_to_ave'_prePRA = `var_to_ave'_prePRA / `pre_months'
	//replace `var_to_ave'_prePRA = . if `var_to_ave'_prePRA == 0
	local var_label: variable label `var_to_ave'
	label var `var_to_ave'_prePRA "Predetermined `var_label' (May-July 1933)"
}

//Num months above PRA limit pre-PRA
gen hours_above35_prePRA = max(0,workweek_prePRA - 35)
label var hours_above35_prePRA "max{0,Pre-PRA Workweek - 35}"

//Above median prePRA hourly earnings
egen med_hourly_earn_prePRA = median(hourly_earn_prePRA)
gen aboveM_hourly_earn_prePRA = hourly_earn_prePRA > med_hourly_earn_prePRA
gen belowM_hourly_earn_prePRA = hourly_earn_prePRA < med_hourly_earn_prePRA
label var aboveM_hourly_earn_prePRA "Above Median Pre-PRA Earnings"
label var belowM_hourly_earn_prePRA "Below Median Pre-PRA Earnings"
drop med_hourly_earn_prePRA

//Generate transforms and label variables
foreach var_to_log of varlist weekly_earn hourly_earn ewemt ewemt_ind emh emh_ind workweek payroll payroll_ind hourly_earn_prePRA workweek_prePRA hours_above35_prePRA {
	local var_label: variable label `var_to_log'
	gen l_`var_to_log' = ln(`var_to_log')
	label var l_`var_to_log'  "Log `var_label'"
	gen PRA_l_`var_to_log' = PRA_period * l_`var_to_log'
	label var PRA_l_`var_to_log' "PRA * Log `var_label'"
}

//Generate interact of prePRA variables and PRA period
foreach var_to_log of varlist above*_workweek_prePRA hours_above35_prePRA aboveM_hourly_earn_prePRA belowM_hourly_earn_prePRA{
	local var_label: variable label `var_to_log'
	gen PRA_`var_to_log' = PRA_period * `var_to_log'
	label var PRA_`var_to_log' "PRA * `var_label'"
}

//Merge business cycle indicator variables
gen yrmon=year*100+month
merge m:1 yrmon using "Data/Source/moncycle.dta", keep(1 3) nogen
drop yrmon

save "Replication/DiD/C1_Time_Window/Data/industry_SSNRA_analysis_monthly_`pre_months'", replace
