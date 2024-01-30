*==============================================================================*
*! GEPD Production (GEPD) - PUBLIC VERSION
*! Project information at: https://www.educationpolicydashboard.org/
*! GEPD Team, World Bank Group [educationdashboard@worldbank.org]

*! TASK: Run all programs to clean the GEPD school data
*==============================================================================*

*-------------------------------------------------------------------------------
* Setup for this task
*-------------------------------------------------------------------------------
* Check that project profile was loaded, otherwise stops code
cap assert ${GEPD_profile_is_loaded} == 1
if _rc != 0 {
  noi disp as error "Please execute the profile_GEPD initialization do in the root of this project and try again."
  exit
}


*-------------------------------------------------------------------------------
* Subroutines for this task
*-------------------------------------------------------------------------------
* Clean and merge teacher roster module, questionnaire, assessment and classroom observation module
do "${clone}/02_programs/School/Stata/02_teacher_module_merge.do"

* Import rawdata from .dta files and merge together into four files: school, first grade, fourth grade, teachers
do "${clone}/02_programs/School/Stata/03_school_data_merge.do"

* Clean school data
do "${clone}/02_programs/School/Stata/04_school_data_cleaner.do"

* Anonymize school data
*do "${clone}/02_programs/School/Stata/04_school_data_anonymizer.do"

*-----------------------------------------------------------------------------
