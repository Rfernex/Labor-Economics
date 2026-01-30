//Plot % of valid or non-missing workweek by size quartile.
use "Data/Generated/establishment_analysis_monthly.dta" if included_industry == 1, clear
gen foo = "Revenue Quartile" //Used to generate xtitle with bar graphs

foreach var_to_sum in valid_imputed_workweek missing_imputed_workweek{
	replace `var_to_sum' = 100*`var_to_sum'
	local var_label: variable label `var_to_sum'
	foreach wgt in ewemt{
		forvalues year = 1933(2)1933{	
			//Appendix Figs. 2 & 3
			graph bar `var_to_sum' if year == `year' [fw = `wgt'], over(revenue_quartile) over(foo) ytitle("Percentage") intensity(0)
			graph export "Figures/missing_data_bySize_`var_to_sum'_`year'_`wgt'.pdf", replace
		}
	}
}
