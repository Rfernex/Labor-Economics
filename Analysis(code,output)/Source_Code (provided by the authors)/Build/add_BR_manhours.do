//Adds manhours data from original BR recrods to the CoM Dataset
args file_to_use
if "`file_to_use'" == ""{
	local file_to_use = "CoM_workweek"
}

//Make sure industry variable is string
use "Data/Source/`file_to_use'", replace
tostring industry_code_num, replace force
save "Data/Source/`file_to_use'", replace

tempfile data_to_merge_ICPSR data_to_merge_CoM CoM_enhanced

//Load the auto dataset from ICPSR
use YEAR A001 AG003 AG004 EMH* using "Data/Source/35604-0001-Data.dta" if YEAR == 1933, clear
//Variable renaming and casting for consistency with other datasets
gen industry_code_num = "1408" 
rename YEAR A001 AG003 AG004 EMH*, lower 
foreach var_to_upper in a001 ag003 ag004{
	replace `var_to_upper' = upper(`var_to_upper')
} 
replace ag003 = "DE KALB" if ag003 == "DEKALB"
tostring emh* year, replace force
save `data_to_merge_ICPSR', replace

//Load our original CoM extract
use "Data/Source/`file_to_use'" if year == "1933" & industry_code_num == "1408"
drop emh*
//Merge in BR data for industry 1408
merge 1:1 year a001 ag003 ag004 industry_code_num using `data_to_merge_ICPSR', nogen
save `data_to_merge_CoM', replace
//Append new data for industry 1408 to our dataset
use "Data/Source/`file_to_use'"
drop if year == "1933" & industry_code_num == "1408"
append using `data_to_merge_CoM'
save `CoM_enhanced', replace

//Load the cotton dataset from ICPSR
use YEAR A001 A002 AG002 AG004 EMH* G000V EWEMT using "Data/Source/35605-0001-Data.dta" if YEAR == 1933, clear
//Variable renaming and casting for consistency with other datasets
replace AG004 = trim(AG004)
gen industry_code_num = "216" 
rename YEAR A001 A002 AG002 AG004 G000V EMH* EWEMT, lower 
foreach var_to_upper in a001 a002 ag002 ag004{
	replace `var_to_upper' = upper(`var_to_upper')
} 
replace ag002 = "Gastoniaa" if ag002 == "Gastonia" & a001 == "TRENTON COTTON MILLS"
tostring emh* year g000v ewemt, replace force
save `data_to_merge_ICPSR', replace

//Load the original CoM
use "Data/Source/`file_to_use'" if year == "1933" & industry_code_num == "216"

//Align matching variables
replace ag002 = "Gastoniaa" if ag002 == "Gastonia" & a001 == "TRENTON COTTON MILLS"
replace ag002 = "STATESVILLE" if obs_id=="1933216000000002085" | obs_id=="1933216000000002080"
replace ag002 = "STONY POINT" if obs_id=="1933216000000002003" | obs_id=="1933216000000002377"
replace ag002 = "STONEWALL" if obs_id=="1933216000000001609"
replace ag002 = "FORT MILL" if obs_id=="1933216000000003871"
replace ag002 = "STEVENSON" if obs_id=="1933216000000000102"
replace ag002 = "STANLEY" if obs_id=="1933216000000001991"
replace ag002 = "STARKVILLE" if obs_id=="1933216000000001628"
replace ag002 = "EL PASO" if obs_id=="1933216000000004416"
replace ag002 = "FT. WORTH" if obs_id=="1933216000000004383"
replace ag002 = "STONINGTON" if obs_id=="1933216000000000381"
replace ag002 = "ARCADIA CITY" if obs_id=="1933216000000000337"
replace ag002 = "ST. PAULS" if obs_id=="1933216000000002402"
replace ewemt = "." if obs_id=="1933216000000003466"

replace ag004 = trim(ag004)
drop emh*
//Merge new ICPSR data
merge 1:1 year g000v ag002 ag004  industry_code_num ewemt using `data_to_merge_ICPSR', nogen
replace ag002 = "Gastonia" if ag002 == "Gastoniaa" & a001 == "TRENTON COTTON MILLS"
replace ewemt = "0" if obs_id=="1933216000000003466"
save `data_to_merge_CoM', replace

//Load the "enhanced" CoM data with information for 1408  
use `CoM_enhanced', clear
drop if year == "1933" & industry_code_num == "216"
//Append info for industry 216
append using `data_to_merge_CoM'

save "Data/Generated/CoM_workweek", replace //save final result
