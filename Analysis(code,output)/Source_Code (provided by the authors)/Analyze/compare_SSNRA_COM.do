//Compare SSNRA data to COM for overlapping industries

use "Data/Generated/industry_SSNRA_analysis_monthly.dta" if year == 1933, replace

//Mapping to COM industries
gen industry_code_num = 1608 if industry == "Cigar"
replace industry_code_num = 1608 if industry == "Cigarette, Snuff, Chewing and Smoking Tobacco"
replace industry_code_num = 1112 if industry == "Structural Steel and Iron Fabricating"
replace industry_code_num = 1112 if industry == "Steel Casting"
replace industry_code_num = 118 if industry == "Ice Cream Manufacturing"
replace industry_code_num = 1408 if industry == "Automobile Manufacturing"

foreach var_to_rename in workweek ewemt{
	rename `var_to_rename' `var_to_rename'_SSNRA
}

//Calculate growth rate in employment
egen industry_num = group(industry)
xtset industry_num month, delta(1)
gen g_ewemt_SSNRA = log(ewemt_SSNRA/l.ewemt_SSNRA)

keep industry_code_num industry *_SSNRA year month
tempfile SSNRA
save `SSNRA'

//Prepare CoM data
use "Data/Generated/establishment_analysis_monthly.dta" if year == 1933, replace

//Calculate mean and median by industry-month-years
local collapsing_string = ""
foreach var_to_rename in imputed_workweek ewemt{
	rename `var_to_rename' `var_to_rename'_COM
	local collapsing_string = "`collapsing_string' (mean) mean_`var_to_rename'_COM = `var_to_rename'_COM (median) med_`var_to_rename'_COM = `var_to_rename'_COM"
}

//Collapse with no weights
collapse `collapsing_string', by(industry_code_num month year)

//Calculate employment growth rates
xtset industry_code_num month, delta(1)
foreach stat in med mean{
	gen g_`stat'_ewemt_COM = log(`stat'_ewemt_COM / l.`stat'_ewemt_COM)
}

//Merge SSNRA data
merge 1:m industry_code_num month year using `SSNRA', keep(3)

//Plot relationship between workweek in datasets 
//Appendix Fig. 5
twoway (function y=x, range(20 60)) (scatter workweek_SSNRA med_imputed_workweek_COM), xtitle("Workweek COM") ytitle("Workweek SSNRA") legend(off)
graph export "Figures/compare_SSNRA_COM_med_workweek.pdf", replace
