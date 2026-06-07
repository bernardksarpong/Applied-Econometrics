********************SECTION 1: PARTIAL (Authors') IDENTIFICATION OF MACROECONOMIC CRISIS**********************
*Crisis episodes for most countries were collected from the appendix of Barro and Ursúa (2008). For countries not covered in their dataset, their crises were identified using the same definition—a cumulative and consecutive decline in real GDP per capita of at least 10 percent—from the Maddison Project Database (2023). We merged the two crisis data to arrive at the final crisis dataset for our analysis.

***Load Maddison Project Database
use "/Users/bernardsarpong/Desktop/Protest_Data_New/maddison2023_web.dta"

*Initial Cleaning of database
rename gdppc gdp
label variable gdp "real GDP per capita"
rename country country_name
drop countrycode pop region
drop if year<1900

*renaming countries
*-------------------------------------------*
replace country_name="Bolivia" if country_name=="Bolivia (Plurinational State of)"
replace country_name="Bosnia Herzegovina" if country_name=="Bosnia and Herzegovina"
replace country_name="Iran" if country_name=="Iran (Islamic Republic of)"
replace country_name="Moldova" if country_name=="Republic of Moldova"
replace country_name="Russia" if country_name=="Russian Federation"
replace country_name="South Korea" if country_name=="Republic of Korea"
replace country_name="Venezuela" if country_name=="Venezuela (Bolivarian Republic of)"
replace country_name="Vietnam" if country_name=="Viet Nam"
replace country_name="Taiwan" if country_name=="Taiwan, Province of China"
replace country_name="North Macedonia" if country_name=="TFYR of Macedonia"
replace country_name="Palestine" if country_name=="State of Palestine"
replace country_name="Tanzania"	if country_name=="U.R. of Tanzania: Mainland"
replace country_name="Hong Kong" if country_name=="China, Hong Kong SAR"

*-------------------------------------------*
* STEP 1: Sort and initialise
*-------------------------------------------*
sort country_name year
gen base_gdp = gdp
gen cum_decline = .
gen crisis_flag = .
gen crisis_start = .
gen crisis_end = .
gen crisis_duration = .

*-------------------------------------------*
* STEP 2: Define base_gdp behaviour
*-------------------------------------------*
* Base GDP should reset when GDP rises (i.e., growth after a fall)
by country_name (year): replace base_gdp = gdp if _n == 1
by country_name (year): replace base_gdp = base_gdp[_n-1] if _n > 1 & gdp <= gdp[_n-1]
by country_name (year): replace base_gdp = gdp if _n > 1 & gdp > gdp[_n-1]

*-------------------------------------------*
* STEP 3: Compute cumulative fractional change (now decline)
*-------------------------------------------*
by country_name (year): replace cum_decline = (gdp / base_gdp) - 1

*-------------------------------------------*
* STEP 4: Assign a spell ID that resets whenever GDP rises
*-------------------------------------------*
by country_name (year): gen reset = gdp > gdp[_n-1]
by country_name: gen spell = sum(reset)
drop reset

*-------------------------------------------*
* STEP 5: Within each spell, identify maximum cumulative decline
*-------------------------------------------*
sort country_name spell year
bysort country_name spell (year): egen decline_size = min(cum_decline)

*-------------------------------------------*
* STEP 6: Flag crisis spells where cumulative decline reaches at least 10%
*-------------------------------------------*
by country_name spell: replace crisis_flag = 1 if decline_size <= -0.10

*-------------------------------------------*
* STEP 7: Record start, end, and duration for crisis spells
*-------------------------------------------*
by country_name spell (year): replace crisis_start = year[1] if crisis_flag == 1
by country_name spell (year): replace crisis_end   = year[_N] if crisis_flag == 1
by country_name spell (year): replace crisis_duration = crisis_end - crisis_start + 1 if crisis_flag == 1

*-------------------------------------------*
* STEP 8: Keep only the last observation of each crisis spell
*-------------------------------------------*
by country_name spell (year): keep if _n == _N & crisis_flag == 1

*-------------------------------------------*
* STEP 9: Clean up output
*-------------------------------------------*
keep country_name year gdp crisis_start crisis_end crisis_duration decline_size

*-------------------------------------------*
* STEP 10: cleaning up: drop missing observations
*-------------------------------------------*
drop if decline_size == .

save "/Users/bernardsarpong/Desktop/Protest_Data_New/crisisnew_data.dta", replace //To be kept for reference purpose only: not for submission

gen source = "Authors'" //noting that this is crisis identified by the authors.

keep country_name crisis_end

save "/Users/bernardsarpong/Desktop/Protest_Data_New/maddisonclean_data.dta", replace

*Load summary crisis dataset collected from "Barro_Ursua"
use "/Users/bernardsarpong/Desktop/Protest_Data_New/crises_years.dta", clear

gen source = "Barro_Ursua"

*append Authors' identified crises and removing duplicates*

append using "/Users/bernardsarpong/Desktop/Protest_Data_New/maddisonclean_data.dta"

* Assign numeric priority: 1 = Barro_Ursua, 2 = Authors'
gen priority = cond(source == "Barro_Ursua", 1, 2)

* Sort so Barro_Ursua comes first within each country-year
sort country_name crisis_end priority

* Keep only the first observation (i.e. Barro_Ursua if it exists)
bysort country_name crisis_end: keep if _n == 1

*Ensuring addition is only countries not covered the in Barro_Ursua Dataset.
*drop all "country_name" with priority condition "2" IF that "country_name" has priority condition "1"
 		*Create a flag for countries that have Barro_Ursua (priority == 1)
bysort country_name: egen has_Barro = max(priority == 1)

		*Drop records with priority == 2 if that country also has priority == 1
drop if has_Barro == 1 & priority == 2

		*Clean up helper variable
drop has_Barro priority source

save "/Users/bernardsarpong/Desktop/Protest_Data_New/crisis_final_data.dta", replace

*********************************SECTION 2: DATA CLEANING-World Values Survey(WVS) and European Values Survey (EVS)**********************
*Load WVS dataset*
use "/Users/bernardsarpong/Desktop/Protest_Data_New/WVS.dta", clear

******************************merge EVS and WVS data****************************
append using "/Users/bernardsarpong/Desktop/Protest_Data_New/EVS.dta"

***************************Data cleaning//Keep only these variables data********************************
keep S001 S003 S007_01 S020 A008 A170 A173 E023 E025 E026 E027 E028 E029 E035 E036 E037 E039 E040 X001 X002 X003 X003R X003R2 X023 X025 X025R X028 X045 X047CS A004 E111_01 E069_11 E069_12 

**************recoding Northern Ireland as United Kingdom and Cyprus==197 as Cyprus==196 ***********************
replace S003 = 826 if S003 == 909
replace S003 = 196 if S003 == 197

********************************Renaming the relevant variables for ease of analysis****************************************************
rename E023 Political_Enthusiast1
rename E025 Petition1
rename E026 Boycott1
rename E027 Protest1 
rename E028 Strike1 
rename E029 Occupation1
rename S020 Survey_year
rename X002 birth_year
rename X025R Education
rename S003 country
rename S007_01 Indvl_ID
rename X023 Edu_age
replace Edu_age =. if Edu_age ==-1
replace Edu_age =. if Edu_age ==-2
replace Edu_age =. if Edu_age ==-3
replace Edu_age =. if Edu_age ==-4
replace Edu_age =. if Edu_age ==-5

***********dropping observations without birth years*********************************************
drop if birth_year== -1
drop if birth_year== -2
drop if birth_year== -3
drop if birth_year== -4
drop if birth_year== -5

***********generate and drop observations without sex*********************************************
gen sex =. 
replace sex =0 if X001==1
replace sex =1 if X001==2

drop if sex == -1
drop if sex == -2
drop if sex == -3
drop if sex == -4
drop if sex == -5

label variable sex "1 if Female"

//Generate birth cohort-country group (Identifier)//
egen cohort_country = group(birth_year country)

*recoding the outcome variable* (Tendency to Protest (have done and might do)==1, Would Never Protest==0)
gen Protest =. 
replace Protest =1 if Protest1==1
replace Protest =1 if Protest1==2
replace Protest =0 if Protest1==3

***recoding variables for other political outcomes************

gen Political_Enthusiast =. 
replace Political_Enthusiast =1 if Political_Enthusiast1==1
replace Political_Enthusiast =1 if Political_Enthusiast1==2
replace Political_Enthusiast =0 if Political_Enthusiast1==3
replace Political_Enthusiast =0 if Political_Enthusiast1==4

gen Petition =.
replace Petition =1 if Petition1==1
replace Petition =1 if Petition1==2
replace Petition =0 if Petition1==3

gen Boycott =.
replace Boycott =1 if Boycott1==1
replace Boycott =1 if Boycott1==2
replace Boycott =0 if Boycott1==3

gen Strike =.
replace Strike =1 if Strike1==1
replace Strike =1 if Strike1==2
replace Strike =0 if Strike1==3

gen Occupation =.
replace Occupation =1 if Occupation1==1
replace Occupation =1 if Occupation1==2
replace Occupation =0 if Occupation1==3

gen Employed=.
replace Employed=0 if X028==4
replace Employed=0 if X028==7 
replace Employed=1 if Employed==.

replace Education =. if Education == -1
replace Education =. if Education == -2
replace Education =. if Education == -3
replace Education =. if Education == -4
replace Education =. if Education == -5

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", replace

****************************************SECTION 3: CONSTRUCTION OF TREATMENT INDICATOR*********************

*Assigning voting ages to all Individual IDs

********** Import and save "Suffrage_Full" dataset in dta. format********** 
import excel "/Users/bernardsarpong/Desktop/Protest_Data_New/Suffrage_Full.xlsx", sheet("Suffrage_Full") firstrow clear
save "/Users/bernardsarpong/Desktop/Protest_Data_New/Suffrage_Full.dta" //saving option

*Load master dataset
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear

* Step 1: Join with the suffrage dataset using country and sex
joinby country sex using "/Users/bernardsarpong/Desktop/Protest_Data_New/Suffrage_Full.dta", unmatched(master)

* Step 2: Generate "yearofeligibility" by adding voting_age to year_of_birth
gen yearofeligibility = birth_year + voting_age

*After joining the two datasets, we need to remove duplicates because all country-by-sex voting ages are matched into each Indvl_ID.
*To do this, we create a helper variable "voteyr_suffyr" to help keep only best maatch observation for each Indvl_ID
*We follow the following steps

* Step 3: Generate "voteyr_suffyr" by subtracting "suffrage_year" from "yearofeligibility"
gen voteyr_suffyr = yearofeligibility - suffrage_year

*Next, keep the smallest non-negative value of voteyr_suffyr for each Individual ID,
***If no non-negative values exist, keep the smallest negative voteyr_suffyr (i.e., closest to zero but still negative)***

*Step 4: Identify the smallest non-negative value of voteyr_suffyr for each ID
gen voteyr_suffyr_nonneg = (voteyr_suffyr >= 0)   // Indicator for non-negative values
bysort Indvl_ID (voteyr_suffyr): gen rank_nonneg = sum(voteyr_suffyr >= 0) // Sort each Indvl_ID group by voteyr_suffyr and assign rank==1 (ascending order) for smallest non-negative value
replace rank_nonneg = . if voteyr_suffyr < 0 // Remove ranks for negative values as they are assigned rank==0 in the previous step. 

*step 5: Drop Observations Not Ranked 1 Within Their Indvl_ID Group But Keep All If All Are Negatives
***First, Identify Groups That Have Only Negative Values:create an indicator to identify whether all observations for voteyr_suffryr within an Indvl_ID is negative.
bysort Indvl_ID (voteyr_suffyr): gen all_neg = (voteyr_suffyr[_N] < 0 & voteyr_suffyr[1] < 0)

*****Now, within each Indvl_ID with all negative observations for voteyr_suffryr, assign the least negative rank of 1. 
*******To rank the least negative (closest to zero) as rank 1, you need to sort by the absolute value of voteyr_suffyr while ensuring that the condition all_neg = 1 is applied.
gen abs_voteyr_suffyr = abs(voteyr_suffyr) // generate absolute values for "voteyr_suffyr" 

bysort Indvl_ID (abs_voteyr_suffyr): gen rank_neg = cond(all_neg, _n, .) //sort by the absolute value of voteyr_suffyr while ensuring that the condition all_neg = 1 is applied

// Step 6: Keep only the desired observations
gen keep_obs = (rank_nonneg == 1) | (rank_neg == 1) // Keep smallest non-negative OR closest-to-zero negative if no non-negative exists

// Step 7: Retain only the required observations
keep if keep_obs

//verification that there's one observation per unique individual ID)
bysort Indvl_ID: gen count = _N   // Count observations per ID
tab count   // Should show only "1" for all IDs

//Step 8:Clean up
drop rank_nonneg rank_neg keep_obs voteyr_suffyr_nonneg voteyr_suffyr abs_voteyr_suffyr _merge

* Step 9: Save the final dataset
save "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", replace

****************Assigning at least 10.0% crisis years to all Indvl_IDs****************

*Load master dataset
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear //

* Step 1: Join with the crises_years using country_name and country

joinby country_name using "/Users/bernardsarpong/Desktop/Protest_Data_New/crisis_final_data.dta", unmatched(master)

* STEP 2: The crisis year to be assigned to each each Indvl_ID should be closest in absolute value to Indvl_ID's "yearofeligibility"
gen crisisend_eligible = crisis_end - yearofeligibility
gen abs_crisisend_eligible = abs(crisisend_eligible)

* STEP 3: Sort by absolute difference and assign a rank==1 for the least "abs_crisisend_eligible" within each Indvl_ID
bysort Indvl_ID (abs_crisisend_eligible): gen rank_crisis = _n

* STEP 4: Identify if there are tied crises (equal absolute difference)
bysort Indvl_ID (abs_crisisend_eligible): gen tied = abs_crisisend_eligible == abs_crisisend_eligible[_n-1] ///
    | abs_crisisend_eligible == abs_crisisend_eligible[_n+1]
bysort Indvl_ID: egen has_tied = max(tied)

* STEP 5: Within each individual, when ties exist, keep only crisis years before eligibility
gen keep_obs_2 = (rank_crisis == 1)
replace keep_obs_2 = 1 if has_tied == 1 & crisis_end < yearofeligibility & abs_crisisend_eligible == abs_crisisend_eligible[1]

* STEP 6: Keep only desired observations
keep if keep_obs_2 == 1


*Step 7:Clean up by dropping all unnecessary variables that have been generated
drop _merge

*Generate Treatment Indicator
rename crisisend_eligible Treatment_Indicator // "crisisend_eligible" is actually the treatment indicator: we just want to rename it appropriately

*Identify only individuals exposed to crisis since their birth//
gen exposed = (crisis_end >= birth_year)

*Identify cohorts in economies with no history of severe economic recession based on the definition of recession in this study// they have "crisis_end ==."
gen crises_free=1
replace crises_free=0 if crisis_end==. // cohorts from crisis-free economies coded==0 for consistency with exposed coding

***merging with Election Years and Electoral Democracy variables from some sources**
joinby country country_name using "/Users/bernardsarpong/Desktop/Protest_Data_New/Election_Years.dta", unmatched(master)

*Clean up by dropping all unnecessary variables that have been generated
drop _merge

*Step 1: drop all observations with election years less than year of eligibility
drop if Election_years < yearofeligibility

*Step 2: Create a new variable that measures the gap between year of eligibility and next election
gen election_gap = Election_years - yearofeligibility

*Step 3: For each Indvl_ID Keep the Closest Election Year
bysort Indvl_ID (election_gap): keep if _n == 1

gen No_Elections=.
replace No_Elections=1 if election_gap>1
replace No_Elections=0 if election_gap <=1

label variable No_Elections "No Elections"

*Electoral Democracy****
joinby country country_name using "/Users/bernardsarpong/Desktop/Protest_Data_New/Electoral_Democracy.dta", unmatched(master)

*Clean up by dropping all unnecessary variables that have been generated
drop _merge

*Step 1: drop all observations with regime-end less than year of eligibility
drop if Regime_end < yearofeligibility

*Step 2: For each Indvl_ID Keep the Regime_end
bysort Indvl_ID (Regime_end): keep if _n == 1

******************************************Pre_Suffrage***************************************************
*Identify cohorts/individuals who had reached voting age but were not eligible to vote due to non-existence of suffrage (Pre-Suffrage Era).
*To do this, we have to create a new variable and assign the "First-Time suffrage years" to Indvl_IDs for respective countries (because male suffrage usually precedes female suffrage)

joinby country country_name using "/Users/bernardsarpong/Desktop/Protest_Data_New/Suffrage_placebo.dta", unmatched(master)

*Clean up by dropping all unnecessary variables that have been generated
drop _merge

*now, generate an Indicator for Pre-Suffrage Era
gen Pre_Suffrage=(yearofeligibility>=male_suffrage)
*The above formula automatically assigns: 
*Pre_Suffrage==1 // did not miss initial suffrage because they attained voting after male suffrage was granted.
*Pre_Suffrage==0 // initially misssed suffrage because male suffrage was granted after they had attained voting age.

******************************************Pre_universal Adult Suffrage***************************************************
gen Adult_Suffrage=(yearofeligibility>=female_suffrage) // This is intended to capture only when countries achieved universal adult suffrage 
*Adult_Suffrage==1 // All who reached voting age during times of universal adult suffrage.
*Adult_Suffrage==0 // those who attained voting age during period of Male suffrage only.
*NB: The initial years of female_suffrage and male_suffrage have been already assigned to all Indvl_ID

******************************************Gendered Suffrage***************************************************
*Identify only Females who had reached voting age but were not eligible to vote due to non-existence of female suffrage (Gendered_Suffrage).
gen Gendered_Suffrage=1 //This first assigns 1 to all observations, 
replace Gendered_Suffrage=0 if sex==2 & yearofeligibility<female_suffrage & male_suffrage < female_suffrage // then we replace it with 0 for only females affected by Gendered_Suffrage.

************************************************SECTION 4: EMPIRICAL ESTIMATIONS**************************************

*Generating the Baseline Treatment Dummy: (Treatment==1, Control==0)

**Baseline Model*Refer to earlier codes on why IF condition is applied in the estimations 
gen Treatment1 =.
replace Treatment1 =1 if Treatment_Indicator >= 0 & Treatment_Indicator <= 4
replace Treatment1 =0 if Treatment_Indicator >= -4 & Treatment_Indicator < 0

label variable Treatment1 "Treatment"

*TABLE 1: Summary Statistics
tab Treatment1 if Protest!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1
tab Protest Treatment1 if Treatment1!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, col nofreq
tab No_Elections Treatment1 if Protest!=. & Treatment1!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, col nofreq
tab sex Treatment1 if Protest!=. & Treatment1!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, col nofreq
tab Electoral_Democracy Treatment1 if Protest!=. & Treatment1!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, col nofreq

*TABLE 2: Estimated Effect of Treatment on Protest Tendency
*Male-to-Universal Suffrage//
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Protest) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*First-line Robustness: Universal Adult_Suffrage//
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Protest) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*TABLE 3: Robustness Check for the Treatment Effect
//Robustness Model// -3 to 3
gen Treatment2 =.
replace Treatment2 =1 if Treatment_Indicator >= 0 & Treatment_Indicator <= 3
replace Treatment2 =0 if Treatment_Indicator >= -3 & Treatment_Indicator < 0

label variable Treatment2 "Treatment"

reghdfe Protest i.Treatment2 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Protest) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment2 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Protest) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", replace //save dataset up to this point.

******************************************Assigning Crisis-Type and Region***************************************

import delimited "/Users/bernardsarpong/Desktop/Protest_Data_New/crisis_type_region_mapping.csv", clear //import csv file to convert into stata before joining

save "/Users/bernardsarpong/Desktop/Protest_Data_New/crisis_type_region_mapping.dta" //saving option

*Load master dataset
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear

joinby country country_name crisis_end using "/Users/bernardsarpong/Desktop/Protest_Data_New/crisis_type_region_mapping.dta", unmatched(master)
drop _merge

************************************************Crisis_type Analysis**********************************************
*TABLE 4: Robustness Checks for the Treatment Effect: War-Related 
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & (crisis_type==2 | crisis_type==3), absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & (crisis_type==2 | crisis_type==3), absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & (crisis_type==2 | crisis_type==3), absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & (crisis_type==2 | crisis_type==3), absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*TABLE 5: Robustness Checks for the Treatment Effect: Post-Communist Dissolutions 
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & crisis_type==4, absorb(i.birth_year i.country i.Survey_year ) vce(cluster i.birth_year#i.country)
outreg2 using c2.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & crisis_type==4, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c2.xls, append nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & crisis_type==4, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c2.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & crisis_type==4, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c2.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

**TABLE 6: Robustness Checks for the Treatment Effect: Other Factors
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & crisis_type==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c3.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & crisis_type==1, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c3.xls, append nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & crisis_type==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c3.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & crisis_type==1, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c3.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

**********************************TRADITIONAL PLACEBO TESTS************************
*Placebo Test for Gendered_Suffrage==0 
*Assign male voting age that existed during this period.
joinby country country_name Gendered_Suffrage using "/Users/bernardsarpong/Desktop/Protest_Data_New/Gendered_Suffrage_Placebo.dta", unmatched(master)
drop _merge

gen Female_placebo_elig = birth_year + Placebo_Gensuff_age //placebo year of eligibility for gendered suffrage
gen Treatment_ID_Female = crisis_end - Female_placebo_elig // Treatment indicator for gendered suffrage

//before we replace these values in their appropriate variable labels we need to SUM these variable to know the extent of replacement//
sum Placebo_Gensuff_age Female_placebo_elig Treatment_ID_Female if Gendered_Suffrage==0

replace voting_age=Placebo_Gensuff_age if Gendered_Suffrage==0 //(3,434 real changes made) stata didn't need to update all 8,960 observations
replace yearofeligibility=Female_placebo_elig if Gendered_Suffrage==0
replace Treatment_Indicator=Treatment_ID_Female if Gendered_Suffrage==0

* We need to try updating the Treatment to avoid any discrepancies that may exist//
replace Treatment1=1 if Treatment_Indicator >= 0 & Treatment_Indicator <= 4 & missing(Treatment_ID_Female) & Gendered_Suffrage==0 //update for the treatment
replace Treatment1=0 if Treatment_Indicator >= -4 & Treatment_Indicator < 0 & missing(Treatment_ID_Female) & Gendered_Suffrage==0 

****TABLE 7: Results of Traditional Placebo Tests
*Placebo Test for Gendered_Suffrage*
reghdfe Protest i.Treatment1 i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==0, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Gendered Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*Placebo Test for Pre_universal Adult Suffrage*
*This group includes all cohorts (both male and female) disenfranchised at some point in time*

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & (Pre_Suffrage==0 | Gendered_Suffrage==0), absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Pre-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*************HETEROGENEITY ANALYSIS for explain mechanism underlying the evidence****

*TABLE 8: Mechanism Underpinning the Treatment Effect***************
reghdfe Protest i.Treatment1##i.No_Elections i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1##i.No_Elections i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

****TABLE 9: Split-Sample of Mechanism Underpinning the Treatment Effect
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & No_Elections==0, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Elections) label drop(i.sex i.Electoral_Democracy) addtext(Controls, YES, Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & No_Elections==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(No Elections) label drop(i.sex i.Electoral_Democracy) addtext(Controls, YES, Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & No_Elections==0, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Elections) label drop(i.sex i.Electoral_Democracy) addtext(Controls, YES, Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1 & No_Elections==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(No Elections) label drop(i.sex i.Electoral_Democracy) addtext(Controls, YES, Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)
***************************************************************************************************************************************

*Figure 1: Characterising Macroeconomic Crisis
use "/Users/bernardsarpong/Desktop/Protest_Data_New/maddison2023_web.dta", clear

*Initial Cleaning of database
drop countrycode pop region
keep if country == "Ghana" & year>=1976 & year<=1987

*Computing year-on-year growth rates
gen Growth = (gdppc / gdppc[_n-1]) - 1

drop if year==1976 // not necessary for my intended plot

gen Growth_percent = round(Growth * 100) //coverting to % and rounding up to the nearest whole number.

twoway (connected Growth_percent year, sort lcolor(blue) mlabel(Growth_percent) mlabformat(%9.1f) mlabsize(small) msymbol(diamond) mlabposition(9)), xlabel(#10, angle(45)) ylabel(, grid) title("Ghana") xtitle("Year") ytitle("Growth of Real GDP per capita (%)")

graph export "/Users/bernardsarpong/Desktop/Protest_Data_New/Graph_Crisis_Episode_Ghana.png", as(png) name("Graph")

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Macroeconomic_crisis_chart.dta", replace
***************************************************************************************************************************************

*Figure 2: Construction of the Treatment Indicator 
//This figure was created in Microsoft Powerpoint

*Figure 3: Voting Age Distribution in the Sample
******************************************************Graphing Voting Age Variation*****************************************
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear

tab voting_age if Treatment1!=. & Protest!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1

* Step 1: Work on a temporary copy of the dataset
preserve

* Step 2: Collapse data to get frequency counts
contract voting_age if Treatment1!=. & Protest!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1

* Step 3: Compute total number of observations
summarize _freq
scalar total = r(sum)

* Step 4: Generate percentage variable
gen pct = 100 * _freq / total

graph bar pct, over(voting_age) ///
    bar(1, color(navy)) ///
    ytitle("Percentage") ///
    title("Voting Age Distribution")
	
save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/Voting_age_distribution.dta", replace

*Figure 4: Geographical Variation in Protest Tendency
****************************************Protest Tendency Map//countries_shp***********************************
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear

*Generate summary of protest data
collapse (mean) Protest if Protest!=. & Treatment1!=. & sex!=. & Electoral_Democracy!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, by(country_name)

replace Protest = round(Protest, 0.01)

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/spmap/protest_summary_11.10.25.dta", replace

*Download country dfb or shp files and give them identical prefix: in this case "country"
*change stata working directory to the location of the country.dfb and country.shp

*We need to generate a combined dta file for the world map: 
spshape2dta country

*Now load the combined dta file.
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/spmap/country.dta", clear 

*Rename country names to match appropriately but first rename the country identifier in the shape file.

rename Country country_name
*-------------------------------------------*
replace country_name="Bosnia Herzegovina" if country_name=="Bosnia and Herzegovina"
replace country_name="North Macedonia" if country_name=="Macedonia"
replace country_name="Macau" if country_name=="Macau (China)"
replace country_name="Hong Kong" if country_name=="Hong Kong (China)"
replace country_name="Trinidad and Tobago" if country_name=="Trinidad & Tobago"

*merge the combined dta file "summary of protest data" that we want to create the map for
merge 1:1 country_name using "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/spmap/protest_summary_11.10.25.dta"

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/spmap/World_Map_11.10.25.dta", replace //Final dataset for spmap

drop if _ID==. //otherwise when you use "grmap" command, the chloropleth will not be plotted.

spmap Protest using country_shp, id(_ID) fcolor(Blues) title("Geographical Variation in Protest Tendency", size(3.5)) note("Source: Authors' illustration based on the merged EVS/WVS 1981-2022 dataset.", size(2.5)) legstyle(2) legend(pos(7) size(2.8) region(fcolor(gs15))) osize(0.05 ..)

graph export "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/spmap/Geographical_Variation.png", as(png) name("Graph")

*Figure 5: Time Variation in Protest Tendency
*****************************************************Protest Tendency Line_Graphs****************************************
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", clear

* Step 1: regional means
preserve
collapse (mean) Protest if Protest!=. & Treatment1!=. & sex!=. & Electoral_Democracy!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, by(region_name Survey_year)
gen level = "Regional"
save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/Regional_11.10.25.dta", replace

* Step 2: global mean
use "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_01.10.25.dta", clear

collapse (mean) Protest if Protest!=. & Treatment1!=. & sex!=. & Electoral_Democracy!=. & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, by(Survey_year)
gen level = "Global"
gen region_name = "Global"
save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/Global_11.10.25.dta", replace

* Step 3: combine
append using  "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/Regional_11.10.25.dta"

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/LineGraph_Data_11.10.25.dta", replace //Final Dataset for Publication//

* Step 4: Time Variation Line Graphs

*Now we want the global plot to show first so; we create a numeric region order variable: This converts the string variable region_name into a numeric variable region_code, automatically assigning numeric codes (alphabetically).

encode region_name, gen(region_code)

*Now, manually assign custom numeric order so "Global" comes first: I'm choosing 7-12 for convenience because the encoding generated region_codes 1-6

replace region_code = 7 if region_name == "Global"
replace region_code = 8 if region_name == "Asia and Oceania"
replace region_code = 9 if region_name == "Europe"
replace region_code = 10 if region_name == "Middle East and North Africa"
replace region_code = 11 if region_name == "Sub-Saharan Africa"
replace region_code = 12 if region_name == "The Americas"

*Let's label define the values
label define region_lbl 7 "Global" 8 "Asia and Oceania" 9 "Europe" 10 "Middle East and North Africa" 11 "Sub-Saharan Africa" 12 "The Americas"
label values region_code region_lbl

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/LineGraph_Data_11.10.25.dta", replace //Final Dataset for Publication//

*PLOT	
twoway (line Protest Survey_year), ///
    by(region_code, title("Time Variation in Protest Tendency") ///
                    note("") caption("") col(3) ///
                    graphregion(color(white))) ///
    xlabel(#10, angle(45)) ///
    ylabel(, grid) ///
    xtitle("Year") ///
    ytitle("Mean Protest Tendency")
	
graph export "/Users/bernardsarpong/Desktop/Protest_Data_New/Maps/Graph_Time Variation.png", as(png) name("Graph")

******************************************APPENDIX***************************
*Table A1: Estimated Effects Under Stricter Treatment Range: -2 to 2
gen Treatment3 =.
replace Treatment3 =1 if Treatment_Indicator >= 0 & Treatment_Indicator <= 2
replace Treatment3 =0 if Treatment_Indicator >= -2 & Treatment_Indicator < 0

label variable Treatment3 "Treatment"

reghdfe Protest i.Treatment3 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c8.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment3 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c8.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*Table A2: Estimated Effects Under Stricter Treatment Range: -1 to 1
gen Treatment4 =.
replace Treatment4 =1 if Treatment_Indicator >= 0 & Treatment_Indicator <= 1
replace Treatment4 =0 if Treatment_Indicator >= -1 & Treatment_Indicator < 0

label variable Treatment4 "Treatment"

reghdfe Protest i.Treatment4 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c9.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment4 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c9.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*Table A3: Estimated Effects Under Stricter Treatment Range: -1 to 0
gen Treatment5 =.
replace Treatment5 =1 if Treatment_Indicator == 0
replace Treatment5 =0 if Treatment_Indicator == -1

label variable Treatment5 "Treatment"

reghdfe Protest i.Treatment5 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c10.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment5 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c10.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*Table A4: Outcome Variable Decomposition Analysis *******
*recoding the outcome variable*  (Might do ==1, Would Never Protest==0)
gen Protest2 =. 
replace Protest2 =1 if Protest1==2
replace Protest2 =0 if Protest1==3

reghdfe Protest2 i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest2 i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

*recoding the outcome variable*  (Have done ==1, Would Never Protest==0)
gen Protest3 =. 
replace Protest3 =1 if Protest1==1
replace Protest3 =0 if Protest1==3

reghdfe Protest3 i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest3 i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

**Table A5: Alternative Specification of Baseline Model
*Controlling for cohort by region fixed effects*
reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(Male-to-Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Adult_Suffrage==1, absorb(i.birth_year i.country i.Survey_year i.birth_year#i.region_code) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(Universal Suffrage) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

************************************************************************FALSIFICATION TESTS**************************************************
*Assigning placebo crises to countries with no history of crises (we assigned regional or global economic crises)
joinby country country_name crises_free using "/Users/bernardsarpong/Desktop/Protest_Data_New/crises_free_placebo.dta", update unmatched(master)
drop _merge

* Step 2: The crisis year to be assigned to each each Indvl_ID should be closest in absolute value Indvl_ID's "yearofeligibility"

replace Treatment_Indicator = crisis_end - yearofeligibility if crises_free==0 & missing(Treatment_Indicator)

replace abs_crisisend_eligible = abs(Treatment_Indicator) if crises_free==0 & missing(abs_crisisend_eligible)

* Step 3: Sort and keep rank==1 for the least "abs_crisisend_eligible" within each Indvl_ID for these crises free economies.
bysort Indvl_ID (abs_crisisend_eligible): keep if _n == 1

****update the missing Treatment values// -4 to 4
replace Treatment1 =1 if crises_free==0 & missing(Treatment1) & Treatment_Indicator >= 0 & Treatment_Indicator <= 4
replace Treatment1 =0 if crises_free==0 & missing(Treatment1) & Treatment_Indicator >= -4 & Treatment_Indicator < 0

*Create a separate dummy variable for ease of exporting to excel with other pseudo-treatments
gen No_Crisis=Treatment1 if crises_free==0

label variable No_Crisis "Pseudo-Treatment"

*For the remaining falsification tests, we create pseudo-treatment groups by shifting the threshold within the treatment range:
*A good starting point is to do quartile-based groups and shift the threshold within the quartiles. Consequently, these three possible scenarios are considered: 
	1.	Q1 vs Q2, Q3, Q4: 25th Percentile Cut-Off
	2.	Q1, Q2 vs. Q3, Q4: 50th Percentile Cut-Off 
	3. 	Q1, Q2, Q3 vs Q4: 75th Percentile Cut-Off	
	
//Placebo Test for Non-Crises Cohorts//	
*Create quartile-Based Groups of cohorts who have been unexposed to crises since birth (albeit these countries have crises history)
egen Un_Exposed = cut(Treatment_Indicator) if exposed==0 & Pre_Suffrage==1 & Gendered_Suffrage==1 & Treatment_Indicator <= -17 & Treatment_Indicator >= -87, group(4)
*Un_Exposed = 3 if  : Treatment_Indicator: -17 to -28 Q4
*Un_Exposed = 2 if  : Treatment_Indicator: -29 to -37 Q3
*Un_Exposed = 1 if  : Treatment_Indicator: -38 to -48 Q2
*Un_Exposed = 0 if  : Treatment_Indicator: -49 to -87 Q1

gen Unexposed =.
replace Unexposed =1 if Un_Exposed == 3
replace Unexposed =1 if Un_Exposed == 2
replace Unexposed =1 if Un_Exposed == 1
replace Unexposed =0 if Un_Exposed == 0

label variable Unexposed "Pseudo-Treatment"

gen Unexposed1 =.
replace Unexposed1 =1 if Un_Exposed == 3
replace Unexposed1 =1 if Un_Exposed == 2
replace Unexposed1 =0 if Un_Exposed == 1
replace Unexposed1 =0 if Un_Exposed == 0

label variable Unexposed1 "Pseudo-Treatment"

gen Unexposed2 =.
replace Unexposed2 =1 if Un_Exposed == 3
replace Unexposed2 =0 if Un_Exposed == 2 
replace Unexposed2 =0 if Un_Exposed == 1
replace Unexposed2 =0 if Un_Exposed == 0

label variable Unexposed2 "Pseudo-Treatment"

*Table A6: Pseudo-Treatment Effects for Crisis-Free and Within-Unexposed Cohorts 

reghdfe Protest i.No_Crisis i.sex i.Electoral_Democracy if exposed==1 & crises_free==0 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using q1.xls, replace nocons ctitle(Crisis-Free Countries) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Unexposed i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(25th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Unexposed1 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(50th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Unexposed2 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(75th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)
*****************************************************************************************************************
	
//Systematic Placebo Test for the Treatment Group//
*Create quartile-Based Groups of cohorts among the treatment group
egen Treatment_G = cut(Treatment_Indicator) if Treatment1==1 & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, group(4)
*Treatment_G = 3 if  : Treatment_Indicator: 3-4 Q4
*Treatment_G = 2 if  : Treatment_Indicator: 2 Q3
*Treatment_G = 1 if  : Treatment_Indicator: 1 Q2
*Treatment_G = 0 if  : Treatment_Indicator: 0 Q1

gen PTreat =.
replace PTreat =1 if Treatment_G == 3
replace PTreat =1 if Treatment_G == 2
replace PTreat =1 if Treatment_G == 1
replace PTreat =0 if Treatment_G == 0

label variable PTreat "Pseudo-Treatment"

gen PTreat1 =.
replace PTreat1 =1 if Treatment_G == 3
replace PTreat1 =1 if Treatment_G == 2
replace PTreat1 =0 if Treatment_G == 1
replace PTreat1 =0 if Treatment_G == 0

label variable PTreat1 "Pseudo-Treatment"

gen PTreat2 =.
replace PTreat2 =1 if Treatment_G == 3
replace PTreat2 =0 if Treatment_G == 2 
replace PTreat2 =0 if Treatment_G == 1
replace PTreat2 =0 if Treatment_G == 0

label variable PTreat2 "Pseudo-Treatment"

*Table A7: Pseudo-Treatment Effects for Within-Treatment Group

reghdfe Protest i.PTreat i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(25th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.PTreat1 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(50th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.PTreat2 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(75th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)


//Systematic Placebo Test for the Control group//
*Create quartile-Based Groups of cohorts among the control group
egen Control = cut(Treatment_Indicator) if Treatment1==0 & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, group(4)

*Control = 3 if  : Treatment_Indicator: -1 Q4
*Control = 2 if  : Treatment_Indicator: -2 Q3
*Control = 1 if  : Treatment_Indicator: -3 Q2
*Control = 0 if  : Treatment_Indicator: -4 Q1

gen PControl =.
replace PControl =1 if Control == 3
replace PControl =1 if Control == 2
replace PControl =1 if Control == 1
replace PControl =0 if Control == 0

label variable PControl "Pseudo-Treatment"

gen PControl1 =.
replace PControl1 =1 if Control == 3
replace PControl1 =1 if Control == 2
replace PControl1 =0 if Control == 1
replace PControl1 =0 if Control == 0

label variable PControl1 "Pseudo-Treatment"

gen PControl2 =.
replace PControl2 =1 if Control == 3
replace PControl2 =0 if Control == 2 
replace PControl2 =0 if Control == 1
replace PControl2 =0 if Control == 0

label variable PControl2 "Pseudo-Treatment"

*Table A8: Pseudo-Treatment Effects for Within-Control Group 

reghdfe Protest i.PControl i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(25th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.PControl1 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(50th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.PControl2 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(75th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)


//Placebo test for Cohorts who were very young (far from gaining voting right) by end of crises//
*Create quartile-Based Groups of young cohorts (among the control group)
egen Young_Cohorts = cut(Treatment_Indicator) if Treatment_Indicator <= -15 & Treatment_Indicator >= -24 & exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, group(4)

*Young_Cohorts = 3 if  : Treatment_Indicator: -15 to -16 Q4
*Young_Cohorts = 2 if  : Treatment_Indicator: -17 Q3
*Young_Cohorts = 1 if  : Treatment_Indicator: -18 to -19 Q2
*Young_Cohorts = 0 if  : Treatment_Indicator: -20 to -24 Q1

gen Placebo_Young =.
replace Placebo_Young =1 if Young_Cohorts == 3
replace Placebo_Young =1 if Young_Cohorts == 2
replace Placebo_Young =1 if Young_Cohorts == 1
replace Placebo_Young =0 if Young_Cohorts == 0

label variable Placebo_Young "Pseudo-Treatment"

gen Placebo_Young1 =.
replace Placebo_Young1 =1 if Young_Cohorts == 3
replace Placebo_Young1 =1 if Young_Cohorts == 2
replace Placebo_Young1 =0 if Young_Cohorts == 1
replace Placebo_Young1 =0 if Young_Cohorts == 0

label variable Placebo_Young1 "Pseudo-Treatment"

gen Placebo_Young2 =.
replace Placebo_Young2 =1 if Young_Cohorts == 3
replace Placebo_Young2 =0 if Young_Cohorts == 2 
replace Placebo_Young2 =0 if Young_Cohorts == 1
replace Placebo_Young2 =0 if Young_Cohorts == 0

label variable Placebo_Young2 "Pseudo-Treatment"

*Table A9: Pseudo-Treatment Effects for Within-Young Cohorts
reghdfe Protest i.Placebo_Young i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(25th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Placebo_Young1 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(50th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Placebo_Young2 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(75th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)


//Placebo test for older cohorts who gained suffrage several years before crises//
*Create quartile-Based Groups of older cohorts (extreme of treatment group)
egen Old_Cohort = cut(Treatment_Indicator) if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1 & Treatment_Indicator>=55, group(4)

*Old_Cohort = 3 if  : Treatment_Indicator: 68 to 99 Q4
*Old_Cohort = 2 if  : Treatment_Indicator: 61 to 67 Q3
*Old_Cohort = 1 if  : Treatment_Indicator: 57 to 60 Q2
*Old_Cohort = 0 if  : Treatment_Indicator: 55 to 56 Q1

gen Placebo_Old =.
replace Placebo_Old =1 if Old_Cohort == 3
replace Placebo_Old =1 if Old_Cohort == 2
replace Placebo_Old =1 if Old_Cohort == 1
replace Placebo_Old =0 if Old_Cohort == 0

label variable Placebo_Old "Pseudo-Treatment"

gen Placebo_Old1 =.
replace Placebo_Old1 =1 if Old_Cohort == 3
replace Placebo_Old1 =1 if Old_Cohort == 2
replace Placebo_Old1 =0 if Old_Cohort == 1
replace Placebo_Old1 =0 if Old_Cohort == 0

label variable Placebo_Old1 "Pseudo-Treatment"

gen Placebo_Old2 =.
replace Placebo_Old2 =1 if Old_Cohort == 3
replace Placebo_Old2 =0 if Old_Cohort == 2 
replace Placebo_Old2 =0 if Old_Cohort == 1
replace Placebo_Old2 =0 if Old_Cohort == 0

label variable Placebo_Old2 "Pseudo-Treatment"

*Table A10: Pseudo-Treatment Effects for Within-Older Cohorts
reghdfe Protest i.Placebo_Old i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, replace nocons ctitle(25th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Placebo_Old1 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(50th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)

reghdfe Protest i.Placebo_Old2 i.sex i.Electoral_Democracy, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using c1.xls, append nocons ctitle(75th Percentile Cut-Off) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)


**Table A11: Estimated Treatment Effect on Other Forms of Protest*********** 
reghdfe Petition i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using A11.xls, replace nocons ctitle(Petition) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)
reghdfe Boycott i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using A11.xls, append nocons ctitle(Boycott) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)
reghdfe Strike i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using A11.xls, append nocons ctitle(Strike) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)
reghdfe Occupation i.Treatment1 i.sex i.Electoral_Democracy if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, absorb(i.birth_year i.country i.Survey_year) vce(cluster i.birth_year#i.country)
outreg2 using A11.xls, append nocons ctitle(Occupation) label drop(i.sex i.Electoral_Democracy) addtext(Cohort FE, YES, Country FE, YES, Survey Year FE, YES) bdec(3) sdec(3)


******Figure A1: Regression Discontinuity Design Plot of the Treatment Effect
//RDD plots//
rdplot Protest1 Treatment_Indicator if exposed==1 & crises_free==1 & Pre_Suffrage==1 & Gendered_Suffrage==1, c(0) ///
	p(1) binselect(esmv) ///
    graph_options(title("RDD Plot: Treatment Effect on Protest") ///
    xtitle("Crisis-Time Enfranchisement") ///
    ytitle("Tendency to Protest") ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small)) ///
    legend(off) ///
    graphregion(color(white)) ///
    bgcolor(white) ///
    plotregion(margin(zero)) ///
    scheme(s1mono))
	
graph export "/Users/bernardsarpong/Desktop/Protest_Data_New/Graph_RDPlot.png", as(png) name("Graph")

save "/Users/bernardsarpong/Desktop/Protest_Data_New/Protest_Final_Dataset.dta", replace //save this final version

*****************************************************************************************THE END********************************************************************************************
