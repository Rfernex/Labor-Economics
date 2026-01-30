
cd  "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1"

//Regressions for effects of PRA using D-in-D spec with preexisting workweek variation

local type_data = "_SSNRA"

local l_payroll = "l_payroll l_payroll_ind"	

//options for outputting table and specifications
local estab_opts = `"nonotes se tex b(%12.3f) replace label varwidth(40) obslast nocon nomtitles nostar"' //star(* 0.1 ** 0.05 *** 0.01)"' [remove stars for AEA]
local cluster_var industry 

use "Data/Generated/industry`type_data'_analysis_monthly.dta" if year == 1933 & month>=4 & month<=10, clear

//Drop sugar beets with large seasonal pattern
drop if tableno == "9"
label var l_payroll_ind "Payroll"

preserve
keep if year == 1933 & inrange(month, 4, 10)
drop if month == 7

// 2) Define panel identifiers (group/time) and baseline
* G: industry_id ; T: month
* D is the intensity of the treatment defined as a continuous interaction variable :  dummy for if PRA was in effect for an industry * nb of hours above PRA limit for this industry

cap drop treat_intensity
gen double treat_intensity = PRA_above35_workweek_prePRA
label var treat_intensity  "PRA \$\times\$ Pre-PRA Workweek"

* Install stute_test if needed
capture which stute_test
if _rc {
    net install stute_test, from("https://raw.githubusercontent.com/chaisemartinPackages/stute_test/main/Stata/dist/git") replace
}

* 2) Residualize outcomes to fit the baseline DiD design (absorbs fixed effects)

// Absorb FEs 
foreach y in l_weekly_earn l_payroll l_payroll_ind {
    cap drop r_`y'
    quietly reghdfe `y', absorb(month industry_id) resid
    predict double r_`y', resid
}

* 3) Balancing checks to ensure panel Stute test can be run safely

xtset industry_id month

* 4) Run Stute tests for each SSNRA outcome on the panel with G and T
* Choose main intensity: absolute distance
local D_var treat_intensity
local breps 1000
local seedv 12
local ord 1
local T0 4

* Weekly earnings
stute_test r_l_weekly_earn `D_var' industry_id month, ///
    order(`ord') brep(`breps') seed(`seedv') ///
    baseline(`T0')

* Payroll (log)
stute_test r_l_payroll `D_var' industry_id month, ///
    order(`ord') brep(`breps') seed(`seedv') ///
    baseline(`T0')

* Payroll (SSNRA indexed)
stute_test r_l_payroll_ind `D_var' industry_id month, ///
    order(`ord') brep(`breps') seed(`seedv') ///
    baseline(`T0')
*stute_export, suffix(payroll_ind) outcome(l_payroll_ind)


local outtex "Replication/DiD/C2_Stute_Test/stute_all.tex"
cap file close __fh
file open __fh using "`outtex'", write replace
file write __fh "{\n"
file write __fh "\begin{tabular}{lrrrrrr}\n"
file write __fh "\hline\n"
file write __fh "Outcome & Coef & SE & z & p & CI Low & CI High \\\\ \hline\n"
file write __fh "l_hourly_earn & " %9.3f Th[1,1] " & " %9.3f Th[2,1] " & " %9.3f Th[3,1] " & " %9.3f Th[4,1] " & " %9.3f Th[5,1] " & " %9.3f Th[6,1] " \\\\ \n"
file write __fh "l_weekly_earn & " %9.3f Tw[1,1] " & " %9.3f Tw[2,1] " & " %9.3f Tw[3,1] " & " %9.3f Tw[4,1] " & " %9.3f Tw[5,1] " & " %9.3f Tw[6,1] " \\\\ \n"
file write __fh "l_payroll & "      %9.3f Tp[1,1] " & " %9.3f Tp[2,1] " & " %9.3f Tp[3,1] " & " %9.3f Tp[4,1] " & " %9.3f Tp[5,1] " & " %9.3f Tp[6,1] " \\\\ \n"
file write __fh "l_payroll_ind & "  %9.3f Tpi[1,1] " & " %9.3f Tpi[2,1] " & " %9.3f Tpi[3,1] " & " %9.3f Tpi[4,1] " & " %9.3f Tpi[5,1] " & " %9.3f Tpi[6,1] " \\\\ \n"
file write __fh "\hline\n"
file write __fh "\end{tabular}\n"
file write __fh "}\n"
file close __fh
	