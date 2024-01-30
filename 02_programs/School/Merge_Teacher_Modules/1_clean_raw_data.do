/*******************************************************************************
Purpose: Cleaning all variables in raw data 

Last modified on: 1/30/2024
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

/*Our goal is to clean all variables in all modules before matching teacher names across modules */ 

* Enter the country we are looking at here: PAK_Balochistan

* Now, we start cleaning our datasets

/*********************** Step 1: Start with roster data ************************/
use "${clone}/01_GEPD_raw_data/School/TEACHERS.dta"

* Dataset should be unique at teacher-id - interview__key level
rename TEACHERS__id teachers_id
rename interview__key interview_key
isid teachers_id interview_key 													
replace m2saq2=lower(m2saq2)

* Run do file with all value labels
do "${clone}/02_programs/School/Merge_Teacher_Modules/z_value_labels.do"
 
* Sex - Recode sex variable as 1 for female and 0 for male
recode m2saq3 2=1 1=0
tab m2saq3
* label values
label define sex 0 "Male" 1 "Female", modify
label val m2saq3 sex 

* Contract status
tab m2saq5
tab m2saq5_other

* Full time status
* Recode part time to 0
recode m2saq6 2=0
label val m2saq6 fulltime

* Destring urban rural variable and recode
cap rename rural urban_rural 
*if urban_rural is string
cap replace urban_rural ="1" if urban_rural =="Rural"
cap replace urban_rural ="0" if urban_rural =="Urban"
cap destring urban_rural, replace

* if urban_rural if numeric
cap recode urban_rural 2=0
cap la val urban_rural rural

* Save file
save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_absence.dta", replace
 
 
/************************** Step 2: Clean pedagogy data ****************************/
/*use "${clone}/GEPD Production Balochistan/01_GEPD_raw_data/School/teacher_pedagogy.dta", clear
count
* Data should be unique at m4saq1_number school_code level

*Gender
if `i'==3|`i'==5 {
	di "No gender variable found"
	}
else{	
	tab m7saq10
	tab m7saq10, nol
	recode m7saq10 2=1 1=0
	la val m7saq10 sex
}
* Destring urban rural variable and recode
cap rename rural urban_rural 
*if urban_rural is string
cap replace urban_rural ="1" if urban_rural =="Rural"
cap replace urban_rural ="0" if urban_rural =="Urban"
cap destring urban_rural, replace

* if urban_rural if numeric
cap recode urban_rural 2=0
cap la val urban_rural rural

* Label variables 
cap la var m4scq4_inpt "How many pupils are in the room?" 
cap la var m4scq4n_girls "How many of them are boys?"
cap la var m4scq5_inpt "How many total pupils have the textbook for class?"
cap la var m4scq6_inpt "How many pupils have pencil/pen?" 
cap la var m4scq7_inpt "How many pupils have an exercise book?"
cap la var m4scq11_inpt "How many pupils were not sitting on desks?"
cap la var m4scq12_inpt "How many students in class as per class list?"

* Save file
save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_pedagogy.dta", replace
*/
/*************************** Step 3: m3(questionnaire) data **************************/

use "${clone}/01_GEPD_raw_data/School/questionnaire_roster.dta", clear
* Teacher name is m3sb_troster and teacher id is m3sb_tnumber
* Data should be unique at m3sb_tnumber- interview key

*isid interview__key m3sb_tnumber
duplicates tag m3sb_tnumber interview__key, g(tag)
tab tag
br if tag ==1
sort m3sb_tnumber interview__key
drop tag
* There are duplicates here

*Rename interview__key
rename interview__key interview_key


*Age - there are some outliers here - this removes one obs of 0 and 4 obs that was above 300
sum m3saq6,d	
winsor m3saq6, g(m3saq6_w) p(0.006)
drop m3saq6
rename m3saq6_w m3saq6
	
* Destring urban rural variable and recode
cap rename rural urban_rural 
*if urban_rural is string
cap replace urban_rural ="1" if urban_rural =="Rural"
cap replace urban_rural ="0" if urban_rural =="Urban"
cap destring urban_rural, replace

* if urban_rural if numeric
cap recode urban_rural 2=0
cap la val urban_rural rural

* Save file
save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_questionnaire.dta", replace

/************************ Step 4: Merge in m5(assessment) data *************************/
use "${clone}/01_GEPD_raw_data/School/teacher_assessment_answers.dta", clear

* Data should be unique at m5sb_tnumber - interview key

* Rename m5sb_tnumber
rename m5sb_tnum m5sb_tnumber

*Rename interview__key
rename interview__key interview_key

* Destring urban rural variable and recode
cap rename rural urban_rural 
*if urban_rural is string
cap replace urban_rural ="1" if urban_rural =="Rural"
cap replace urban_rural ="0" if urban_rural =="Urban"
cap destring urban_rural, replace

* if urban_rural if numeric
cap recode urban_rural 2=0
cap la val urban_rural rural

* Save file
save "${clone}\01_GEPD_raw_data\School\Cleaned_teacher_modules\teacher_assessment.dta", replace

/************* Run python script for fuzzy matching ****************************/
python script "${clone}/02_programs/School/Merge_Teacher_Modules/2_teacher_name_matching.py"
disp "End of teacher name matching"


