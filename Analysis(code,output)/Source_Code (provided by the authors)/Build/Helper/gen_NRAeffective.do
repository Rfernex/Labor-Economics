//Read in NRA code dates and generate effective NRA treatment variable
//Data NRA_codes should include variables industry, year, month, day when code went into effect
merge 1:1 industry year month using "Data/Source/NRA_codes"
gen time = year + (month-1)/12
gen NRAeffective = (30-day) / 30 //day only non-missing in single month'
replace NRAeffective = 0 if NRAeffective == .
bysort ind: egen time_NRA = max(time*(NRAeffective >0 ))
replace NRAeffective = 1 if time > time_NRA
//If want to define treatement as only if after the 15th of day when CoM is supposed to refer to
//replace NRAeffective = day >= 15 if day ~= . 
drop day
