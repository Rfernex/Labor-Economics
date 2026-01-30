//Generate PRA & NRA Period variables
gen PRA_period  = (year==1933 & month >= 8 & month <= 10) 
label var PRA_period "PRA (August-October 1933)"

//Compliance crisis variables
gen compcrisis = 0
replace compcrisis =1 if year==1934 & month > 3
replace compcrisis = 1 if year==1935 & month < 6
label var compcrisis "Compliance Crisis"

gen NRAcompcrisis = compcrisis*NRAeffective //NRAeffective is defined by hand
gen PRAcompcrisis = compcrisis*PRAeffective
label var NRAcompcrisis "NRA X Compliance Crisis"
label var PRAcompcrisis "PRA X Compliance Crisis"

gen NRAearly=0
replace NRAearly=NRAeffective if year==1933 & month > 6
replace NRAearly=NRAeffective if year==1934 & month < 4
label var NRAearly "NRA X Pre-Compliance Crisis"

gen PRAearly=0
replace PRAearly=PRAeffective if year==1933 & month > 6
replace PRAearly=PRAeffective if year==1934 & month < 4
label var PRAearly "PRA X Pre-Compliance Crisis"
