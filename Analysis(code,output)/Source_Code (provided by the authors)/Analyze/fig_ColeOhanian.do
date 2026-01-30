//Plot labor input data from Cole & Ohanian (1999) 
use "Data/Source/labor_input_ColeOhanian99.dta", replace

//Change labels
label var emp "Aggregate Employment"
label var hours "Aggregate Hours"

//Emp and Hours 
//Fig. 1
sort year
twoway (line emp year, lwidth(thick)) (line hours year, lwidth(thick)), xtitle("Year") ytitle("Index") xlabel(1929(1)1939) legend(position(6) rows(1))
graph export "Figures/fig_ColeOhanian_labor_input.pdf", replace
