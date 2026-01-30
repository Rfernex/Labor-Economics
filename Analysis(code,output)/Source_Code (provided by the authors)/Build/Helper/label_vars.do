//Label variables
capture label var eql "Equal Weight"
capture label var region_str "Region (String)"
capture label var ewemt "Monthly Employment"
capture label var emh "Manhours"
capture label var estabid_num "(Numeric) Establishment ID"
capture label var industry_code_num "(Numeric) Industry Code"
capture label var d008_workweek "Workweek Reported on Schedule"
capture label var valid_d008_workweek "Valid Workweek as Reported on Schedule"
capture label var quarter "Quarter"
capture label var month "Month"
capture label var merge_NIRA "Merged with NIRA Code Data"
capture label var CoMIndustryGroup "COM Industry Group"

//Quartile variables
capture label var revenue "Revenue"
capture label var skill_mix "High-Low Skill Ratio"
capture label var wage "Wage"
foreach var_quartile in revenue skill_mix wage{
	capture local var_label: variable label `var_quartile'
	capture label var `var_quartile'_quartile "`var_label' Quartile"
}

//Generated workweek variables
capture label var imputed_workweek "Imputed Workweek"
capture label var imputed_workweek_six "Imputed Workweek (Six Day Basis)"
capture label var valid_imputed_workweek "Valid Imputed Workweek Length"
capture label var valid_imputed_workweek_six "Valid Imputed Workweek Length (Six Day Basis)"
capture label var missing_imputed_workweek "Missing Imputed Workweek Length"
capture label var missing_imputed_workweek_six "Missing Imputed Workweek Length (Six Day Basis)"
capture label var included_industry "Industry with at Least One Valid Workweek Observation"
capture label var workweek_limit "Industry-specific PRA Workweek Limit"

//Log variables
foreach var_log of varlist *{
	capture local var_label: variable label `var_log'
	capture label var l_`var_log' "Log of `var_label'"
}
