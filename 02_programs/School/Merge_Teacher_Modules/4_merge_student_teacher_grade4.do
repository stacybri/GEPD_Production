/*******************************************************************************
Purpose: Merging grade 4 student level data to teacher data 

Last modified on: 
By: 
    
*******************************************************************************/

clear all
set more off
macro drop _all
cap log close
program drop _all
matrix drop _all
*set trace on
*set tracedepth 1

global date = c(current_date)
global username = c(username)

** File paths
* If you have one drive installed on your local machine, use this base
*global base "C:/Users/${username}/WBG/HEDGE Files - HEDGE Documents/GEPD-Confidential/General/LEGO_Teacher_Paper"

* set up all globals
global base "C:\Users\Hersheena\OneDrive\Desktop\Professional\WBG_GEPD_2023\LEGO_Teacher_Paper"
global data "$base\3_input_data"
global temp "$base\4_temp_data"
global final "$base\5_output_data"
global code "$base\1_code\2_merging_modules"
global log "$base\2_log"

log using "$log/merge_student_teacher_${username}_${date}.log", replace 

/*Our goal is to have a student level file that combines student modules (grade 4) and teacher modules:
 modules 1(roster), 4 (questionnaire), 5 (assessment) and 7 (pedagogy/classroom observation).
The final data should be unique at the student_id - school_code level.
*/ 

*Enter the 3 letter code for the country here. E.g Tchad - TCD
global countries TCD

/******************	Tchad ***********************/
foreach cty in $countries {
    
/* Step 1: Start with roster data */
use "$data/`cty'/`cty'_fourth_grade_assessment.dta", clear

*Data should be unique at the interview key - student - school code level
cap isid student_number interview_key school_code

duplicates tag student_number interview_key school_code, g(tag)
duplicates drop student_number interview_key school_code, force

/* Every student in this data is in grade 4. They were in the same classroom as
the teacher in the classroom observation (pedagogy dataset).

To combine these two data sets, we want to merge the student level file and teacher
level file on school code.
1. Restrict teacher level file to observations that were in the pedagogy dataset.
2. Merge with student level file on school code
3. Merge with school level file on school code

*/

* 1. merge with pedagogy teacher level file.
preserve 
*keep obs in grade 4 only
use "$temp/`cty'/`cty'_teacher_pedagogy.dta", clear
keep if grade==4
isid school_code

save "$temp/`cty'/`cty'_pedagogy_grade4.dta", replace
restore

merge m:1 school_code using "$temp/`cty'/TCD_pedagogy_grade4.dta"
drop _merge

* Merge with other teacher modules
preserve 
use "$final/`cty'/`cty'_teacher_level.dta", clear
keep if in_pedagogy==1
count

* is it unique at the school code level. Every school should have only one classroom observed
cap isid school_code

save "$temp/`cty'/`cty'_in_pedagogy.dta", replace
restore

* since master and using data are both not unique at teacher id-school code, use join by
cap joinby m4saq1 m4saq1_number school_code using "$temp/`cty'/`cty'_in_pedagogy.dta", unmatched(master)
drop _merge

* 3. Merge with school level file on school code
merge m:1 school_code using "$data/`cty'/`cty'_school_modules.dta", force
cap sort school_code student_number interview_key

* create a string version of school_code
gen school_code_str=school_code
tostring school_code_str, replace

* label variables 
do "$code/zz_label_all_variables.do"

* Save final data
save "$final/`cty'/`cty'_student_teacher_school_level.dta", replace

*erase temp data
erase "$temp/`cty'/`cty'_in_pedagogy.dta"
}

log close