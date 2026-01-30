

cd  "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1"

// 0) Sample: Apr–Jun (pre) and Aug–Oct (post), drop July
keep if year == 1933 & inrange(month, 4, 10)
drop if month == 7

// 1) Keep needed variables
// Adjust the treatment var name if different (e.g., use the author's true name)
local treat above35_workweek_prePRA

// 2) Save full panel for safety
tempfile panel1933
save `panel1933', replace

// 3) Build pre means by industry (Apr–Jun)
preserve
    keep if inlist(month, 4, 5, 6)
    // Keep the treatment variable so we can carry it over (firstnm)
    collapse (mean) pre_hour = l_hourly_earn ///
                     pre_week = l_weekly_earn ///
                     pre_pay  = l_payroll_ind ///
             (firstnm) `treat', by(industry_id)
    tempfile pre
    save `pre', replace
restore

// 4) Build post means by industry (Aug–Oct)
preserve
    keep if inlist(month, 8, 9, 10)
    // Treatment should be positive here if defined as interaction by the author
    collapse (mean) post_hour = l_hourly_earn ///
                     post_week = l_weekly_earn ///
                     post_pay  = l_payroll_ind, by(industry_id)
    tempfile post
    save `post', replace
restore

// 5) Merge pre and post, form deltas
use `pre', clear
merge 1:1 industry_id using `post', nogen keep(match)

// Deltas: post - pre
gen double d_hour = post_hour - pre_hour
gen double d_week = post_week - pre_week
gen double d_pay  = post_pay  - pre_pay

// 6) Define cross-sectional regressor for Δ spec
gen double D_cs = `treat'
label var D_cs "Pre-PRA dose "

// 7) Ensure stute_test is available (skip if already installed)
capture which stute_test
if _rc {
    net install stute_test, from("https://raw.githubusercontent.com/chaisemartinPackages/stute_test/main/Stata/dist/git") replace
}

// 8) Parameters and Stute tests
local ord   3
local breps 999
local seedv 1000

// Hourly earnings (Δ pre→post)
stute_test d_hour D_cs, order(`ord') brep(`breps') seed(`seedv')

// Weekly earnings (Δ pre→post)
stute_test d_week D_cs, order(`ord') brep(`breps') seed(`seedv')

// Payroll (SSNRA indexed, Δ pre→post)
stute_test d_pay  D_cs, order(`ord') brep(`breps') seed(`seedv')
