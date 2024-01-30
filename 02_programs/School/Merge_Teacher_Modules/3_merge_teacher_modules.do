/*******************************************************************************
Purpose: Merging all teacher modules (roster, pedagogy, asssessment, and questionnaire)

Last modified on: 1/30/2024
By: Hersheena Rajaram
    
*******************************************************************************/
* Install packages
ssc install matchit
ssc install freqindex

global date = c(current_date)
global username = c(username)

/*Our goal is to have a teacher level file that combines modules 1(roster), 
4 (questionnaire), 5 (assessment) and 7 (pedagogy/classroom observation).
The final data should be unique at the teacher_id - school_code level.
*/ 

* Enter the country we are looking at here: 
global cty PAK_Balochistan

/********************* Step 1: Start with roster data ***************************/
use "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_absence.dta", clear

* Dataset should be unique at teacher-id - interview_key
isid teachers_id interview_key
replace m2saq2=lower(m2saq2)
 
count
di "There are `r(N)' teachers in the teacher roster for `cty'"


/************************ Step 2: Merge in modules key with roster *********************/

*Import fuzzy match result, check validity and clean as much as we can
preserve

use "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_merged.dta", clear

*isid teachers_id interview_key

* Create a flag for duplicates
duplicates tag teachers_id interview_key, g(tag)
tab tag


foreach tag in 1 2 3 {
	* create a score system to see which observation is most complete
	*gen pedagogy_case`tag'_tag=`tag' if missing(m4saq1) & missing(m4saq1_number) & tag==`tag'
		foreach v in m3 m5 {
			gen `v'_case`tag'_tag=1 if missing(`v'sb_troster) & missing(`v'sb_tnumber) & tag==`tag'
		}
	egen temp_case`tag'=rowtotal(m3_case`tag'_tag m5_case`tag'_tag)
	bys m2saq2 teachers_id interview_key: egen tag_case`tag'=min(temp_case`tag')

	* drop observations with less data
	drop if (temp_case`tag'!=tag_case`tag') & tag==`tag'

	*drop extra vars
	drop temp_case`tag' m3_case`tag'_tag m5_case`tag'_tag temp_case`tag' tag_case`tag'
}


* 6 duplicates remain
/*
teachers_id	interview_key	m2saq2				m3sb_tnumber	m3sb_troster correct teachers_id
1			26-11-74-98		razia				1				sajida			24
1			26-11-74-98		razia				1				abida			22
3			48-11-76-90		miss noreen akhtar	3				habiba			20 - This one is already correctly matched
3			48-11-76-90		miss noreen akhtar	3				fatima			19 - This one is already correctly matched
4			26-11-74-98		wahida				4				fareeda			2 - This one is already correctly matched
4			26-11-74-98		wahida				4				feroza			13

*/

duplicates drop teachers_id interview_key if interview_key=="48-11-76-90" & m2saq2=="miss noreen akhtar", force
replace m3sb_tnumber=. 	if interview_key=="48-11-76-90" & m2saq2=="miss noreen akhtar"
replace m3sb_troster="" 	if interview_key=="48-11-76-90" & m2saq2=="miss noreen akhtar"

drop if interview_key=="26-11-74-98" & m2saq2=="wahida" & m3sb_troster=="fareeda"

*create a flag for those that were wrong
gen flag_mismatch=0
replace flag_mismatch=1 if interview_key=="26-11-74-98" & m2saq2=="razia" & m3sb_troster=="sajida"
replace m3sb_tnumber=24 if interview_key=="26-11-74-98" & m2saq2=="razia" & m3sb_troster=="sajida"

replace flag_mismatch=1 if interview_key=="26-11-74-98" & m2saq2=="razia" & m3sb_troster=="abida"
replace m3sb_tnumber=22 if interview_key=="26-11-74-98" & m2saq2=="razia" & m3sb_troster=="abida"

replace flag_mismatch=1 if interview_key=="26-11-74-98" & m2saq2=="wahida" & m3sb_troster=="feroza"
replace m3sb_tnumber=13 if interview_key=="26-11-74-98" & m2saq2=="wahida" & m3sb_troster=="feroza"

* Now check duplicates in each modules

/*Module 4 - Pedagogy
duplicates tag m4saq1_number m4saq1 interview_key, g(module4)
replace module4=0 if missing(m4saq1_number) & missing(m4saq1)
tab module4																		//0 dups
*/

****************************** Module 3 - Questionnaire *************************
duplicates tag m3sb_tnumber m3sb_troster interview_key, g(module3)
replace module3=0 if missing(m3sb_tnumber) & missing(m3sb_troster)
tab module3			
																				//138 dups
*Create a match score between the name in roster and the name in questionnaire
*Replace module 3 variables to missing for the obs with the least match score
gen m3_lwr=lower(m3sb_troster)
matchit m2saq2 m3_lwr
bys interview_key: egen max_matchscore=max(similscore)
foreach v in similscore max_matchscore {
    replace `v'  =round(`v' , 0.001)
	*tostring `v', replace force
}

replace m3sb_troster="" if similscore<max_matchscore & similscore!=0 & module3!=0
replace m3sb_tnumber=. if similscore<max_matchscore & similscore!=0 & module3!=0

* Drop if similscore is 0 and teacher name in module 3 and roster are not missing
drop if similscore==0 & !missing(m2saq2) & !missing(m3_lwr) & module3!=0

drop module3 similscore max_matchscore
duplicates tag m3sb_tnumber m3sb_troster interview_key, g(module3)
replace module3=0 if missing(m3sb_tnumber) & missing(m3sb_troster)
tab module3																		//6 dups

* Duplicated names but different IDs - replace m3sb_tnumber and m3sb_troster to missing
gen flag_dup_names=0
replace flag_dup_names=1 if teachers_id==m3sb_tnumber & module3!=0
replace m3sb_tnumber=. if flag_dup_names==1
replace m3sb_troster="" if flag_dup_names==1
drop flag_dup_names module3

************************* Module 5 - Assessment **********************************
duplicates tag m5sb_tnumber m5sb_troster interview_key, g(module5)
replace module5=0 if missing(m5sb_tnumber) & missing(m5sb_troster)
tab module5																		//9 dups

*Create a match score between the name in roster and the name in assessment
*Replace module 5 variables to missing for the obs with the least match score
gen m5_lwr=lower(m5sb_troster)
matchit m2saq2 m5sb_troster
bys interview_key: egen max_matchscore=max(similscore)
foreach v in similscore max_matchscore {
    replace `v'  =round(`v' , 0.001)
	*tostring `v', replace force
}

replace m5sb_troster="" if similscore<max_matchscore & similscore!=0 & module5!=0
replace m5sb_tnumber=. if similscore<max_matchscore & similscore!=0 & module5!=0


* Drop if similscore is 0 and teacher name in module 5 and roster are not missing
drop if similscore==0 & !missing(m2saq2) & !missing(m5_lwr) & module5!=0


drop module5
duplicates tag m5sb_tnumber m5sb_troster interview_key, g(module5)
replace module5=0 if missing(m5sb_tnumber) & missing(m5sb_troster)
tab module5																		//4 dups


* Duplicated names but different IDs - replace m5sb_tnumber and m5sb_troster to missing
gen flag_dup_names=0
replace flag_dup_names=1 if teachers_id==m5sb_tnumber & module5!=0
replace m5sb_tnumber=. if flag_dup_names==1
replace m5sb_troster="" if flag_dup_names==1
drop flag_dup_names module5

save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\teacher_merged_clean.dta", replace

restore

*Save flagged duplicates/mismatches
preserve 
use "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\teacher_merged_clean.dta", clear

keep if flag_mismatch==1
drop flag_mismatch teachers_id

gen m3 = m3sb_tnumber
rename m3 teachers_id
isid teachers_id interview_key

save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\teacher_merged_mismatches.dta", replace
restore

*Merge back mismatches in modules key data
preserve 

use "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\teacher_merged_clean.dta", replace

drop if flag_mismatch==1
isid teachers_id interview_key
merge 1:1 teachers_id interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\teacher_merged_mismatches.dta"
drop _merge
isid teachers_id interview_key

save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_merged_clean.dta", replace
restore

************************ MERGE ROSTER WITH MODULES KEY NOW ********************
/* Master is roster and is unique at teachers_id - interview_key level
   Using is the modules key data - not unique at teachers id and hashed_school_code
   Merge 1:m on teachers_id and hashed_school_code
*/


* Merge modules key and roster
merge 1:1 teachers_id interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_merged_clean.dta"
drop _merge
isid teachers_id interview_key

/******************** Step 2: Merge in pedagogy data ******************************/
*WE DO NOT HAVE PEDAGOGY DATA RIGHT NOW

/* Merge pedagogy data
Master is unique at teachers_id and interview_key
Using is not unique at m4saq1_number and school_code
We want to merge pedagogy on the m4saq1_number and school_code from the modules key


merge 1:m teachers_id interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_pedagogy.dta"
*/

/************************* Step 3: Merge in m3(questionnaire) data **************************/
/* Master is unique at teacher id and interview key BUT not unique at m3sbt_number and interview_key
Using is unique at m3sb_tnumber- m3sb_troster - interview key
DO a m:1 merge in m3sb_tnumber m3sb_troster interview_key
*/
merge m:1 m3sb_troster m3sb_tnumber interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_questionnaire.dta", gen(merge1)

* 604 matches out of 642
* 40 obs unmatched. Most of them are because the ID in module 3 does not match the roster.
* We will try to split teacher names into first names and then match on school_code and first name.
split m3sb_troster
split m2saq2

*save obs that were unmatched
preserve

keep if merge1==2
replace m3sb_troster1=m3sb_troster2 if m3sb_troster1=="Miss"
rename m3sb_troster1 first_name
replace first_name=lower(first_name)
isid first_name interview_key
save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\questionnaire_first_name_match.dta", replace 

restore

* Rename m2saq2 to first name
rename m2saq21 first_name

*Drop pbs to be be merged and merge it back in
drop if merge1==2 & !missing(m2saq2)
merge m:1 first_name interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\questionnaire_first_name_match.dta", ///
			update gen(merge2)

*36 more merges. Total merge = 604+36 = 640
* export names that were matched
preserve
keep if merge2==5
keep interview_key teachers_id m2saq2 m2saq21 m3sb_tnumber m3sb_troster m3sb_troster1
export excel using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\m3_matched.xlsx", sheetreplace firstrow(variables) 
restore

*export names that did not match
preserve
keep if merge2==2
keep interview_key teachers_id m2saq2 m2saq21 m3sb_tnumber m3sb_troster m3sb_troster1
export excel using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\m3_unmatched.xlsx", sheetreplace firstrow(variables) 
restore


/**************************** Step 6: Merge in m5(assessment) data ************************/

/* Master is not unique at m5sb_tnumber and interview_key
Using is unique at m5sb_tnumber and interview_key
Do a m:1 merge on m5sb_tnumber m5sb_troster interview_key
*/

drop merge*
merge m:1 m5sb_troster m5sb_tnumber interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_assessment.dta", gen(merge1)
*615 out of 635 matches

/* there are 20 observations from assessment only. A quick check shows that the 
m5sb_tnumber is missing from modules key while these teachers had m5sb_tnumber 
in assessment data.Save a temp data with observations 
with _merge==2 and merge on teachers_id - school_code instead
*/
preserve
keep if merge1==2
drop teachers_id
gen m5_id=m5sb_tnumber
rename m5_id teachers_id

isid teachers_id interview_key

save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\assessment_temp.dta", replace
restore

* merge on teachers_id and school code
drop if merge1==2
merge m:1 teachers_id interview_key using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\assessment_temp.dta", update gen(merge2)

*26 more merges. Now a total of 641 matches.
* export names that were matched
preserve
keep if merge2==5
keep interview_key teachers_id m2saq2 m5sb_tnumber m5sb_troster
export excel using "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\temp\m3_matched.xlsx", sheetreplace firstrow(variables) 
restore

* Check on duplicates
duplicates tag teachers_id interview_key, g(tag_dup_final)
tab tag_dup_final

/* There are 5 duplicated teacher id - school code combos because the same teachers
taught frade 2 and grade 4 in the same school. So we have a grade 2 obs and a grade 4 obs.
*/

* drop temp/unecessary vars 
drop tag_dup_final merge*

* label variables 
do "${clone}/02_programs/School/Merge_Teacher_Modules/zz_label_all_variables.do"


sort interview_key teachers_id

* Save final data
save "${clone}\01_GEPD_raw_data\School\Balochistan_teacher_level.dta", replace


