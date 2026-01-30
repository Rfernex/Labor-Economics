// Taylor style regressions
args SSNRA
if "`SSNRA'" == "" {
    local SSNRA = 1
}

local estab_opts `"nonotes nostar se tex b(%12.3f) replace label varwidth(40) obslast nocon nomtitles"'
local absorb_vars industry_id year month
local cluster_var industry_id
local cluster_var_C1 industry_id#month   // CHECK 1: alternative clustering
local employment_vars = "workweek ewemt emh ewemt_ind emh_ind"
local wage_vars = "hourly_earn weekly_earn"
local indexed_ewemt_models "m_workweek m_ewemt_ind m_emh_ind m_hourly_earn m_weekly_earn m_payroll_ind"
local level_ewemt_models "m_workweek m_ewemt m_emh m_hourly_earn m_weekly_earn m_payroll"
local indexed_ewemt_models_noearn "m_workweek m_ewemt_ind m_emh_ind"
local mgroups_list `" "Workweek" "Employment" "Manhours" "Hourly Earnings" "Weekly Earnings" "Payroll" "'
local pattern_6 "1 1 1 1 1 1"

if `SSNRA' == 1 {
    use "Data/Generated/industry_SSNRA_analysis_monthly" if tableno ~= "9", replace
    local wage_vars = "`wage_vars' payroll payroll_ind"
    local vars_to_reg = "`employment_vars' `wage_vars'"
    label var l_hourly_earn "Hourly Earnings"
    label var l_weekly_earn "Weekly Earnings"
    label var l_payroll_ind "Payroll"
    label var l_ewemt_ind "Employment"
    label var l_emh_ind "Manhours"
}
else{
    use "Data/Generated/establishment_analysis_monthly.dta", replace
    rename l_imputed_workweek l_workweek
    rename industry_code_num industry_id
    local vars_to_reg = "`employment_vars'"
}

// Labels
label var NRAcompcrisis "CCNRA"
label var PRAcompcrisis "CCPRA"
label var NRAearly "ENRA"
label var PRAearly "EPRA"
label var l_workweek "Workweek"
label var l_payroll "Payroll"
label var l_ewemt "Employment"
label var l_emh "Manhours"
label var ipfrbnsa97 "IP"
label var spstock3539 "S\&P Stock Index"
label var ricustloan "Interest Rates"

// Prepare titles
local mtitles = ""
local pattern = ""
foreach var_to_reg in `vars_to_reg' {
    local var_label: variable label l_`var_to_reg'
    local mtitles = `"`mtitles' "`var_label'""'
    local pattern = "`pattern' 1"
}

// Log controls (idempotent)
capture drop l_ipfrbnsa97 l_spstock3539
gen l_ipfrbnsa97 = log(ipfrbnsa97)
label var l_ipfrbnsa97 "IP"
gen l_spstock3539 = log(spstock3539) // CHECK 2 : add log of S&P stock index
label var l_spstock3539 "S&P Stock Index"

// Ensure month_year exists in case you use it elsewhere
capture confirm variable month_year
if _rc {
    gen month_year = ym(year, month)
    format month_year %tm
}

// =================== BASELINE : no modifications ==========================

eststo clear
foreach var_to_reg in `vars_to_reg' {
    qui eststo m_`var_to_reg': reghdfe l_`var_to_reg' ///
        NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97, ///
        absorb(`absorb_vars') vce(cluster `cluster_var')
    if "`var_to_reg'"=="workweek" & _rc==0 {
        capture drop sample_src
        gen byte sample_src = e(sample)
    }
    if "`var_to_reg'"=="ewemt" & _rc==0 {
        capture drop sample_ewemt_src
        gen byte sample_ewemt_src = e(sample)
    }
}

estimates restore m_workweek
estimates store BL_m_workweek
estimates restore m_ewemt_ind
estimates store BL_m_ewemt_ind
estimates restore m_hourly_earn
estimates store BL_m_hourly_earn

// =================== CHECK 2 : additional macro control ===================

eststo clear
foreach var_to_reg in `vars_to_reg' {
    qui eststo m_`var_to_reg': reghdfe l_`var_to_reg' ///
        NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_spstock3539, ///
        absorb(`absorb_vars') vce(cluster `cluster_var')
    if "`var_to_reg'"=="workweek" & _rc==0 {
        capture drop sample_src
        gen byte sample_src = e(sample)
    }
    if "`var_to_reg'"=="ewemt" & _rc==0 {
        capture drop sample_ewemt_src
        gen byte sample_ewemt_src = e(sample)
    }
}

// exports Table 1 
esttab `indexed_ewemt_models' using "Replication/Taylor/C2_macro/regs_Taylor_SSNRA`SSNRA'_IP_Check", ///
    `estab_opts' ///
    keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_spstock3539) ///
    order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_spstock3539) ///
    mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)
	
estimates restore m_workweek
estimates store C2_m_workweek
estimates restore m_ewemt_ind
estimates store C2_m_ewemt_ind
estimates restore m_hourly_earn
estimates store C2_m_hourly_earn

// =================== CHECK 1: alternative clustering ===================

eststo clear
foreach var_to_reg in `vars_to_reg' {
    local if_sample = ""
    if "`var_to_reg'"=="workweek" local if_sample "if sample_src"
    if "`var_to_reg'"=="ewemt"    local if_sample "if sample_ewemt_src"
    qui eststo m_`var_to_reg': reghdfe l_`var_to_reg' ///
        NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 `if_sample', ///
        absorb(`absorb_vars') vce(cluster `cluster_var_C1')
}

// exports Table 1 
esttab `indexed_ewemt_models' using "Replication/Taylor/C1_clustering/regs_Taylor_SSNRA`SSNRA'_IP_Check", ///
    `estab_opts' ///
    keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) ///
    order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97) ///
    mgroups(`mgroups_list', pattern(`pattern_6') prefix(\multicolumn{@span}{c}{) suffix(}) span)

estimates restore m_workweek
estimates store C1_m_workweek
estimates restore m_ewemt_ind
estimates store C1_m_ewemt_ind
estimates restore m_hourly_earn
estimates store C1_m_hourly_earn
	
// =================== TABLE : comparison with baseline ===================


// Baseline vs Check 1 vs Check 2 
local estab_opts_no_mtitles: subinstr local estab_opts " nomtitles" "", all

esttab BL_m_workweek C1_m_workweek C2_m_workweek ///
       BL_m_ewemt_ind C1_m_ewemt_ind C2_m_ewemt_ind ///
       BL_m_hourly_earn C1_m_hourly_earn C2_m_hourly_earn using ///
    "Replication/Taylor/Appendix_Compare/comparison_table.tex", ///
    nonotes se tex b(%12.3f) replace label varwidth(40) obslast nocon ///
    mgroups("Workweek" "Employment" "Hourly Earnings", ///
            pattern(1 1 1  1 1 1  1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(})) ///
    mtitles("Baseline" "Check 1" "Check 2"  "Baseline" "Check 1" "Check 2"  "Baseline" "Check 1" "Check 2") ///
    keep(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_spstock3539) ///
    order(NRAearly NRAcompcrisis PRAearly PRAcompcrisis l_ipfrbnsa97 l_spstock3539)
