*==============================================================================*
*! TASK: Clean raw data file, run fuzzy matching script and merge teacher modules.
*==============================================================================*

*-------------------------------------------------------------------------------
* Setup for this task
*-------------------------------------------------------------------------------
clear all

*set the paths
gl data_dir ${clone}/01_GEPD_raw_data/
gl processed_dir ${clone}/03_GEPD_processed_data/


*save some useful locals
local preamble_info_individual school_code 
local preamble_info_school school_code 
local not school_code
local not1 interview__id


*-------------------------------------------------------------------------------
* Subroutines for this task
*-------------------------------------------------------------------------------
* Clean and run fuzzy matching script
do "${clone}/02_programs/School/Merge_Teacher_Modules/1_clean_raw_data.do"

* Merge teacher roster module, questionnaire, assessment and classroom observation module
do "${clone}/02_programs/School/Merge_Teacher_Modules/3_merge_teacher_modules.do"

*-----------------------------------------------------------------------------
