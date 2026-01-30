//Compare distributions of imputed workweek to workweek reported on schedule weighted by employment
use "Data/Generated/establishment_analysis_monthly.dta" if month == 12, replace //Load December data, which is reference month for workweek question on schedule

//Percentage of imputed relative to reported workweek 
gen diff_workweek = 100*imputed_workweek / d008_workweek if valid_imputed_workweek == 1 & valid_d008_workweek == 1

forvalues year = 1933(2)1933{
	//Appendix Fig. 4
	twoway (kdensity diff_workweek [aw = ewemt] if  year == `year' & abs(diff_workweek-100)<50, lwidth(thick)), xtitle("Imputed Workweek as % of Usual Workweek") ytitle("Density")  xlabel(50(10)150)
	graph export "Figures/compare_workweek_vars_diff_`year'.pdf", replace
}
