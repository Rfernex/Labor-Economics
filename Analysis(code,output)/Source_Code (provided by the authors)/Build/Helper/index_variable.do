//Index values to particular value based on cond by group
args var_to_index group_var cond

//If no group var, then create a dummy variable that is a single group
if "`group_var'"==""{
	tempvar group_var
	gen `group_var' = 1
}

//Count that condition is unique by group
tempvar cond_var num_count value_to_index_with
gen `cond_var' = `cond'

// bysort `group_var': egen `num_count' = total(`cond_var')
// qui sum `num_count'
// foreach stat in min max{
// 	local `stat'_count = r(`stat')
// }

// //Check: Condition does not uniquely identify a base value
// assert `max_count' <= 1
// //Check: Condition is never satisfied
// assert `min_count' > 1 

//Index the values
bysort `group_var': egen `value_to_index_with' = max(`cond_var' * `var_to_index') //Assumes that values of `var_to_index' are strictly positive
replace `var_to_index' = 100*`var_to_index' / `value_to_index_with'
