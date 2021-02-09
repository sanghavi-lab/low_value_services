# Description of all code files

These notes briefly highlight the purposes of the code files that are in the tables in each section. All code files listed below are shareable per our Data Use Agreement (DUA) with the Centers for Medicare and Medicaid Services (CMS) and will be posted publicly on our GitLab page. README file is also available in docx.

**Software**

We used SAS 9.4, Stata/MP 15.0, and R Version 3.5.1 for this analysis.

**C1. Identifying Low-Value Services**

All programs were made to be run on the 2006-2014 Medicare data, formatted like the data housed at the National Bureau of Economic Research (NBER). These programs search for low-value services occurring between 2007 and 2014. Note that searching for low-value services in a given year (the &quot;index&quot; year) also requires using data in a &quot;lookback&quot; year, the prior year. We first created Medicare file extracts containing variables needed for low-value service screening, then searched for low-value services, created beneficiary-level covariates for analysis, and combined outputs to create a beneficiary-year-level dataset with beneficiaries&#39; low-value services and covariates. For each measure and each year, the program produced two sets of low-value services. One set has low-value services identified using a &quot;specific&quot; detection criteria and the other has low-value services identified using a &quot;sensitive&quot; detection criteria.

**Table S11. Files related with identifying low-value services**

| Program name | Input files (File source) | Output files |
| - | - | - |
| Mcarextracts.sas | Beneficiary summary files for the index year and prior year <br>Carrier (line and claim), outpatient (line and claim), and MedPAR claims files for the index year and prior year <br>BETOS to HCPCS crosswalk for the index year and prior year | ourbenes'year'_20.sas7bdat<br>car'year'_20.sas7bdat<br>otpt'year'_20.sas7bdat<br>medpar'year'_20.sas7bdat
|flags.sas|car'year'_20.sas7bdat<br>otpt'year'_20.sas7bdat<br>medpar'year'_20.sas7bdat|fl_'measure_number'_'year'_'sensitivity_level'.sas7bdat|
|covars.sas|ourbenes'year’_20.sas7bdat<br>car'year’_20.sas7bdat<br>otpt'year’_20.sas7bdat<br>medpar'year’_20.sas7bdat|ourbenescovars.sas7bdat|
| flags2.sas | fl_‘measure_number’_'year’_'sensitivity_level'.sas7bdat<br>ourbenescovars.sas7bdat | yranalysis_20.sas7bdat|

Note: 'Year&#39; ranges from 2007-2014. &#39;Measure_number&#39; ranges from 1-31. `Sensitivity\_level&#39; takes on values of &quot;sensitive&quot; and &quot;specific&quot;.

**C2. Identify Primary Care Providers**

We identified for each beneficiary his/her primary care provider as the provider (NPI) with whom the beneficiary had the most allowed charges on primary care claims within each year. To be conservative with our analysis, we constructed our sample based on low-value services identified using the &quot;specific&quot; detection criteria. We limited our sample by only including NPIs with at least 11 patients in years 2007-2014, as per our DUA with CMS.

**Table S12. Files related with identifying primary care providers**

| Program name | Input files (File source) | Output files |
| --- | --- | --- |
| AssignNPI.sas|Carrier (line and claim) files|claims\_npi\_20.sas7bdat |
|MergeNPI.sas | claims\_npi\_20.sas7bdat<br>yranalysis\_20.sas7bdat | bene\_pcp\_final.sas7bdat |

**C3. Apply Further Denominator Exclusions**

We applied finer exclusion criteria to the low-value service denominators following the denominator definitions in Table 1 of the manuscript. From the carrier, outpatient, and MedPAR claims we identified relevant claims for patients who should be excluded from each denominator for head imaging, back imaging, PAP test, PTH test, and spinal injection. We also used chronic condition flags to exclude patients with history of prostate cancer from PSA test, stroke or transient ischemic attack (TIA) from carotid artery screening.

**Table S13. Files related with applying further denominator exclusions**

| Program name | Input files (File source) | Output files |
| --- | --- | --- |
|Denomexclusion.sas|car`year’_20.sas7bdat<br>otpt'year’_20.sas7bdat<br>medpar'year’_20.sas7bdat<br>bsfcc'year’.sas7bdat|excervcar_'year’.sas7bdat<br>excncrpthcar_'year’.sas7bdat<br>expthcar_'year’.sas7bdat<br>exrhinoctcar_'year’.sas7bdat<br>exbackscancar_'year’.sas7bdat<br>excervotpt_'year’.sas7bdat<br>excncrpthotpt_'year’.sas7bdat<br>expthotpt_'year’.sas7bdat<br>exrhinoctotpt_'year’.sas7bdat<br>exbackscanotpt_'year’.sas7bdat<br>exrhcathmedpar_'year’.sas7bdat<br>cerv_ex.sas7bdat<br>hica.sas7bdat<br>stroke.sas7bdat<br>|
|Denomexclusionflag.sas|car'year’_20.sas7bdat<br>otpt'year’_20.sas7bdat|backscan_ex.sas7bdat<br>head_ex.sas7bdat<br>spinj_ex.sas7bdat|
|Denommerge.sas | bene_pcp_final.sas7bdat<br>cerv_ex.sas7bdat<br>hica.sas7bdat<br>stroke.sas7bdat<br>backscan_ex.sas7bdat<br>head_ex.sas7bdat<br>spinj_ex.sas7bdat|bene_pcp_final_ex.sas7bdat|

Note: 'Year&#39; ranges from 2007-2014.

**C4. Create Sample Summary Statistics and Add Additional Covariates**

We calculated rates of low-value service utilization as a percentage of qualifying patients who received the service and identified the top eight low-value services with the highest utilization rates. We merged our sample of low-value services with CAHPS survey data by NPI and dropped observations for NPIs who have no CAHPS reviews. Then we created NPI deciles based on per NPI count of beneficiaries and generated 101 random samples stratifying on NPI deciles. Finally, we merged in HCC scores, chronic condition indicators, and zip-level socioeconomic variables and created eight output datasets for the top eight low-value services with the highest utilization rates.

**Table S14. Files related with creating sample summary statistics and adding additional covariates**

| Program name | Input files (File source) | Output files |
| --- | --- | --- |
| Exhibit1.sas|bene_pcp_final_ex.sas7bdat|lvsuse_meancount_bin.csv|
|Sample.sas|bene_pcp_final_ex.sas7bdat|lvs_npisamp.sas7bdat|
|Addvar.sas |lvs_npisamp.sas7bdat|lvscle_backscan.sas7bdat<br>lvscle_cerv.sas7bdat<br>lvscle_ctdasym.sas7bdat<br>lvscle_head.sas7bdat<br>lvscle_psa.sas7bdat<br>lvscle_pth.sas7bdat<br>lvscle_spinj.sas7bdat<br>lvscle_t3.sas7bdat|

**C5. Modeling and Analysis**

To make it computationally viable, we ran a model with all fixed effects only to predict the outcome variable of whether patients received a low value service. In R, we used glm() to generate fixed effects predictions separately for each of the eight low value services on the linear (log-odds) scale. The fixed effects included patient characteristics (age, sex, race, chronic conditions indicators, and dual status), geographical characteristics, including household income, percent poverty, percent population with college/less than high school education, and percent population who live alone, year, and HRR (hospital referral regions). Predictions for each low value service at the bene-year level were then used in an interaction with low value service type in a mixed model with NPI random effects (with beneficiaries nested). We use melogit in Stata to run the three-level mixed-effects logistic regressions. The NPI-level random effects were saved as the low-value service exposure composites.

Using these low-value service exposure composites, we ranked NPIs into quintiles and deciles, for different purposes. For Figure 1, we calculated rates of receipts of individual low-value services for PCP patient populations by quintiles of the low-value service exposure composites. We centered and rescaled CAHPS measures on a 0 to 10 scale and created CAHPS score composites for interactions with the personal doctor. We regressed CAHPS measures on low value service exposure composites adjusting for patient characteristics (age, dual status, education, health status) using PROC MIXED procedure in SAS.

**Table S15. Files related with modeling and analysis**

| Program name | Input files (File source) | Output files |
| --- | --- | --- |
|Fepredict.R|lvscle_backscan.sas7bdat<br>lvscle_cerv.sas7bdat<br>lvscle_ctdasym.sas7bdat<br>lvscle_head.sas7bdat<br>lvscle_psa.sas7bdat<br>lvscle_pth.sas7bdat<br>lvscle_spinj.sas7bdat<br>lvscle_t3.sas7bdat|lvscle_backscan_fe.sas7bdat<br>lvscle_cerv_fe.sas7bdat<br>lvscle_ctdasym_fe.sas7bdat<br>lvscle_head_fe.sas7bdat<br>lvscle_psa_fe.sas7bdat<br>lvscle_pth_fe.sas7bdat<br>lvscle_spinj_fe.sas7bdat<br>lvscle_t3_fe.sas7bdat|
|addfixedpred.sas|lvscle_backscan.sas7bdat<br>lvscle_cerv.sas7bdat <br>lvscle_ctdasym.sas7bdat <br>lvscle_head.sas7bdat<br>lvscle_psa.sas7bdat<br>lvscle_pth.sas7bdat<br>lvscle_spinj.sas7bdat<br>lvscle_t3.sas7bdat<br>lvscle_backscan_fe.sas7bdat<br>lvscle_cerv_fe.sas7bdat<br>lvscle_ctdasym_fe.sas7bdat<br>lvscle_head_fe.sas7bdat<br>lvscle_psa_fe.sas7bdat<br>lvscle_pth_fe.sas7bdat<br>lvscle_spinj_fe.sas7bdat<br>lvscle_t3_fe.sas7bdat|lvscle_8measures.sas7bdat<br>lvscle'sample’.dta|
|Randomeffects.do|lvscle`sample’.dta|lvscle_re`sample'.csv|
|Exhibit3.sas|lvscle_re'sample'.csv<br>lvscle_8measures.sas7bdat|exhibit3.csv|
|Exhibit5.sas|lvscle_8measures.sas7bdat<br>lvscle_re'sample'.csv|exhibit5.csv|
|Regression.sas | lvscle_re'sample'.csv|exhibit4.csv|

Note: `Sample&#39; ranges from 1-101.
