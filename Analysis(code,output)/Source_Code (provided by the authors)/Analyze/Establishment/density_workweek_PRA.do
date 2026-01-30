//Plots of density of workweek & employment before & after PRA
use "Data/Generated/establishment_analysis_monthly.dta" if included_industry == 1 & valid_imputed_workweek == 1 & month >= 4 & month <= 10 & month ~= 7, clear //Use 3-month window of months around PRA enactment

gen pre_PRA = month < 7 //PRA period definition consistent with prepost build files.

//Scale workweek variable and relabel
foreach suffix in "" "_six"{
	replace imputed_workweek`suffix' = 100*imputed_workweek`suffix' / workweek_limit
	label var imputed_workweek`suffix' "Workweek as % of PRA Limit"
}

foreach var_to_plot in imputed_workweek imputed_workweek_six{
	local var_label: variable label `var_to_plot'	
	foreach wgt in ewemt  {
		if "`var_to_plot'" == "imputed_workweek_six" | "`var_to_plot'" == "imputed_workweek" | "`wgt'" == "eql"{
			twoway (kdensity `var_to_plot' if pre_PRA == 1 & year == 1933 [aw = `wgt'], lwidth("thick") lcolor(red*1.2)) (kdensity `var_to_plot' if pre_PRA == 0 & year == 1933 [aw = `wgt'], lpattern("dash") lwidth("thick") lcolor(red*1.2)) (kdensity `var_to_plot' if pre_PRA == 1 & year == 1935 [aw = `wgt'], lwidth("thick") lcolor("eltblue")) (kdensity `var_to_plot' if pre_PRA == 0 & year == 1935 [aw = `wgt'], lpattern("dash") lwidth("thick") lcolor("eltblue")), xtitle("`var_label'") ytitle("Density") legend(order(1 "Apr. - June 1933" 2 "Aug. - Oct. 1933" 3 "Apr. - June 1935" 4 "Aug. - Oct. 1935") position(6) rows(2)) 
			//Fig. 3 and Appendix Fig. 7
			graph export "Figures/density_PRA_`var_to_plot'_`wgt'.pdf", as(pdf) replace
		}
	}
}	
