*! version 1.0 23sept2016
*---------------------------------------------------------*
* Calculates descriptive statistics for panel data
* Author: Paulo Guimaraes     
*---------------------------------------------------------*
*version 0.6 adds excel output

program define panelstat, rclass sortpreserve
syntax varlist (min=2 max=2) [if] [in], [ ///
GAPS /// Analyzes data gaps
RUNS ///
PATTERN /// /*Output needs improvement */
DEMO /// /*Demography*/
CONT /// /*Ignores gaps in the time variable*/
MAXPAT(integer 10) /// /*Maximum number of patterns in the data*/
EXCEL(string) /// /*output results to excel file*/
KEEPMaxgap(string) /// /*variable contains the largest gap size for the individual*/
KEEPNgaps(string) /// /*variable contains the number of gaps for the individual*/
]
version 13
capture drop _ord
gen long _ord=_n
preserve
tempvar touse
mark `touse' `if' `in'
qui keep if `touse'
tokenize `varlist'
keep _ord `varlist'
global ps_maxpat=`maxpat'

*******************
* Create panel vars
*******************
tempvar i t
qui gengroup `1' `i' 
if "`cont'"=="cont" {
tempvar yearst
gen `yearst'=string(`2')
encode `yearst', gen(`t')
}
else {
clonevar `t'=`2' 
}
label var `t' "Time"
******************

*****************************
* Create auxiliary variables
*****************************
tempvar mint maxt
sort `i' `t'
qui bys `i' (`t'): gen _nn=_n
qui bys `i' (`t'): gen _NN=_N

label var _NN "Observ per individual"
qui bys `i': gen _dift=`t'-`t'[_n-1]-1
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
tempfile temp1
if "`keepmaxgap'"!=""|"`keepngaps'"!="" {
if "`keepmaxgap'"!="" {
bys `i': egen int `keepmaxgap'=max(_dift)
}
if "`keepngaps'"!="" {
gen int `keepngaps'=_ngaps
}
sort _ord
save `temp1'
}

**************************
* Basic panel descriptives
**************************
basicdescriptives `i' `t' "`excel'"

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

restore
if "`keepmaxgap'"!=""|"`keepngaps'"!="" {
sort _ord
qui merge 1:1 _ord using `temp1', keepusing(`keepmaxgap' `keepngaps')
drop _ord _merge
}

end

* Need to confirm delta is 1!!!

program define module2
args i t excel
preserve
keep `i' `t' _nn _NN _dift _ngaps
local sheet "gaps"
di _dup(53) "*"
local fr "Distribution of the size of the time gaps"
di "`fr'"
di _dup(53) "*"
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
excelcol `pos'
local col `r(column)'
di _dup(53) "*"
local fr "Observations per individual vs number of time gaps"
di "`fr'"
di _dup(53) "*"
tab _NN _ngaps if _dift>0,  matcol(`mat1') matrow(`mat2') matcell(`mat3') 
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel `col'1 "`fr'"
puttab2toexcel `pos' 3 "Observ per Individual" "Number of gaps per individual" `mat1' `mat2' `mat3' `sheet'
}
di _dup(53) "*"
matrix off=colsof(`mat3')
local pos=off[1,1]+`pos'+2
excelcol `pos'
local col `r(column)'
local fr "Observations per individual vs size of time gaps"
di "`fr'"
di _dup(53) "*"
tab _NN _dift if _dift>0, matcol(`mat1') matrow(`mat2') matcell(`mat3')
if "`excel'"!="" {
qui putexcel set "`excel'.xlsx", sheet(`sheet') modify
puttexttoexcel `col'1 "`fr'"
puttab2toexcel `pos' 3 "Observ per Individual" "Size of time gaps" `mat1' `mat2' `mat3' `sheet'
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
by `i': gen inc1=(`t'-`t'[_n-1]==1)
gen entry=1-inc1
by `i': gen first=_n==1
gen reentry=ent-first
by `i': gen inc2=(`t'[_n+1]-`t'==1)
gen exit=1-inc2
by `i': gen last=_n==_N
gen tempexit=exit-last
collapse (sum) total inc1 entry first reentry inc2 exit last tempexit, by(`t')
rename `t' period
di _dup(53) "*"
local fr "Yearly changes - incumbents, entrants and exits"
di "`fr'"
di _dup(53) "*"
list 
di "time - time period"
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
putexcel F3=("reentry")
putexcel G3=("inc2")
putexcel H3=("exit")
putexcel I3=("last")
putexcel J3=("tempexit")
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
replace `v2'=1 in 1 if `v1'!="" 
replace `v2'=`v2'[_n-1]+(`v1'!=`v1'[_n-1]) if (`v1'!=""&_n>1)
}
else {
replace `v2'=1 in 1 if `v1'<. 
replace `v2'=`v2'[_n-1]+(`v1'!=`v1'[_n-1]) if (`v1'<.&_n>1)
}
end

