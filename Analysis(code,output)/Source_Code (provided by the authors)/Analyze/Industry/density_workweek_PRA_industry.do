//Plots of density of workweek & employment before & after PRA using industry data
args type_data //Select daatset to use. default is NICB.
if "`type_data'" == ""{ //default is NICB data.
	local type_data = "_NICB"
}

use "Data/Generated/industry`type_data'_analysis_monthly.dta" if month >= 4 & month <= 10 & month ~= 7, clear //Use 3-month window of months around PRA enactment

//PRA period definition consistent with prepost build files.
gen pre_PRA = month < 7
gen eql = 1

//Scale workweek variable and relabel
replace workweek = 100*workweek / 35
label var workweek "Workweek as % of PRA Limit"
label var l_ewemt "Log Employment Index"

foreach var_to_plot in  workweek{
	local var_label: variable label `var_to_plot'
	foreach wgt in ewemt {
		if "`var_to_plot'" == "workweek" | "`wgt'" == "eql"{
			//Appendix Fig. 6
			twoway (kdensity `var_to_plot' if pre_PRA == 1 & year == 1933 [aw = `wgt'], lwidth("thick") lcolor(red*1.2)) (kdensity `var_to_plot' if pre_PRA == 0 & year == 1933 [aw = `wgt'], lpattern("dash") lwidth("thick") lcolor(red*1.2)) (kdensity `var_to_plot' if pre_PRA == 1 & year == 1935 [aw = `wgt'], lwidth("thick") lcolor("eltblue")) (kdensity `var_to_plot' if pre_PRA == 0 & year == 1935 [aw = `wgt'], lpattern("dash") lwidth("thick") lcolor("eltblue")), xtitle("`var_label'") ytitle("Density") legend(order(1 "Apr. - June 1933" 2 "Aug. - Oct. 1933" 3 "Apr. - June 1935" 4 "Aug. - Oct. 1935") position(6) rows(2))
			graph export "Figures/density`type_data'_PRA_`var_to_plot'_`wgt'.pdf", as(pdf) replace
		}
	}
}
