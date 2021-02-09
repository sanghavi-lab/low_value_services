/*Project: Low Value Services and Physician Reviews from CAHPS*/
/*Date Created: March 12, 2017*/

/*  FUNCTIONS:
    I.  Collect/construct beneficiary covariates from summary file and claims
    II. Combine years for analytical dataset

 For batch mode:  sas -log=covars20.log covars20.sas  & */

 /* Macros, internal and external: */

 %let sample= 20;
 %include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
 %let minyear=2007;
 %let maxyear=2014;

/* directory assignment */
%dir;


/***************************************************/
/*** Collect spending and summary file variables ***/
/**************************************************/

%macro covarsbsf;
%do i=&minyear %to &maxyear;

/** Construct non-part B spending vars from BSF CU cut **/

data work.bsfcu_&i;
        * Set missing to zero ;
        set bsf&i..bsfcu&i;

        array spVars
        hop_mdcr_pmt
        hop_bene_pmt
        acute_mdcr_pmt
        acute_bene_pmt
        oip_mdcr_pmt
        oip_bene_pmt
        snf_mdcr_pmt
        snf_bene_pmt
        hos_mdcr_pmt
        hh_mdcr_pmt
        dme_mdcr_pmt
        dme_bene_pmt;

        do over spVars;
        if (missing(spVars)) then spVars = 0;
        else if (spVars < 0) then spVars = 0;
        end;

        Spend_OP = sum(of hop_mdcr_pmt
        hop_bene_pmt);

        Spend_IP = sum(of acute_mdcr_pmt
        acute_bene_pmt
        oip_mdcr_pmt
        oip_bene_pmt);

        Spend_SNF = sum(of snf_mdcr_pmt
        snf_bene_pmt);

        Spend_HS = hos_mdcr_pmt;
        Spend_HH = hh_mdcr_pmt;
        Spend_DME = sum(of dme_mdcr_pmt
        dme_bene_pmt);
run;

/** Construct part B spending vars from part be claims files **/
proc sql;
create table work.Spend_Carr_&i as
select Bene_ID, sum(alowchrg) as Spend_Carr
from car&i..carc&i
group by Bene_ID;
quit;

/** Combine  with ourbenes dataset while construcing other BSF vars including CCW vars **/

/*note this is because buyin_mo is char in 07, 08, and the dual indicator is in a different bsf cut in 2010 on */
%if &i < 2009 %then %let buyincond= Z.buyin_mo in ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12');
%else %let buyincond= Z.buyin_mo>0;

%if &i < 2010 %then %let dualdata= bsf&i..bsfab&i;
%else %let dualdata= bsf&i..bsfd&i;

proc sql;
        create table work.ourbenes_&i as
        select L.*,
        R.AMIE     format=date9. as DT_AMI,
        R.ALZHE    format=date9. as DT_ALZHEIM,
        R.ALZHDMTE format=date9. as DT_DEMENT,
        R.ATRIALFE format=date9. as DT_ATRIAL,
        R.CATARCTE format=date9. as DT_CATARACT,
        R.CHRNKDNE format=date9. as DT_KIDNEY,
        R.COPDE    format=date9. as DT_COPD,
        R.CHFE    format=date9. as DT_CHF,
        R.DIABTESE format=date9. as DT_DIABET,
        R.GLAUCMAE format=date9. as DT_GLAUCOMA,
        R.HIPFRACE format=date9. as DT_HIPFRACT,
        R.ISCHMCHE format=date9. as DT_ISCHEM,
        R.DEPRSSNE format=date9. as DT_DEPRESS,
        R.OSTEOPRE format=date9. as DT_OSTEO,
        R.RA_OA_E  format=date9. as DT_ARTHRIT,
        R.STRKTIAE format=date9. as DT_STROKE,
        R.CNCRBRSE format=date9. as DT_CANCBRST,
        R.CNCRCLRE format=date9. as DT_CANCCOLN,
        R.CNCRPRSE format=date9. as DT_CANCPROST,
        R.CNCRLNGE format=date9. as DT_CANCLUNG,
        R.CNCENDME format=date9. as DT_CANCENDO,
        R.hypoth,
        case when T.Spend_OP   is not null then T.Spend_OP   else 0 end as Spend_OP,
        case when T.Spend_IP   is not null then T.Spend_IP   else 0 end as Spend_IP,
        case when T.Spend_SNF  is not null then T.Spend_SNF  else 0 end as Spend_SNF,
        case when T.Spend_HS   is not null then T.Spend_HS   else 0 end as Spend_HS,
        case when T.Spend_HH   is not null then T.Spend_HH   else 0 end as Spend_HH,
        case when T.Spend_DME  is not null then T.Spend_DME  else 0 end as Spend_DME,
        case when X.Spend_Carr is not null then X.Spend_Carr else 0 end as Spend_CAR,
        calculated Spend_OP + calculated Spend_IP  + calculated Spend_SNF + calculated Spend_HS +
        calculated Spend_HH + calculated Spend_DME + calculated Spend_CAR as medspend_all,
        Z.state_cd, Z.ms_cd, Z.orec, case when &buyincond or Y.dual_mo in ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12') then 1 else 0 end as mcaid
        from
        out.ourbenes&i._&sample as L
        left join
        bsf&i..bsfcc&i as R
        on L.bene_id = R.bene_id
        left join
        work.bsfcu_&i as T
        on L.bene_id = T.bene_id
        left join bsf&i..bsfab&i as Z
        on L.bene_id = Z.bene_id
        left join work.Spend_Carr_&i as X
        on L.bene_id = X.bene_id
        left join &dualdata as Y
        on L.bene_id = Y.bene_id;
quit;

/* Modify variables */

data work.ourbenestemp_&i;
set work.ourbenes_&i;
CCW_Alzheim = (not missing(DT_ALZHEIM) and DT_ALZHEIM < mdy(1, 1, &i));
CCW_AMI = (not missing(DT_AMI) and DT_AMI < mdy(1, 1, &i));
CCW_Arthrit = (not missing(DT_ARTHRIT) and DT_ARTHRIT < mdy(1, 1, &i));
CCW_Atrial = (not missing(DT_ATRIAL) and DT_ATRIAL < mdy(1, 1, &i));
CCW_Breast = (not missing(DT_CANCBRST) and DT_CANCBRST < mdy(1, 1, &i));
CCW_Cataract = (not missing(DT_CATARACT) and DT_CATARACT < mdy(1, 1, &i));
CCW_CHF = (not missing(DT_CHF) and DT_CHF < mdy(1, 1, &i));
CCW_Colon = (not missing(DT_CANCCOLN) and DT_CANCCOLN < mdy(1, 1, &i));
CCW_COPD = (not missing(DT_COPD) and DT_COPD < mdy(1, 1, &i));
CCW_Dement = (not missing(DT_DEMENT) and DT_DEMENT < mdy(1, 1, &i));
CCW_Depress = (not missing(DT_DEPRESS) and DT_DEPRESS < mdy(1, 1, &i));
CCW_Diabetes = (not missing(DT_DIABET) and DT_DIABET < mdy(1, 1, &i));
CCW_Endomet = (not missing(DT_CANCENDO) and DT_CANCENDO < mdy(1, 1, &i));
CCW_Glaucoma = (not missing(DT_GLAUCOMA) and DT_GLAUCOMA < mdy(1, 1, &i));
CCW_HipFract = (not missing(DT_HIPFRACT) and DT_HIPFRACT < mdy(1, 1, &i));
CCW_Ischemic = (not missing(DT_ISCHEM) and DT_ISCHEM < mdy(1, 1, &i));
CCW_Kidney = (not missing(DT_KIDNEY) and DT_KIDNEY < mdy(1, 1, &i));
CCW_Lung = (not missing(DT_CANCLUNG) and DT_CANCLUNG < mdy(1, 1, &i));
CCW_Osteo = (not missing(DT_OSTEO) and DT_OSTEO < mdy(1, 1, &i));
CCW_Prostate = (not missing(DT_CANCPROST) and DT_CANCPROST < mdy(1, 1, &i));
CCW_Stroke = (not missing(DT_STROKE) and DT_STROKE < mdy(1, 1, &i));

CCW_Total = sum(of CCW_Alzheim -- CCW_Stroke);

* Excluding eye conditions. ;
CCW_Total_ex = sum(of CCW_Alzheim -- CCW_Breast CCW_CHF -- CCW_Endomet CCW_HipFract -- CCW_Stroke);

length Bene_Zip5 $5;
Bene_Zip5 = substr(strip(Bene_Zip), 1, 5);
if (Bene_Zip5 in ("00000", "00005", "99999")) then call missing(Bene_Zip5);
drop Bene_Zip;
run;

/* denominator codes from CCW */

proc sql;
        create table work.ourbenestemp1_&i as
        select *,
        case when DT_KIDNEY<=mdy(12,31,&i) and DT_KIDNEY is not missing then 1 else 0 end as dfl_ckd            ,
        case when DT_ISCHEM<=mdy(12,31,&i) and DT_ISCHEM is not missing then 1 else 0 end as dfl_ihd            ,
        case when DT_OSTEO<=mdy(12,31,&i) and DT_OSTEO is not missing then 1 else 0 end as dfl_ost                      ,
        case when (mdy(1,1,&i)-BENE_DOB)/365.25 >=65 and sex='2'        then 1 else 0 end as dfl_oldlady                ,
        case when (mdy(1,1,&i)-BENE_DOB)/365.25 >=75 and sex='1'         then 1 else 0 end as dfl_oldman                ,
        case when (mdy(1,1,&i)-BENE_DOB)/365.25 >=86                                 then 1 else 0 end as dfl_old                       ,
        case when DT_CANCPROST<=mdy(12,31, &i) and DT_CANCPROST is not missing then 1 else 0 end as dfl_prost,
        case when hypoth in(1,3) then 1 else 0 end as dfl_hypoth
        from work.ourbenestemp_&i;
quit;

data work.ourbenestemp1_&i;
set work.ourbenestemp1_&i (drop = dt_: hypoth);
run;

%end;
%mend covarsbsf;
%covarsbsf;

/****************************************/
/* searching claims for denomintor info */
/****************************************/

%macro covarsclm;
%do i=&minyear %to &maxyear;


proc sql;
        create table work.cardenom_&i as
        select bene_id,
        sum(case when ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
        and expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as countsurg,
        sum(case when
        ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P2A', 'P2B', 'P2C', 'P2D', 'P2E', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
        and expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as countsurgplus,
        sum(case when index(dgnsall, ' 4510') + index(dgnsall, ' 45111') + index(dgnsall, ' 45119') + index(dgnsall, ' 4512') +
                index(dgnsall, ' 45181') + index(dgnsall, ' 4519') +  index(dgnsall, ' 4534')+ index(dgnsall, ' 4535')+
                index(dgnsall, ' 4151')+ index(dgnsall, ' V1251') + index(dgnsall, ' V1255') >0 and expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as countdvt,
        sum(case when index(dgnsall, ' 7802 ') + index(dgnsall, ' 9921 ') > 0 and expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as countsync,
        sum(case when index(dgnsall, ' 36211') + index(dgnsall, ' 40') + index(dgnsall, ' 4372') >0
        and expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as counthtn,
        sum(case when index(dgnsall, ' 72871') + index(dgnsall, ' 7294')>0 and  expnsdt1>=mdy(1, 1, &i) then 1 else 0 end) as countplant,
        sum(case when betos in('P9A', 'P9B') then 1 else 0 end) as countdial,
        0 as counticu
        from
        out.car&i._&sample
        group by bene_id;
quit;


proc sql;
        create table work.otptdenom_&i  as
        select bene_id,
        sum(case when ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
        and rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as countsurg,
        sum(case when
        ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P2A', 'P2B', 'P2C', 'P2D', 'P2E', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
        and rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as countsurgplus,
        sum(case when index(dgnsall, ' 4510') + index(dgnsall, ' 45111') + index(dgnsall, ' 45119') + index(dgnsall, ' 4512') +
                index(dgnsall, ' 45181') + index(dgnsall, ' 4519') +  index(dgnsall, ' 4534')+ index(dgnsall, ' 4535')+
                index(dgnsall, ' 4151')+ index(dgnsall, ' V1251') + index(dgnsall, ' V1255') >0 and rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as countdvt,
        sum(case when index(dgnsall, ' 7802 ') + index(dgnsall, ' 9921 ') > 0 and rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as countsync,
        sum(case when index(dgnsall, ' 36211') + index(dgnsall, ' 40') + index(dgnsall, ' 4372') >0
        and rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as counthtn,
        sum(case when index(dgnsall, ' 72871') + index(dgnsall, ' 7294')>0 and  rev_dt>=mdy(1, 1, &i) then 1 else 0 end) as countplant,
        sum(case when betos in('P9A', 'P9B') then 1 else 0 end) as countdial,
        0 as counticu
        from
        out.otpt&i._&sample
        group by bene_id;
quit;

/*icu stays during medical admissions */
proc sql;
        create table work.medpardenom_&i  as
        select bene_id,
        0 as countsurg,
        0 as countsurgplus,
        0 as countdvt,
        0 as countsync,
        0 as counthtn,
        0 as countplant,
        0 as countdial,
        sum(case when dschrgdt>=mdy(1, 1, &i) and icuindcd is not missing and
         ((&i=2007 and icuindcd ~='' and not(
        (drg_cd>='001' & drg_cd <='008') | (drg_cd>='036' & drg_cd<='042') | (drg_cd>='049' & drg_cd <='063') | (drg_cd>='075' & drg_cd <='077') |
        (drg_cd>='103' & drg_cd<='120') |  (drg_cd>='146' & drg_cd <='171') | (drg_cd>='191' & drg_cd<='201') | (drg_cd>='209' & drg_cd <='234') |
        (drg_cd>='257' & drg_cd <='270') | (drg_cd>='285' & drg_cd<='293') |  (drg_cd>='302' & drg_cd<='315') | (drg_cd>='334' & drg_cd <='345') |
        (drg_cd>='353' & drg_cd<='365') | (drg_cd>='370' & drg_cd <='371') | (drg_cd>='374' & drg_cd<='375') | (drg_cd='377') | (drg_cd='381') |
        (drg_cd>='392' & drg_cd<='394') | (drg_cd>='400' & drg_cd<='402') | (drg_cd>='406' & drg_cd <='408') | (drg_cd='415') | (drg_cd='424') |
        (drg_cd>='439' & drg_cd<='443') | (drg_cd>='458' & drg_cd<='459') | (drg_cd='461') | (drg_cd='468') | (drg_cd>='471' & drg_cd <='472') |
        (drg_cd='474') | (drg_cd>='476' & drg_cd<='480') | (drg_cd='482') | (drg_cd>='484' & drg_cd<='488') | (drg_cd='491') | ( drg_cd>='493' & drg_cd <='504') |
        (drg_cd>='506' & drg_cd<='507') | (drg_cd>='512' & drg_cd <='515') | (drg_cd>='519' & drg_cd <='520') | (drg_cd='525') | (drg_cd>='528' & drg_cd<='541') |
        (drg_cd='543 ') | ( drg_cd>='547' & drg_cd<='550 ') | ( drg_cd>='551' & drg_cd<='554 ') | ( drg_cd>='567' & drg_cd<='573 ') | ( drg_cd='578 ') | ( drg_cd='579')))
        |
        (&i>2007 and icuindcd ~='' and not((drg_cd>='001' & drg_cd <='003') | (drg_cd>='005' & drg_cd <='008') | drg_cd ='010' | (drg_cd>='020' & drg_cd<='033') | (drg_cd>='037' & drg_cd<='042')|
        (drg_cd>='113' & drg_cd<='117') | (drg_cd>='129' & drg_cd <='139') | (drg_cd>='163' & drg_cd <='168') |( drg_cd>='215'  & drg_cd<='245')|
        (drg_cd>='252' & drg_cd<='264') | (drg_cd>='326' & drg_cd <='358') | (drg_cd>='405' & drg_cd<='425') | (drg_cd>='453' & drg_cd <='517') |
        (drg_cd>='570' & drg_cd<='585') | (drg_cd>='614' & drg_cd <='630') | (drg_cd>='652' & drg_cd<='675') | (drg_cd>='707' & drg_cd <='718') |
        (drg_cd>='820' & drg_cd<='830') | (drg_cd>='853' & drg_cd <='858') | (drg_cd='876') | (drg_cd>='901' & drg_cd<='909') |
        (drg_cd>='927' & drg_cd<='929') | (drg_cd>='939' & drg_cd <='941') | (drg_cd>='955' & drg_cd<='959') | (drg_cd>='969' & drg_cd<='970') |
        (drg_cd>='981' & drg_cd <='989'))))
        then 1 else 0 end) as counticu
        from
        out.medpar&i._&sample
        group by bene_id;
quit;

proc sql;
        create table work.allclmdenom_&i  as
        select bene_id,
        max(countsurg) as countsurg,
        max(countsurgplus) as countsurgplus,
        max(countdvt) as countdvt,
        max(countsync) as countsync,
        max(countplant) as countplant,
        max(counticu) as counticu,
        max(countdial) as countdial,
        max(counthtn) as counthtn
        from
        (select * from
        work.cardenom_&i
        union all
        (select * from
        work.otptdenom_&i )
        union all
        (select * from
        work.medpardenom_&i ))
        group by bene_id;
quit;

/* merge back into bene dataset */
proc sql;
        create table work.ourbenestemp2_&i (drop=dfl_ckd) as
        select L.*,
        case when R.countsurg>0 then 1 else 0 end as dfl_surg,
        case when R.countsurgplus>0 then 1 else 0 end as dfl_surgplus,
        case when R.countdvt>0 then 1 else 0 end as dfl_dvt,
        case when R.countsync>0 then 1 else 0 end as dfl_sync,
        case when R.counthtn>0 then 1 else 0 end as dfl_htn,
        case when R.counticu>0 then 1 else 0 end as dfl_icu,
        case when R.countdial>0 and L.dfl_ckd=1 then 1 else 0 end as dfl_ckddial,
        case when R.countdial=0 and L.dfl_ckd=1 then 1 else 0 end as dfl_ckdnodial,
        case when R.countplant>0 then 1 else 0 end as dfl_plant
        from work.ourbenestemp1_&i as L
        left join
        work.allclmdenom_&i as R
        on L.bene_id=R.bene_id;
quit;

%end;

%mend covarsclm;
%covarsclm;


/* and combine for annual dataset */
data out.yrourbenescovars_&sample;
         set
        work.ourbenestemp2_2007
        work.ourbenestemp2_2008
        work.ourbenestemp2_2009
        work.ourbenestemp2_2010
        work.ourbenestemp2_2011
        work.ourbenestemp2_2012
        work.ourbenestemp2_2013
        work.ourbenestemp2_2014;
run;



proc sort data=out.yrourbenescovars_&sample nodupkey;
by year bene_id ;
run;
