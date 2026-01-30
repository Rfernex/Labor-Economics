//Analysis of characteristics of those just above to just below the workweek limit before PRA
args at_PRA_limit
if "`at_PRA_limit'"==""{
	local at_PRA_limit = "at_PRA_limit"
}

use "Data/Generated/establishment_analysis_monthly.dta" if year == 1933 & `at_PRA_limit' ~= . & included_industry == 1 & valid_imputed_workweek == 1, replace 

drop if industry_code_num == 1608 //Drop cigarettes because throws off the plots

//Workweek above limit
gen above_limit = imputed_workweek >= workweek_limit if imputed_workweek ~= .

//Define pre and Post PRA periods
gen pre_PRA = 1 if (month == 6 | month == 5 | month == 4)
replace pre_PRA = 0 if (month == 8 | month == 9 | month == 10)

//Generate variables to plot
gen l_g000v = log(g000v)
gen l_wage = log(wage)
gen south = south_atlantic == 1 | east_south_central == 1 | west_south_central == 1

//Relabel for outputting to figure
label var l_g000v "Revenue"
label var l_ewemt "Employment"
label var l_wage "Wage"
label var south "South"

//Get list of industries to loop over
levelsof industry_code_num, local(industries)

local plots_to_combine = ""
foreach varTemp of varlist l_g000v l_ewemt l_wage south {  //By dep. var.
	eststo clear
	local plotting_string = ""
	foreach j of local industries{ //By industry
		local ind_name : label industry_codes `j'
		local ind_label = "Ind`j'" 
		qui reg `varTemp' above_limit if industry_code_num==`j' & pre_PRA == 1 & `at_PRA_limit' == 1, robust
		qui sum `varTemp' if e(sample) == 1
		//scale coefficient and se by sd of dependent variable
		matrix A = e(b)
		matrix B = e(V)
		matrix A[1,1] = A[1,1] / `r(sd)'
		matrix B[1,1] = B[1,1] / `r(sd)'^2
		capture erepost b = A V = B //this "reposts" the estimates that we will save and plot later
		if _rc == 0{
			local plotting_string "`plotting_string' `ind_label' , bylabel(`ind_name')||"		
			eststo `ind_label'
		}	
	}
	local l_var: variable label `varTemp'
	coefplot `plotting_string', keep(above_limit) xline(0, lcolor(red)) horizontal bycoefs xtitle("`l_var'") mlabel(string(@b,"%9.3f")) mlabposition(12) mlabcolor(black)
	local current_file = "Figures/compare_`varTemp'_prePRA`i'"
	graph save "`current_file'.gph", replace //this is graph for combine
	local plots_to_combine = "`plots_to_combine' `current_file'.gph"
}
graph combine `plots_to_combine', xcommon  iscale(.5)
//Fig. 5 and Appendix Fig. 1
graph export "Figures/compare_`at_PRA_limit'_prePRA`i'.pdf", as(pdf) replace	

//clean up gph files
foreach plot_to_combine in `plots_to_combine'{ 
	rm 	"`plot_to_combine'"
}
