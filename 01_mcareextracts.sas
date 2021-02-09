/*Project: Low Value Services and Physician Reviews from CAHPS*/
/*Date Created: February 24, 2017*/

/*FUNCTIONS:
    I.   Construct beneficiary-year sample based on inclusion criteria
    II.  Construct claims extracts with limited fields necessary for detecting low-value services

 /* Macros, internal and external: */
        /* This "sample" corresponds to different sizes of the Medicare files in the NBER directories.
        They can be 0001 (0.01%), 01 (1%), 05 (5%), or 20 (20%). The file directory and files all include
        this tag in their names. */
         %let sample= 20;
         %let minyear=2007;
         %let maxyear=2014;
        /* variables to keep */
         %let ccwvars = bene_id amie chrnkdne chrnkidn cncrclre cncrprse ischmche osteopre strktiae hypoth;
         %let medparvars = admsndt bene_id dschrgdt drg_cd prcdrcd: pmt_amt coin_amt ded_amt blddedam prpayamt type_adm src_adms er_amt icuindcd ;

         %include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";

         /* Libname Statements */
        %dir ;

/* Beneficiary sample construction */

/*
        Exclusion criteria:
                        -Continuous enrollment through index and index minus one year, defined as:
                        -months alive in index year equals months in A and B
                        -presence in both index year summary file and 12 months of the index year minus one
                        -no months in hmo in either index or index minus one years.
*/


%macro ourbenes;
        %do i=&minyear %to &maxyear;
                %let lastyear = %eval(&i-1);


                /*select all benes in both index and prior year */
                        proc sql;
                        create table work.ourbenes&i as
                                select &i as year, L.bene_id, L.age, L.bene_dob, L.sex, L.race, L.bene_zip,
                                L.a_mo_cnt as amocntyr, L.b_mo_cnt as bmocntyr, L.hmo_mo as hmomoyr,
                                index(L.buyin01, '3') + index(L.buyin01, 'C') +
                                index(L.buyin02, '3') + index(L.buyin02, 'C') +
                                index(L.buyin03, '3') + index(L.buyin03, 'C') +
                                index(L.buyin04, '3') + index(L.buyin04, 'C') +
                                index(L.buyin05, '3') + index(L.buyin05, 'C') +
                                index(L.buyin06, '3') + index(L.buyin06, 'C') +
                                index(L.buyin07, '3') + index(L.buyin07, 'C') +
                                index(L.buyin08, '3') + index(L.buyin08, 'C') +
                                index(L.buyin09, '3') + index(L.buyin09, 'C') +
                                index(L.buyin10, '3') + index(L.buyin10, 'C') +
                                index(L.buyin11, '3') + index(L.buyin11, 'C') +
                                index(L.buyin12, '3') + index(L.buyin12, 'C') as eligyr,
                                index(R.buyin01, '3') + index(R.buyin01, 'C') +
                                index(R.buyin02, '3') + index(R.buyin02, 'C') +
                                index(R.buyin03, '3') + index(R.buyin03, 'C') +
                                index(R.buyin04, '3') + index(R.buyin04, 'C') +
                                index(R.buyin05, '3') + index(R.buyin05, 'C') +
                                index(R.buyin06, '3') + index(R.buyin06, 'C') +
                                index(R.buyin07, '3') + index(R.buyin07, 'C') +
                                index(R.buyin08, '3') + index(R.buyin08, 'C') +
                                index(R.buyin09, '3') + index(R.buyin09, 'C') +
                                index(R.buyin10, '3') + index(R.buyin10, 'C') +
                                index(R.buyin11, '3') + index(R.buyin11, 'C') +
                                index(R.buyin12, '3') + index(R.buyin12, 'C') as eliglastyr,
                                R.a_mo_cnt as amocntlastyr, R.b_mo_cnt as bmocntlastyr, R.hmo_mo as hmomolastyr,
                                case when not(missing(L.death_dt)) and L.death_dt <= mdy(12, 31, &i) then month(L.death_dt) else 12 end as mos_alive,
                                case when cMiss(L.state_cd, L.cnty_cd) = 0 and L.cnty_cd ^= "999" then 0 else 1 end as countymiss
                                from
                                bsf&i..bsfab&i as L
                                inner join
                                bsf&lastyear..bsfab&lastyear as R
                                on L.bene_id=R.bene_id;
                        quit;

                /*destring month count since some years have this as string variables */
                        data work.ourbenes&i._1;
                                set ourbenes&i;
                                amocntyrnew=            1*amocntyr;
                                bmocntyrnew=            1*bmocntyr;
                                hmomoyrnew=             1*hmomoyr;
                                eligyrnew=              1*eligyr;
                                amocntlastyrnew=        1*amocntlastyr;
                                bmocntlastyrnew=        1*bmocntlastyr;
                                hmomolastyrnew=         1*hmomolastyr;
                                eliglastyrnew=          1*eliglastyr;
                                mos_alive=              1*mos_alive;
                        run;

                /*restrict based on inclusion criteria. No age criteria */
                        proc sql;
                                create table out.ourbenes&i._&sample as
                                select bene_id, age, bene_dob, year, sex, race, bene_zip
                                from
                                work.ourbenes&i._1
                                where (amocntyrnew=bmocntyrnew=12 or amocntyrnew=bmocntyrnew=mos_alive) and amocntlastyrnew=bmocntlastyrnew=eliglastyrnew=12
                                and hmomolastyrnew=hmomoyrnew=0 and countymiss=0;
                        quit;

                /*sort and remove any duplicates (there shouldn't be any, anyway)*/
                        proc sort data=out.ourbenes&i._&sample nodupkey;
                         by bene_id;
                        run;

        %end;
%mend ourbenes;
%ourbenes;

/* clear work directory */
proc datasets lib=work
 nolist kill;
quit;
run;


/* Carrier sample construction */
        /*  The goal here is to combine claim, line, demographic and ccw variables
                required to screen for lines low-value services for an index year and a
                lookback year. The macro creates a dataset for each year that includes all
                the claim lines for the index year and the lookback year, and all the relevant variables.

                Note that our general approach for detecting diagnoses is to concatenate
                all the diagnoses together into one long string variable and to search for specific
                diagnoses within this long string.

                Also note that this quadruple merge only keeps claims from benes
                who appear in our sample out.ourbenes'year'

                */

%macro car;
        %do i=&minyear %to &maxyear;
        %let lastyear = %eval(&i-1);
        /*these next four lines are here because of different diagnosis code variable names across years of data */
        %if &i<=2009 %then %let dgns=B.dgns_cd1, B.dgns_cd2, B.dgns_cd3, B.dgns_cd4, B.dgns_cd5, B.dgns_cd6, B.dgns_cd7, B.dgns_cd8,;
        %else %let dgns=B.icd_dgns_cd1, B.icd_dgns_cd2, B.icd_dgns_cd3, B.icd_dgns_cd4, B.icd_dgns_cd5, B.icd_dgns_cd6, B.icd_dgns_cd7, B.icd_dgns_cd8,;
        %if &lastyear <= 2009 %then %let dgnslastyr=X.dgns_cd1, X.dgns_cd2, X.dgns_cd3, X.dgns_cd4, X.dgns_cd5, X.dgns_cd6, X.dgns_cd7, X.dgns_cd8,;
        %else %let dgnslastyr= X.icd_dgns_cd1, X.icd_dgns_cd2, X.icd_dgns_cd3, X.icd_dgns_cd4, X.icd_dgns_cd5, X.icd_dgns_cd6, X.icd_dgns_cd7, X.icd_dgns_cd8, ;
                proc sql;
                        create table out.car&i._&sample as
                                select coalesce(A.bene_id, B.bene_id) as bene_id, coalesce(A.clm_id, B.clm_id) as clm_id, A.betos,
                                A.expnsdt1, A.hcpcs_cd, A.plcsrvc, A.lalowchg, A.prf_npi, A.prgrpnpi, A.tax_num, A.hcfaspcl,
                                catx(" ", ".", &dgns ".")
                                format=$51. as dgnsall, C.*, D.bene_dob, D.sex
                                from
                                car&i..carl&i. as A
                                inner join
                                car&i..carc&i as B
                                on A.clm_id=B.clm_id
                                inner join
                                bsf&i..bsfcc&i (keep = &ccwvars) as C
                                on A.bene_id=C.bene_id
                                inner join
                                out.ourbenes&i._&sample as D
                                on A.bene_id=D.bene_id
                        union all
                                select coalesce(W.bene_id, X.bene_id) as bene_id, coalesce(W.clm_id, X.clm_id) as clm_id, W.betos,
                                W.expnsdt1, W.hcpcs_cd, W.plcsrvc, W.lalowchg, W.prf_npi, W.prgrpnpi, W.tax_num, W.hcfaspcl,
                                catx(" ", ".", &dgnslastyr ".")
                                format=$51. as dgnsall, Y.*, Z.bene_dob, Z.sex
                                from
                                car&lastyear..carl&lastyear. as W
                                inner join
                                car&lastyear..carc&lastyear as X
                                on W.clm_id=X.clm_id
                                inner join
                                bsf&i..bsfcc&i (keep = &ccwvars) as Y
                                on W.bene_id=Y.bene_id
                                inner join
                                out.ourbenes&i._&sample as Z
                                on W.bene_id=Z.bene_id  ;
                        quit;
        %end;
%mend car;
 %car;


/* Outpatient sample construction */
        /* this step is analagous to the carrier sample construction */

%macro otpt;
        %do i=&minyear %to &maxyear;
        %let lastyear = %eval(&i-1);
        /*these next four lines are here because of different diagnosis code variable names across years of data */
        %if &i<=2009 %then %let dgns=B.dgnscd1, B.dgnscd2, B.dgnscd3, B.dgnscd4, B.dgnscd5, B.dgnscd6, B.dgnscd7, B.dgnscd8, B.dgnscd9, B.dgnscd10,;
        %else %let dgns=B.icd_dgns_cd1, B.icd_dgns_cd2, B.icd_dgns_cd3, B.icd_dgns_cd4, B.icd_dgns_cd5, B.icd_dgns_cd6, B.icd_dgns_cd7, B.icd_dgns_cd8, B.icd_dgns_cd9, B.icd_dgns_cd10,;
        %if &lastyear <= 2009 %then %let dgnslastyr=B.dgnscd1, B.dgnscd2, B.dgnscd3, B.dgnscd4, B.dgnscd5, B.dgnscd6, B.dgnscd7, B.dgnscd8, B.dgnscd9, B.dgnscd10,;
        %else %let dgnslastyr= B.icd_dgns_cd1, B.icd_dgns_cd2, B.icd_dgns_cd3, B.icd_dgns_cd4, B.icd_dgns_cd5, B.icd_dgns_cd6, B.icd_dgns_cd7, B.icd_dgns_cd8, B.icd_dgns_cd9, B.icd_dgns_cd10, ;
                proc sql;
                        create table out.otpt&i._&sample as
                                select coalesce(A.bene_id, B.bene_id) as bene_id, A.clm_id, A.hcpcs_cd, E.betos, A.rev_dt, A.rev_cntr, A.revblood + A.revdctbl + A.wageadj + A.revpmt + A.rev_msp1 + A.rev_msp2 as lalowchg,
                                catx(" ", ".", &dgns ".")
                                format=$63. as dgnsall, C.*, D.bene_dob, D.sex
                                from
                                otpt&i..opr&i. as A
                                inner join
                                otpt&i..opc&i as B
                                on A.clm_id=B.clm_id
                                inner join
                                bsf&i..bsfcc&i (keep = &ccwvars) as C
                                on A.bene_id=C.bene_id
                                inner join
                                out.ourbenes&i._&sample as D
                                on A.bene_id=D.bene_id
                                left join bet&i..betos&i as E
                                on A.hcpcs_cd=E.hcpcs_cd
                        union all
                                select coalesce(A.bene_id, B.bene_id) as bene_id, A.clm_id, A.hcpcs_cd, E.betos, A.rev_dt, A.rev_cntr, A.revblood + A.revdctbl + A.wageadj + A.revpmt + A.rev_msp1 + A.rev_msp2 as lalowchg,
                                catx(" ", ".", &dgnslastyr ".")
                                format=$63. as dgnsall, C.*, D.bene_dob, D.sex
                                from
                                otpt&lastyear..opr&lastyear. as A
                                inner join
                                otpt&lastyear..opc&lastyear as B
                                on A.clm_id=B.clm_id
                                inner join
                                bsf&i..bsfcc&i (keep = &ccwvars) as C
                                on A.bene_id=C.bene_id
                                inner join
                                out.ourbenes&i._&sample as D
                                on A.bene_id=D.bene_id
                                left join bet&i..betos&i as E
                                on A.hcpcs_cd=E.hcpcs_cd;
                quit;
        %end;
%mend otpt;
 %otpt;


/* Medpar sample construction*/
        /* this step is simpler than the carrier and outpatient steps because there is only
         one row per discharge (i.e. no multiple lines). We don't merge the CCW variables here
         because they are not needed for the low-value care detection algorithms */


%macro medpar;
        %do i=&minyear %to &maxyear;
        %let lastyear = %eval(&i-1);
                proc sql;
                        create table out.medpar&i._&sample as
                                select admsndt, bene_id, dschrgdt, drg_cd, prcdrcd1, prcdrcd2, prcdrcd3, prcdrcd4, prcdrcd5, prcdrcd6,
                                pmt_amt + coin_amt + ded_amt + blddedam + prpayamt as alowchrg,
                                type_adm, src_adms, er_amt, icuindcd
                                from
                                mpar&i..med&i
                        union all
                                select admsndt, bene_id, dschrgdt, drg_cd, prcdrcd1, prcdrcd2, prcdrcd3, prcdrcd4, prcdrcd5, prcdrcd6,
                                pmt_amt + coin_amt + ded_amt + blddedam + prpayamt as alowchrg,
                                type_adm, src_adms, er_amt, icuindcd
                                from
                                mpar&lastyear..med&lastyear;
                quit;
        %end;
%mend medpar;
  %medpar;
