//Compare trends across datasets
use "Data/Generated/establishment_analysis_monthly.dta" if included_industry == 1, clear

local vars_to_index = "workweek" //variables to plot

//Plotting patterns for industries from the two datasets
local pattern_0 = "solid"
local pattern_1 = "dash"
local pattern_2 = "dot"

//xlines for year: PRA - 1933, Scheter - 1935
local line_1933 = "7.5"
local line_1935 = "5.5"

//Group labels for datasets
local lab_1 = "COM"
local lab_2 = "NICB"
local lab_3 = "SSNRA"

//Rename for consistency with NICB data
rename ewemt ewemt_wgt
rename imputed_workweek workweek
rename industry_code_num industry_id

//Collapse to industry level
gen ewemt = 1
collapse (mean) workweek (sum) ewemt [aw = ewemt_wgt], by(industry_id year month)

//Indicator for CoM industry
gen data_establishment = 1

//Append industry-level data
foreach type_data in "_SSNRA" "_NICB"{
	append using "Data/Generated/industry`type_data'_analysis_monthly", generate(data_industry`type_data')
	replace data_establishment = 0 if data_establishment == .
}

//Remap industry ids
tostring industry_id, replace force
replace industry = industry_id if industry == ""
egen industry_id_new = group(industry)
gen group  = 1 if data_establishment == 1
replace group  = 2 if data_industry_NICB == 1
replace group  = 3 if data_industry_SSNRA == 1
drop ewemt_1933 //Conflicts with code below

//Plot medians by month and industry group
collapse (median) `vars_to_index', by(year month group)
forvalues year = 1933(2)1933{
	foreach var_to_index in `vars_to_index'{
		gen `var_to_index'_`year' = `var_to_index'
		local plotting_string = ""
		local legend_string = ""
		qui do "Code/Build/Helper/index_variable" `var_to_index'_`year' group "year == `year' & month == 1"
		forvalues group = 1(1)3{
			local plotting_string = "`plotting_string' (line `var_to_index'_`year' month if group == `group' & year == `year', lwidth(thick))"
			local legend_string = `"`legend_string' `group' "`lab_`group''""'
		}
		sort month
		//Fig. 2
		twoway `plotting_string', xlabel(1(1)12) xtitle("Month") ytitle("Index") legend(order(`legend_string') position(6) rows(1)) xline(`line_`year'')
		graph export "Figures/compare_establishment_industry_med_`var_to_index'_`year'.pdf", replace
	}
}
