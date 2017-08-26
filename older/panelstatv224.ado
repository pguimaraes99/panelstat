*! version 2.24 4jan2017
*---------------------------------------------------------*
* Calculates descriptive statistics for panel data
* Author: Paulo Guimaraes     
*---------------------------------------------------------*
program define panelstat, rclass sortpreserve
syntax varlist (min=2 max=2) [if] [in], [ ///
GAPS /// Analyzes data gaps
RUNS /// Analyzes runs
PATTERN /// /*  */
DEMO /// /* demography*/
CONT /// /* ignores gaps in the time variable*/
NOSUM /// /* do not report summary of panel */
MAXPAT(integer 10) /// /* Maximum number of patterns in the data*/
ABSV(integer 10) /// /* absolute value */
RELV(integer 100) /// /* relative value */
LIMTRAN(integer 5) /// /* limit for transition */
SDMIS(real 1) /// /* factor to apply to standard deviation on miscode  */
LLMIS(real 10) /// /* lower limit to flag changes on miscode */
DIFMIS(real 100) /// /*upper limit on the difference between the changes in the two variables compared with miscode  */
EXCEL(string) /// /* output results to excel file*/
KEEPMaxgap(string) /// /* variable contains the largest gap size for the individual*/
KEEPNgaps(string) /// /* variable contains the number of gaps for the individual*/
CHECKID(string) /// /* check whether variable can be used as an id */
ABS(varlist) /// /* check absolute change within i */
REL(varlist) /// /* check relative change within i */
WIV(varlist) /// /* Check consistency of variables constant within ID */
WTV(varlist) /// /* Check consistency of variables constant within TIME */
TABOVERT(varlist) /// /*Produces a tab of the variable with # of obs per category over time*/
FLOWS(varlist) /// /*Calculates the flows for the chosen variables*/
TRANS(varlist) /// /*creates an indicator showing whether the transition probability is below some level*/
MISCODE(string) /// /* requires a stub for list of variables. Checks for compensanting changes between pairs of variables */
KEEPWIV /// /* keep an indicator for the wiv variables */
KEEPWTV /// /* keep an indicator for the wiv variables */
KEEPABS /// /* keep an indicator for the wiv variables */
KEEPREL /// /* keep an indicator for the wiv variables */
ALL ///
]
version 13
capture drop _ord
capture drop _check
capture drop _flag_m_*
gen long _ord=_n
preserve
tempvar touse
mark `touse' `if' `in'
qui keep if `touse'
tokenize `varlist'
if "`miscode'"!="" {
unab misvar: `miscode'*
}
keep _ord `varlist' `wiv' `wtv' `tabovert' `flows' `checkid' `abs' `rel' `trans' `misvar'
global ps_maxpat=`maxpat'
global ps_absv=`absv'
global ps_relv=`relv'
global ps_low=`llmis'
global ps_dif=`difmis'
global ps_sdf=`sdmis'
**************************************
if "`nosum'"=="" {
local basic basic
}
if "`all'"!="" {
local gaps gaps
local runs runs
local pattern pattern
local demo demo
}

*******************
* Create panel vars
*******************
tempvar i t k
*local dim=2
qui gengroup `1' `i' 
if "`cont'"=="cont" {
tempvar yearst
gen `yearst'=string(`2')
encode `yearst', gen(`t')
drop `yearst'
}
else {
clonevar `t'=`2' 
}

*****************************
* Create auxiliary variables
*****************************

sort `i' `t'
qui bys `i' (`t'): gen _nn=_n
qui bys `i' (`t'): gen _NN=_N
qui bys `t' (`i'): gen _tt=_n
qui bys `t' (`i'): gen _TT=_N
label var _NN "Observ per individual"
qui bys `i' (`t'): gen _dift=`t'-`t'[_n-1]-1
qui replace _dift=0 if _nn==1
label var _dift "Size of time gaps"
qui bys `i': egen _ngaps=total(_dift>0)
label var _ngaps "Number of gaps per individual"
bys `i' (`t'): gen _run=_n==1
qui bys `i' (`t'): replace _run=_run[_n-1]+`t'-`t'[_n-1]-1 if _n>1
* Note: Number of runs by individual = # gaps plus 1


**************************
* Variables to retain
**************************
tempfile temp1 temp2 temp3 temp4 temp5 temp6 temp7 temp8
if "`keepmaxgap'"!=""|"`keepngaps'"!="" {
if "`keepmaxgap'"!="" {
bys `i': egen int `keepmaxgap'=max(_dift)
}
if "`keepngaps'"!="" {
gen int `keepngaps'=_ngaps
}
sort _ord
qui save `temp1'
}

**************************
* Basic panel descriptives
**************************
if "`basic'"=="basic" {
basicdescriptives `i' `t' "`excel'"
}

if "`gaps'"=="gaps" {
module2 `i' `t' "`excel'"
}

if "`runs'"=="runs" {
module5 `i' `t' "`excel'"
}

if "`demo'"=="demo" {
module3 `i' `t' "`excel'"
}

if "`pattern'"=="pattern" {
module4 `i' `t' "`excel'"
}

if "`checkid'"!="" {
checkthisid `i' `t' `checkid'
sort _ord
qui save `temp4'
}

if "`abs'"!="" {
checkabsval `i' `t' "`abs'"
if "`keepabs'"!="" {
sort _ord
qui save `temp5'
}
}

if "`rel'"!="" {
checkrelval `i' `t' "`rel'"
if "`keeprel'"!="" {
sort _ord
qui save `temp6'
}
}

if "`wiv'"!="" {
local fr "Analysis of wiv variables"
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet("wiv") modify
puttexttoexcel A1 "`fr'"
puttexttoexcel A4 "Total # Obs"
puttexttoexcel A5 "Nonmissing Obs"
puttexttoexcel A6 " % nonmissing"
puttexttoexcel A8 " Minimum value"
puttexttoexcel A9 " Maximum value"
puttexttoexcel A11 "Total i-Obs"
puttexttoexcel A12 "Invariant no missing"
puttexttoexcel A13 "Variant no missing"
puttexttoexcel A14 "Complete missing"
puttexttoexcel A15 "Invariant with missing"
puttexttoexcel A16 "Variant with missing"
}
local varwiv ""
local col=3
foreach var of varlist `wiv' {
checkvar _nn `i' "`var'" "`1'" `col' "`excel'"
rename _w_ _wiv_`var'
if "`keepwiv'"!="" {
local varwiv `varwiv' _wiv_`var'
}
local col=`col'+1
}
if "`keepwiv'"!="" {
sort _ord
qui save `temp2'
}
}

if "`wtv'"!="" {
local fr "Analysis of wtv variables"
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet("wtv") modify
puttexttoexcel A1 "`fr'"
puttexttoexcel A4 "Total # Obs"
puttexttoexcel A5 "Nonmissing Obs"
puttexttoexcel A6 " % nonmissing"
puttexttoexcel A8 " Minimum value"
puttexttoexcel A9 " Maximum value"
puttexttoexcel A11 "Total t-Obs"
puttexttoexcel A12 "Invariant no missing"
puttexttoexcel A13 "Variant no missing"
puttexttoexcel A14 "Complete missing"
puttexttoexcel A15 "Invariant with missing"
puttexttoexcel A16 "Variant with missing"
}
local varwtv ""
local col=3
foreach var of varlist `wtv' {
checkvar _tt `t' "`var'" "`2'" `col' "`excel'"
rename _w_ _wtv_`var'
if "`keepwtv'"!="" {
local varwtv `varwtv' _wtv_`var'
}
local col=`col'+1
}
if "`keepwtv'"!="" {
sort _ord
qui save `temp3'
}
}

if "`tabovert'"!="" {
foreach var of varlist `tabovert' {
tabover `t' "`var'" "`excel'"
}
}

if "`flows'"!="" {
foreach var of varlist `flows' {
di _dup(53) "*"
local fr "Time flows for variable `var'"
di "`fr'"
di _dup(53) "*"
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet("fl_`var'") modify
}
calcflow `i' `t' "`var'" "`excel'"
}
}

if "`trans'"!="" {
di
capture label define translabel ///
1 "p<5" ///
2 "5<=p<25" ///
3 "25<=p<75" ///
4 "75<=p<95" ///
5 "95<=p<100" ///
6 "p=100"
foreach var of varlist `trans' {
di _dup(53) "*"
local fr "Distribution of transition probabilities (t-1 to t) for classes of `var'"
di "`fr'"
di _dup(53) "*"
calctrans `i' `t' "`var'"
}
sort _ord
qui save `temp7'
}

**********************************************************************

if "`miscode'"!="" {
local nmvars: word count `misvar'
local m1mis=`nmvars'-1
forval m=1 / `nmvars' {
local mp1=`m'+1
forval k=`mp1' / `nmvars' {
qui cprmiscvars `i' `t' `miscode'`m' `miscode'`k'
qui sum _flag_cpr, meanonly
if r(mean)>0 {
rename _flag_cpr _flag_m_`m'_`k'
}
else {
drop _flag_cpr
}
}
}
sort _ord
qui save `temp8'
}
***********************************************************************


restore

if "`keepmaxgap'"!=""|"`keepngaps'"!="" {
sort _ord
qui merge 1:1 _ord using `temp1', keepusing(`keepmaxgap' `keepngaps')
drop _merge
}

if "`keepwiv'"!=""&"`wiv'"!="" {
capture drop _wiv_*
qui merge 1:1 _ord using `temp2', keepusing(_wiv_*)
drop _merge
capture label define wivlabel ///
1 "complete time-invariant" ///
2 "complete time-variant"   ///
3 "Complete missing"       ///
4 "time-invariant with miss" ///
5 "time-variant with miss"
label values _wiv_* wivlabel
}

if "`keepwtv'"!=""&"`wtv'"!=""{
capture drop _wtv_*
qui merge 1:1 _ord using `temp3', keepusing(_wtv_*)
drop _merge
capture label define wtvlabel ///
1 "complete i-invariant" ///
2 "complete i-variant"   ///
3 "Complete missing"       ///
4 "i-invariant with miss" ///
5 "i-variant with miss"
label values _wtv_* wtvlabel
}

if "`checkid'"!="" {
qui merge 1:1 _ord using `temp4', keepusing(_check)
drop _merge
}

if "`abs'"!=""&"`keepabs'"!="" {
qui merge 1:1 _ord using `temp5', keepusing(_abs_*)
drop _merge
}

if "`rel'"!=""&"`keeprel'"!="" {
qui merge 1:1 _ord using `temp6', keepusing(_rel_*)
drop _merge
}

if "`trans'"!="" {
qui merge 1:1 _ord using `temp7', keepusing(_trans)
drop _merge
}

if "`miscode'"!="" {
capture merge 1:1 _ord using `temp8', keepusing(_flag_*)
capture drop _merge
di
di _dup(53) "*"
di "Checking for miscoding on `miscode'"
di _dup(53) "*"
di
di "Variables: `misvar'"
di "criteria used: llmis=`llmis', difmis=`difmis', sdmis=`sdmis' "
di
if _rc==111 {
di "Nothing to report - no flags created "
}
else {
di "The following flags were created:"
tabstat _flag_*, statistics(sum) columns(statistics) longstub
}
}

capture drop _ord
end

program define module2
args i t excel
preserve
keep `i' `t' _nn _NN _dift _ngaps
local sheet "gaps"
di _dup(53) "*"
local fr "Distribution of the size of the time gaps"
di "`fr'"
di _dup(53) "*"
qui count if _dift>0
if r(N)>0 {
tempname col1 col2
tab _dift if _dift>0, matrow(`col1') matcell(`col2')  
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "`fr'"
puttabtoexcel 1 3 "Size of time gaps" `col1' `col2' `sheet'
}
di
di _dup(53) "*"
local fr "Distribution of the number of gaps by individual"
di "`fr'"
di _dup(53) "*"
tab _ngaps if _nn==1, matrow(`col1') matcell(`col2')  
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel E1 "`fr'"
puttabtoexcel 5 3 "Size of time gaps" `col1' `col2' `sheet'
}
di
di _dup(53) "*"
local fr "Size of time gap vs number of gaps per individual"
di "`fr'"
di _dup(53) "*"
tempname mat1 mat2 mat3
tab _dift _ngaps if _dift>0, matcol(`mat1') matrow(`mat2') matcell(`mat3') 
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel I1 "`fr'"
puttab2toexcel 9 3 "Size of time gaps" "Number of gaps per individual" `mat1' `mat2' `mat3' `sheet'
}
matrix off=colsof(`mat3')
local pos=off[1,1]+11
di _dup(53) "*"
local fr "Observations per individual vs number of time gaps"
di "`fr'"
di _dup(53) "*"
tab _NN _ngaps if _dift>0,  matcol(`mat1') matrow(`mat2') matcell(`mat3') 
if "`excel'"!="" {
excelcol `pos'
local col `r(column)'
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel `col'1 "`fr'"
puttab2toexcel `pos' 3 "Observ per Individual" "Number of gaps per individual" `mat1' `mat2' `mat3' `sheet'
}
di _dup(53) "*"
matrix off=colsof(`mat3')
local pos=off[1,1]+`pos'+2
local fr "Observations per individual vs size of time gaps"
di "`fr'"
di _dup(53) "*"
tab _NN _dift if _dift>0, matcol(`mat1') matrow(`mat2') matcell(`mat3')
if "`excel'"!="" {
excelcol `pos'
local col `r(column)'
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel `col'1 "`fr'"
puttab2toexcel `pos' 3 "Observ per Individual" "Size of time gaps" `mat1' `mat2' `mat3' `sheet'
}
}
else {
di
di "There are no time gaps"
di
}
restore
end

program define module3
args i t excel
preserve
local sheet "demo"
keep `i' `t'
sort `i' `t'
gen total=1
label var total "Total"
bys `i' (`t'): gen inc1=(`t'-`t'[_n-1]==1)
gen entry=1-inc1
by `i' (`t'): gen first=_n==1
gen reent=ent-first
by `i' (`t'): gen inc2=(`t'[_n+1]-`t'==1)
gen exit=1-inc2
by `i' (`t'): gen last=_n==_N
gen reexit=exit-last
collapse (sum) total inc1 entry first reent inc2 exit last reexit, by(`t')
rename `t' period
di _dup(53) "*"
local fr "Time changes - incumbents, entrants and exits"
di "`fr'"
di _dup(53) "*"
list 
di "period - time period"
di "total - total number of individuals at period t"
di "inc1 - number of individuals at t that are also present at t-1"
di "entry - number of individuals at t that are not present at t-1"
di "first - number of individuals at t who show up for the first time at t"
di "reent - number of individuals at t that are reentering at period t"
di "inc2 - number of individuals at t that are also present at t+1"
di "exit - number of individuals at t that are not present at t+1"
di "last - number of individuals at t that are not present at any future period"
di "reexit - number of individuals at t that are not present at t+1 but appear in later periods"
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
qui {
puttexttoexcel A1 "`fr'"
putexcel A3=("period")
putexcel B3=("total")
putexcel C3=("inc1")
putexcel D3=("entry")
putexcel E3=("first")
putexcel F3=("reent")
putexcel G3=("inc2")
putexcel H3=("exit")
putexcel I3=("last")
putexcel J3=("reexit")
}
tempname mat
mkmat _all, mat(`mat')
qui putexcel A4=matrix(`mat'), sheet(`sheet') colwise
}
restore
end

program define module4
args i t excel
local sheet "pattern"
preserve
keep `i' `t'
sort `i' `t'
qui gen _dum=1
tempvar tt
sum `t', meanonly
gen `tt'=`t'-r(min)+1
local k=r(max)-r(min)+1
drop `t'
qui reshape wide _dum, i(`i') j(`tt')
qui recode _dum1 .=0
qui gen str Pattern=string(_dum1)
if `k'>1 {
forval ct=2/`k' {
capture recode _dum`ct' .=0
qui capture replace Pattern=Pattern+string(_dum`ct')
}
}
contract Pattern
rename _freq Frequency
qui count
if r(N)<$ps_maxpat {
global ps_maxpat=r(N)
}
di
di _dup(53) "*"
local fr "Top $ps_maxpat patterns in the data"
di "`fr'"
di _dup(53) "*"
gsort - Frequency
list Pattern Frequency in 1/$ps_maxpat, ab(10)
di
di "Note: 1 if observation is in the dataset; 0 otherwise"
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "`fr'"
qui putexcel A3=("Pattern")
qui putexcel B3=("Frequency")
forval i=1/$ps_maxpat {
local rowa=Pattern[`i']
local rowb=Frequency[`i']
local row=`i'+3
puttexttoexcel A`row' "`rowa'"
putnumtoexcel B`row' "`rowb'"
}
}
restore
end

program define module5
args i t excel
local sheet "runs"
preserve
keep `i' `t' _run
sort `i' `t'
bys `i' _run: gen N=_N
label var N "Length of run"
bys `i' _run: gen n=_n
di _dup(53) "*"
local fr "Distribution of complete runs by size"
di "`fr'"
di _dup(53) "*"
tempname col1 col2
tab N if n==1, matrow(`col1') matcell(`col2')  
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "`fr'"
puttabtoexcel 1 3 "Lenght of run" `col1' `col2' `sheet'
}
di
restore
end

program define basicdescriptives
args i t excel
xtset, clear
qui xtset `i' `t'
local tdelta=r(tdelta)
local tmax=r(tmax)
local tmin=r(tmin)
local imax=r(imax)
local imin=r(imin)
di
di _dup(53) "*"
di "Analyzing `c(filename)'"
di _dup(53) "*"
di
if "`excel'"!="" {
putexcel clear
qui putexcel set "`excel'.xlsx", sheet("Main") replace
puttexttoexcel A1 "Basic Descriptive Statistics"
puttexttoexcel A3 "filename"
puttexttoexcel B3 "`c(filename)'"
puttexttoexcel A4 "time"
puttexttoexcel B4 "`c(current_time)' - `c(current_date)' "
}
qui count
local totobs=r(N)
di _dup(53) "*"
di "There are `totobs' time x individuals observations"
if "`excel'"!="" {
puttexttoexcel A6 "time x individuals observations:"
putnumtoexcel B6 `totobs'
}
qui count if _nn==1
local ni=r(N)
di "There are `ni' unique individuals"
if "`excel'"!="" {
puttexttoexcel A7 "Number of unique individuals:"
putnumtoexcel B7 `ni'
}
di "Time values range from `tmin' to `tmax'"
local range=`tmax'-`tmin'+1
di "Maximum time range is `range'"
if "`excel'"!="" {
puttexttoexcel A8 "Minimum time value"
putnumtoexcel B8 `tmin'
puttexttoexcel A9 "Maximum time value"
putnumtoexcel B9 `tmax'
puttexttoexcel A10 "Maximum time range"
putnumtoexcel B10 `range'
}
local avgperin=`totobs'/`ni'
di "The average number of periods per individual is `avgperin'"
if "`excel'"!="" {
puttexttoexcel A11 "Average number of periods per individual"
putnumtoexcel B11 `avgperin'
}
local potmax=`ni'*(`tmax'-`tmin'+1)
local share1=100*`totobs'/`potmax'
di "The level of completeness is " %3.2f `share1' "%" "(100% is a fully balanced panel)" 
if "`excel'"!="" {
puttexttoexcel A12 "Potential maximum # of cells"
putnumtoexcel B12 `potmax'
puttexttoexcel A13 "Level of completeness"
putnumtoexcel B13 `share1'
}
qui sum _ngaps if _nn==1, meanonly
local avggapi=r(mean)
di "Average number of gaps per individual is " `avggapi'
if "`excel'"!="" {
puttexttoexcel A14 "Average number of gaps per individual"
putnumtoexcel B14 `avggapi'
}
qui sum _dift if _dift>0, meanonly
local avgapsize=r(mean)
local larggap=r(max)
di "Average gap size is " `avgapsize'
di "Largest gap is " `larggap'
di _dup(53) "*"
if "`excel'"!="" {
puttexttoexcel A15 "Average gap size is"
putnumtoexcel B15 `avgapsize'
puttexttoexcel A16 "Largest gap"
putnumtoexcel B16 `larggap'
}
*di "Average run size is "
*di "Largest run is " 
di
di _dup(53) "*"
local fr "Distribution of number of observations per individual"
local sheet "obsperind"
di "`fr'"
di _dup(53) "*"
tempname col1 col2
tab _NN if _nn==1, matrow(`col1') matcell(`col2')  
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "`fr'"
puttabtoexcel 1 3 "#obs per ind" `col1' `col2' `sheet'
}
* 
di
di _dup(53) "*"
local fr "Number of individuals per time unit"
local sheet "indpertime"
di "`fr'"
di _dup(53) "*"
tab `t', matrow(`col1') matcell(`col2')
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "`fr'"
puttabtoexcel 1 3 "#obs per time unit" `col1' `col2' `sheet'
}
di
end

program define checkthisid
args i t var
tempvar group di dj dmj allmi nvar minv maxv
qui sum `var', meanonly
local mmm=r(max)
qui gen double `nvar'=`var'
qui replace `nvar'=_n+`mmm' if `var'==.
qui group2hdfe `i' `nvar', group(`group')
drop `nvar'
bys `group' (`i'): gen byte `di'=`i'[_N]==`i'[1]
bys `group' (`var'): gen byte `dj'=`var'[_N]==`var'[1]
bys `group' (`var'): gen byte `dmj'=`var'[_N]==.
qui gen byte _check=0
label var _check "ID checking"
qui replace _check=1 if `di'==1&`dj'==1&`dmj'==0
qui replace _check=2 if `di'==1&`dj'==0&`dmj'==0
qui replace _check=3 if `di'==0&`dj'==1&`dmj'==0
qui replace _check=4 if `di'==0&`dj'==0&`dmj'==0
* Now handle missing values
bys `group' (`var'): gen `allmi'=`var'[1]==.
bys `group': egen double `minv'=min(`var')
bys `group': egen double `maxv'=max(`var')
qui replace _check=5 if `allmi'==1
qui replace _check=6 if `di'==1&`allmi'==0&`minv'==`maxv'&`dmj'==1
qui replace _check=7 if `di'==1&`minv'!=`maxv'&`dmj'==1
qui replace _check=8 if `di'==0&`dmj'==1
capture label drop _checklabel
label define _checklabel ///
1 "1 1:1 ids coincide" ///
2 "2 1:m multiple values of `var' " ///
3 "3 m:1 multiple values of id " ///
4 "4 m:m multiple values of `var' and id " ///
5 "5 1:. all values missing for `var' " ///
6 "6 1:.1 unique values of `var' with missing " ///
7 "7 1:.m multiple values of `var' with missing " ///
8 "8 m:. multiple values of id with missing " 
label values _check _checklabel
di _dup(53) "*"
di "Checking if variable `var' can be id"
di _dup(53) "*"
tab _check if _nn==1
di
end

program define checkabsval
args  i t vars
xtset, clear
qui xtset `i' `t'
tempvar chg
capture label define chglabel ///
1 "positive change" ///
2 "negative change" ///
3 "no change" ///
4 "abnormal pos chg"  ///
5 "abnormal neg chg"  ///
6 "missing"
foreach var of varlist `vars' {
capture drop `chg'
qui gen double `chg'=d.`var'
capture drop _abs_`var'
qui gen _abs_`var'=0
qui replace _abs_`var'=1 if `chg'>0&`chg'<=$ps_absv
qui replace _abs_`var'=2 if `chg'<0&`chg'>=-$ps_absv
qui replace _abs_`var'=3 if `chg'==0
qui replace _abs_`var'=4 if `chg'>$ps_absv&`chg'<.
qui replace _abs_`var'=5 if `chg'<-$ps_absv
qui replace _abs_`var'=6 if `chg'==.
label values _abs_`var' chglabel
di
di _dup(53) "*"
di "Absolute changes over time for `var' (absv set to $ps_absv)"
di _dup(53) "*"
tab _abs_`var'
di
}
end

program define checkrelval
args  i t vars
xtset, clear
qui xtset `i' `t'
tempvar chg
capture label define chglabel ///
1 "positive change" ///
2 "negative change" ///
3 "no change" ///
4 "abnormal pos chg"  ///
5 "abnormal neg chg"  ///
6 "missing"
foreach var of varlist `vars' {
capture drop `chg'
qui gen double `chg'=(200*d.`var')/(`var'+l.`var')
capture drop _rel_`var'
qui gen _rel_`var'=0
qui replace _rel_`var'=1 if `chg'>0&`chg'<=$ps_relv
qui replace _rel_`var'=2 if `chg'<0&`chg'>=-$ps_relv
qui replace _rel_`var'=3 if `chg'==0
qui replace _rel_`var'=4 if `chg'>$ps_relv&`chg'<.
qui replace _rel_`var'=5 if `chg'<-$ps_relv
qui replace _rel_`var'=6 if `chg'==.
label values _rel_`var' chglabel
di
di _dup(53) "*"
di "Relative changes over time for `var' (relv set to $ps_relv)"
di _dup(53) "*"
tab _rel_`var'
di "Note: Relative change is calculated relative to the average of x_{t} and x_{t-1}"
di
}
end

program define checkvar
args type dim var dimlab pos excel
tempvar dum1 dum2 max min
di
di "Analyzing variable `var' within `dimlab' "
qui count
local NN=r(N)
qui sum `var', meanonly
local Nvar=r(N)
local Nmin=r(min)
local Nmax=r(max)
local shV=`Nvar'/`NN'*100
di
di "There are " %5.2f `shV' "% nonmissing observations (`Nvar' out of `NN')"
di
qui count if `type'==1
local nind=r(N)
* Complete
bys `dim' (`var'): gen byte `dum1'=(`var'[1]==`var'[_N])&(`var'[_N]<.)
qui count if `dum1'==1&`type'==1
local cvar=r(N)
local shcvar=`cvar'/`nind'*100
* Variable (inconsistent observations without missing)
bys `dim' (`var'): gen byte `dum2'=(`var'[1]!=`var'[_N])&(`var'[_N]<.)
qui count if `dum2'==1&`type'==1
local vvar=r(N)
local shvvar=`vvar'/`nind'*100
qui replace `dum1'=2 if `dum2'
drop `dum2'
* All missing
bys `dim' (`var'): gen byte `dum2'=missing(`var'[1])
qui count if `dum2'==1&`type'==1
qui replace `dum1'=3 if `dum2'
local mvar=r(N)
local shmvar=`mvar'/`nind'*100
drop `dum2'
*
qui bys `dim': egen double `max'=max(`var')
qui bys `dim': egen double `min'=min(`var')
qui bys `dim' (`var'): gen byte `dum2'=(`max'==`min')&`var'[1]<.&missing(`var'[_N])
qui count if `dum2'==1&`type'==1
qui replace `dum1'=4 if `dum2'
local mcvar=r(N)
local shmcvar=`mcvar'/`nind'*100
local vmvar=`nind'-`mvar'-`cvar'-`vvar'-`mcvar'
local shvmvar=`vmvar'/`nind'*100
*
di "For the variable `var' we have:"
di "        values range from `Nmin' to `Nmax'"
di "        `cvar' complete invariant `dimlab'-observations (" %5.2f `shcvar' "%) "
di "        `vvar' complete variant `dimlab'-observations (" %5.2f `shvvar' "%) "
di "        `mvar' completely missing `dimlab'-observations (" %5.2f `shmvar' "%)"
di "        `mcvar' invariant `dimlab'-observations with missing values (" %5.2f `shmcvar' "%) "
di "        `vmvar' variant `dimlab'-observations with missing values (" %5.2f `shvmvar' "%) "
qui recode `dum1' 0=5
rename `dum1' _w_
if "`excel'"!="" {
excelcol `pos'
local col `r(column)'
puttexttoexcel `col'3 "`var'"
putnumtoexcel `col'4 `NN'
putnumtoexcel `col'5 `Nvar'
putnumtoexcel `col'6 `shV'
putnumtoexcel `col'8 `Nmin'
putnumtoexcel `col'9 `Nmax'
putnumtoexcel `col'11 `nind'
putnumtoexcel `col'12 `cvar'
putnumtoexcel `col'13 `vvar'
putnumtoexcel `col'14 `mvar'
putnumtoexcel `col'15 `mcvar'
putnumtoexcel `col'16 `vmvar'
}
end

program define tabover
args t var excel
preserve
contract `t' `var'
rename _freq n
qui reshape wide n, i(`var') j(`t')
di
di "Tabulation of `var' over time"
list
di
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet("tab_`var'") modify
export excel using "`excel'.xlsx", sheet("tab_`var'") firstrow(variables)
}
restore
end

program define calcflow
args i t var excel
preserve
local sheet "fl_`var'"
keep `i' `t' `var'
qui bys `i' (`t'): gen inc1=(`t'-`t'[_n-1]==1)
gen c_inc=0
qui replace c_inc=`var'-`var'[_n-1] if inc1
gen c_exp=0
qui replace c_exp=`var'-`var'[_n-1] if inc1&(`var'>`var'[_n-1])
gen c_cont=0
qui replace c_cont=`var'-`var'[_n-1] if inc1&(`var'<`var'[_n-1])
gen c_inc1=0
qui replace c_inc1=`var' if inc1&missing(`var'[_n-1])
gen c_inc2=0
qui replace c_inc2=`var'[_n-1] if inc1&missing(`var')
gen c_entry=0
qui replace c_entry=`var' if inc1==0
collapse (sum) `var' c_* , by(`t')
qui gen double chg=`var'-`var'[_n-1]
qui gen double c_exit=chg-c_entry-c_inc-c_inc1+c_inc2
rename `t' period
order period `var' chg c_inc c_exp c_cont c_entry c_exit  c_inc1 c_inc2
list
di "`var' - total sum of `var' at period t"
di "chg - sum of `var' at t minus t-1"
di "c_inc - changes from individuals present at t and at t-1"
di "c_exp - positive changes (expansions) from individuals present at t and at t-1"
di "c_cont - negative changes (contractions) from individuals present at t and at t-1"
di "c_entry - change resulting from entry (present at t but not at t-1)"
di "c_exit - change resulting from exits (present at t-1 but not at t)"
di "c_inc1 - change from individuals present at t and t-1 but with missing data at t-1"
di "c_inc2 - change from individuals present at t and t-1 but with missing data at t"
di
if "`excel'"!="" {
qui {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel A1 "Flows for variable `var'"
putexcel A3=("period")
putexcel B3=("`var'")
putexcel C3=("chg")
putexcel D3=("chg_inc")
putexcel E3=("expansion")
putexcel F3=("contraction")
putexcel G3=("entry")
putexcel H3=("exit")
putexcel I3=("miss_1")
putexcel J3=("miss_2")
tempname mat
mkmat _all, mat(`mat')
qui putexcel A4=matrix(`mat'), sheet(`sheet') colwise
}
}
end

program define calctrans
args i t var
qui {
xtset `i' `t'
tempvar tl lx fx NN0 NN1 dum
gen `lx'=l.`var'
gen `tl'=l.`t'
bys `tl' `t' `var' :gen `NN0'=_N if `lx'<.&`var'<.
bys `tl' `t' `var' `lx':gen `NN1'=_N if `lx'<.&`var'<.
capture drop _trans_`var'
gen _trans_`var'=`NN1'/`NN0'*100
gen `dum'=.
replace `dum'=1 if _trans_`var'<5
replace `dum'=2 if _trans_`var'<25&_trans_`var'>=5
replace `dum'=3 if _trans_`var'<75&_trans_`var'>=25
replace `dum'=4 if _trans_`var'<95&_trans_`var'>=75
replace `dum'=5 if _trans_`var'<100&_trans_`var'>=95
replace `dum'=6 if _trans_`var'==100
label values `dum' translabel
label var `dum' "Distribution of probabilities"
}
tab `t' `dum'
end

program define cprmiscvars
args i t var1 var2
xtset `i' `t'
tempvar chg1 chg2 sd1 sd2 maxsd
bys `i': gen `chg1'=`var1'-l.`var1'
bys `i': gen `chg2'=`var2'-l.`var2'
bys `i': egen `sd1'=sd(`var1')
bys `i': egen `sd2'=sd(`var2')
egen `maxsd'=rowmax(`sd1' `sd2')
replace `maxsd'=`maxsd'*$ps_sdf
capture drop _flag_cpr
gen _flag_cpr=abs(`chg1')>max(`maxsd',$ps_low)&abs(`chg2')>max(`maxsd',$ps_low)&(`chg1'<0&`chg2'>0|`chg1'>0&`chg2'<0)&!missing(`chg1')&!missing(`chg2')&(abs(`chg2'+`chg1')<$ps_dif)
end

program define puttexttoexcel
args cell content
qui putexcel `cell'=("`content'")
end

program define putnumtoexcel
args cell content
qui putexcel `cell'=(`content')
end

program define puttabtoexcel
args c r tit1 col1 col2 sheet
tempname one temp col3 mat
excelcol `c'
local colname `r(column)'
local cell1="`colname'"+"`r'"
local cp1=`c'+1
excelcol `cp1'
local colname `r(column)'
local cell2="`colname'"+"`r'"
local cp2=`c'+2
excelcol `cp2'
local colname `r(column)'
local cell3="`colname'"+"`r'"
local nr=`r'+3
excelcol `c'
local colname `r(column)'
local cell4="`colname'"+"`nr'"
matrix `one'=J(1,rowsof(`col1'),1)
matrix `temp'=`one'*`col2'
matrix `col3'=`col2'/`temp'[1,1]
matrix `mat'=(`col1',`col2',`col3')
qui putexcel `cell1'=("`tit1'")
qui putexcel `cell2'=("Frequency")
qui putexcel `cell3'=("Percent")
qui putexcel `cell4'=matrix(`mat'), sheet(`sheet') colwise
end

program define puttab2toexcel
args c r tit1 tit2 mat1 mat2 mat3 sheet
tempname one temp col3 mat
local cp1=`c'+1
local p=`r'+1
excelcol `c'
local colname `r(column)'
local cell1="`colname'"+"`p'"
local p=`r'+3
local cell4="`colname'"+"`p'"
local p=`r'
excelcol `cp1'
local colname `r(column)'
local cell2="`colname'"+"`p'"
local p=`r'+2
local cell3="`colname'"+"`p'"
local p=`r'+3
local cell5="`colname'"+"`p'"
************
qui putexcel `cell1'=("`tit1'")
qui putexcel `cell2'=("`tit2'")
qui putexcel `cell3'=matrix(`mat1'), sheet(`sheet')
qui putexcel `cell4'=matrix(`mat2'), sheet(`sheet') colwise
qui putexcel `cell5'=matrix(`mat3'), sheet(`sheet')
end


* Equivalent to egen group function but faster
program define gengroup
args v1 v2
local vtype: type `v1'
sort `v1'
gen long `v2'=.
if substr("`vtype'",1,3)=="str" {

replace `v2'=1 in 1 if trim(`v1')!="" 
replace `v2'=`v2'[_n-1]+(trim(`v1')!=trim(`v1'[_n-1])) if (trim(`v1')!=""&_n>1)
}
else {
replace `v2'=1 in 1 if `v1'<. 
replace `v2'=`v2'[_n-1]+(`v1'!=`v1'[_n-1]) if (`v1'<.&_n>1)
}
end

