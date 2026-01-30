//Tables of employment below and above PRA limit before and after the PRA
use "Data/Generated/establishment_analysis_monthly.dta" if included_industry == 1 & valid_imputed_workweek == 1 & (year == 1933 | year == 1935), clear

args within bw 
if "`within'" == ""{ //Default to not within
	local within = 0
}
if "`bw'" == ""{ //Hours BW
	local bw = 1000	//Default to everyone above and below the BW
}

//Add label for figure output in withi case
if `within' == 1{
	local lab_within = "_withinEstab"
}

//Control plotting patterns
local color_1 = "eltblue"
local color_0 = "red*1.2"

local legend_1 = "Just Below Workweek Limit"
local legend_0 = "Just Above Workweek Limit"

local pattern_1933 = "solid"
local pattern_1935 = "dash"

gen not_july = ~(month == 7)

foreach week_basis in ""{
	replace under_PRA_limit`week_basis' = . if abs(imputed_workweek`week_basis'-35)>=`bw'
	if `within'{
		//Categorize establishments by category in July
		replace under_PRA_limit`week_basis' = . if not_july == 1
		bysort establishment_ID (not_july): carryforward under_PRA_limit`week_basis', replace
	}
	
	foreach ind_to_keep in "all"{
		preserve
			//Keep only observations for given industry (or all)
			if "`ind_to_keep'" ~= "all"{
				keep if industry_code_num == `ind_to_keep'
			}
			//Construct employment variables: (1) total; (2) %; (3) indexed
 			collapse (sum) ewemt, by(year month under_PRA_limit`week_basis')
			label var ewemt "Employment"
			bysort month year: egen total_ewemt = sum(ewemt)
			gen perc_ewemt = 100*ewemt / total_ewemt 
			label var perc_ewemt "% of Employment"
			gen index_ewemt = ewemt
			label var index_ewemt "Employment (Indexed)"
			do "Code/Build/Helper/index_variable" index_ewemt "year under_PRA_limit`week_basis'" "month == 1" 

			//Plot variables by month and year 
			foreach var_to_plot in index_ewemt {
				local plotting_string = ""
				local legend_string = ""
				local plotting_string_1933 = ""
				local legend_string_1933 = ""
				local counter = 1
				foreach year in 1933 1935{
					forvalues i = 0(1)1{
						local plotting_string = "`plotting_string' (line `var_to_plot' month if year == `year' & under_PRA_limit`week_basis' == `i', lwidth(thick) lcolor(`color_`i'') lpattern(`pattern_`year''))"
						local legend_string = `"`legend_string' `counter' "`legend_`i'' in `year'""'
						if `year'==1933{
							local plotting_string_1933 = "`plotting_string_1933' (line `var_to_plot' month if year == `year' & under_PRA_limit`week_basis' == `i' & month>=4 & month<=10, lwidth(thick) lcolor(`color_`i'') lpattern(`pattern_`year''))"
							local legend_string_1933 = `"`legend_string_1933' `counter' "`legend_`i''""'
						}
						local ++counter
					}
				}
				sort month
				local var_label: variable label `var_to_plot'
		
				//Fig. 4
				twoway `plotting_string', xtitle("Month") xlabel(1(1)12) xline(7.5) ytitle("`var_label'") legend(order(`legend_string') position(6) rows(2))
				graph export "Figures/plot_employment_byWorkweek`lab_within'`week_basis'_`var_to_plot'_`ind_to_keep'_bw`bw'.pdf", replace
			}	
		restore
	}
}		
