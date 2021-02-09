******************************************************************************************;
* Exhibit 5. Average patient and physician characteristics by quintiles of LVS composites*;
******************************************************************************************; 

/*Create balance tables comparing the first quintile and the fifth quintile NPIs as ranked by their low value service composites
  Average characteristics at both the bene-level and at the NPI-level
  For characteristics that are unique at bene-level, average over unique benes in year 2014
  For characteristics that are not unique at bene-level, average over unique bene-year*/
 
/* Libname Statements */
 %let sample= 20;
 %include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/analysis/dir.sas";
 %dir;

*Read in low value service composites;
proc import datafile = "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/8lvs/npire.csv"
 out =re
 dbms = CSV replace;
 getnames=yes;
run;

data re(drop=_npi);
format npi $10.;
set re(rename=(npi=_npi));
npi=put(_npi,10.);
run;

proc sort data=re;
by re;
run;

*Select characteristics that are unique at bene-level;
data npibene;
set prach.lvscle_8measures_final(keep=npi bene_id female white asian black hispanic age year
zip5_college zip5_in_poverty zip5_hhinc_mdn zip5_live_alone zip5_lt_hs);
if year=2014;
run;

proc sort data=npibene nodupkeys;
by npi bene_id;
run;

*Select characteristics that are not unique at the bene-level;
data npiyear;
set prach.lvscle_8measures_final(keep=npi bene_id mcaid hcc_t1 ccw_total year NPI_TotalChg medspend_all);
length beneyear $30.;
beneyear=bene_id || left(year);
run;

proc sort data=npiyear nodupkeys;
by npi beneyear;
run;

*Rank NPIs based on their low value service composites;
%macro split(rank)
data re; 
   set re nobs=numobs; 
   length  rank 3.;
   rank=floor(_n_*&rank./(numobs+1))+1; 
run;

*Calculate NPI-level average bene characteristics that are unique at the bene-level;
proc sql;
create table npibenec as 
    select distinct c.npi,
          count(distinct c.bene_id) as no_bene,
          mean(c.female) as mean_female,
          mean(c.white) as mean_white,
          mean(c.asian) as mean_asian,
          mean(c.black) as mean_black,
          mean(c.hispanic) as mean_hispanic,
          mean(c.age) as mean_age,
          mean(zip5_college) as mean_zipcollege,
          mean(zip5_hhinc_mdn) as mean_ziphhinc,
          mean(zip5_in_poverty) as mean_zippoverty,
          mean(zip5_live_alone) as mean_zipalone,
          mean(zip5_lt_hs) as mean_lths,
          r.rank
from npibene as c, re as r
where (c.npi=r.npi)
group by c.npi;
quit;

proc means data=npibenec noprint;
class rank;
Output Out =npi_chars Mean= STD= / autoname;
Run;

*Calculate bene-level average bene characteristics that are unique at the bene-level;
proc sql;
create table benec as 
    select 
          mean(c.female) as mean_female,
          mean(c.white) as mean_white,
          mean(c.asian) as mean_asian,
          mean(c.black) as mean_black,
          mean(c.hispanic) as mean_hispanic,
          mean(c.age) as mean_age,
          mean(zip5_college) as mean_zipcollege,
          mean(zip5_hhinc_mdn) as mean_ziphhinc,
          mean(zip5_in_poverty) as mean_zippoverty,
          mean(zip5_live_alone) as mean_zipalone,
          mean(zip5_lt_hs) as mean_lths,
          r.rank
from npibene as c, re as r
where (c.npi=r.npi)
group by c.bene_id;
quit;

proc means data=benec noprint;
class rank;
Output Out =bene_char Mean= STD= / autoname;
Run;

*Calculate NPI- and bene-level averages for characteristics that are not uniuqe at the bene-level;
%Macro char(var,id,stat);

proc sql;
create table yearc as 
   select distinct c.&id., 
                   &stat.(c.&var.) as &stat._&var.,
                   r.rank
   from npiyear as c, re as r
   where (c.npi=r.npi)
   group by c.&id.;
quit;

proc means data=yearc noprint;
class rank;
var &stat._&var.;
Output Out =&id.&var. Mean= STD= / autoname;
Run;

proc print data=&id.&var. noobs;
title "&var. &id.-level";
where rank=1 or rank=&rank.;
run;

%mend char;

*NPI-level averages for characteristics that are unique at the bene-level;
proc print data=npi_char noobs;
title "patient characteristics at NPI-level";
where rank=1 or rank=&rank.;
run;

*NPI-level averages for characteristics that are not unique at the bene-level;
%char(mcaid,npi,mean)
%char(hcc_t1,npi,mean)
%char(ccw_total,npi,mean)
%char(bene_id,npi,count)
%char(NPI_TotalChg,npi,sum)
%char(medspend_all,npi,sum)

*Bene-level averages for characteristics that are unique at the bene-level;
proc print data=bene_char noobs;
title "patient characteristics at bene-level";
where rank=1 or rank=&rank.;
run;

*Bene-level averages for characteristics that are not unique at the bene-level;
%char(mcaid,bene,mean)
%char(hcc_t1,bene,mean)
%char(ccw_total,bene,mean)
%char(bene_id,bene,count)
%char(BENE_TotalChg,bene,sum)
%char(medspend_all,bene,sum)

%mend split;

ods csvall file="/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/csv/exhibit5.csv";
%split(5)
%split(3)
%split(2)
ods csvall close;

******************************************************************************************;
* Exhibit 5. Average CAHPS scores by quintiles of LVS composites                         *;
******************************************************************************************; 
/*Center and rescore CAHPS survey items*/

     *Cahps survey question;
     %let cahps =   md_explain md_listen md_respect md_sptime
                    ca_rtnasaw ca_illasaw sp_getappt ca_wt15mns smokequit sp_mdinformd
                    md_testfup md_testasan md_talkmeds md_medrecs;

      array cahps14 md_explain md_listen md_respect md_sptime
                    ca_rtnasaw ca_illasaw sp_getappt ca_wt15mns smokequit sp_mdinformd
                    md_testfup md_testasan md_talkmeds md_medrecs;
      *Rescore and center CAHPS measure to 0 to 10 scale;
      do over cahps14;
         cahps14 = 10*(cahps14-1)/3;
      end;
      
      *Calculate mean CAHPS score for each survey question;
      proc sql;
           create table two as
           select *,
                  mean(md_explain) as gm_explain,
                  mean(md_listen) as gm_listen,
                  mean(md_respect) as gm_respect,
                  mean(md_sptime) as gm_sptime,
                  mean(mean(md_explain,md_listen,md_respect,md_sptime)) as gm_mdcomm,
                  mean(ca_rtnasaw) as gm_acc1,
                  mean(ca_illasaw) as gm_acc2,
                  mean(sp_getappt) as gm_acc3,
                  mean(md_testfup) as gm_test1,
                  mean(md_testasan) as gm_test2,
                  mean(mean(ca_rtnasaw,ca_illasaw,sp_getappt)) as gm_access,
                  mean(mean(md_testfup,md_testasan)) as gm_test
           from one;
      quit;


    proc sort data=two; by npi;
  
    *Substract CAHPS survey items by its own grand mean;
    data lvscle; merge lvs0 two(in=ok); by npi;

         if ok;
 
        if md_explain>=0  then md1   = md_explain - gm_explain;
        if md_listen>=0   then md2   = md_listen  - gm_listen;
        if md_respect>=0  then md3   = md_respect - gm_respect;
        if md_sptime>=0   then md4   = md_sptime  - gm_sptime;
        if ca_rtnasaw>=0  then acc1  = ca_rtnasaw - gm_acc1;
        if ca_illasaw>=0  then acc2  = ca_illasaw - gm_acc2;
        if sp_getappt>=0  then acc3  = sp_getappt - gm_acc3;
        if md_testfup>=0  then test1 = md_testfup - gm_test1;
        if md_testasan>=0 then test2 = md_testasan -gm_test2;
        
        *Create composites of related CAHPS survey items;
        mdcommunicat = mean(md1,md2,md3,md4) + gm_mdcomm;
        timelyaccess = mean(acc1,acc2,acc3)  + gm_access;
        testresults  = mean(test1,test2)     + gm_test;
        
        if mean(md1,md2,md3,md4)=. then mdcommunicat=.;
        if mean(acc1,acc2,acc3)=.  then timelyaccess=.;

options ls=120 nofmterr;

%global po1; %let po1 = /data/Medicare_P01_2009/data/cahps_claims;

libname dat  "&po1/sasdata";
libname new  ".";

%global cahps_vars;

*CAHPS survey items;
%let cahps_vars = rate_care     rate_md      rate_spec   ca_wt15mns
                  mdcommunicat  md_explain   md_listen   md_respect  md_sptime
                  timelyaccess  ca_rtnasaw   ca_illasaw  sp_getappt 
                  testresults   md_testfup   md_testasan ;

%let ncahps_vars = nrate_care    nrate_md     nrate_spec   nca_wt15mns
                   nmdcommunicat nmd_explain  nmd_listen   nmd_respect  nmd_sptime
                   ntimelyaccess nca_rtnasaw  nca_illasaw  nsp_getappt 
                   ntestresults  nmd_testfup  nmd_testasan ;

data lvs0; set new.lvs_data_new(keep = npi lvs_re rank5 &cahps_vars);
     
     *creating mean scores by quintiles of LVS composites for each CAHPS survey item; 
     proc means mean nway noprint data =lvs0;
          var &cahps_vars;
          output out=m0 mean = &ncahps_vars;

data m0; set m0(keep= &ncahps_vars);
    
     id=1;

     proc print data=m0;
     proc sort; by id;

data r0; set lvs0(keep=npi rank5);
    
     ** Comparing first and fifth quintile **;

     if rank5=1 then lvs_5th_1st=0; else if rank5=5 then lvs_5th_1st=1;

     proc sort nodupkey; by npi;

 %macro runModel(outdat, depVar);

  data d00; set new.re_&depVar(keep = estimate npi);

       id=1;
       proc sort; by id;

  data &outdat(drop=estimate); merge m0 d00; by id;

       &depVar = estimate + n&depVar;

       proc print data=&outdat(obs=2);
       
       proc sort; by npi;

 %mend;
 %runModel(d1, rate_care);
 %runModel(d2, rate_md);
 %runModel(d3, rate_spec);
 %runModel(d4, ca_wt15mns);
 %runModel(d5, mdcommunicat);
 %runModel(d6, md_explain);
 %runModel(d7, md_listen);
 %runModel(d8, md_respect);
 %runModel(d9, md_sptime);
 %runModel(d10, timelyaccess);
 %runModel(d11, ca_rtnasaw);
 %runModel(d12, ca_illasaw);
 %runModel(d13, sp_getappt);
 %runModel(d14, testresults);
 %runModel(d15, md_testfup);
 %runMOdel(d16, md_testasan);

 data n0; merge d1 d2 d3 d4 d5 d6 d7 d8 d9 d10 d11 d12 d13 d14 d15 d16; by npi;

        proc sort; by npi;

 data one; merge r0(in=a) n0(in=b); by npi;

      if a and b;

%macro test(class);
    *output CAHPS scores mean and standard deviation for the first and fifth quintile;
    proc means mean std data=one;
         class &class;
         var &cahps_vars;
    run;

%mend;
%test(lvs_5th_1st);

endsas;

