//Generate some industry level summary statistics for 1933
use "Data/Generated/establishment_analysis_monthly" if included_industry == 1 & month == 1, clear

gen estab = 1 //number of establishments
foreach var_to_scale in g000v e005s{
	replace `var_to_scale' = `var_to_scale' / 1000
}

//Summary statistics of industries in 1933 
preserve 
	keep if year == 1933
	collapse (mean) ewemt g000v e005s, by(industry_code_num) 
	//prepare for writing data out to TeX format
	tostring ewemt g000v e005s, force replace format(%9.2f)
	replace e005s = e005s + "\\"
	local val = e005s in `=_N'
	replace e005s = "`val' \bottomrule" in `=_N'
	//Appendix Table 1
	export delimited using "Tables/summary_stats_inds.tex", delimiter("&") replace novarnames 
restore

//Distribution of establishments by industry and year 
collapse (sum) estab, by(industry_code_num year) 
bysort year: egen total_estabs = sum(estab)
//replace estab = estab*100/total_estabs
drop total_estabs
keep if year == 1933
reshape wide estab, i(industry_code_num) j(year)
//prepare for writing data out to TeX format
tostring estab*, force replace format(%9.0f)
replace estab1933 = estab1933 + "\\"
local val = estab1933 in `=_N'
replace estab1933 = "`val' \bottomrule" in `=_N'
//Appendix Table 2
export delimited using "Tables/summary_stats_ind_counts.tex", delimiter("&") replace novarnames 
