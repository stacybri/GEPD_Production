
*Anonymize GEPD data files for school, teachers, students
*Written by Mohammed El-desouky, and Last updated on December 12, 2023.

/*--------------------------------------------------------------------------------
*Note to users: Running multiple commands in this file requires manual verification 
and inspection, this as some of the anonymization procedures are dependant on the
distribution of the data particular to each country, and cutoffs and intervals must
be adjusted accordingly-- more explanations are given throughout this Do-file.
-------------------------------------------------------------------------------*/

clear all

*set the paths
gl data_dir ${clone}/03_GEPD_processed_data/
gl processed_dir ${clone}/03_GEPD_processed_data/

*Set working directory on your computer here
gl wrk_dir "${processed_dir}//School//Confidential//Cleaned//"
gl save_dir "${processed_dir}//School//Anonymized//"


********************************************************************************
* ************* 1- School data *********
********************************************************************************

use "${wrk_dir}/school.dta" 

*Checking IDs:
tab school_code, m				//Typically all schools should have an ID

isid school_code 
								//Typically obs should be identical 

*------------------------------------------------------------------------------*								
*Addressing the districts:
*----------------------------------------
*--- District name
tab school_district_preload, m	//Typically no missings

egen district_code = group(school_district_preload)
								//Generates IDs for each district name
								
bysort school_district_preload: gen ref_id = 1 if _n == 1
								//Needed for the following step-- extracting into a seperate file

{								//Run the follwoing as a bloc -- to extract district names and masked codes						
preserve 

drop if ref_id==.

keep school_district_preload district_code

save "${save_dir}\sensetive_masked\district_info.dta", replace

restore																							
}								

loc drop ref_id school_district_preload hashed_school_district _merge tag_dup_final flag_m5_dup_teach_id

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}


order school_code school_code_preload school_name_preload district_code school_province_preload						
								//droping the district identifing variable
								//ordering other indentifing varibales 
								
*------------------------------------------------------------------------------*
*Addressing the schools:
*---------------------------------
*--- Official school codes and school names
egen school_code_maskd = group(school_code)

isid school_code_maskd
bysort school_code: gen ref_id = 1 if _n == 1
	tab ref_id
	br school_code school_code_maskd ref_id


{								//Run the follwoing as a bloc -- to extract school codes official and masked					
preserve 

drop if ref_id==.

keep school_code school_code_maskd school_name_preload

save "${save_dir}\sensetive_masked\school_info.dta"

restore																							
}								

loc drop ref_id school_name_preload school_code school_code_preload hashed_school_code _merge

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}


order school_code_maskd

*--- dropping School geospatial data
tab school_code_maskd, m
tab m1s0q9__Longitude, m
tab m1s0q9__Latitude, m

				
sort school_code_maskd


{								//Run the follwoing as a bloc -- to extract school geo data					
preserve 

keep school_code_maskd m1s0q9__Latitude m1s0q9__Longitude

save "C:\Users\moham\Documents\GitHub\GEPD_Production\03_GEPD_processed_data\School\Anonymized\sensitive_masked\schoolgeo_info.dta", replace

restore																							
}	


drop m1s0q9__Latitude m1s0q9__Longitude

*--- School land line number and principal mobile number
br m1saq2 m1saq2b

drop m1saq2 m1saq2b

*--- School enrollement (dropping the vars as it it is already calculated in the teachers')
loc drop total_enrolled m1saq7 m1saq8
foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

*--- Total number of 5th grade enrollments 
sum m1saq8a_etri, d				//we will use the percentiles' values to recode the groups		
								//fix our starting and ending points for recoding on (10% and 90%) 
								//rounding down/up the 10% values to the closest hundredth or tenth (depending on each countries distribution)
								//rounding down/up the 90% values to the closest hundredth
								//Then we split the rest of the categories in between into equal intervals.


recode m1saq8a_etri (0/20=1 "20 and less") ///
(21/40=2 "21-40 inclu") (41/60=3 "41-60 inclu") ///
(61/80=4 "61-80 inclu")(81/100=5 "81-100 inclu") (101/max=6 "More than 100")(.=.), gen (m1saq8a_etri_c)

	tab m1saq8a_etri_c
	label var m1saq8a_etri_c "total 5th grade enrolled at school"

drop m1saq8a_etri

*------------------------------------------------------------------------------*
*Addressing school principals:
*--------------------------------------
*--- name of principals and other var names (to be dropped)
br  m1saq1_first m1saq1_last m1s0q2_name m1s0q1_name m1s0q1_name_other name1 name2 name3 name4 name5 m6_teacher_name m8_teacher_name

drop  m1saq1_first m1saq1_last m1s0q2_name m1s0q1_name m1s0q1_name_other name1 name2 name3 name4 name5 m6_teacher_name m8_teacher_name

*--- Position in school (recoding low frequency obs if needed)
tab m7saq1
tab m1saq3

tab m7saq1, nolabel
	replace m7saq1 =97 if m7saq1== 6 

drop m1saq3

*--- Position in school_other (drop var)
tab m7saq1_other
drop m7saq1_other

*--- Year started position teaching (turn dates into years, then interval recoding)
tab m7saq8

gen m7saq8_y = 2023-m7saq8		//First, we convert dates to years, by subtracting from the year of the survey
	tab m7saq8_y 
	tab m7saq8
	
sum  m7saq8_y , d				//Will use the percentiles' values to recode the low frequency groups at the end and bottom of the distribution
								//will use the values of 10% 
								//will use the values of 90% 
								//Then only recode the low frequency obs at top and the bottom

recode m7saq8_y (0/2=2 "2 years and less") (14/max=14 "more than 13 years")(.=.), gen (m7saq8_c)

	label var m7saq8_c "Which year achieved the current position in the school- N. of years"

		tab m7saq8_c

drop m7saq8_y m7saq8

*--- Age (Two steps control)-- this shall be investigated on a case by case basis (depending ot each dataset)
tab m7saq9, m

replace m7saq9 = m7saq9+1
	tab m7saq9, m
							//Introducing some noise by adding extra year to the age var

				 
sum  m7saq9 , d

							//Will use the percentiles' values to recode the groups
							//will use the values of 10% and 90%
							//Then, only recode the low frequency obs at top and the bottom
 

recode m7saq9 (23/35=35 " 35 years old and less")(57/max=57 "more than 56 years")(.=.), gen (m7saq9_c)
	tab m7saq9_c, m

	label var m7saq9_c "What is your age?"
	

drop m7saq9
							
*--- Education_other (drop var)
tab m7saq7_other
drop m7saq7_other

*--- gender (drop var)
tab m7saq10
drop m7saq10

*--- Salary variable (top/bottom recoding)
tab m7shq2_satt

sum  m7shq2_satt , d        //Will use the percentiles' values to recode the groups
							//will use the values of 10% and 90%
							//Then, only recode the low frequency obs at top and the bottom
 

recode m7shq2_satt (0/12500=801 "12500 and less") (286501/max=286501 "more than 286500")(.=.), gen (m7shq2_satt_c)
	tab m7shq2_satt_c, m
	
	label var m7shq2_satt_c "What is your net monthly salary as a public-school principal?"
	

drop m7shq2_satt

*------------------------------------------------------------------------------*
*--- dropping unnecessary vars
*--------------------------------------
loc drop hashed_school_province school_address_preload ///
m1s0q2_name m1s0q2_code m1s0q2_emis school_info_correct school_emis_preload ///
school_address_preload survey_time m7saq10 ///
enumerator_name_other enumerator_number ///
m1s0q2_code m1s0q2_emis m1s0q9_latitude m1s0q9_longitude m1s0q9_accuracy ///
m1s0q9_altitude m1s0q9_timestamp survey_time m6_class_count m1s0q1_comments ///
m7sb_troster_pknw_0 m7sb_troster_pknw_1 m7sb_troster_pknw_2 m7sb_troster_pknw_3 ///
m7sb_troster_pknw_4 m7sb_troster_pknw_5 m7sb_troster_pknw_6 m7sb_troster_pknw_7 ///
m3sb_troster_0 m3sb_troster_1 m3sb_troster_2 m3sb_troster_3 m3sb_troster_4 ///
m5sb_troster_0 m5sb_troster_1 m5sb_troster_2 m5sb_troster_3 m5sb_troster_4 ///
m2saq2* m6s1q1* m8s1q1* m1saq3_other m1saq6a_other m1saq6b_other m1sbq9_other_infr ///
m1sbq17_other_infr m1scq2_other_imon m1scq8_other_imon m7saq6_other m7sbq2_other_opmn ///
m7sbq3_other_opmn m7sbq4_other_opmn m7sbq5_other_opmn m7scq1_other_opmn ///
m7scq5_other_opmn m7sdq4_other_pman m7sdq5_other_pman m7seq1_other_pman ///
m7seq2_other_pman m7seq3_other_pman m7sgq1_other_ssld m7sgq4_other_ssup ///
m7sgq6_other_ssup m7sgq10_other_sevl m7sgq11_other_sevl m7sgq12_other_sevl ///
enumerator_name_other m1s0q1_number_other m4saq1 comments m2saq2__0 m2saq2__1 m2saq2__2 ///
m2saq2__3 m2saq2__4 m2saq2__5 m2saq2__6 m2saq2__7 m2saq2__8 m2saq2__9 m2saq2__10 m2saq2__11 ///
m2saq2__12 m2saq2__13 m2saq2__14 m2saq2__15 m2saq2__16 m2saq2__17 m2saq2__18 m2saq2__19 ///
m2saq2__20 m2saq2__21 m2saq2__22 m2saq2__23 m2saq2__24 m2saq2__25 m2saq2__26 m2saq2__27 ///
m2saq2__28 m2saq2__29 m7sb_* m3sb_t* m3sb_etri_roster__0 m5sb_* m9saq1 m10s1q1* m10_teacher_name

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

*------------------------------------------------------------------------------*
*Saving anonymized school dataset:
*-------------------------------------
save "${save_dir}\school.dta"

	clear

	
********************************************************************************
* ************* 2- Teachers data *********
********************************************************************************	

use "${wrk_dir}/teachers.dta" 

*Checking IDs:
tab teachers_id, m				//Typically all teachers should have an ID
tab school_code, m				//Typically all schools should have an ID

isid teachers_id school_code
								//Typically obs should be identical 
								
*------------------------------------------------------------------------------*
*Addressing the districts:
*--------------------------------------------
*--- District name
tab school_district_preload  
								//Since we have already extracted district data above, we don't need to generate random codes to them again
								//We will only matched the random codes generated and stored while anonymizing school data

sort school_district_preload
joinby school_district_preload using "${save_dir}\sensetive_masked\district_info.dta", unmatched(both)
								//merging district anonymous codes to the school data
								
tab _merge
								//Checking the quality of the merge -- clean and error free merge							

local drop ref_id school_district_preload _merge tag_dup_final flag_m5_dup_teach_id

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}


order hashed_school_code hashed_school_province hashed_school_district school_code school_name_preload district_code						

*------------------------------------------------------------------------------*
*Addressing the Schools:
*--------------------------------------------
*--- Official school codes and school names
br hashed_school_code school_code

sort school_code
joinby school_code using "${save_dir}\sensetive_masked\school_info.dta", unmatched(both)
								//merging school anonymous codes to the school data
								
tab _merge
								//Checking the quality of the merge -- clean and error free merge							


local drop school_code school_code_preload hashed_school_code _merge school_name_preload
foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

order hashed_school_province district_code school_code_maskd

*--- School geospatial data
drop lat lon


*--- School enrollement 
sum total_enrolled, d			//we will use the percentiles' values to recode the groups		
								//fix our starting and ending points for recoding on (10% and 90%) 
								//rounding down/up the 10% values to the closest hundredth or tenth (depending on each countries distribution)
								//rounding down/up the 90% values to the closest hundredth
								//Then we split the rest of the categories in between into equal intervals.


recode total_enrolled (0/200=1 "200 or less") (201/300=2 "201-300 inclu") ///
(301/400=3 "301-400 inclu") ///
(401/500=4 "401-500 inclu") (501/600=5 "501-600 inclu") ///
(601/700=6 "601-700 inclu") (701/800=7 "701-800 inclu") ///
(801/900=8 "801-900 inclu") (901/1000=9 "901-1000 inclu") (1001/1100=10 "1001-1100 inclu") ///
(1101/1200=11 "1101-1200 inclu") (1201/1300=12 "1201-1300 inclu") ///
(1301/max=13 "More than 1300")(.=.), gen (total_enrolled_c)

	tab total_enrolled_c
	label var total_enrolled_c "total enrolled at school"

drop total_enrolled

*------------------------------------------------------------------------------*
*Addressing teachers:
*--------------------------------------------
*--- Teacher name (to be dropped)
drop m2saq2 teacher_name_x m4saq1 teacher_name_y m5sb_troster teacher_name m3sb_troster  

*--- Position in school (recoding low frequency obs if needed)
tab m2saq4
tab m2saq4, nolabel									
	replace m2saq4 =97 if m2saq4== 6 

*--- Position in school_other (drop var)
drop m2saq4_other

*--- Contract status_other (drop var)
drop m2saq5_other

*--- Age (Two steps control)-- this shall be investigated on a case by case basis (depending on each dataset)
tab m3saq6, m				 // a lot of missings on this varibale 

replace m3saq6 = m3saq6+1
	tab m3saq6
							//Step 1- Introducing some noise by adding extra year to the age var

							//Obs above 59 are low frequency (1 and 2 obs) on each age category
							//Obs below 23 are low frequency (1 and 2 obs) on each age category
							//Step 2- Recoding their values 
sum m3saq6, d
	
recode m3saq6 (21/23=23 " 23 years old and less")(60/max=60 "more than 59 years")(.=.), gen (m3saq6_c)
	tab m3saq6_c, m

	label var m3saq6_c "What is your age?"
	
drop m3saq6

*--- Education_other (drop var)
tab m3saq4_other
drop m3saq4_other

*--- Salary delay (recoding)
tab m3seq7_tatt
sum m3seq7_tatt, d

recode m3seq7_tatt (11/max=11 "more than 10 months")(.=.), gen (m3seq7_tatt_c)

	label var m3seq7_tatt_c "How many months was your salary delayed in the last academic year"

	tab m3seq7_tatt_c

drop m3seq7_tatt

*--- Year starting teaching (turn dates into years, then interval recoding)
tab m3saq5

gen m3saq5_y = 2023-m3saq5
	tab m3saq5_y 
	tab m3saq5
	
sum m3saq5_y , d				//Will use the percentiles' values to recode the groups
								//will use the values of 10% and 90%
								//Just recode the low frequency var

recode m3saq5_y (0/2=2 "2 years or less") (22/max=22 "more than 21 years")(.=.), gen (m3saq5_c)

	label var m3saq5_c "What year did you begin teaching - N. of years"

		tab m3saq5_c

drop m3saq5_y m3saq5

*------------------------------------------------------------------------------*
*--- dropping unnecessary vars
*--------------------------------------
loc drop hashed_school_code hashed_school_province hashed_school_district ///
m1s0q2_name m1s0q2_code m1s0q2_emis school_info_correct school_emis_preload ///
school_address_preload school_code_preload school_name survey_time m7saq10 ///
m2saq8_other teacher_available_other m3s0q1_other m3saq3_other m3sbq1_other_tatt ///
m3sbq2_other_tmna m3sbq5_other_pedg m2sbq8_other_tmna m3sbq9_other_tmna ///
m3sbq10_other_tmna m3sdq5_tsup_other m3sdq12_other_tsup m3sdq17_other_ildr ///
m3sdq18_other_ildr m3sdq25_other_ildr m3seq5_other_tatt m3seq8_other_tsdp ///
unique_teach_id teacher_unique_id iden district

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

*------------------------------------------------------------------------------*
*Saving anonymized teacher dataset:
*-------------------------------------
save "${save_dir}\teachers.dta"

	clear


********************************************************************************
* ************* 3- Students g1 and g2 data *********
********************************************************************************

*------------------------------------------------------------------------------*
*For first grade students
*------------------------------------------------------------------------------*
use "${wrk_dir}/first_grade_assessment.dta" 


*Checking IDs:
tab school_code, m						//Typically all schools should have an ID
tab ecd_assessment__id, m				//Typically all students should have an ID

isid school_code ecd_assessment__id 
								//Typically obs should be identical -- ununique 

*Masking school information:								
br school_code

sort school_code
joinby school_code using "${save_dir}\sensetive_masked\school_info.dta\school_info.dta", unmatched(both)
								//merging school anonymous codes to the school data
								
tab _merge
tab _merge, nolab
	drop if _merge==2
	drop _merge	
	
							//Clean merge, all obs from master were matched

*Dropping un necessary varibales 
loc drop school_code school_name_preload m6s1q1 interview__id interview__key school

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

order school_code_maskd

* Saving anonymized g1 dataset 
save "${save_dir}\first_grade_assessment.dta"

	clear

*------------------------------------------------------------------------------*	
*For fourth grade students
*------------------------------------------------------------------------------*
use "${wrk_dir}/fourth_grade_assessment.dta" 


*Checking IDs:
tab school_code, m					//Typically all schools should have an ID
tab fourth_grade_assessment__id, m	//Typically all students should have an ID

unique school_code fourth_grade_assessment__id 
								//Typically obs should be identical -- not unique 					

*Masking school information:								
br school_code

sort school_code
joinby school_code using "${save_dir}\sensetive_masked\school_info.dta\school_info.dta", unmatched(both)
								//merging school anonymous codes to the school data
								
tab _merge
tab _merge, nolab
	drop if _merge==2
	drop _merge
								//Clean merge, all obs from master were matched

*Dropping un necessary varibales 
loc drop school_code school_name_preload _merge m8s1q1 interview__id interview__key school

foreach var of local drop{
      capture drop `var'
      di in r "return code for: `var': " _rc
}

order school_code_maskd

* Saving anonymized g4 dataset 
save "${save_dir}\fourth_grade_assessment.dta"

	clear
	
	

