/*Project: Low Value Services and Physician Reviews from CAHPS*/
/*Date Created: April 19, 2017*/


/*  FUNCTIONS:
    I.   Combine and deduplicate low-value services from different measures each year
        II.  Merge with prices to create spending each year
        III. Collapse by bene, append all years of utilization/spending statistics
        IV.  Merge with beneficiary dataset to create person-year level analytical dataset
*/

 /* Macros, internal and external: */

 %let sample= 20;
 %include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
 %let minyear=2007;
 %let maxyear=2014;

/* directory assignment */
%dir;

/*************************/
/*************************/
/* Large (sensitive) flags */
/*************************/
/*************************/

/* append all low-value services */
%macro lgcombine;

%do i=&minyear  %to &maxyear;
        data work.flaglargeall_&i.;
                length subflag $12;
                set
                flags.fl_1_&i._lg_&sample
                flags.fl_2_&i._lg_&sample
                flags.fl_3_&i._lg_&sample
                flags.fl_4_&i._lg_&sample
                flags.fl_5_&i._lg_&sample
                flags.fl_6_&i._lg_&sample
                flags.fl_7_&i._lg_&sample
                flags.fl_8_&i._lg_&sample
                flags.fl_9_&i._lg_&sample
                flags.fl_10_&i._lg_&sample
                flags.fl_11_&i._lg_&sample
                flags.fl_12_&i._lg_&sample
                flags.fl_13_&i._lg_&sample
                flags.fl_14_&i._lg_&sample
                flags.fl_15_&i._lg_&sample
                flags.fl_16_&i._lg_&sample
                flags.fl_17_&i._lg_&sample
                flags.fl_18_&i._lg_&sample
                flags.fl_19_&i._lg_&sample
                flags.fl_20_&i._lg_&sample
                flags.fl_21_&i._lg_&sample
                flags.fl_22_&i._lg_&sample
                flags.fl_23_&i._lg_&sample
                flags.fl_24_&i._lg_&sample
                flags.fl_25_&i._lg_&sample
                flags.fl_26_&i._lg_&sample
                flags.fl_27_&i._lg_&sample
                flags.fl_28_&i._lg_&sample
                flags.fl_29_&i._lg_&sample
                flags.fl_30_&i._lg_&sample
                flags.fl_31_&i._lg_&sample;
                keep bene_id hcpcs_cd expnsdt1 carclm_id otptclm_id flag subflag;
                run;

                proc sort data=work.flaglargeall_&i;
                        by subflag bene_id expnsdt1 flag;
        run;
%end;
%mend lgcombine;
%lgcombine;

/********************/
/***Deduplication ***/
/********************/
/* detect and drop any event occuring within 7 days of last same type of subflag */

%macro lgdedup;
%do i=&minyear  %to &maxyear;

        data work.flaglarge_&i;
                set work.flaglargeall_&i;
                by subflag bene_id ;
                lag_expnsdt1 = lag(expnsdt1);
                dif_expnsdt1 = expnsdt1-lag_expnsdt1;
                if first.bene_id then do;
                lag_expnsdt1= .;
                dif_expnsdt1= .;
                end;
                format lag_expnsdt1 date9.;
                if 0<=dif_expnsdt1 and dif_expnsdt1<=7 then delete;
        run;

        /* specific deduplication for stress tests, since high and low stresses might
        be defined differently across carrier and outpatient sets */

        proc sql;
                create table work.flaglarge01_&i as
                select *, case when flag='preopst' or flag='stress' then 1 else 0 end as stress
                from work.flaglarge_&i
                order by calculated stress, bene_id, expnsdt1;
        quit;


        data work.flaglarge02_&i;
                set work.flaglarge01_&i;
                by stress bene_id ;
                lag_expnsdt1 = lag(expnsdt1);
                dif_expnsdt1 = expnsdt1-lag_expnsdt1;
                if first.bene_id then do;
                lag_expnsdt1= .;
                dif_expnsdt1= .;
                end;
                format lag_expnsdt1 date9.;
                if 0<=dif_expnsdt1 and dif_expnsdt1<=7 and stress=1 then delete;
        run;

%end;
%mend lgdedup;
%lgdedup;

/******************************************************/
/* merge in pricing info from costs, collapse by bene */
/******************************************************/

/* for annual data */
%macro yrlgcostbene;
%do i=&minyear  %to &maxyear;
        proc sql;
                create table work.yrflaglarge1_&i. as
                select L.bene_id, L.expnsdt1, L.hcpcs_cd, L.carclm_id, L.otptclm_id, L.flag, coalesce(L.subflag, R.subflag) as subflag, R.cost1 as price
                from work.flaglarge02_&i as L
                left join
                out.costtrans as R
                on L.subflag=R.subflag;
        quit;

        /* calculate total number of flags by flag type */
        proc sql;
                create table work.yrflaglarge2_&i. as
                select *,
                case when flag='psa'            then count(flag) else 0 end as fl_l_psa         ,
                case when flag='colon'          then count(flag) else 0 end as fl_l_colon               ,
                case when flag='cerv'           then count(flag) else 0 end as fl_l_cerv                ,
                case when flag='cncr'           then count(flag) else 0 end as fl_l_cncr                ,
                case when flag='bmd'            then count(flag) else 0 end as fl_l_bmd ,
                case when flag='pth'            then count(flag) else 0 end as fl_l_pth ,
                case when flag='preopx'         then count(flag) else 0 end as fl_l_preopx      ,
                case when flag='preopec'        then count(flag) else 0 end as fl_l_preopec     ,
                case when flag='pft'            then count(flag) else 0 end as fl_l_pft         ,
                case when flag='preopst'        then count(flag) else 0 end as fl_l_preopst     ,
                case when flag='vert'           then count(flag) else 0 end as fl_l_vert                ,
                case when flag='arth'           then count(flag) else 0 end as fl_l_arth                ,
                case when flag='rhinoct'        then count(flag) else 0 end as fl_l_rhinoct     ,
                case when flag='sync'           then count(flag) else 0 end as fl_l_sync                ,
                case when flag='renlstent'      then count(flag) else 0 end as fl_l_renlstent   ,
                case when flag='stress'         then count(flag) else 0 end as fl_l_stress      ,
                case when flag='pci'            then count(flag) else 0 end as fl_l_pci         ,
                case when flag='backscan'       then count(flag) else 0 end as fl_l_backscan    ,
                case when flag='head'           then count(flag) else 0 end as fl_l_head                ,
                case when flag='eeg'            then count(flag) else 0 end as fl_l_eeg         ,
                case when flag='ctdsync'        then count(flag) else 0 end as fl_l_ctdsync     ,
                case when flag='ctdasym'        then count(flag) else 0 end as fl_l_ctdasym     ,
                case when flag='cea'            then count(flag) else 0 end as fl_l_cea         ,
                case when flag='homocy'         then count(flag) else 0 end as fl_l_homocy      ,
                case when flag='hyperco'        then count(flag) else 0 end as fl_l_hyperco     ,
                case when flag='ivc'            then count(flag) else 0 end as fl_l_ivc         ,
                case when flag='spinj'          then count(flag) else 0 end as fl_l_spinj               ,
                case when flag='t3'             then count(flag) else 0 end as fl_l_t3          ,
                case when flag='plant'          then count(flag) else 0 end as fl_l_plant               ,
                case when flag='vitd'           then count(flag) else 0 end as fl_l_vitd                ,
                case when flag='rhcath'         then count(flag) else 0 end as fl_l_rhcath              ,
                case when flag='psa'            then price else 0 end as sp_l_psa               ,
                case when flag='colon'          then price else 0 end as sp_l_colon             ,
                case when flag='cerv'           then price else 0 end as sp_l_cerv              ,
                case when flag='cncr'           then price else 0 end as sp_l_cncr              ,
                case when flag='bmd'            then price else 0 end as sp_l_bmd       ,
                case when flag='pth'            then price else 0 end as sp_l_pth       ,
                case when flag='preopx'         then price else 0 end as sp_l_preopx    ,
                case when flag='preopec'        then price else 0 end as sp_l_preopec   ,
                case when flag='pft'            then price else 0 end as sp_l_pft               ,
                case when flag='preopst'        then price else 0 end as sp_l_preopst   ,
                case when flag='vert'           then price else 0 end as sp_l_vert              ,
                case when flag='arth'           then price else 0 end as sp_l_arth              ,
                case when flag='rhinoct'        then price else 0 end as sp_l_rhinoct   ,
                case when flag='sync'           then price else 0 end as sp_l_sync              ,
                case when flag='renlstent'      then price else 0 end as sp_l_renlstent ,
                case when flag='stress'         then price else 0 end as sp_l_stress    ,
                case when flag='pci'            then price else 0 end as sp_l_pci               ,
                case when flag='backscan'       then price else 0 end as sp_l_backscan  ,
                case when flag='head'           then price else 0 end as sp_l_head              ,
                case when flag='eeg'            then price else 0 end as sp_l_eeg               ,
                case when flag='ctdsync'        then price else 0 end as sp_l_ctdsync   ,
                case when flag='ctdasym'        then price else 0 end as sp_l_ctdasym   ,
                case when flag='cea'            then price else 0 end as sp_l_cea               ,
                case when flag='homocy'         then price else 0 end as sp_l_homocy    ,
                case when flag='hyperco'        then price else 0 end as sp_l_hyperco   ,
                case when flag='ivc'            then price else 0 end as sp_l_ivc               ,
                case when flag='spinj'          then price else 0 end as sp_l_spinj             ,
                case when flag='t3'             then price else 0 end as sp_l_t3                ,
                case when flag='plant'          then price else 0 end as sp_l_plant             ,
                case when flag='vitd'           then price else 0 end as sp_l_vitd              ,
                case when flag='rhcath'         then price else 0 end as sp_l_rhcath
                from  work.yrflaglarge1_&i.
                group by bene_id, flag;
        quit;


/* assign flag type totals to bene_level (from Bene-flag level) */

proc sql;
        create table work.yrflaglarge_&i._&sample as
        select bene_id, sum(price) as spending_l, count(flag) as fl_l_all, &i as year,
        max(fl_l_psa            ) as fl_l_psa           ,
        max(fl_l_colon          ) as fl_l_colon         ,
        max(fl_l_cerv           ) as fl_l_cerv          ,
        max(fl_l_cncr           ) as fl_l_cncr          ,
        max(fl_l_bmd            ) as fl_l_bmd   ,
        max(fl_l_pth            ) as fl_l_pth   ,
        max(fl_l_preopx         ) as fl_l_preopx        ,
        max(fl_l_preopec        ) as fl_l_preopec       ,
        max(fl_l_pft            ) as fl_l_pft           ,
        max(fl_l_preopst        ) as fl_l_preopst       ,
        max(fl_l_vert           ) as fl_l_vert          ,
        max(fl_l_arth           ) as fl_l_arth          ,
        max(fl_l_rhinoct        ) as fl_l_rhinoct       ,
        max(fl_l_sync           ) as fl_l_sync          ,
        max(fl_l_renlstent      ) as fl_l_renlstent,
        max(fl_l_stress         ) as fl_l_stress        ,
        max(fl_l_pci            ) as fl_l_pci           ,
        max(fl_l_backscan       ) as fl_l_backscan      ,
        max(fl_l_head           ) as fl_l_head          ,
        max(fl_l_eeg            ) as fl_l_eeg           ,
        max(fl_l_ctdsync        ) as fl_l_ctdsync       ,
        max(fl_l_ctdasym        ) as fl_l_ctdasym       ,
        max(fl_l_cea            ) as fl_l_cea           ,
        max(fl_l_homocy         ) as fl_l_homocy        ,
        max(fl_l_hyperco        ) as fl_l_hyperco       ,
        max(fl_l_ivc            ) as fl_l_ivc           ,
        max(fl_l_spinj          ) as fl_l_spinj         ,
        max(fl_l_t3             ) as fl_l_t3            ,
        max(fl_l_plant          ) as fl_l_plant         ,
        max(fl_l_vitd           ) as fl_l_vitd          ,
        max(fl_l_rhcath         ) as fl_l_rhcath        ,
        sum(sp_l_psa            ) as sp_l_psa           ,
        sum(sp_l_colon          ) as sp_l_colon         ,
        sum(sp_l_cerv           ) as sp_l_cerv          ,
        sum(sp_l_cncr           ) as sp_l_cncr          ,
        sum(sp_l_bmd            ) as sp_l_bmd   ,
        sum(sp_l_pth            ) as sp_l_pth   ,
        sum(sp_l_preopx         ) as sp_l_preopx        ,
        sum(sp_l_preopec        ) as sp_l_preopec       ,
        sum(sp_l_pft            ) as sp_l_pft           ,
        sum(sp_l_preopst        ) as sp_l_preopst       ,
        sum(sp_l_vert           ) as sp_l_vert          ,
        sum(sp_l_arth           ) as sp_l_arth          ,
        sum(sp_l_rhinoct        ) as sp_l_rhinoct       ,
        sum(sp_l_sync           ) as sp_l_sync          ,
        sum(sp_l_renlstent      ) as sp_l_renlstent,
        sum(sp_l_stress         ) as sp_l_stress        ,
        sum(sp_l_pci            ) as sp_l_pci           ,
        sum(sp_l_backscan       ) as sp_l_backscan      ,
        sum(sp_l_head           ) as sp_l_head          ,
        sum(sp_l_eeg            ) as sp_l_eeg           ,
        sum(sp_l_ctdsync        ) as sp_l_ctdsync       ,
        sum(sp_l_ctdasym        ) as sp_l_ctdasym       ,
        sum(sp_l_cea            ) as sp_l_cea           ,
        sum(sp_l_homocy         ) as sp_l_homocy        ,
        sum(sp_l_hyperco        ) as sp_l_hyperco       ,
        sum(sp_l_ivc            ) as sp_l_ivc           ,
        sum(sp_l_spinj          ) as sp_l_spinj         ,
        sum(sp_l_t3                     ) as sp_l_t3            ,
        sum(sp_l_plant          ) as sp_l_plant         ,
        sum(sp_l_vitd           ) as sp_l_vitd          ,
        sum(sp_l_rhcath         ) as sp_l_rhcath
        from work.yrflaglarge2_&i.
        group by bene_id;
quit;

%end;
%mend yrlgcostbene;
%yrlgcostbene


/* append each year of large flags together */


data out.yrflaglarge_&sample;
         set
         work.yrflaglarge_2007_&sample
         work.yrflaglarge_2008_&sample
         work.yrflaglarge_2009_&sample
         work.yrflaglarge_2010_&sample
         work.yrflaglarge_2011_&sample
         work.yrflaglarge_2012_&sample
         work.yrflaglarge_2013_&sample
         work.yrflaglarge_2014_&sample;
run;

/*****************************/
/*****************************/
/* small (specific) flags */
/*****************************/
/*****************************/

/* append all low-value services */
%macro smcombine;

%do i=&minyear  %to &maxyear;
        data work.flagsmallall_&i.;
                length subflag $12;
                set
                flags.fl_1_&i._sm_&sample
                flags.fl_2_&i._sm_&sample
                flags.fl_3_&i._sm_&sample
                flags.fl_4_&i._sm_&sample
                flags.fl_5_&i._sm_&sample
                flags.fl_6_&i._sm_&sample
                flags.fl_7_&i._sm_&sample
                flags.fl_8_&i._sm_&sample
                flags.fl_9_&i._sm_&sample
                flags.fl_10_&i._sm_&sample
                flags.fl_11_&i._sm_&sample
                flags.fl_12_&i._sm_&sample
                flags.fl_13_&i._sm_&sample
                flags.fl_14_&i._sm_&sample
                flags.fl_15_&i._sm_&sample
                flags.fl_16_&i._sm_&sample
                flags.fl_17_&i._sm_&sample
                flags.fl_18_&i._sm_&sample
                flags.fl_19_&i._sm_&sample
                flags.fl_20_&i._sm_&sample
                flags.fl_21_&i._sm_&sample
                flags.fl_22_&i._sm_&sample
                flags.fl_23_&i._sm_&sample
                flags.fl_24_&i._sm_&sample
                flags.fl_25_&i._sm_&sample
                flags.fl_26_&i._sm_&sample
                flags.fl_27_&i._sm_&sample
                flags.fl_28_&i._sm_&sample
                flags.fl_29_&i._sm_&sample
                flags.fl_30_&i._sm_&sample
                flags.fl_31_&i._sm_&sample;
                keep bene_id hcpcs_cd expnsdt1 carclm_id otptclm_id flag subflag;
                run;

                proc sort data=work.flagsmallall_&i;
                        by subflag bene_id expnsdt1 flag;
        run;
%end;
%mend smcombine;
%smcombine;

/********************/
/***Deduplication ***/
/********************/
/* detect and drop any event occuring within 7 days of last same type of subflag */

%macro smdedup;
%do i=&minyear  %to &maxyear;

        data work.flagsmall_&i;
                set work.flagsmallall_&i;
                by subflag bene_id ;
                lag_expnsdt1 = lag(expnsdt1);
                dif_expnsdt1 = expnsdt1-lag_expnsdt1;
                if first.bene_id then do;
                lag_expnsdt1= .;
                dif_expnsdt1= .;
                end;
                format lag_expnsdt1 date9.;
                if 0<=dif_expnsdt1 and dif_expnsdt1<=7 then delete;
        run;

        /* specific deduplication for stress tests, since high and low stresses might
        be defined differently across carrier and outpatient sets */

        proc sql;
                create table work.flagsmall01_&i as
                select *, case when flag='preopst' or flag='stress' then 1 else 0 end as stress
                from work.flagsmall_&i
                order by calculated stress, bene_id, expnsdt1;
        quit;


        data work.flagsmall02_&i;
                set work.flagsmall01_&i;
                by stress bene_id ;
                lag_expnsdt1 = lag(expnsdt1);
                dif_expnsdt1 = expnsdt1-lag_expnsdt1;
                if first.bene_id then do;
                lag_expnsdt1= .;
                dif_expnsdt1= .;
                end;
                format lag_expnsdt1 date9.;
                if 0<=dif_expnsdt1 and dif_expnsdt1<=7 and stress=1 then delete;
        run;

%end;
%mend smdedup;
%smdedup;

/******************************************************/
/* merge in pricing info from costs, collapse by bene */
/******************************************************/


%macro yrsmcostbene;
%do i=&minyear  %to &maxyear;
        proc sql;
                create table work.yrflagsmall1_&i. as
                select L.bene_id, L.expnsdt1, L.hcpcs_cd, L.carclm_id, L.otptclm_id, L.flag, coalesce(L.subflag, R.subflag) as subflag, R.cost1 as price
                from work.flagsmall02_&i as L
                left join
                out.costtrans as R
                on L.subflag=R.subflag;
        quit;

        /* calculate total number of flags by flag type */
        proc sql;
                create table work.yrflagsmall2_&i. as
                select *,
                case when flag='psa'            then count(flag) else 0 end as fl_s_psa         ,
                case when flag='colon'          then count(flag) else 0 end as fl_s_colon               ,
                case when flag='cerv'           then count(flag) else 0 end as fl_s_cerv                ,
                case when flag='cncr'           then count(flag) else 0 end as fl_s_cncr                ,
                case when flag='bmd'            then count(flag) else 0 end as fl_s_bmd ,
                case when flag='pth'            then count(flag) else 0 end as fl_s_pth ,
                case when flag='preopx'         then count(flag) else 0 end as fl_s_preopx      ,
                case when flag='preopec'        then count(flag) else 0 end as fl_s_preopec     ,
                case when flag='pft'            then count(flag) else 0 end as fl_s_pft         ,
                case when flag='preopst'        then count(flag) else 0 end as fl_s_preopst     ,
                case when flag='vert'           then count(flag) else 0 end as fl_s_vert                ,
                case when flag='arth'           then count(flag) else 0 end as fl_s_arth                ,
                case when flag='rhinoct'        then count(flag) else 0 end as fl_s_rhinoct     ,
                case when flag='sync'           then count(flag) else 0 end as fl_s_sync                ,
                case when flag='renlstent'      then count(flag) else 0 end as fl_s_renlstent   ,
                case when flag='stress'         then count(flag) else 0 end as fl_s_stress      ,
                case when flag='pci'            then count(flag) else 0 end as fl_s_pci         ,
                case when flag='backscan'       then count(flag) else 0 end as fl_s_backscan    ,
                case when flag='head'           then count(flag) else 0 end as fl_s_head                ,
                case when flag='eeg'            then count(flag) else 0 end as fl_s_eeg         ,
                case when flag='ctdsync'        then count(flag) else 0 end as fl_s_ctdsync     ,
                case when flag='ctdasym'        then count(flag) else 0 end as fl_s_ctdasym     ,
                case when flag='cea'            then count(flag) else 0 end as fl_s_cea         ,
                case when flag='homocy'         then count(flag) else 0 end as fl_s_homocy      ,
                case when flag='hyperco'        then count(flag) else 0 end as fl_s_hyperco     ,
                case when flag='ivc'            then count(flag) else 0 end as fl_s_ivc         ,
                case when flag='spinj'          then count(flag) else 0 end as fl_s_spinj               ,
                case when flag='t3'             then count(flag) else 0 end as fl_s_t3          ,
                case when flag='plant'          then count(flag) else 0 end as fl_s_plant               ,
                case when flag='vitd'           then count(flag) else 0 end as fl_s_vitd                ,
                case when flag='rhcath'         then count(flag) else 0 end as fl_s_rhcath              ,
                case when flag='psa'            then price else 0 end as sp_s_psa               ,
                case when flag='colon'          then price else 0 end as sp_s_colon             ,
                case when flag='cerv'           then price else 0 end as sp_s_cerv              ,
                case when flag='cncr'           then price else 0 end as sp_s_cncr              ,
                case when flag='bmd'            then price else 0 end as sp_s_bmd       ,
                case when flag='pth'            then price else 0 end as sp_s_pth       ,
                case when flag='preopx'         then price else 0 end as sp_s_preopx    ,
                case when flag='preopec'        then price else 0 end as sp_s_preopec   ,
                case when flag='pft'            then price else 0 end as sp_s_pft               ,
                case when flag='preopst'        then price else 0 end as sp_s_preopst   ,
                case when flag='vert'           then price else 0 end as sp_s_vert              ,
                case when flag='arth'           then price else 0 end as sp_s_arth              ,
                case when flag='rhinoct'        then price else 0 end as sp_s_rhinoct   ,
                case when flag='sync'           then price else 0 end as sp_s_sync              ,
                case when flag='renlstent'      then price else 0 end as sp_s_renlstent ,
                case when flag='stress'         then price else 0 end as sp_s_stress    ,
                case when flag='pci'            then price else 0 end as sp_s_pci               ,
                case when flag='backscan'       then price else 0 end as sp_s_backscan  ,
                case when flag='head'           then price else 0 end as sp_s_head              ,
                case when flag='eeg'            then price else 0 end as sp_s_eeg               ,
                case when flag='ctdsync'        then price else 0 end as sp_s_ctdsync   ,
                case when flag='ctdasym'        then price else 0 end as sp_s_ctdasym   ,
                case when flag='cea'            then price else 0 end as sp_s_cea               ,
                case when flag='homocy'         then price else 0 end as sp_s_homocy    ,
                case when flag='hyperco'        then price else 0 end as sp_s_hyperco   ,
                case when flag='ivc'            then price else 0 end as sp_s_ivc               ,
                case when flag='spinj'          then price else 0 end as sp_s_spinj             ,
                case when flag='t3'             then price else 0 end as sp_s_t3                ,
                case when flag='plant'          then price else 0 end as sp_s_plant             ,
                case when flag='vitd'           then price else 0 end as sp_s_vitd              ,
                case when flag='rhcath'         then price else 0 end as sp_s_rhcath
                from  work.yrflagsmall1_&i.
                group by bene_id, flag;
        quit;


/* assign flag type totals to bene_level (from Bene-flag level) */

proc sql;
        create table work.yrflagsmall_&i._&sample as
        select bene_id, sum(price) as spending_s, count(flag) as fl_s_all, &i as year,
        max(fl_s_psa            ) as fl_s_psa           ,
        max(fl_s_colon          ) as fl_s_colon         ,
        max(fl_s_cerv           ) as fl_s_cerv          ,
        max(fl_s_cncr           ) as fl_s_cncr          ,
        max(fl_s_bmd            ) as fl_s_bmd   ,
        max(fl_s_pth            ) as fl_s_pth   ,
        max(fl_s_preopx         ) as fl_s_preopx        ,
        max(fl_s_preopec        ) as fl_s_preopec       ,
        max(fl_s_pft            ) as fl_s_pft           ,
        max(fl_s_preopst        ) as fl_s_preopst       ,
        max(fl_s_vert           ) as fl_s_vert          ,
        max(fl_s_arth           ) as fl_s_arth          ,
        max(fl_s_rhinoct        ) as fl_s_rhinoct       ,
        max(fl_s_sync           ) as fl_s_sync          ,
        max(fl_s_renlstent      ) as fl_s_renlstent,
        max(fl_s_stress         ) as fl_s_stress        ,
        max(fl_s_pci            ) as fl_s_pci           ,
        max(fl_s_backscan       ) as fl_s_backscan      ,
        max(fl_s_head           ) as fl_s_head          ,
        max(fl_s_eeg            ) as fl_s_eeg           ,
        max(fl_s_ctdsync        ) as fl_s_ctdsync       ,
        max(fl_s_ctdasym        ) as fl_s_ctdasym       ,
        max(fl_s_cea            ) as fl_s_cea           ,
        max(fl_s_homocy         ) as fl_s_homocy        ,
        max(fl_s_hyperco        ) as fl_s_hyperco       ,
        max(fl_s_ivc            ) as fl_s_ivc           ,
        max(fl_s_spinj          ) as fl_s_spinj         ,
        max(fl_s_t3                     ) as fl_s_t3            ,
        max(fl_s_plant          ) as fl_s_plant         ,
        max(fl_s_vitd           ) as fl_s_vitd          ,
        max(fl_s_rhcath         ) as fl_s_rhcath        ,
        sum(sp_s_psa            ) as sp_s_psa           ,
        sum(sp_s_colon          ) as sp_s_colon         ,
        sum(sp_s_cerv           ) as sp_s_cerv          ,
        sum(sp_s_cncr           ) as sp_s_cncr          ,
        sum(sp_s_bmd            ) as sp_s_bmd   ,
        sum(sp_s_pth            ) as sp_s_pth   ,
        sum(sp_s_preopx         ) as sp_s_preopx        ,
        sum(sp_s_preopec        ) as sp_s_preopec       ,
        sum(sp_s_pft            ) as sp_s_pft           ,
        sum(sp_s_preopst        ) as sp_s_preopst       ,
        sum(sp_s_vert           ) as sp_s_vert          ,
        sum(sp_s_arth           ) as sp_s_arth          ,
        sum(sp_s_rhinoct        ) as sp_s_rhinoct       ,
        sum(sp_s_sync           ) as sp_s_sync          ,
        sum(sp_s_renlstent      ) as sp_s_renlstent,
        sum(sp_s_stress         ) as sp_s_stress        ,
        sum(sp_s_pci            ) as sp_s_pci           ,
        sum(sp_s_backscan       ) as sp_s_backscan      ,
        sum(sp_s_head           ) as sp_s_head          ,
        sum(sp_s_eeg            ) as sp_s_eeg           ,
        sum(sp_s_ctdsync        ) as sp_s_ctdsync       ,
        sum(sp_s_ctdasym        ) as sp_s_ctdasym       ,
        sum(sp_s_cea            ) as sp_s_cea           ,
        sum(sp_s_homocy         ) as sp_s_homocy        ,
        sum(sp_s_hyperco        ) as sp_s_hyperco       ,
        sum(sp_s_ivc            ) as sp_s_ivc           ,
        sum(sp_s_spinj          ) as sp_s_spinj         ,
        sum(sp_s_t3                     ) as sp_s_t3            ,
        sum(sp_s_plant          ) as sp_s_plant         ,
        sum(sp_s_vitd           ) as sp_s_vitd          ,
        sum(sp_s_rhcath         ) as sp_s_rhcath
        from work.yrflagsmall2_&i.
        group by bene_id;
quit;

%end;
%mend yrsmcostbene;
%yrsmcostbene


/* append each year of small flags together */

data out.yrflagsmall_&sample;
         set
         work.yrflagsmall_2007_&sample
         work.yrflagsmall_2008_&sample
         work.yrflagsmall_2009_&sample
         work.yrflagsmall_2010_&sample
         work.yrflagsmall_2011_&sample
         work.yrflagsmall_2012_&sample
         work.yrflagsmall_2013_&sample
         work.yrflagsmall_2014_&sample;
run;

/************************************************/
/************************************************/
/* merge with oubenescovars to create analytic file    */
/************************************************/
/************************************************/

/* merge to bene_level dataset */
proc sql;
        create table work.yranalysis_&sample as
        select * from out.yrourbenescovars_&sample as A
        left join out.yrflagsmall_&sample as S
        on A.bene_id=S.bene_id and A.year=S.year
        left join out.yrflaglarge_&sample as L
        on A.bene_id=L.bene_id and A.year=L.year;
quit;


/* turn missing flag data to 0's. */
data out.yranalysis_&sample;
        set work.yranalysis_&sample;
        array flags fl_: spending: sp_: ;
        do over flags;
        if flags=. then flags=0;
        end;
run;

