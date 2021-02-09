//Run mixed effect logistic regression with clusters at the NPI- and patient- level for each of the 101 low value service specific sub-samples

display "$S_TIME  $S_DATE"

forval i=1/101 {

clear all
set more off

use lvscle`i'.dta,clear

//Label service variable
egen serv=group(service)
label define serv 1 "backscan" 2 "cerv" 3 "ctdasym" 4 "head" 5 "psa" 6 "pth" 7 "spinj" 8 "t3"
label values serv serv

//Run mixed effect regression
//Predictor: interact the service categorical variables with the fixed-effects predictions(treat as continuous)
//Outcome: binary flags identifying whether bene received low value service
melogit outcome serv##c.predictions, || npi: || BENE_ID:
estimates save lvscle`i'_mod

//Generate random effects at the NPI- and patient-level 
predict re*, reffects
preserve
//Keep distinct NPIs
duplicates drop npi, force
//Check NPI-level random effects
summarize re1, detail
//Save NPI-level random effects
outsheet npi re1 using lvscle_re`i'.csv, comma

restore
}
display "$S_TIME  $S_DATE"
