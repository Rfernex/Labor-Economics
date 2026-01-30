//Program to create subfolders (if they don't exist) for figures and tables as well as install necessary packages

//Subfolders for figures and tables to create
capture mkdir "Data/Generated"
capture mkdir "Data/Generated/Bunching"
capture mkdir "Figures"
capture mkdir "Tables"

//programs installed from SSC
foreach package_to_install in estout reghdfe coefplot xttrans2 ftools regsave carryforward savesome{
 	capture ssc install `package_to_install'
}
