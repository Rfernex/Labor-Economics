//Builds the monthly establishment data
use "Data/Generated/CoM_workweek.dta", clear //Load the original data

//When using v2 dataset
capture rename establishment_id establishment_ID
foreach var_to_destring in industry_code_num region{
	destring `var_to_destring', replace force
}

//Destring numeric variables
destring year d00* emh*  ewemt* g000v e005s e004t, force replace
drop ewemt

//Rename manhours and monthly emploment variables
local counter = 1 
foreach n in 01 02 03 04 05 06 07 08 09{ 
	rename emh`n' emh`counter'
	rename ewemt`n' ewemt`counter'
	local ++counter
}

//In cotton goods (in 1935) some workhours are zero when should be missing
forvalues i = 1/12{
	replace emh`i' = . if emh`i' == 0 & ewemt`i' > 0 & ewemt`i' ~= .
}

//This has some bizarre incorrect emh variable which is in the hundreds of millions
drop if establishment_ID == "216ZDMWURLWZN"

do "Code/Build/Helper/calculate_workweek" //Calculate workweek

//Keep only needed variables
keep incorporated establishment_ID ewemt* imputed_workweek* year industry_code_num region g000v valid_imputed_workweek* missing_imputed_workweek* emh* e005s d008_workweek valid_d008_workweek e004t

//Setup the panel
tempvar pseudo_id
gen `pseudo_id' = _n
reshape long ewemt emh imputed_workweek imputed_workweek_six valid_imputed_workweek valid_imputed_workweek_six missing_imputed_workweek missing_imputed_workweek_six, i(`pseudo_id') j(month)
drop `pseudo_id'
egen estabid_num = group( establishment_ID)

//Create industry specific workweek limit (See Table 1 of the appendix)
//In general, used the limit over longer period of time
gen workweek_limit =  40 if industry_code_num == 118 //Ice Cream
replace workweek_limit = 40 if industry_code_num == 216 //Cotton Goods
replace workweek_limit = 40 if industry_code_num == 1110 //Blast Furnaces
replace workweek_limit = 40 if industry_code_num ==  1112 //Steel works
replace workweek_limit = 40 if industry_code_num == 1608 //Cigars
replace workweek_limit = 40 if industry_code_num == 130 //Sugar cane
replace workweek_limit = 40 if industry_code_num == 131 //Sugar refining
replace workweek_limit = 35 if workweek_limit == .  //All the rest

//Effective amount of time NRA code is in effect
gen time = year + (month-1)/12

gen NRAeffective = 0
replace NRAeffective = 1 if time >= 1933 + (8-1)/12 & industry_code_num == 118 //Ice cream code in effect 8/1/33

replace NRAeffective = 26/30 if month == 8 & year == 1933 & industry_code_num == 119
replace NRAeffective  = 1 if time > 1933 + (8-1)/12 & industry_code_num == 119 //Ice manufacturing code in effect 8/4/33

replace NRAeffective = 11/30 if month == 8 & year == 1933 & (industry_code_num == 1110 | industry_code_num == 1112) //Blast furnaces and steel works codes in effect 8/19/33
replace NRAeffective  = 1 if time > 1933 + (8-1)/12 & (industry_code_num == 1110 | industry_code_num == 1112) 

replace NRAeffective = 13/30 if month == 7 & year == 1933 & industry_code_num == 216
replace NRAeffective  = 1 if time > 1933 + (7-1)/12 & industry_code_num == 216 //Cotton goods code in effect 7/17/33

replace NRAeffective = 19/30 if month == 8 & year == 1933 & industry_code_num == 1608
replace NRAeffective  = 1 if time > 1933 + (8-1)/12 & industry_code_num == 1608 //Cigar manfacturing code in effect 8/11/33

replace NRAeffective = 25/30 if month == 9 & year == 1933 & industry_code_num == 1408
replace NRAeffective  = 1 if time > 1933 + (9-1)/12 & industry_code_num == 1408 //Autos code in effect 9/5/33

replace NRAeffective = 11/30 if month == 8 & year == 1933 & industry_code_num == 131
replace NRAeffective  = 1 if time > 1933 + (8-1)/12 & industry_code_num == 131 //Sugar refining code in effect 8/19/33. This is a little vague assuming that it is Cane Sugar.

gen PRAeffective = 0 
replace PRAeffective = 17/30 if month == 8 & year == 1933
replace PRAeffective = 1 if time > 1933 + (8-1)/12
drop time

//Generate PRA & NRA Period variables
do "Code/Build/Helper/nra_variables"

//Create indicators for workweek within `bandwidth' of PRA limit 
foreach days_label in "" "_six"{
	local lab_day = ""
	if "`days_label'" == "_size"{
		local lab_day = "(6 Day Basis)"
	}
	forvalues bw = 2(2)4{ 
		gen at_PRA_limit`days_label'_bw`bw' = abs(imputed_workweek`days_label' - workweek_limit) <=`bw' if missing_imputed_workweek`days_label' == 0 //Flag for within PRA workweek limit
		label var at_PRA_limit`days_label'_bw`bw' "Workweek within Bandwidth `bw' Hours of Limit `lab_day'"
		gen over_PRA_limit`days_label'_bw`bw' = imputed_workweek`days_label' - workweek_limit - `bw' > 0 if missing_imputed_workweek`days_label' == 0 //Flag for over PRA workweek limit
		label var over_PRA_limit`days_label'_bw`bw' "Workweek over Limit + `bw' Bandwidth `lab_day'"
		gen under_PRA_limit`days_label'_bw`bw' = imputed_workweek`days_label' - workweek_limit + `bw' < 0 if missing_imputed_workweek`days_label' == 0 //Flag for below PRA workweek limit	
		label var under_PRA_limit`days_label'_bw`bw' "Workweek under Limit - `bw' Bandwidth `lab_day'"
	}
}

//Set variables with 2 hour bw as default
rename *_bw2 *

//Create regional indicator variables
gen region_str = ""
local regions new_england mid_atlantic east_north_central west_north_central south_atlantic east_south_central west_south_central mountain pacific 
local counter = 1
foreach region in `regions'{
	gen `region' = region == `counter'
	local ++counter
	local region_label = proper(subinstr("`region'", "_", " ",.))
	replace region_str = "`region_label'" if `region' == 1
	label var `region' "`region_label'"
}

//Generate log variables
foreach var_to_log of varlist emh imputed_workweek* ewemt{
	local var_label: variable label `var_to_log'
	gen l_`var_to_log' = log(`var_to_log')
	label var l_`var_to_log' "Log `var_label'"
}

//Calculate quartiles of variables (revenue, skill mix, wage)
gen revenue = g000v
replace e004t = 0 if e004t == . 
gen skill_mix = e004t / ewemt 
gen wage = e005s/ewemt

foreach group_var in revenue skill_mix wage{
	egen `group_var'_quartile = xtile(`group_var'), by(year industry_code_num) nq(4)
}
gen eql = 1 //generate variable for equal weighting
 
//Identify industry-years with at least one non-missing workweek observation
bysort year industry_code_num: egen included_industry = max(1 - missing_imputed_workweek)	

//generate industry groups
tostring industry_code_num, gen(CoMIndustryNumberString)
gen CoMIndustryGroup = ""
replace CoMIndustryGroup = substr(CoMIndustryNumberString,1,1) if length(CoMIndustryNumberString) == 3
replace CoMIndustryGroup = substr(CoMIndustryNumberString,1,2) if length(CoMIndustryNumberString) == 4
destring CoMIndustryGroup, replace
drop CoMIndustryNumberString

do "Code/Build/Helper/label_vars" //Label variables
do "Code/Build/Helper/indlabel" //Label industries

//Merge business cycle indicator variables for 1933 and 1935
gen yrmon=year*100+month
merge m:1 yrmon using "Data/Source/moncycle.dta", keep(1 3) nogen
drop yrmon

compress
save "Data/Generated/establishment_analysis_monthly.dta", replace //Save dataset
