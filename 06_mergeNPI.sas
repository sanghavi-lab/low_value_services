/*Merge identified PCPs to benes in the same year of the low value service provision*/

%let sample= 20;
%include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
/* Libname Statements */
%dir;

*Merge PCPs to the benes for the specific set of low value services identified in the claims;
proc sql;
        create table analysis_specific as
        select L.bene_id, L.age, L.year, L.sex, L.race, L.STATE_CD, L.bene_zip5, L.medspend_all, L.mcaid, L.CCW_Total,
        L.dfl_ihd, L.dfl_ost, L.dfl_oldlady, L.dfl_oldman, L.dfl_old, L.dfl_prost, L.dfl_hypoth, L.dfl_surg, L.dfl_surgplus,
        L.dfl_dvt, L.dfl_sync, L.dfl_htn, L.dfl_icu, L.dfl_ckddial, L.dfl_ckdnodial, L.dfl_plant, L.spending_s, L.fl_s_all,
        L.fl_s_psa, L.fl_s_colon, L.fl_s_cerv, L.fl_s_cncr, L.fl_s_bmd, L.fl_s_pth, L.fl_s_preopx, L.fl_s_preopec, L.fl_s_pft,
        L.fl_s_preopst, L.fl_s_vert, L.fl_s_arth, L.fl_s_rhinoct, L.fl_s_sync, L.fl_s_renlstent, L.fl_s_stress,
        L.fl_s_pci, L.fl_s_backscan, L.fl_s_head, L.fl_s_eeg, L.fl_s_ctdsync, L.fl_s_ctdasym, L.fl_s_cea, L.fl_s_homocy,
        L.fl_s_hyperco, L.fl_s_ivc, L.fl_s_spinj, L.fl_s_t3, L.fl_s_plant, L.fl_s_vitd, L.fl_s_rhcath,
        R.bene_id, R.npi, R.pcp, R.NPI_TotalChg, R.Most_Recent, R.n, R.year_claims
        from
        out.yranalysis_20 as L
        inner join
        out.claims_npi_20 as R
        on (L.bene_id=R.bene_id) AND (L.year=R.year_claims);
quit;

data bene_pcp;
set analysis_specific;
keep bene_id npi;
run;

proc sort data=bene_pcp nodupkey out=bene_pcp;
by bene_id npi;
run;

*Keep PCPs who have at least 11 benes;
proc sql;
create table bene_pcp_11 as
  select *
   from bene_pcp
    group by npi
     having count(*) ge 11 ;
quit;

proc contents data=bene_pcp_11;
run;

proc print data=bene_pcp_11(obs=10);
run;

proc sort data=bene_pcp_11 out=bene_pcp_11;
by npi bene_id;
run;

proc sort data=analysis_specific out=analysis_specific;
by npi bene_id;
run;

*Reduce the low value service sample to those performed for benes whose PCPs have at least 11 benes;
data ori.bene_pcp_final;
merge bene_pcp_11 (IN=master) analysis_specific(IN=using);
by npi bene_id;
if master;
run;

*Create denominator flags as denom_lvsname to identify benes who qualify for each low value service;
data ori.bene_pcp_final;
set ori.bene_pcp_final;
denom_cerv=0;
  if dfl_oldlady=1 then denom_cerv=1;
denom_cncr=0;
  if dfl_ckddial=1 then denom_cncr=1;
denom_colon=0;
  if dfl_old=1 then denom_colon=1;
denom_psa=0;
  if dfl_oldman=1 then denom_psa=1;
denom_bmd=0;
  if dfl_ost=1 then denom_bmd=1;
denom_pth=0;
  if dfl_ckdnodial=1 then denom_pth=1;
denom_homocy=1;
denom_hyperco=0;
  if dfl_dvt=1 then denom_hyperco=1;
denom_t3=0;
  if dfl_hypoth=1 then denom_t3=1;
denom_vitd=1;
denom_pft=0;
  if dfl_surgplus=1 then denom_pft=1;
denom_preopec=0;
  if dfl_surg=1 then denom_preopec=1;
denom_preopst=0;
  if dfl_surg=1 then denom_preopst=1;
denom_preopx=0;
  if dfl_surg=1 then denom_preopx=1;
denom_backscan=1;
denom_ctdasym=1;
denom_ctdsync=0;
  if dfl_sync=1 then denom_ctdsync=1;
denom_eeg=1;
denom_head=1;
denom_plant=0;
  if dfl_plant=1 then denom_plant=1;
denom_rhinoct=1;
denom_sync=0;
  if dfl_sync=1 then denom_sync=1;
denom_cea=0;
  if sex=2 then denom_cea=1;
denom_ivc=1;
denom_pci=0;
  if dfl_ihd=1 then denom_pci=1;
denom_renlstent=0;
  if dfl_htn=1 then denom_renlstent=1;
denom_rhcath=0;
  if dfl_icu=1 then denom_rhcath=1;
denom_stress=0;
  if dfl_ihd=1 then denom_stress=1;
denom_arth=1;
denom_spinj=1;
denom_vert=0;
  if dfl_ost=1 then denom_vert=1;
run;

*Create race and sex variables;
data ori.bene_pcp_final;
set ori.bene_pcp_final;
white=0;
  if race="1" then white=1;
black=0;
  if race="2" then black=1;
asian=0;
  if race="4" then asian=1;
hispanic=0;
  if race="5" then hispanic=1;
other=0;
  if race in ("0","3","6") then other=1;
female=0;
  if sex="2" then female=1;
run;

*Create year variables;
data ori.bene_pcp_final;
set ori.bene_pcp_final;
year2007=0;
  if year="2007" then year2007=1;
year2008=0;
  if year="2008" then year2008=1;
year2009=0;
  if year="2009" then year2009=1;
year2010=0;
  if year="2010" then year2010=1;
year2011=0;
  if year="2011" then year2011=1;
year2012=0;
  if year="2012" then year2012=1;
year2013=0;
  if year="2013" then year2013=1;
run;

*Create a binary indictor for each low value service to flag whether bene received the service;
data ori.bene_pcp_final;
set ori.bene_pcp_final;
bin_cerv=0;
  if fl_s_cerv>0 then bin_cerv=1;
bin_cncr=0;
  if fl_s_cncr>0 then bin_cncr=1;
bin_colon=0;
  if fl_s_colon>0 then bin_colon=1;
bin_psa=0;
  if fl_s_psa>0 then bin_psa=1;
bin_bmd=0;
  if fl_s_bmd>0 then bin_bmd=1;
bin_pth=0;
  if fl_s_pth>0 then bin_pth=1;
bin_homocy=0;
  if fl_s_homocy>0 then bin_homocy=1;
bin_hyperco=0;
  if fl_s_hyperco>0 then bin_hyperco=1;
bin_t3=0;
  if fl_s_t3>0 then bin_t3=1;
bin_vitd=0;
  if fl_s_vitd>0 then bin_vitd=1;
bin_pft=0;
  if fl_s_pft>0 then bin_pft=1;
bin_preopec=0;
  if fl_s_preopec>0 then bin_preopec=1;
bin_preopst=0;
  if fl_s_preopst>0 then bin_preopst=1;
bin_preopx=0;
  if fl_s_preopx>0 then bin_preopx=1;
bin_backscan=0;
  if fl_s_backscan>0 then bin_backscan=1;
bin_ctdasym=0;
  if fl_s_ctdasym>0 then bin_ctdasym=1;
bin_ctdsync=0;
  if fl_s_ctdsync>0 then bin_ctdsync=1;
bin_eeg=0;
  if fl_s_eeg>0 then bin_eeg=1;
bin_head=0;
  if fl_s_head>0 then bin_head=1;
bin_plant=0;
  if fl_s_plant>0 then bin_plant=1;
bin_rhinoct=0;
  if fl_s_rhinoct>0 then bin_rhinoct=1;
bin_sync=0;
  if fl_s_sync>0 then bin_sync=1;
bin_cea=0;
  if fl_s_cea>0 then bin_cea=1;
bin_ivc=0;
  if fl_s_ivc>0 then bin_ivc=1;
bin_pci=0;
  if fl_s_pci>0 then bin_pci=1;
bin_renlstent=0;
  if fl_s_renlstent>0 then bin_renlstent=1;
bin_rhcath=0;
  if fl_s_rhcath>0 then bin_rhcath=1;
bin_stress=0;
  if fl_s_stress>0 then bin_stress=1;
bin_arth=0;
  if fl_s_arth>0 then bin_arth=1;
bin_spinj=0;
  if fl_s_spinj>0 then bin_spinj=1;
bin_vert=0;
  if fl_s_vert>0 then bin_vert=1;
run;
