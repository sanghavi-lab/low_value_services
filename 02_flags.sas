/*Project: Low Value Services and Physician Reviews from CAHPS*/
/*Date Created: March 9, 2017*/


/*  PROGRAM FUNCTIONS:
    I.   Construct dataset for each year with potential flag instances based on single claim data
        II.  Construct exclusion datasets for merging and implementing exclusion criteria
        III. Merge and exclude in order to create datasets of sensitive and specific low-value incidences

 For batch mode:  sas -log=flags20.log flags20.sas  & */

/* Macros, internal and external: */

 %let sample= 20;
 %include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";

/* Libname Statements */
 %dir;



/* Some macros */
        /*number of measures */
        %let numflags=31;

        /*minimum year of searching */
        %let minyear=2007;

        /*maximum year of searching*/
        %let maxyear=2014;

        /*abbreviated names of the measures*/
        %let allflags='psa', 'colon', 'cerv', 'cncr', 'bmd', 'pth', 'preopx', 'preopec', 'pft', 'preopst',
                                        'vert', 'arth', 'rhinoct', 'sync', 'renlstent', 'ivc', 'stress', 'pci', 'head', 'backscan',
                                        'eeg', 'ctdsync', 'ctdasym', 'cea', 'homocy', 'hyperco', 'spinj', 't3',
                                        'plant', 'vitd', 'rhcath' ;

        /*variables to keep at different steps*/
        %let carkeep=  bene_id clm_id hcpcs_cd expnsdt1 bene_dob sex dgnsall cncrprse chrnkdne chrnkidn ischmche strktiae cncrclre osteopre amie hypoth;
        %let otptkeep= bene_id clm_id hcpcs_cd rev_dt   bene_dob sex dgnsall cncrprse chrnkdne chrnkidn ischmche strktiae cncrclre osteopre amie hypoth;
        %let flkeep= bene_id hcpcs_cd expnsdt1 carclm_id otptclm_id flag subflag;

        /*names of output datasets */
        %let workflcar=work.flcar1_&i work.flcar2_&i work.flcar3_&i work.flcar4_&i work.flcar5_&i work.flcar6_&i work.flcar7_&i work.flcar8_&i work.flcar9_&i work.flcar10_&i
                                   work.flcar11_&i work.flcar12_&i work.flcar13_&i work.flcar14_&i work.flcar15_&i work.flcar16_&i work.flcar17_&i work.flcar18_&i work.flcar19_&i work.flcar20_&i
                                   work.flcar21_&i work.flcar22_&i work.flcar23_&i work.flcar24_&i work.flcar25_&i work.flcar26_&i work.flcar27_&i work.flcar28_&i work.flcar29_&i
                                   work.flcar30_&i work.flcar31_&i ;
        %let workflotpt=work.flotpt1_&i work.flotpt2_&i work.flotpt3_&i work.flotpt4_&i work.flotpt5_&i work.flotpt6_&i work.flotpt7_&i work.flotpt8_&i work.flotpt9_&i work.flotpt10_&i
                                   work.flotpt11_&i work.flotpt12_&i work.flotpt13_&i work.flotpt14_&i work.flotpt15_&i work.flotpt16_&i work.flotpt17_&i work.flotpt18_&i work.flotpt19_&i work.flotpt20_&i
                                   work.flotpt21_&i work.flotpt22_&i work.flotpt23_&i work.flotpt24_&i work.flotpt25_&i work.flotpt26_&i  work.flotpt27_&i  work.flotpt28_&i  work.flotpt29_&i
                                   work.flotpt30_&i work.flotpt31_&i;


/*******************************************************/
/* Assign procedure and "condition" codes for each flag*/
/*******************************************************/

%macro flagcodes;
/* Assign baseline detection codes for each flag*/
         %do i=&minyear %to &maxyear ;
                /* procedure codes for detection*/
                %let prcd1=  in ('G0103', '84152', '84153', '84154'); /*PSA */
                %let prcd2=  in ('G0104', 'G0105', 'G0106', 'G0120', 'G0121', 'G0122', 'G0328', '82270')
                                          or (hcpcs_cd>='45330' and hcpcs_cd <='45345') or  (hcpcs_cd>='45378' and hcpcs_cd <='45392'); /*Colon*/
                %let prcd3=  in ('G0123', 'G0124', 'G0141', 'G0143', 'G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'P3001', 'Q0091'); /*Cerv*/
                %let prcd4=  in('77057', 'G0202', /* mammogram */
                                          'G0104', 'G0105', 'G0106', 'G0120', 'G0120', 'G0121', 'G0122', 'G0328', '82270', /* colorectal */
                                          'G0102', 'G0103', '84152', '84153', '84154', /* prostate screening, including digital rectal */
                                          'G0123', 'G0124', 'G0141', 'G0143', 'G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'P3001', 'Q0091' /* cervical */)
                                          or (((hcpcs_cd>='45330' and hcpcs_cd <='45345') or  (hcpcs_cd>='45378' and hcpcs_cd <='45392')) and index(dgnsall, ' V7651') >0) /* extra colon */;   /*cncr*/
                %let prcd5=  in('76070', '76071', '76075', '76076', '76078', '76977', '77078', '77079', '77080', '77081', '77083', '78350', '78351'); /*bmd*/
                %let prcd6=  in('83970'); /*pth*/
                %let prcd7=  in('71010', '71015', '71020', '71021', '71022', '71023', '71030', '71034', '71035'); /* preopx */
                %let prcd8=  in('93303', '93304', '93306', '93307', '93308', '93312', '93315', '93318'); /*preopec */
                %let prcd9=  in('94010'); /*PFT*/
                %let prcd10= in('93015', '93016', '93017', '93018', '93350', '93351', '78451', '78452', '78453', '78454',
                                            '78460', '78461', '78464', '78465', '78472', '78473', '78481', '78483', '78491', '78492',
                                                '75552', '75553', '75554', '75555', '75556', '75557', '75558', '75559', '75560', '75561',
                                                '75562', '75563', '75564', '75574', '0146T', '0147T', '0148T', '0149T'); /*preopst*/
                %let prcd11= in('22520', '22521', '22523', '22524'); /*vert*/
                %let prcd12= in('29877', '29879', '29880', '29881', 'G0289 '); /*arth*/
                %let prcd13= in ('70486', '70487', '70488'); /*rhinoct*/
                %let prcd14= in ('70450', '70460', '70470', '70551', '70552', '70553'); /*sync */
                %let prcd15= in ('35471', '35450', '37205', '37207', '37236', '75960', '75966'); /*renlstent*/
                %let prcd16= in ('37191', '37192', '75940'); /*ivc*/
                %let prcd17= in('93015', '93016', '93017', '93018', '93350', '93351', '78451', '78452', '78453', '78454',
                                            '78460', '78461', '78464', '78465', '78472', '78473', '78481', '78483', '78491', '78492',
                                                '75552', '75553', '75554', '75555', '75556', '75557', '75558', '75559', '75560', '75561',
                                                '75562', '75563', '75564', '75574', '0146T', '0147T', '0148T', '0149T'); /*stress*/
                %let prcd18= in('92920', '92924', '92928', '92933', '92937', '92943', '92980', '92982', 'G0290', 'C9600', 'C9602',
                                                'C9604', 'C9607'); /*pci*/
                %let prcd19= in ('70450', '70460', '70470', '70551', '70552', '70553') ; /*head*/
                %let prcd20= in ('72010', '72020', '72052', '72100', '72110', '72114', '72120', '72200', '72202', '72220',
                                                '72131', '72132', '72133', '72141', '72142', '72146', '72147', '72148', '72149', '72156', '72157', '72158'); /*backscan*/
                %let prcd21= in ('95812', '95813', '95816', '95819', '95822', '95827', '95830', '95957') ; /*eeg*/
                %let prcd22= in ('70498', '70547', '70548', '70549', '93880', '93882', '3100F') ; /*ctdsync*/
                %let prcd23= in ('70498', '70547', '70548', '70549', '93880', '93882', '3100F') ; /*ctdasym*/
                %let prcd24= ='35301'; /*cea*/
                %let prcd25= ='83090'; /*homocy*/
                %let prcd26= in('81240', '81241', '83090', '85300', '85303', '85306', '85613', '86147'); /*hyperco*/
                %let prcd27= in('62311', '64483', '20552', '20553', '64493', '64475'); /*spinj*/
                %let prcd28= in('84480', '84481'); /*t3*/
                %let prcd29= in('73620', '73630', '73650', '73718', '73719', '73720', '76880', '76881', '76882'); /*plant*/
                %let prcd30= ='82652'; /*vitd*/
                %let prcd31= ='93503'; /*rhcath*/

                /*condition codes for baseline exclusion/inclusion criteria */
                %let cond1= (&expnsdt1-bene_dob)/365.25 >75; /*PSA */
                %let cond2= (&expnsdt1-bene_dob)/365.25 >76; /*Colon */
                %let cond3= (&expnsdt1-bene_dob)/365.25 >65; /*Cerv*/
                %let cond4=  &expnsdt1-chrnkdne>0 and not( hcpcs_cd in('G0102', 'G0103', '84152', '84153', '84154') and &expnsdt1-cncrprse>0); /* Cncr */
                %let cond5=  1=1; /* Bmd */
                %let cond6=   (&expnsdt1-chrnkdne>0) &  chrnkidn in(1,3); /* PTH */ /* the log file notes that missing values are generated since chrnkdne is missing often. it's ok */
                %let cond7=  1=1; /* Preopx */;
                %let cond8=  1=1; /* Preopec */;
                %let cond9=  1=1; /* PFT */;
                %let cond10= 1=1; /* Preopst */;
                %let cond11= index(dgnsall, ' 73313 ') + index(dgnsall, ' 8052 ') + index(dgnsall, ' 8054 ') > 0; /*vert*/
                %let cond12= index(dgnsall, ' 7177 ') + index(dgnsall, ' 73392 ') + index(dgnsall, ' 71500 ') +
                                         index(dgnsall, ' 71509 ') + index(dgnsall, ' 71510 ') + index(dgnsall, ' 71516 ') +
                                     index(dgnsall, ' 71526 ') + index(dgnsall, ' 71536 ') + index(dgnsall, ' 71596 ') >0 ; /*arth*/
                %let cond13= index(dgnsall, ' 461') + index(dgnsall, ' 473') > 0; /*rhinoct*/
                %let cond14= index(dgnsall, ' 7802 ') + index(dgnsall, ' 9921 ') > 0; /*sync*/
                %let cond15= 1=1;  /*renlstent*/
                %let cond16= 1=1; /*ivc*/
                %let cond17= &expnsdt1-ischmche>180; /*stress*/
                %let cond18= &expnsdt1-ischmche>180; /*pci*/
                %let cond19= index(dgnsall, ' 30781 ') + index(dgnsall, ' 339') + index(dgnsall, ' 346') + index(dgnsall, ' 7840')> 0  and
                                         index(dgnsall, ' 33920 ') + index(dgnsall, ' 33921 ') + index(dgnsall, ' 33922 ') + index(dgnsall, ' 33943 ') = 0; /*head*/
                %let cond20= index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                                        index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 7242') +
                                        index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                                        index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                                        index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472')
                                        >0;  /*backscan*/
                %let cond21=  index(dgnsall, ' 30781 ') + index(dgnsall, ' 339') + index(dgnsall, ' 346') + index(dgnsall, ' 7840')> 0; /*eeg*/
                %let cond22= index(dgnsall, ' 7802') + index(dgnsall, ' 9921')>0; /*ctdsync*/
                %let cond23= index(dgnsall, ' 430') + index(dgnsall, ' 431') + index(dgnsall, ' 43301') + index(dgnsall, ' 43311') +index(dgnsall, ' 43321') + index(dgnsall, ' 43331')  + index(dgnsall, ' 43381') + index(dgnsall, ' 43391') +
                                        index(dgnsall, ' 43400') + index(dgnsall, ' 43401') + index(dgnsall, ' 43410') + index(dgnsall, ' 43411') + index(dgnsall, ' 43490') + index(dgnsall, ' 43491')  + index(dgnsall, ' 4350') +
                                        index(dgnsall, ' 4350') + index(dgnsall, ' 4351') + index(dgnsall, ' 4353') + index(dgnsall, ' 4358') + index(dgnsall, ' 4359') + index(dgnsall, ' 436') + index(dgnsall, ' 99702') +
                                        index(dgnsall, ' 3623') + index(dgnsall, ' 36284') + index(dgnsall, ' 7802') + index(dgnsall, ' 781') + index(dgnsall, ' 7820') + index(dgnsall, ' 7845') +
                                        index(dgnsall, ' 9921') + index(dgnsall, ' V1254')=0 and &expnsdt1-strktiae < 0; /*ctdasym*/
                %let cond24= &expnsdt1-strktiae<0 and
                                        index(dgnsall, ' 430') + index(dgnsall, ' 431') + index(dgnsall, ' 43301') + index(dgnsall, ' 43311')+ index(dgnsall, ' 43321') + index(dgnsall, ' 43331')  + index(dgnsall, ' 43381') + index(dgnsall, ' 43391') +
                                        index(dgnsall, ' 43400') + index(dgnsall, ' 43401') + index(dgnsall, ' 43410') + index(dgnsall, ' 43411') + index(dgnsall, ' 43490') + index(dgnsall, ' 43491')  + index(dgnsall, ' 4350') +
                                        index(dgnsall, ' 4350') + index(dgnsall, ' 4351') + index(dgnsall, ' 4353') + index(dgnsall, ' 4358') + index(dgnsall, ' 4359') + index(dgnsall, ' 436') + index(dgnsall, ' 99702') +
                                        index(dgnsall, ' 781') + index(dgnsall, ' 7820') + index(dgnsall, ' 7845') + index(dgnsall, ' V1254') =0 ; /*cea*/
                %let cond25= 1=1; /*homocy*/
                %let cond26= 1=1; /*hyperco*/
                %let cond27= index(dgnsall, ' 7213') + index(dgnsall, ' 72142') + index(dgnsall, ' 72190') + index(dgnsall, ' 72191') + index(dgnsall, ' 72210') + index(dgnsall, ' 7222') +
                                        index(dgnsall, ' 72252') + index(dgnsall, ' 7226') + index(dgnsall, ' 72270') + index(dgnsall, ' 72273') + index(dgnsall, ' 72280') +
                                        index(dgnsall, ' 72283') + index(dgnsall, ' 72293') + index(dgnsall, ' 72400') + index(dgnsall, ' 72402') + index(dgnsall, ' 72403') +
                                        index(dgnsall, ' 7242') + index(dgnsall, ' 7243') + index(dgnsall, ' 7244') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') +
                                        index(dgnsall, ' 72470') + index(dgnsall, ' 72471') + index(dgnsall, ' 72479') + index(dgnsall, ' 7384') + index(dgnsall, ' 7385') +
                                        index(dgnsall, ' 7393') + index(dgnsall, ' 7394') + index(dgnsall, ' 75612') + index(dgnsall, ' 8460') + index(dgnsall, ' 8461') +
                                        index(dgnsall, ' 8462') + index(dgnsall, ' 8463') + index(dgnsall, ' 8468') + index(dgnsall, ' 8469') + index(dgnsall, ' 8472') > 0    ; /*spinj*/
                %let cond28= hypoth in(1,3); /*t3*/
                %let cond29= index(dgnsall, ' 72871') + index(dgnsall, ' 7294')>0;  /*plant*/
                %let cond30= index(dgnsall, ' 27542') + index(dgnsall, ' 58881') =0 and &expnsdt1-chrnkdne <=0 ; /*vitd*/
                %let cond31= 1=1; /*rhcath*/


                /*These last lines allow the user to change the detection criteria
                  for a measure across different years. However, we have found that this is
                  not necessary based on how CPT and ICD-9 codes change over time.
                  Instead, we ensure that all codes are searched for in all years,
                  even if some of the newer codes are only present in later years */

                 %do j=1 %to &numflags;
                        %global prcd&j._&i. cond&j._&i.;
                        %let prcd&j._&i.=&&prcd&j.;
                        %let cond&j._&i.=&&cond&j.;

                %end;
         %end;
%mend flagcodes;


/****************************************/
/* flag claims based on cpt, icd-9, CCW */
/****************************************/

/*
This initial flagging applies any exclusion/inclusion criteria for the sensitive version of our
measures that can be applied using the information in a single row of data.
*/

%macro flags1;
        %let expnsdt1=expnsdt1; /*this macro allows me to use the different service date variable name for the outpatient file without changing the conditions in flagcodes */
        %flagcodes;
         %do i=&minyear  %to &maxyear;
                data &workflcar;
                        set out.car&i._&sample (keep=&carkeep where = (expnsdt1>= mdy(1,1,&i)));
                        array flags[&numflags] $12 _TEMPORARY_ (&allflags);
                         %do j= 1 %to &numflags;
                        if  hcpcs_cd &&prcd&j._&i and  &&cond&j._&i  then do;
                                flag=flags[&j];
                                output work.flcar&j._&i;
                                end;
                        %end;
                run;
        %end;

        %let expnsdt1=rev_dt; /*this macro allows me to use the different service date variable name for the outpatient file without changing the conditions in flagcodes */
        %flagcodes;
         %do i=&minyear  %to &maxyear;
                data &workflotpt;
                        length flag $ 12;
                        set out.otpt&i._&sample (keep=&otptkeep where = (rev_dt>= mdy(1,1,&i)));
                        array flags[&numflags] $12 _TEMPORARY_ (&allflags);
                        %do j= 1 %to &numflags;
                        if hcpcs_cd &&prcd&j._&i and &&cond&j._&i  then do;
                                flag=flags(&j);
                                output work.flotpt&j._&i;
                                end;
                        %end;
                run;
         %end;

/* Merge carrier and outpatient flags and add subflags when they can be determined by single claim */
         %do i=&minyear  %to &maxyear;
         %do j=1 %to &numflags;
         proc sql;
        create table work.flcarotpt&j._&i  as
                select coalesce(L.bene_id, R.bene_id) as bene_id, coalesce(L.bene_dob, R.bene_dob) format=date9. as bene_dob, coalesce(L.hcpcs_cd, R.hcpcs_cd) as hcpcs_cd,
                coalesce(L.expnsdt1, R.rev_dt) format=date9. as expnsdt1, coalesce(L.flag, R.flag) as flag, L.dgnsall as cardgns, R.dgnsall as otptdgns,
                L.clm_id as carclm_id, R.clm_id as otptclm_id,
                case when calculated flag='cncr'    and calculated hcpcs_cd in('77057', 'G0202') then "ckdmamm"
                         when calculated flag='cncr'    and (calculated hcpcs_cd in('G0104', 'G0105', 'G0106', 'G0120', 'G0120', 'G0121', 'G0122') or (calculated hcpcs_cd>='45330' and calculated hcpcs_cd <='45345') or
                                                                                                (calculated hcpcs_cd>='45378' and calculated hcpcs_cd <='45392')) then "colonosc"
                         when calculated flag='cncr'    and calculated hcpcs_cd in('G0328', '82270') then "occult"
                         when calculated flag='cncr'    and calculated hcpcs_cd in('G0123', 'G0124', 'G0141', 'G014', 'G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'P3001', 'Q0091') then "cerv"
                         when calculated flag='cncr'    and calculated hcpcs_cd in('G0102', 'G0103', '84152', '84153', '84154') then "psa"
                         when calculated flag='sync' then "head"
                         when calculated flag in('ctdsync', 'ctdasym') then  "ctd"
                         when calculated flag='plant' and calculated hcpcs_cd in ('73620', '73630', '73650') then "plantx"
                         when calculated flag='plant' and calculated hcpcs_cd in ('73718', '73719', '73720') then "plantmri"
                         when calculated flag='plant' and calculated hcpcs_cd in ('76880', '76881', '76882') then "plantus"
                         else calculated flag end as subflag,
                         coalesce(L.cncrprse, R.cncrprse) format=date9. as cncrprse, coalesce(L.chrnkdne, R.chrnkdne) format=date9. as chrnkdne,
                         coalesce(L.chrnkidn, R.chrnkidn) as chrnkidn, coalesce(L.ischmche, R.ischmche) format=date9. as ischmche,
                         coalesce(L.strktiae, R.strktiae) format=date9. as strktiae, coalesce(L.cncrclre, R.cncrclre) format=date9. as cncrclre,
                         coalesce(L.osteopre, R.osteopre) format=date9. as osteopre, coalesce(L.amie, R.amie) format=date9. as amie,
                         coalesce(L.sex, R.sex) as sex
                from work.flcar&j._&i. as L
                full join
                work.flotpt&j._&i. as R
                on L.bene_id=R.bene_id and L.hcpcs_cd=R.hcpcs_cd and L.expnsdt1=R.rev_dt and L.flag=R.flag;
        quit;
         %end;
         %end;
%mend flags1;
%flags1;

/************************************/
/* Scan claims again for exclusions */
/************************************/

%macro excludecar;
        %let expnsdt1=expnsdt1;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id expnsdt1;
        %let excar= work.ercar_&i (keep=&basevars)
                                work.excervcar_&i (keep=&basevars)
                                work.excncrpthcar_&i (keep=&basevars)
                                work.exbmdcar_&i (keep=&basevars)
                                work.expthcar_&i (keep=&basevars)
                                work.expreopcar_&i (keep=&basevars betos hcpcs_cd)
                                work.expftcar_&i (keep=&basevars betos hcpcs_cd)
                                work.exrhinoctcar_&i (keep=&basevars)
                                work.exbackscancar_&i (keep=&basevars)
                                work.exeegcar_&i (keep=&basevars)
                                work.exhomocycar_&i (keep=&basevars)
                                work.exhypercocar_&i (keep=&basevars)
                                work.explantcar_&i (keep=&basevars)
                                work.exvitdcar_&i (keep=&basevars);

        data &excar;
                set out.car&i._&sample (keep=bene_id expnsdt1 hcpcs_cd dgnsall betos chrnkdne chrnkidn);

                /*ER visits */
                        if  hcpcs_cd in ('99281', '99282', '99283', '99284', '99285') then output work.ercar_&i;

                /*Cervical cancer, abnormal pap etc. */
                        if index(dgnsall, ' 180') + index(dgnsall, ' 184') + index(dgnsall, ' 2190') + index(dgnsall, ' 2331') +
                        index(dgnsall, ' 2332') + index(dgnsall, ' 2333') + index(dgnsall, ' 6221') + index(dgnsall, ' 7950') +
                        index(dgnsall, ' 7951') + index(dgnsall, ' V1040 ') + index(dgnsall, ' V1041') + index(dgnsall, ' V1322') > 0
                        then output  work.excervcar_&i;

                /*Dialysis for cncr, pth */
                        if betos in('P9A', 'P9B') & expnsdt1-chrnkdne>0 then output work.excncrpthcar_&i;

                /*bmd */
                        if hcpcs_cd in('76070', '76071', '76075', '76076', '76078', '76977', '77078', '77079', '77080', '77081', '77083', '78350', '78351')
                        then output work.exbmdcar_&i;

                /*PTH hypercalcemia for ckd patients */
                        if index(dgnsall, ' 27542 ')>0 & chrnkidn in(1,3)
                        then output work.expthcar_&i;

                /*Preop surgeries except for pft measure */
                        if ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
                        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
                        and expnsdt1>=mdy(1,1,&i)
                        then output work.expreopcar_&i;

                /*Preop surgeries for pft measure */
                        if  ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P2A', 'P2B', 'P2C', 'P2D', 'P2E', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
                        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
                        and expnsdt1>=mdy(1,1,&i)
                        then output work.expftcar_&i;

                /* Sinusitis diagnosis for rhinoct */
                        if index(dgnsall, ' 461') + index(dgnsall, ' 473') >0
                        then output work.exrhinoctcar_&i;

                /* back pain diagnosis for backscan*/
                        if index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                        index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 72403 ') + index(dgnsall, ' 7242') +
                        index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                        index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                        index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472') >0
                        then output work.exbackscancar_&i;

                /*seizures/convulsions for EEG */
                        if index(dgnsall, ' 345') + index(dgnsall, ' 7803') + index(dgnsall, ' 7810') > 0
                        then output work.exeegcar_&i;

                /*B12 or folate testing for homocy */
                        if hcpcs_cd in ('82746', '82747', '82607')
                        then output work.exhomocycar_&i;

                /*dvt/pe for hyperco*/
                        if index(dgnsall, ' 4510') + index(dgnsall, ' 45111') + index(dgnsall, ' 45119') + index(dgnsall, ' 4512') +
                        index(dgnsall, ' 45181') + index(dgnsall, ' 4519') +  index(dgnsall, ' 4534')+ index(dgnsall, ' 4535')+
                        index(dgnsall, ' 4151')+ index(dgnsall, ' V1251') + index(dgnsall, ' V1255') >0
                        then output work.exhypercocar_&i;

                /*foot pain of fasciitis for plant */
                        if index(dgnsall, ' 72871') + index(dgnsall, ' 7294') >0
                        then output work.explantcar_&i;

                /* hypercalcemia for vitamin d measure */
                        if index(dgnsall, ' 27542')>0
                        then output work.exvitdcar_&i;

        run;
%end;
%mend excludecar;
 %excludecar;

%macro excludeotpt;
        %let expnsdt1 = rev_dt;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id rev_dt chrnkidn;
        %let exotpt= work.erotpt_&i (keep=&basevars rev_cntr)
                                 work.excervotpt_&i (keep=&basevars)
                                 work.excncrpthotpt_&i (keep=&basevars)
                                 work.exbmdotpt_&i (keep=&basevars)
                                 work.expthotpt_&i (keep=&basevars)
                                 work.expreopotpt_&i (keep=&basevars betos  hcpcs_cd)
                                 work.expftotpt_&i (keep=&basevars betos hcpcs_cd)
                                 work.exrhinoctotpt_&i (keep=&basevars )
                                 work.exbackscanotpt_&i (keep=&basevars )
                                 work.exeegotpt_&i (keep=&basevars dgnsall)
                                 work.exhomocyotpt_&i (keep=&basevars)
                                 work.exhypercootpt_&i (keep=&basevars)
                                 work.explantotpt_&i (keep=&basevars)
                                 work.exvitdotpt_&i (keep=&basevars);

        data &exotpt;
        set out.otpt&i._&sample (keep=bene_id rev_dt hcpcs_cd rev_cntr dgnsall betos chrnkdne chrnkidn );

                /*ER visits */
                        if hcpcs_cd in ('99281', '99282', '99283', '99284', '99285')
                        or rev_cntr in ('0450', '0451', '0452', '0456', '0459')
                        or rev_cntr='0981' then output work.erotpt_&i;

                /*Cervical cancer, abnormal pap etc. */
                        if index(dgnsall, ' 180') + index(dgnsall, ' 184') + index(dgnsall, ' 2190') + index(dgnsall, ' 2331') +
                        index(dgnsall, ' 2332') + index(dgnsall, ' 2333') + index(dgnsall, ' 6221') + index(dgnsall, ' 7950') +
                        index(dgnsall, ' 7951') + index(dgnsall, ' V1040 ') + index(dgnsall, ' V1041') + index(dgnsall, ' V1322') > 0
                        then output  work.excervotpt_&i;

                /*Dialysis for cncr, pth */
                        if betos in('P9A', 'P9B') & rev_dt-chrnkdne>0 then output work.excncrpthotpt_&i;

                /*bmd */
                        if hcpcs_cd in('76070', '76071', '76075', '76076', '76078', '76977', '77078', '77079', '77080', '77081', '77083', '78350', '78351')
                        then output work.exbmdotpt_&i;

                /*PTH hypercalcemia for ckd patients */
                        if index(dgnsall, ' 27542 ')>0 & chrnkidn in(1,3)
                        then output work.expthotpt_&i;

                /*Preop surgeries except for pft measure */
                        if ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
                        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
                        and rev_dt>=mdy(1,1,&i)
                        then output work.expreopotpt_&i;

                /*Preop surgeries for pft measure */
                        if  ((betos in ('P1A', 'P1B', 'P1C', 'P1D', 'P1E', 'P1F', 'P2A', 'P2B', 'P2C', 'P2D', 'P2E', 'P3D', 'P4A', 'P4B', 'P4C', 'P5C', 'P5D', 'P8A', 'P8G')
                        and hcpcs_cd>='10021' and hcpcs_cd<='69990') or hcpcs_cd in ('19120', '19125', '47562', '47563', '49560', '58558'))
                        and rev_dt>=mdy(1,1,&i)
                        then output work.expftotpt_&i;

                /* Sinusitis diagnosis for rhinoct */
                        if index(dgnsall, ' 461') + index(dgnsall, ' 473') >0
                        then output work.exrhinoctotpt_&i;

                /* back pain diagnosis for backscan*/
                        if index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                         index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 7242') +
                         index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                         index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                         index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472')  >0
                        then output work.exbackscanotpt_&i;

                /*seizures/convulsions for EEG */
                        if index(dgnsall, ' 345') + index(dgnsall, ' 7803') + index(dgnsall, ' 7810') > 0
                        then output work.exeegotpt_&i;

                /*B12 or folate testing for homocy */
                        if hcpcs_cd in ('82746', '82747', '82607')
                        then output work.exhomocyotpt_&i;

                /*dvt/pe for hyperco*/
                        if index(dgnsall, ' 4510') + index(dgnsall, ' 45111') + index(dgnsall, ' 45119') + index(dgnsall, ' 4512') +
                        index(dgnsall, ' 45181') + index(dgnsall, ' 4519') +  index(dgnsall, ' 4534')+ index(dgnsall, ' 4535')+
                        index(dgnsall, ' 4151')+ index(dgnsall, ' V1251') + index(dgnsall, ' V1255') >0
                        then output work.exhypercootpt_&i;

                /*foot pain of fasciitis for plant */
                        if index(dgnsall, ' 72871') + index(dgnsall, ' 7294') >0
                        then output work.explantotpt_&i;

                /* hypercalcemia for vitamin d measure */
                        if index(dgnsall, ' 27542 ')>0
                        then output work.exvitdotpt_&i;

        run;
 %end;
%mend excludeotpt;
 %excludeotpt;

%macro excludemedpar;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id admsndt;
        %let exmedpar= work.ermedpar_&i (keep=&basevars) work.exrhcathmedpar_&i (keep=&basevars dschrgdt drg_cd icuindcd);

        data &exmedpar;
        set out.medpar&i._&sample (keep=bene_id admsndt type_adm src_adms er_amt dschrgdt icuindcd drg_cd);

                /*ER visits */
                        if type_adm='1' | src_adms='7' | er_amt >0 then output work.ermedpar_&i;

                /*inpatient stays with ICU but not a surgical DRG */
                         if mdy(10,1,2007)>dschrgdt and mdy(1,1,&i)<=dschrgdt and icuindcd ~='' and not(
                        (drg_cd>='001' & drg_cd <='008') | (drg_cd>='036' & drg_cd<='042') | (drg_cd>='049' & drg_cd <='063') | (drg_cd>='075' & drg_cd <='077') |
                        (drg_cd>='103' & drg_cd<='120') |  (drg_cd>='146' & drg_cd <='171') | (drg_cd>='191' & drg_cd<='201') | (drg_cd>='209' & drg_cd <='234') |
                        (drg_cd>='257' & drg_cd <='270') | (drg_cd>='285' & drg_cd<='293') |  (drg_cd>='302' & drg_cd<='315') | (drg_cd>='334' & drg_cd <='345') |
                        (drg_cd>='353' & drg_cd<='365') | (drg_cd>='370' & drg_cd <='371') | (drg_cd>='374' & drg_cd<='375') | (drg_cd='377') | (drg_cd='381') |
                        (drg_cd>='392' & drg_cd<='394') | (drg_cd>='400' & drg_cd<='402') | (drg_cd>='406' & drg_cd <='408') | (drg_cd='415') | (drg_cd='424') |
                        (drg_cd>='439' & drg_cd<='443') | (drg_cd>='458' & drg_cd<='459') | (drg_cd='461') | (drg_cd='468') | (drg_cd>='471' & drg_cd <='472') |
                        (drg_cd='474') | (drg_cd>='476' & drg_cd<='480') | (drg_cd='482') | (drg_cd>='484' & drg_cd<='488') | (drg_cd='491') | ( drg_cd>='493' & drg_cd <='504') |
                        (drg_cd>='506' & drg_cd<='507') | (drg_cd>='512' & drg_cd <='515') | (drg_cd>='519' & drg_cd <='520') | (drg_cd='525') | (drg_cd>='528' & drg_cd<='541') |
                        (drg_cd='543 ') | ( drg_cd>='547' & drg_cd<='550 ') | ( drg_cd>='551' & drg_cd<='554 ') | ( drg_cd>='567' & drg_cd<='573 ') | ( drg_cd='578 ') | ( drg_cd='579')
                        )
                        then output work.exrhcathmedpar_&i;


                        if  mdy(10,1,2007)<=dschrgdt and mdy(1,1,&i)<=dschrgdt and icuindcd ~='' and not((drg_cd>='001' & drg_cd <='003') | (drg_cd>='005' & drg_cd <='008') | drg_cd ='010' | (drg_cd>='020' & drg_cd<='033') | (drg_cd>='037' & drg_cd<='042')|
                        (drg_cd>='113' & drg_cd<='117') | (drg_cd>='129' & drg_cd <='139') | (drg_cd>='163' & drg_cd <='168') |( drg_cd>='215'  & drg_cd<='245')|
                        (drg_cd>='252' & drg_cd<='264') | (drg_cd>='266' & drg_cd <='267') | (drg_cd>='326' & drg_cd <='358') | (drg_cd>='405' & drg_cd<='425') | (drg_cd>='453' & drg_cd <='520') |
                        (drg_cd>='570' & drg_cd<='585') | (drg_cd>='614' & drg_cd <='630') | (drg_cd>='652' & drg_cd<='675') | (drg_cd>='707' & drg_cd <='718') |
                        (drg_cd>='820' & drg_cd<='830') | (drg_cd>='853' & drg_cd <='858') | (drg_cd='876') | (drg_cd>='901' & drg_cd<='909') |
                        (drg_cd>='927' & drg_cd<='929') | (drg_cd>='939' & drg_cd <='941') | (drg_cd>='955' & drg_cd<='959') | (drg_cd>='969' & drg_cd<='970') |
                        (drg_cd>='981' & drg_cd <='989'))

                        then output work.exrhcathmedpar_&i;


        run;
 %end;
%mend excludemedpar;
 %excludemedpar;

/************************************/
/* Process flags with exclusions */
/************************************/

/*emergency room visits */

%macro emerg;
%do i=&minyear  %to &maxyear;
proc sql;
        create table flags.er_&i._&sample as
                select distinct bene_id, rev_dt format=date9. as erdt
                        from work.erotpt_&i
                union
                select distinct bene_id, expnsdt1 format=date9. as erdt
                        from work.ercar_&i
                union
                select distinct bene_id, admsndt format=date9. as erdt
                        from work.ermedpar_&i
                ;
quit;
%end;
%mend emerg;
 %emerg;



/**** 1) PSA Screening ****/

%macro psa;

%do i=&minyear  %to &maxyear;
data flags.fl_1_&i._lg_&sample;
        set flcarotpt1_&i ;
        keep &flkeep;
run;

data flags.fl_1_&i._sm_&sample;
        set flcarotpt1_&i ;
        where (expnsdt1-cncrprse)<=0;
        keep &flkeep;
run;

%end;
%mend psa;
 %psa;

/**** 2) Colon cancer screening ****/

%macro colon;
%do i=&minyear  %to &maxyear;
        proc sql;
                create table flags.fl_2_&i._lg_&sample (keep=&flkeep) as
                select bene_id, hcpcs_cd, expnsdt1, carclm_id, otptclm_id, flag,
                        case when  hcpcs_cd in('G0328', '82270') then 1 else 0 end as occult,
                        case when avg(calculated occult)=1 then 'occult' else 'colonosc' end format=$12. as subflag
                from work.flcarotpt2_&i
                group by bene_id, expnsdt1;
        quit;
%end;

%do i=&minyear  %to &maxyear;
        proc sql;
                create table flags.fl_2_&i._sm_&sample (keep=&flkeep) as
                select bene_id, hcpcs_cd, expnsdt1, carclm_id, otptclm_id, flag, bene_dob, cncrclre,
                        case when hcpcs_cd in('G0328', '82270') then 1 else 0 end as occult,
                        case when avg(calculated occult)=1 then 'occult' else 'colonosc' end format=$12. as subflag
                from work.flcarotpt2_&i
                group by bene_id, expnsdt1
                having expnsdt1-cncrclre<=0 and
                (hcpcs_cd in ('G0104', 'G0105', 'G0106', 'G0120', 'G0120', 'G0121', 'G0122', 'G0328', '82270') or
                index(otptdgns, ' V7651') + index(cardgns, ' V7651') >0)
                and (expnsdt1-bene_dob)/365.25 >86;
        quit;
%end;
%mend colon;
 %colon;


/**** 3) Cervical cancer Screening ****/

%macro cerv;

%do i=&minyear  %to &maxyear;

data flags.fl_3_&i._lg_&sample;
        set flcarotpt3_&i ;
        keep &flkeep;
run;



/*Earliest cervical cancer / abnormal pap date (with year lookback) for women receiving paps */

proc sql;
create table work.cervdt_&i as
        select bene_id, min(cervdt) format=date9. as cervdt from (
                select bene_id, expnsdt1 format=date9. as cervdt
                from work.excervcar_&i
                union all
                select bene_id, rev_dt format=date9. as cervdt
                from work.excervotpt_&i)
        group by bene_id;
quit;

proc sql;
create table flags.fl_3_&i._sm_&sample (keep=&flkeep) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.carclm_id,
        L.otptclm_id, L.flag, L.subflag
        from work.flcarotpt3_&i as L
        left join
        work.cervdt_&i as R
        on L.bene_id = R.bene_id
        where expnsdt1-cervdt<0 and index(otptdgns, ' V1040 ') + index(otptdgns, ' V1041') +
        index(otptdgns, ' V1322') + index(otptdgns, ' V1589') +
        index(cardgns, ' V1040 ') + index(cardgns, ' V1041') + index(cardgns, ' V1322')   + index(cardgns, ' V1589') =0;
quit;

%end;
%mend cerv;
 %cerv;


/**** 4) Cancer screening in ESRD ****/

%macro cncr;
%do i=&minyear  %to &maxyear;

/*find first dialysis in year (with lookback year) */
proc sql;
create table work.firstdial_&i as
        select bene_id, min(expnsdt1) format=date9. as firstdial from (
                select bene_id, expnsdt1
                from work.excncrpthcar_&i
                union all
                select bene_id, rev_dt as expnsdt1
                from work.excncrpthotpt_&i
                )
        group by bene_id;
quit;

/* merge and keep screenings after dialysis */
proc sql;
create table work.fl_4_&i._lg_&sample (keep=&flkeep bene_dob) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.carclm_id,
        L.otptclm_id, L.flag, L.subflag, L.bene_dob format=date9.
        from work.flcarotpt4_&i as L
        left join
        work.firstdial_&i as R
        on L.bene_id = R.bene_id
        where expnsdt1-firstdial>0;
quit;

/* only keep screenings for narrow measure if age >75*/
data flags.fl_4_&i._lg_&sample flags.fl_4_&i._sm_&sample;
        set work.fl_4_&i._lg_&sample;
        if (expnsdt1-bene_dob)/365.25 >75 then do;
                /* keep &flkeep; */
                output flags.fl_4_&i._sm_&sample;
                end;
        keep &flkeep;
        output flags.fl_4_&i._lg_&sample;
        run;

%end;
%mend cncr;
 %cncr;


/**** 5) Bone Mineral Density ****/

%macro bmd;
%do i=&minyear  %to &maxyear;

/*find earliest bmd test */
proc sql;
create table work.firstbmd_&i as
        select bene_id, min(expnsdt1) format=date9. as firstbmd from (
                select bene_id, expnsdt1
                from work.exbmdcar_&i
                union all
                select bene_id, rev_dt as expnsdt1
                from work.exbmdotpt_&i
                )
        group by bene_id;
quit;

/*keep initial bmd hits if a prior test was within 30 days and two years before */

proc sql;
create table work.fl_5_&i._lg_&sample (keep=&flkeep osteopre firstbmd) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.carclm_id,
        L.otptclm_id, L.flag, L.subflag, L.osteopre format=date9., R.firstbmd
                from  work.flcarotpt5_&i as L
                inner join
                work.firstbmd_&i as R
                on L.bene_id = R.bene_id
                where firstbmd + 30 < expnsdt1;
quit;

data flags.fl_5_&i._lg_&sample (keep=&flkeep)  flags.fl_5_&i._sm_&sample (keep=&flkeep) ;
        set work.fl_5_&i._lg_&sample;
        output flags.fl_5_&i._lg_&sample;
        if firstbmd-osteopre>=0 then output flags.fl_5_&i._sm_&sample;
run;


%end;

%mend bmd;
 %bmd;


/**** 6) PTH ****/

%macro pth;
%do i=&minyear  %to &maxyear;

proc sql;
create table work.hica_&i as
        select unique bene_id from (
                select bene_id
                from work.expthcar_&i
                union all
                select bene_id
                from work.expthotpt_&i
                )
        ;
quit;


/* merge and drop screenings after dialysis (work.firstdial made in cncr macro) */
proc sql;
create table flags.fl_6_&i._lg_&sample (keep=&flkeep) as
        select  coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.carclm_id,
        L.otptclm_id, L.flag, L.subflag, R.firstdial
        from work.flcarotpt6_&i as L
        left join
        work.firstdial_&i as R
        on L.bene_id = R.bene_id
        where (firstdial-30>expnsdt1 | firstdial=.) ;
quit;

/* drop patients with hypercalcemia for narrow measure */
proc sql;
create table flags.fl_6_&i._sm_&sample (keep=&flkeep) as
        select * from flags.fl_6_&i._lg_&sample
        where bene_id not in(select bene_id from work.hica_&i);
quit;

%end;
%mend pth;
 %pth;


/**** 7) Preopx ****/

%macro preopx;
%do i=&minyear  %to &maxyear;

/*combine car and otpt surgery hits */

proc sql;
create table work.surg_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, coalesce(L.hcpcs_cd, R.hcpcs_cd) as hcpcs_surg,
        coalesce(L.expnsdt1, R.rev_dt) format=date9. as surgdt, coalesce(L.betos, R.betos) as betos
        from work.expreopcar_&i as L
        full join
        work.expreopotpt_&i as R
        on L.bene_id=R.bene_id and L.hcpcs_cd=R.hcpcs_cd and L.expnsdt1=R.rev_dt;
quit;


/* merge to include only x-rays 30 days before surgery or with V-codes */

proc sql;
create table work.surgxray_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.cardgns, L.otptdgns,
        L.carclm_id, L.otptclm_id, L.flag, L.subflag, R.surgdt,
        case when R.surgdt-30 <= L.expnsdt1 <= R.surgdt then 1 else 0 end as flag30
        from  work.flcarotpt7_&i as L
        left join
        work.surg_&i as R
        on L.bene_id=R.bene_id
        where R.surgdt-30 <= L.expnsdt1 <= R.surgdt or
         (index(cardgns, ' V7281 ') + index(cardgns, ' V7282 ') + index(cardgns, ' V7283 ')  + index(cardgns, ' V7284 ')
          + index(otptdgns, ' V7281 ') + index(otptdgns, ' V7282 ') + index(otptdgns, ' V7283 ')  + index(otptdgns, ' V7284 ')> 0);
quit;


/* create large measure */
data flags.fl_7_&i._lg_&sample;
        set work.surgxray_&i ;
        keep &flkeep;
run;


/* detect ER stays for xray/surg pts */

proc sql;
create table work.preopxer_&i as
        select L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.erdt
                from work.surgxray_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where ((R.erdt<=L.expnsdt1<=R.erdt+1 and R.erdt is not missing)
                or ((L.expnsdt1<= R.erdt <= L.surgdt) and R.erdt is not missing and L.surgdt is not missing));
quit;


/* detect inpt stays containing xrays or 30 days prior to xrays */

proc sql;
create table work.preopxinpt_&i as
        select  L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.admsndt, R.dschrgdt
                from work.surgxray_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+30) and R.dschrgdt is not missing));
quit;

/* create small measure by excluding v-code only, er, and inpatient cases */

proc sql;
create table flags.fl_7_&i._sm_&sample (keep=&flkeep) as
        select * from work.surgxray_&i
        where flag30=1 and
                (carclm_id is missing or (carclm_id not in (select carclm_id from work.preopxer_&i)
                        and carclm_id not in (select carclm_id from work.preopxinpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.preopxer_&i)
                        and otptclm_id not in (select otptclm_id from work.preopxinpt_&i)));
quit;

%end;
%mend preopx;
  %preopx;


/**** 8) Preopec ****/

%macro preopec;
%do i=&minyear  %to &maxyear;

/*note: use work.surg_&i from preopx macro  */


/* merge to include only pft 30 days before surgery or with V-codes */

proc sql;
create table work.surgecho_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.cardgns, L.otptdgns,
        L.carclm_id, L.otptclm_id, L.flag, L.subflag, R.surgdt,
        case when R.surgdt-30 <= L.expnsdt1 <= R.surgdt then 1 else 0 end as flag30
        from  work.flcarotpt8_&i as L
        left join
        work.surg_&i as R
        on L.bene_id=R.bene_id
        where R.surgdt-30 <= L.expnsdt1 <= R.surgdt or
         (index(cardgns, ' V7281 ') + index(cardgns, ' V7282 ') + index(cardgns, ' V7283 ')  + index(cardgns, ' V7284 ')
          + index(otptdgns, ' V7281 ') + index(otptdgns, ' V7282 ') + index(otptdgns, ' V7283 ')  + index(otptdgns, ' V7284 ')> 0);
quit;


/* create large measure */
data flags.fl_8_&i._lg_&sample;
        set work.surgecho_&i ;
        keep &flkeep;
run;


/* detect ER stays for echo/surg pts */

proc sql;
create table work.preopecer_&i as
        select L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.erdt
                from work.surgecho_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where ((R.erdt<=L.expnsdt1<=R.erdt+1 and R.erdt is not missing)
                or ((L.expnsdt1<= R.erdt <= L.surgdt) and R.erdt is not missing and L.surgdt is not missing));
quit;


/* detect inpt stays containing echos or 30 days prior to echos */

proc sql;
create table work.preopecinpt_&i as
        select  L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.admsndt, R.dschrgdt
                from work.surgecho_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+30) and R.dschrgdt is not missing));
quit;

/* create small measure by excluding v-code only, er, and inpatient cases */

proc sql;
create table flags.fl_8_&i._sm_&sample (keep=&flkeep) as
        select * from work.surgecho_&i
        where flag30=1 and
                (carclm_id is missing or (carclm_id not in (select carclm_id from work.preopecer_&i)
                        and carclm_id not in (select carclm_id from work.preopecinpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.preopecer_&i)
                        and otptclm_id not in (select otptclm_id from work.preopecinpt_&i)));
quit;

%end;
%mend preopec;
 %preopec;



/**** 9) PFT ****/
/*note that pft's have a different surgery list */
/*macro still needs to be edited */
%macro pft;
%do i=&minyear  %to &maxyear;


/*combine car and otpt surgery hits */

proc sql;
create table work.psurg_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, coalesce(L.hcpcs_cd, R.hcpcs_cd) as hcpcs_surg,
        coalesce(L.expnsdt1, R.rev_dt) format=date9. as surgdt, coalesce(L.betos, R.betos) as betos
        from work.expftcar_&i as L
        full join
        work.expftotpt_&i as R
        on L.bene_id=R.bene_id and L.hcpcs_cd=R.hcpcs_cd and L.expnsdt1=R.rev_dt;
quit;




/* merge to include only pfts 30 days before surgery or with V-codes */

proc sql;
create table work.surgpft_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.cardgns, L.otptdgns,
        L.carclm_id, L.otptclm_id, L.flag, L.subflag, R.surgdt,
        case when R.surgdt-30 <= L.expnsdt1 <= R.surgdt then 1 else 0 end as flag30
        from  work.flcarotpt9_&i as L
        left join
        work.psurg_&i as R
        on L.bene_id=R.bene_id
        where R.surgdt-30 <= L.expnsdt1 <= R.surgdt or
         (index(cardgns, ' V7281 ') + index(cardgns, ' V7282 ') + index(cardgns, ' V7283 ')  + index(cardgns, ' V7284 ')
          + index(otptdgns, ' V7281 ') + index(otptdgns, ' V7282 ') + index(otptdgns, ' V7283 ')  + index(otptdgns, ' V7284 ')> 0);
quit;


/* create large measure */
data flags.fl_9_&i._lg_&sample;
        set work.surgpft_&i ;
        keep &flkeep;
run;


/* detect ER stays for pft/surg pts */

proc sql;
create table work.preoppfter_&i as
        select L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.erdt
                from work.surgpft_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where ((R.erdt<=L.expnsdt1<=R.erdt+1 and R.erdt is not missing)
                or ((L.expnsdt1<= R.erdt <= L.surgdt) and R.erdt is not missing and L.surgdt is not missing));
quit;


/* detect inpt stays containing pfts or 30 days prior to pfts */

proc sql;
create table work.preoppftinpt_&i as
        select  L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.admsndt, R.dschrgdt
                from work.surgpft_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+30) and R.dschrgdt is not missing));
quit;

/* create small measure by excluding v-code only, er, and inpatient cases */

proc sql;
create table flags.fl_9_&i._sm_&sample (keep=&flkeep) as
        select * from work.surgpft_&i
        where flag30=1 and
                (carclm_id is missing or (carclm_id not in (select carclm_id from work.preoppfter_&i)
                        and carclm_id not in (select carclm_id from work.preoppftinpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.preoppfter_&i)
                        and otptclm_id not in (select otptclm_id from work.preoppftinpt_&i)));
quit;

%end;
%mend pft;
 %pft;


/**** 10) Preop stress ****/

%macro preopst;
%do i=&minyear  %to &maxyear;

/*note: use work.surg_&i from preopx macro  */


proc sql;
create table work.surg_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, coalesce(L.hcpcs_cd, R.hcpcs_cd) as hcpcs_surg,
        coalesce(L.expnsdt1, R.rev_dt) format=date9. as surgdt, coalesce(L.betos, R.betos) as betos
        from work.expreopcar_&i as L
        full join
        work.expreopotpt_&i as R
        on L.bene_id=R.bene_id and L.hcpcs_cd=R.hcpcs_cd and L.expnsdt1=R.rev_dt;
quit;


/* merge to include only stress 30 days before surgery or with V-codes */

proc sql;
create table work.surgstress_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.hcpcs_cd, L.expnsdt1, L.cardgns, L.otptdgns, L.subflag,
        L.carclm_id, L.otptclm_id, L.flag, R.surgdt,
        case when R.surgdt-30 <= L.expnsdt1 <= R.surgdt then 1 else 0 end as flag30
        from  work.flcarotpt10_&i as L
        left join
        work.surg_&i as R
        on L.bene_id=R.bene_id
        where R.surgdt-30 <= L.expnsdt1 <= R.surgdt or
         (index(cardgns, ' V7281 ') + index(cardgns, ' V7282 ') + index(cardgns, ' V7283 ')  + index(cardgns, ' V7284 ')
          + index(otptdgns, ' V7281 ') + index(otptdgns, ' V7282 ') + index(otptdgns, ' V7283 ')  + index(otptdgns, ' V7284 ')> 0);
quit;

/* edit subflags */
proc sql;
create table work.surgstress1_&i as
        select *, case when hcpcs_cd in('93015', '93016', '93017', '93018') then 1 else 0 end as tread,
        case when avg(calculated tread)=1 then "lowstress" else "highstress" end as subflag,
        case when hcpcs_cd in ('75552', '75553', '75554', '75555', '75556', '75557', '75558', '75559', '75560', '75561', '75562', '75563', '75564')
        then 1 else 0 end as mri, case when avg(calculated mri)=1 then 1 else 0 end as mrionly,
        case when hcpcs_cd in ('75574', '0146T', '0147T', '0148T', '0149T')
        then 1 else 0 end as ct, case when avg(calculated ct)=1 then 1 else 0 end as ctonly
        from work.surgstress_&i (drop=subflag)
        group by bene_id, expnsdt1;
quit;

/* create large measure */
data flags.fl_10_&i._lg_&sample;
        set work.surgstress1_&i ;
        keep &flkeep mrionly ctonly;
run;


/* detect ER stays for stress/surg pts */

proc sql;
create table work.preopster_&i as
        select L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.erdt
                from work.surgstress1_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where ((R.erdt<=L.expnsdt1<=R.erdt+1 and R.erdt is not missing)
                or ((L.expnsdt1<= R.erdt <= L.surgdt) and R.erdt is not missing and L.surgdt is not missing));
quit;


/* detect inpt stays containing stresss or 30 days prior to stresss */

proc sql;
create table work.preopstinpt_&i as
        select  L.bene_id, L.carclm_id, L.otptclm_id, L.surgdt, R.admsndt, R.dschrgdt
                from work.surgstress1_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+30) and R.dschrgdt is not missing));
quit;

/* create small measure by excluding v-code only, er, and inpatient cases */

proc sql;
create table flags.fl_10_&i._sm_&sample (keep=&flkeep mrionly) as
        select * from work.surgstress1_&i
        where flag30=1 and
                (carclm_id is missing or (carclm_id not in (select carclm_id from work.preopster_&i)
                        and carclm_id not in (select carclm_id from work.preopstinpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.preopster_&i)
                        and otptclm_id not in (select otptclm_id from work.preopstinpt_&i)));
quit;

%end;
%mend preopst;
%preopst;

/**** 11) Vertebroplasty ****/

%macro vert;
%do i=&minyear  %to &maxyear;

data flags.fl_11_&i._sm_&sample (keep=&flkeep)  flags.fl_11_&i._lg_&sample (keep=&flkeep) ;
        set flcarotpt11_&i;
        if  index(cardgns, ' 1702 ') + index(cardgns, ' 1985 ') + index(cardgns, ' 20973 ') +
        index(cardgns, ' 20300 ') + index(cardgns, ' 20301 ') + index(cardgns, ' 20302 ') +
        index(cardgns, ' 2132 ') + index(cardgns, ' 22809 ') + index(cardgns, ' 2380 ') +
        index(cardgns, ' 2386 ') + index(cardgns, ' 2392 ') +
        index(otptdgns, ' 1702 ') + index(otptdgns, ' 1985 ') + index(otptdgns, ' 20973 ') +
        index(otptdgns, ' 20300 ') + index(otptdgns, ' 20301 ') + index(otptdgns, ' 20302 ') +
        index(otptdgns, ' 2132 ') + index(otptdgns, ' 22809 ') + index(otptdgns, ' 2380 ') +
        index(otptdgns, ' 2386 ') + index(otptdgns, ' 2392 ') =0
        then output flags.fl_11_&i._sm_&sample;
        output flags.fl_11_&i._lg_&sample;
run;

%end;
%mend vert;
 %vert;


/**** 12) Arth ****/

%macro arth;
%do i=&minyear  %to &maxyear;

data flags.fl_12_&i._sm_&sample (keep=&flkeep)  flags.fl_12_&i._lg_&sample (keep=&flkeep);
        set flcarotpt12_&i;
        if index(cardgns, ' 8360 ') + index(cardgns, ' 8361 ') + index(cardgns, ' 8362 ') + index(cardgns, ' 7170 ') + index(cardgns, ' 71741 ') +
        index(otptdgns, ' 8360 ') + index(otptdgns, ' 8361 ') + index(otptdgns, ' 8362 ') + index(otptdgns, ' 7170 ') + index(otptdgns, ' 71741 ') =0
        then output flags.fl_12_&i._sm_&sample;
        output flags.fl_12_&i._lg_&sample;
run;

%end;
%mend arth;
 %arth;


/**** 13) rhinoct ****/

%macro rhinoct;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_13_&i._lg_&sample;
        set work.flcarotpt13_&i;
        keep &flkeep;
run;

/* collect all rhinosinusitis diagnoses from exclusion scan */
proc sql;
create table work.rhinoall_&i as
        select bene_id, expnsdt1 format=date9. as rhinodt from (
                select bene_id, expnsdt1
                from work.exrhinoctcar_&i
                union all
                select bene_id, rev_dt as expnsdt1
                from work.exrhinoctotpt_&i)
        where bene_id in (select bene_id from work.flcarotpt13_&i);
quit;


/*look for sinusitis diagnoses more than a month and less than a year before scan */
proc sql;
create table work.rhinodrop_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.expnsdt1, L.carclm_id, L.otptclm_id, R.rhinodt
                from work.flcarotpt13_&i as L
                left join
                work.rhinoall_&i as R
                on L.bene_id = R.bene_id
                where ((L.expnsdt1-365 <= R.rhinodt <= L.expnsdt1-30));
quit;

/*exclude scans for narrow measure in chronic sinusitis cases and based on claims diagnoses */
proc sql;
create table flags.fl_13_&i._sm_&sample (keep=&flkeep) as
        select * from work.flcarotpt13_&i
        where
        index(cardgns, ' 2770') + index(cardgns, ' 042') + index(cardgns, ' 07953') +
        index(cardgns, ' 279') + index(cardgns, ' 471') + index(cardgns, ' 373') + index(cardgns, ' 37600') +
        index(cardgns, ' 37601') +  index(cardgns, ' 368') + index(cardgns, ' 369')+
        index(cardgns, ' 800') + index(cardgns, ' 801') + index(cardgns, ' 802') +
        index(cardgns, ' 803') + index(cardgns, ' 804') + index(cardgns, ' 850') + index(cardgns, ' 851') +
        index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') + index(cardgns, ' 854') +
        index(cardgns, ' 870') + index(cardgns, ' 871') + index(cardgns, ' 872') +
        index(cardgns, ' 873') + index(cardgns, ' 9590') + index(cardgns, ' 910') + index(cardgns, ' 920') + index(cardgns, ' 921') +
        index(otptdgns, ' 2770') + index(otptdgns, ' 042') + index(otptdgns, ' 07953') +
        index(otptdgns, ' 279') + index(otptdgns, ' 471') + index(otptdgns, ' 373') + index(otptdgns, ' 37600') +
        index(otptdgns, ' 37601') +  index(otptdgns, ' 368') + index(otptdgns, ' 369') +
        index(otptdgns, ' 800') + index(otptdgns, ' 801') + index(otptdgns, ' 802') +
        index(otptdgns, ' 803') + index(otptdgns, ' 804') + index(otptdgns, ' 850') + index(otptdgns, ' 851') +
        index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') + index(otptdgns, ' 854') +
        index(otptdgns, ' 870') + index(otptdgns, ' 871') + index(otptdgns, ' 872') +
        index(otptdgns, ' 873') + index(otptdgns, ' 9590') + index(otptdgns, ' 910') + index(otptdgns, ' 920') + index(otptdgns, ' 921')= 0 and
        (carclm_id is missing or carclm_id not in (select carclm_id from work.rhinodrop_&i)) and
        (otptclm_id is missing or otptclm_id not in (select otptclm_id from work.rhinodrop_&i));
quit;


%end;
%mend rhinoct;
 %rhinoct;



/**** 14) sync ****/

%macro sync;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_14_&i._lg_&sample (keep=&flkeep) flags.fl_14_&i._sm_&sample (keep=&flkeep);
        set work.flcarotpt14_&i;
        output flags.fl_14_&i._lg_&sample;
        if index(cardgns, ' 345') + index(cardgns, ' 43') + index(cardgns, ' 800') + index(cardgns, ' 801') + index(cardgns, ' 802') +
        index(cardgns, ' 803') + index(cardgns, ' 804') + index(cardgns, ' 850') + index(cardgns, ' 851') +
        index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') + index(cardgns, ' 854') +
        index(cardgns, ' 870') + index(cardgns, ' 871') + index(cardgns, ' 872') + index(cardgns, ' 873') +
        index(cardgns, ' 9590') + index(cardgns, ' 910') + index(cardgns, ' 920') + index(cardgns, ' 921') +
        index(cardgns, ' 7803') + index(cardgns, ' 78097') + index(cardgns, ' 781') + index(cardgns, ' 7820') +
        index(cardgns, ' 7845') +  index(cardgns, ' V1254 ') +
        index(otptdgns, ' 345') + index(otptdgns, ' 43') + index(otptdgns, ' 800') + index(otptdgns, ' 801') + index(otptdgns, ' 802') +
        index(otptdgns, ' 803') + index(otptdgns, ' 804') + index(otptdgns, ' 850') + index(otptdgns, ' 851') +
        index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') + index(otptdgns, ' 854') +
        index(otptdgns, ' 870') + index(otptdgns, ' 871') + index(otptdgns, ' 872') + index(otptdgns, ' 873') +
        index(otptdgns, ' 9590') + index(otptdgns, ' 910') + index(otptdgns, ' 920') + index(otptdgns, ' 921') +
        index(otptdgns, ' 7803') + index(otptdgns, ' 78097') + index(otptdgns, ' 781') + index(otptdgns, ' 7820') +
        index(otptdgns, ' 7845') +  index(otptdgns, ' V1254 ')= 0 then
        output flags.fl_14_&i._sm_&sample;
run;


%end;
%mend sync;
%sync;



/**** 15) renlstent ****/

%macro renlstent;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_15_&i._lg_&sample /*(keep=&flkeep)*/ flags.fl_15_&i._sm_&sample /*(keep=&flkeep)*/;
        set work.flcarotpt15_&i;
        output flags.fl_15_&i._lg_&sample;
        if
        index(cardgns, ' 4401 ') + index(cardgns, ' 40501 ') + index(cardgns, ' 40511 ') + index(cardgns, ' 40591 ') +
        index(otptdgns, ' 4401 ') + index(otptdgns, ' 40501 ') + index(otptdgns, ' 40511 ') + index(otptdgns, ' 40591 ') > 0
        and
        index(cardgns, ' 4473') + index(otptdgns, ' 4473') = 0
        then output flags.fl_15_&i._sm_&sample;
run;


%end;
%mend renlstent;
 %renlstent ;



/**** 16) ivc ****/

%macro ivc;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_16_&i._lg_&sample (keep=&flkeep) flags.fl_16_&i._sm_&sample (keep=&flkeep);
        set work.flcarotpt16_&i;
        output flags.fl_16_&i._lg_&sample;
        output flags.fl_16_&i._sm_&sample;
run;


%end;
%mend ivc;
 %ivc;



/**** 17) stress ****/

%macro stress;
%do i=&minyear  %to &maxyear;

/*edit subflags, and note MRI only */
proc sql;
create table work.stress_&i as
        select *, case when hcpcs_cd in('93015', '93016', '93017', '93018') then 1 else 0 end as tread,
        case when avg(calculated tread)=1 then "lowstress" else "highstress" end as subflag,
        case when hcpcs_cd in ('75552', '75553', '75554', '75555', '75556', '75557', '75558', '75559', '75560', '75561', '75562', '75563', '75564')
        then 1 else 0 end as mri, case when avg(calculated mri)=1 then 1 else 0 end as mrionly,
        case when hcpcs_cd in ('75574', '0146T', '0147T', '0148T', '0149T')
        then 1 else 0 end as ct, case when avg(calculated ct)=1 then 1 else 0 end as ctonly
        from work.flcarotpt17_&i (drop=subflag)
        group by bene_id, expnsdt1;
quit;


/* detect ER stays associated with stress (within 14 days) */

proc sql;
create table work.stresser_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.erdt
                from work.stress_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where (R.erdt<=L.expnsdt1<=R.erdt+14) and R.erdt is not missing;
quit;


/* detect inpt stays containing stress or 14 days prior to stresss */

proc sql;
create table work.stressinpt_&i as
        select  coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.admsndt, R.dschrgdt
                from work.stress_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+14) and R.dschrgdt is not missing));
quit;

/* create large measure by excluding inpatient and er associated stresses and non-AMI patients */

proc sql;
create table work.fl_17_&i._lg_&sample as
        select * from work.stress_&i
        where (carclm_id is missing or (carclm_id not in (select carclm_id from work.stresser_&i)
                        and carclm_id not in (select carclm_id from work.stressinpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.stresser_&i)
                        and otptclm_id not in (select otptclm_id from work.stressinpt_&i)));
quit;

data flags.fl_17_&i._lg_&sample;
        set work.fl_17_&i._lg_&sample;
        keep &flkeep mrionly ctonly;
run;

/* create small measure with AMI exclusion */
data flags.fl_17_&i._sm_&sample;
        set work.fl_17_&i._lg_&sample;
        where expnsdt1-amie>180;
        keep &flkeep mrionly ctonly;
run;

%end;
%mend stress;
%stress;


/**** 18) pci ****/

%macro pci;
%do i=&minyear  %to &maxyear;

/* detect ER stays associated with stay (within 14 days) */

proc sql;
create table work.pcier_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.erdt
                from work.flcarotpt18_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where (R.erdt<=L.expnsdt1<=R.erdt+14) and R.erdt is not missing;
quit;

/* create large measure, with ER stays excluded */

proc sql;
create table work.fl_18_&i._lg_&sample /*(keep=&flkeep amie)*/ as
        select *
        from work.flcarotpt18_&i
        where (carclm_id is missing or (carclm_id not in (select carclm_id from work.pcier_&i)))
                and (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.pcier_&i)));
quit;

/* create small measure, with only amie patients stays excluded */

data flags.fl_18_&i._lg_&sample (keep=&flkeep) flags.fl_18_&i._sm_&sample (keep=&flkeep) ;
        set work.fl_18_&i._lg_&sample ;
        output flags.fl_18_&i._lg_&sample ;
        if expnsdt1-amie>180 then output flags.fl_18_&i._sm_&sample ;
run;


%end;
%mend pci;
 %pci;


/**** 19) head ****/

%macro head;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_19_&i._lg_&sample (keep=&flkeep) flags.fl_19_&i._sm_&sample (keep=&flkeep);
        set work.flcarotpt19_&i;
        output flags.fl_19_&i._lg_&sample;
        if index(otptdgns, ' 14') + index(otptdgns, ' 15') + index(otptdgns, ' 16') + index(otptdgns, ' 17') +
                index(otptdgns, ' 18') + index(otptdgns, ' 19') + index(otptdgns, ' 200') +  index(otptdgns, ' 201') + index(otptdgns, ' 202') +
                index(otptdgns, ' 203') + index(otptdgns, ' 204') + index(otptdgns, ' 205') + index(otptdgns, ' 206') + index(otptdgns, ' 207') +
                index(otptdgns, ' 208') + index(otptdgns, ' 230') + index(otptdgns, ' 231') + index(otptdgns, ' 232') + index(otptdgns, ' 233') + index(otptdgns, ' 234') +
                index(otptdgns, ' 235') + index(otptdgns, ' 236') + index(otptdgns, ' 237') + index(otptdgns, ' 238') + index(otptdgns, ' 239') +
                index(otptdgns, ' 33920 ') + index(otptdgns, ' 33921 ') + index(otptdgns, ' 33922 ') + index(otptdgns, ' 33943 ') +
                index(otptdgns, ' 3463') + index(otptdgns, ' 3466') + index(otptdgns, ' 4465') +
                index(otptdgns, ' 345') + index(otptdgns, ' 43') + index(otptdgns, ' 800') + index(otptdgns, ' 801') + index(otptdgns, ' 802') +
                index(otptdgns, ' 803') + index(otptdgns, ' 804') + index(otptdgns, ' 850') + index(otptdgns, ' 851') +
                index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') + index(otptdgns, ' 854') +
                index(otptdgns, ' 870') + index(otptdgns, ' 871') + index(otptdgns, ' 872') +
                index(otptdgns, ' 873') + index(otptdgns, ' 9590') + index(otptdgns, ' 910') + index(otptdgns, ' 920') +
                index(otptdgns, ' 921') + index(otptdgns, ' 7803') + index(otptdgns, ' 78097') +
                index(otptdgns, ' 781') + index(otptdgns, ' 7820') + index(otptdgns, ' 7845') +
                index(otptdgns, ' 79953') + index(otptdgns, ' V1254 ') + index(otptdgns, ' V10') +
                index(cardgns, ' 14') + index(cardgns, ' 15') + index(cardgns, ' 16') + index(cardgns, ' 17') +
                index(cardgns, ' 18') + index(cardgns, ' 19') + index(cardgns, ' 200') +  index(cardgns, ' 201') + index(cardgns, ' 202') +
                index(cardgns, ' 203') + index(cardgns, ' 204') + index(cardgns, ' 205') + index(cardgns, ' 206') + index(cardgns, ' 207') +
                index(cardgns, ' 208') + index(cardgns, ' 230') + index(cardgns, ' 231') + index(cardgns, ' 232') + index(cardgns, ' 233') + index(cardgns, ' 234') +
                index(cardgns, ' 235') + index(cardgns, ' 236') + index(cardgns, ' 237') + index(cardgns, ' 238') + index(cardgns, ' 239') +
                index(cardgns, ' 33920 ') + index(cardgns, ' 33921 ') + index(cardgns, ' 33922 ') + index(cardgns, ' 33943 ') +
                index(cardgns, ' 3463') + index(cardgns, ' 3466') + index(cardgns, ' 4465') +
                index(cardgns, ' 345') + index(cardgns, ' 43') + index(cardgns, ' 800') + index(cardgns, ' 801') + index(cardgns, ' 802') +
                index(cardgns, ' 803') + index(cardgns, ' 804') + index(cardgns, ' 850') + index(cardgns, ' 851') +
                index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') + index(cardgns, ' 854') +
                index(cardgns, ' 870') + index(cardgns, ' 871') + index(cardgns, ' 872') +
                index(cardgns, ' 873') + index(cardgns, ' 9590') + index(cardgns, ' 910') + index(cardgns, ' 920') +
                index(cardgns, ' 921') + index(cardgns, ' 7803') + index(cardgns, ' 78097') +
                index(cardgns, ' 781') + index(cardgns, ' 7820') + index(cardgns, ' 7845')  +
                index(otptdgns, ' 79953') + index(cardgns, ' V1254 ') + index(cardgns, ' V10') = 0
        then output flags.fl_19_&i._sm_&sample;
run;


%end;
%mend head;
 %head;


/**** 20) backscan ****/

%macro backscan;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_20_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt20_&i;
        output flags.fl_20_&i._lg_&sample;
run;

/* find first back pain  */
proc sql;
create table work.firstback_&i as
        select bene_id, min(backdt) format=date9. as firstback from (
                select bene_id, expnsdt1 as backdt
                from work.exbackscancar_&i
                union all
                select bene_id, rev_dt as backdt
                from work.exbackscanotpt_&i
                )
        where bene_id in (select bene_id from work.flcarotpt20_&i)
        group by bene_id;
quit;

/* create small measure with exclusion diagnoses and within 6 wk of first back pain */
proc sql;
create table flags.fl_20_&i._sm_&sample (keep=&flkeep firstback) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.firstback
        from work.flcarotpt20_&i as L
        inner join
        work.firstback_&i as R
        on L.bene_id=R.bene_id
        where index(otptdgns, ' 14') + index(otptdgns, ' 15') + index(otptdgns, ' 16') + index(otptdgns, ' 17') +
                index(otptdgns, ' 18') + index(otptdgns, ' 19') + index(otptdgns, ' 200') +  index(otptdgns, ' 201') + index(otptdgns, ' 202') +
                index(otptdgns, ' 203') + index(otptdgns, ' 204') + index(otptdgns, ' 205') + index(otptdgns, ' 206') + index(otptdgns, ' 207') +
                index(otptdgns, ' 208') + index(otptdgns, ' 230') + index(otptdgns, ' 231') + index(otptdgns, ' 232') + index(otptdgns, ' 233') + index(otptdgns, ' 234') +
                index(otptdgns, ' 235') + index(otptdgns, ' 236') + index(otptdgns, ' 237') + index(otptdgns, ' 238') + index(otptdgns, ' 239') +
                index(otptdgns, ' 80') + index(otptdgns, ' 81') + index(otptdgns, ' 82') + index(otptdgns, ' 83') + index(otptdgns, ' 850') +
                index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') +
                index(otptdgns, ' 854') + index(otptdgns, ' 86') + index(otptdgns, ' 905') + index(otptdgns, ' 906') + index(otptdgns, ' 907') +
                index(otptdgns, ' 908') + index(otptdgns, ' 909') + index(otptdgns, ' 92611 ') + index(otptdgns, ' 92612 ') + index(otptdgns, ' 929') +
                index(otptdgns, ' 952') + index(otptdgns, ' 958') + index(otptdgns, ' 959') + index(otptdgns, ' 3040')  + index(otptdgns, ' 3041') +
                index(otptdgns, ' 3042') + index(otptdgns, ' 3044') + index(otptdgns, ' 3054') + index(otptdgns, ' 3055') + index(otptdgns, ' 3056') + index(otptdgns, ' 3057') +
                index(otptdgns, ' 34460') + index(otptdgns, ' 7292') + index(otptdgns, ' 4210') + index(otptdgns, ' 4211') + index(otptdgns, ' 4219') +
                index(otptdgns, ' 038')  + index(otptdgns, ' 01') + index(otptdgns, ' 730')  + index(otptdgns, ' 7806') + index(otptdgns, ' 7830') +
                index(otptdgns, ' 7832') + index(otptdgns, ' 78079') + index(otptdgns, ' 7808') + index(otptdgns, ' 2859') +
                index(otptdgns, ' 72142')  + index(otptdgns, ' 72191') + index(otptdgns, ' 72270')  + index(otptdgns, ' 72273') + index(otptdgns, ' 7244') +
                index(cardgns, ' 14') + index(cardgns, ' 15') + index(cardgns, ' 16') + index(cardgns, ' 17') +
                index(cardgns, ' 18') + index(cardgns, ' 19') + index(cardgns, ' 200') +  index(cardgns, ' 201') + index(cardgns, ' 202') +
                index(cardgns, ' 203') + index(cardgns, ' 204') + index(cardgns, ' 205') + index(cardgns, ' 206') + index(cardgns, ' 207') +
                index(cardgns, ' 208') + index(cardgns, ' 230') + index(cardgns, ' 231') + index(cardgns, ' 232') + index(cardgns, ' 233') + index(cardgns, ' 234') +
                index(cardgns, ' 235') + index(cardgns, ' 236') + index(cardgns, ' 237') + index(cardgns, ' 238') + index(cardgns, ' 239')      +
                index(cardgns, ' 80') + index(cardgns, ' 81') + index(cardgns, ' 82') + index(cardgns, ' 83') + index(cardgns, ' 850') +
                index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') +
                index(cardgns, ' 854') + index(cardgns, ' 86') + index(cardgns, ' 905') + index(cardgns, ' 906') + index(cardgns, ' 907') +
                index(cardgns, ' 908') + index(cardgns, ' 909') + index(cardgns, ' 92611 ') + index(cardgns, ' 92612 ') + index(cardgns, ' 929') +
                index(cardgns, ' 952') + index(cardgns, ' 958') + index(cardgns, ' 959') + index(cardgns, ' 3040')  + index(cardgns, ' 3041') +
                index(cardgns, ' 3042') + index(cardgns, ' 3044') + index(cardgns, ' 3054') + index(cardgns, ' 3055') + index(cardgns, ' 3056') + index(cardgns, ' 3057') +
                index(cardgns, ' 34460') + index(cardgns, ' 7292') + index(cardgns, ' 4210') + index(cardgns, ' 4211') + index(cardgns, ' 4219') +
                index(cardgns, ' 038')  + index(cardgns, ' 01') + index(cardgns, ' 730')  + index(cardgns, ' 7806') + index(cardgns, ' 7830') +
                index(cardgns, ' 7832') + index(cardgns, ' 78079') + index(cardgns, ' 7808') + index(cardgns, ' 2859') +
                index(cardgns, ' 72142')  + index(cardgns, ' 72191') + index(cardgns, ' 72270')  + index(cardgns, ' 72273') + index(cardgns, ' 7244')
                =0 and expnsdt1-firstback<42;
quit;

%end;
%mend backscan;
 %backscan;


/**** 21) eeg ****/

%macro eeg;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_21_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt21_&i;
        output flags.fl_21_&i._lg_&sample;
run;

/* search for first seizure/convulsions  */
proc sql;
create table work.firstseiz_&i as
        select bene_id, min(seizdt) format=date9. as firstseiz from (
                select bene_id, expnsdt1 as seizdt
                from work.exeegcar_&i
                union all
                select bene_id, rev_dt as seizdt
                from work.exeegotpt_&i
                )
        where bene_id in (select bene_id from work.flcarotpt21_&i)
        group by bene_id;
quit;



/*merge and exclude those with prior/current seizure diagnoses */

proc sql;
create table flags.fl_21_&i._sm_&sample (keep=&flkeep) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.firstseiz
        from work.flcarotpt21_&i as L
        left join
        work.firstseiz_&i as R
        on L.bene_id=R.bene_id
        where  index(cardgns, ' 345') + index(cardgns, ' 7803') + index(cardgns, ' 7810')
        + index(otptdgns, ' 345') + index(otptdgns, ' 7803') + index(otptdgns, ' 7810')=0 and
        (firstseiz>expnsdt1 or firstseiz is missing);
quit;


%end;
%mend eeg;
 %eeg;

/**** 22) ctdsync ****/

%macro ctdsync;
%do i=&minyear  %to &maxyear;

/* create measures from initial flag, with exclusions */
data flags.fl_22_&i._lg_&sample (keep=&flkeep) flags.fl_22_&i._sm_&sample (keep=&flkeep);
        set work.flcarotpt22_&i;
        output flags.fl_22_&i._lg_&sample;
        if expnsdt1-strktiae<0 and
                index(otptdgns, ' 430') + index(otptdgns, ' 431') + index(otptdgns, ' 43301') + index(otptdgns, ' 43311') +
                index(otptdgns, ' 43321') + index(otptdgns, ' 43331')  + index(otptdgns, ' 43381') + index(otptdgns, ' 43391') +
                index(otptdgns, ' 43400') + index(otptdgns, ' 43401') + index(otptdgns, ' 43410') + index(otptdgns, ' 43411') +
                index(otptdgns, ' 43490') + index(otptdgns, ' 43491')  + index(otptdgns, ' 4350') +
                index(otptdgns, ' 4350') + index(otptdgns, ' 4351') + index(otptdgns, ' 4353') + index(otptdgns, ' 4358') +
                index(otptdgns, ' 4359')+ index(otptdgns, ' 436') + index(otptdgns, ' 99702') +
                index(otptdgns, ' 781') + index(otptdgns, ' 7820') + index(cardgns, ' 7845')  + index(otptdgns, ' V1254') +
                index(otptdgns, ' 3623') + index(otptdgns, ' 36284') +
                index(cardgns, ' 430') + index(cardgns, ' 431') + index(cardgns, ' 43301') + index(cardgns, ' 43311') +
                index(cardgns, ' 43321') + index(cardgns, ' 43331')  + index(cardgns, ' 43381') + index(cardgns, ' 43391') +
                index(cardgns, ' 43400') + index(cardgns, ' 43401') + index(cardgns, ' 43410') + index(cardgns, ' 43411') +
                index(cardgns, ' 43490') + index(cardgns, ' 43491')  + index(cardgns, ' 4350') +
                index(cardgns, ' 4350') + index(cardgns, ' 4351') + index(cardgns, ' 4353') + index(cardgns, ' 4358') +
                index(cardgns, ' 4359') + index(cardgns, ' 436') + index(cardgns, ' 99702') +
                index(cardgns, ' 781')  + index(cardgns, ' 7820') + index(cardgns, ' 7845')  + index(cardgns, ' V1254') +
                index(cardgns, ' 3623') + index(cardgns, ' 36284') =0
        then output flags.fl_22_&i._sm_&sample;
run;


%end;
%mend ctdsync;
 %ctdsync;


/**** 23) ctdasym ****/

%macro ctdsync;
%do i=&minyear  %to &maxyear;

/* create measures from initial flag, with exclusions */
data flags.fl_23_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt23_&i;
run;


/* detect ER stays associated with stay (within 14 days) */

proc sql;
create table work.ctdasymer_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.erdt
                from work.flcarotpt23_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where (R.erdt<=L.expnsdt1<=R.erdt+14) and R.erdt is not missing;
quit;


/* detect inpt stays containing ctdasym or 14 days prior to ctdasyms */

proc sql;
create table work.ctdasyminpt_&i as
        select  coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.admsndt, R.dschrgdt
                from work.flcarotpt23_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+14) and R.dschrgdt is not missing));
quit;

/* create small measure by excluding inpatient and er associated ctdasymes and non-AMI patients */

proc sql;
create table flags.fl_23_&i._sm_&sample /*(keep=&flkeep)*/ as
        select * from work.flcarotpt23_&i
        where (carclm_id is missing or (carclm_id not in (select carclm_id from work.ctdasymer_&i)
                        and carclm_id not in (select carclm_id from work.ctdasyminpt_&i))) and
                (otptclm_id is missing or (otptclm_id not in (select otptclm_id from work.ctdasymer_&i)
                        and otptclm_id not in (select otptclm_id from work.ctdasyminpt_&i)));
quit;

%end;
%mend ctdsync;
 %ctdsync;


/**** 24) cea ****/

%macro cea;
%do i=&minyear  %to &maxyear;



/* detect ER stays associated with stay (within 14 days) */

proc sql;
create table work.ceaer_&i as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.erdt
                from work.flcarotpt24_&i as L
                left join
                flags.er_&i._&sample as R
                on L.bene_id=R.bene_id
                where (R.erdt<=L.expnsdt1<=R.erdt+14) and R.erdt is not missing;
quit;


/* create large measure by excluding inpatient and er associated cea */

proc sql;
create table flags.fl_24_&i._lg_&sample (keep=&flkeep sex) as
        select * from work.flcarotpt24_&i
        where (carclm_id is missing or carclm_id not in (select carclm_id from work.ceaer_&i)) and
                (otptclm_id is missing or otptclm_id not in (select otptclm_id from work.ceaer_&i)) ;
quit;

/*create small measure by restricting to women only */
proc sql;
create table flags.fl_24_&i._sm_&sample (keep=&flkeep) as
        select * from flags.fl_24_&i._lg_&sample
        where sex='2';
quit;

%end;
%mend cea;
 %cea;



/**** 25) homocy ****/

%macro homocy;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_25_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt25_&i;
        output flags.fl_25_&i._lg_&sample;
run;

/* search for folate/b12 testing   */
proc sql;
create table work.firstfb12_&i as
        select bene_id, min(fb12dt) format=date9. as firstfb12 from (
                select bene_id, expnsdt1 as fb12dt
                from work.exhomocycar_&i
                union all
                select bene_id, rev_dt as fb12dt
                from work.exhomocyotpt_&i
                )
        where bene_id in (select bene_id from work.flcarotpt25_&i)
        group by bene_id;
quit;



/*merge and exclude those with prior folate/b12 testing or current deficiency diagnoses */

proc sql;
create table flags.fl_25_&i._sm_&sample (keep=&flkeep) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.firstfb12
        from work.flcarotpt25_&i as L
        left join
        work.firstfb12_&i as R
        on L.bene_id=R.bene_id
        where  index(cardgns, ' 2662') + index(cardgns, ' 2704') + index(cardgns, ' 2810') + index(cardgns, ' 2811')+
        index(cardgns, ' 2812')+ index(cardgns, ' 2859') + index(otptdgns, ' 2662') + index(otptdgns, ' 2704') +
        index(otptdgns, ' 2810') + index(otptdgns, ' 2811')+ index(otptdgns, ' 2812')+ index(otptdgns, ' 2859')=0 and
        (firstfb12>expnsdt1 or firstfb12 is missing);
quit;


%end;
%mend homocy;
 %homocy;



/**** 26) hyperco ****/

%macro hyperco;
/*note that this measure especially requires deduplication */
%do i=&minyear  %to &maxyear;

/* merge dvts/pes, calculate first date*/
proc sql;
        create table work.dvt_&i as
                select distinct bene_id, dvtdt, min(dvtdt) format=date9. as firstdvt from
                (select distinct bene_id, expnsdt1 format=date9. as dvtdt
                        from work.exhypercocar_&i
                union
                select distinct bene_id, rev_dt format=date9. as dvtdt
                        from work.exhypercootpt_&i)
                where bene_id in (select bene_id from work.flcarotpt26_&i)
                group by bene_id;
quit;

/*merge in dvt dates and keep hypercoag tests within 30 days after */

proc sql;
        create table work.dvthyperco_&i as
                select *
                from
                work.flcarotpt26_&i as L
                inner join
                work.dvt_&i as R
                on L.bene_id=R.bene_id
                where expnsdt1-30 <= dvtdt <= expnsdt1  and dvtdt is not missing;
quit;

/* create large measure from above */
proc sql;
        create table flags.fl_26_&i._lg_&sample as
        select unique * from
        work.dvthyperco_&i (keep=&flkeep);
quit;

/*keep only those with not prior dvt >90 days */
proc sql;
        create table work.dvthyperco2_&i as
                select *
                from
                work.dvthyperco_&i
                where firstdvt> expnsdt1-90 and firstdvt is not missing;
quit;

/* create small measure from above */
proc sql;
        create table flags.fl_26_&i._sm_&sample as
        select unique * from
        work.dvthyperco2_&i (keep=&flkeep);
quit;


%end;
%mend hyperco;
 %hyperco;


/**** 27) spinj ****/

%macro spinj;
%do i=&minyear  %to &maxyear;
/* detect inpt stays containing spinj or 14 days prior to spinj */

proc sql;
create table work.spinjinpt_&i as
        select  coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.admsndt, R.dschrgdt
                from work.flcarotpt27_&i as L
                left join
                out.medpar&i._&sample  as R
                on L.bene_id = R.bene_id
                where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
                or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+14) and R.dschrgdt is not missing));
quit;


/* prep large measure by excluding inpatient associated spinjs */

proc sql;
create table work.fl_27_&i._lg_&sample as
        select * from work.flcarotpt27_&i
        where (carclm_id is missing or carclm_id not in (select carclm_id from work.spinjinpt_&i)) and
                (otptclm_id is missing or otptclm_id not in (select otptclm_id from work.spinjinpt_&i));
quit;


/* create large measure from above and small measure by excluding radiculopathy associated spinjs */
data flags.fl_27_&i._lg_&sample (keep=&flkeep) flags.fl_27_&i._sm_&sample (keep=&flkeep);
        set work.fl_27_&i._lg_&sample;
        output flags.fl_27_&i._lg_&sample;
        if index(cardgns, ' 72142') + index(cardgns, ' 72191') + index(cardgns, ' 72270') +
        index(cardgns, ' 72273') + index(cardgns, ' 7243')+ index(cardgns, ' 7244') +
        index(otptdgns, ' 72142') + index(otptdgns, ' 72191') + index(otptdgns, ' 72270') +
        index(otptdgns, ' 72273') + index(otptdgns, ' 7243')+ index(otptdgns, ' 7244') =0
        then output flags.fl_27_&i._sm_&sample;
run;
%end;
%mend spinj;
 %spinj;


/**** 28) t3 ****/

%macro t3;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_28_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt28_&i;
run;

/* small measure is identical */
data flags.fl_28_&i._sm_&sample (keep=&flkeep);
        set work.flcarotpt28_&i;
run;

%end;
%mend t3;
 %t3;


/**** 29) plant ****/

%macro plant;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_29_&i._lg_&sample (keep=&flkeep);
        set work.flcarotpt29_&i;
run;

/* find first foot pain diagnosis */
proc sql;
create table work.firstplant_&i as
        select bene_id, min(plantdt) format=date9. as firstplant from (
                select bene_id, expnsdt1 as plantdt
                from work.explantcar_&i
                union all
                select bene_id, rev_dt as plantdt
                from work.explantotpt_&i
                )
        where bene_id in (select bene_id from work.flcarotpt29_&i)
        group by bene_id;
quit;


/* restrict narrow measure to within two weeks */
proc sql;
create table flags.fl_29_&i._sm_&sample (keep=&flkeep firstplant) as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.firstplant
        from work.flcarotpt29_&i as L
        inner join
        work.firstplant_&i as R
        on L.bene_id=R.bene_id
        where expnsdt1-firstplant<14;
quit;


%end;
%mend plant;
 %plant;



/**** 30) vitd ****/

%macro vitd;
%do i=&minyear  %to &maxyear;

/* create large measure from initial flag */
data flags.fl_30_&i._lg_&sample (keep=&flkeep cardgns otptdgns);
        set work.flcarotpt30_&i;
run;

/* combine carrier and otpt hypercalemia potential exclusions */

proc sql;
create table work.vitdhica_&i as
        select unique bene_id, expnsdt1 format=date9. as hicadt from (
                select bene_id, expnsdt1
                from work.exvitdcar_&i
                union all
                select bene_id, rev_dt format=date9. as expnsdt1
                from work.exvitdotpt_&i
                )
        where bene_id in (select bene_id from work.flcarotpt30_&i)
        ;
quit;


/* detect tests within 30 days of hypercalcemia diagnosis for exclusion*/
proc sql;
create table work.vitdhica2_&i(keep=&flkeep)  as
        select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.hicadt
        from work.flcarotpt30_&i as L
        inner join
        work.vitdhica_&i as R
        on L.bene_id=R.bene_id
        where hicadt< expnsdt1 < hicadt+30 and hicadt is not missing;
quit;

/* restrict narrow measure based on diagnoses and excluding tests in above dataset */
proc sql;
create table flags.fl_30_&i._sm_&sample (keep=&flkeep) as
        select * from  work.flcarotpt30_&i
        where index(cardgns, ' 135') + index(cardgns, ' 01') + index(cardgns, ' 173') + index(cardgns, ' 1890') +
                index(cardgns, ' 1891')+ index(cardgns, ' 188') + index(cardgns, ' 174') + index(cardgns, ' 175') + index(cardgns, ' 1830') +
                index(cardgns, ' 200') + index(cardgns, ' 201') + index(cardgns, ' 202') + index(cardgns, ' 203') + index(cardgns, ' 204') +
                index(cardgns, ' 205') +  index(cardgns, ' 206') +  index(cardgns, ' 207') +  index(cardgns, ' 208') +
                index(otptdgns, ' 135') + index(otptdgns, ' 01') + index(otptdgns, ' 173') + index(otptdgns, ' 1890') +
                index(otptdgns, ' 1891')+ index(otptdgns, ' 188') + index(otptdgns, ' 174') + index(otptdgns, ' 175') + index(otptdgns, ' 1830') +
                index(otptdgns, ' 200') + index(otptdgns, ' 201') + index(otptdgns, ' 202') + index(otptdgns, ' 203') + index(otptdgns, ' 204') +
                index(otptdgns, ' 205') +  index(otptdgns, ' 206') +  index(otptdgns, ' 207') +  index(otptdgns, ' 208') =0
                and (carclm_id is missing or carclm_id not in (select carclm_id from  work.vitdhica2_&i)) and
                (otptclm_id is missing or otptclm_id not in (select otptclm_id from  work.vitdhica2_&i));
quit;

%end;
%mend vitd;
 %vitd;


/**** 31) rhcath ****/

/*create small measure by looking for rhcaths that occurred during the (inclusion criteria selected) inpatient stays */

%macro rhcath;
%do i=&minyear  %to &maxyear;

/* merge rhcath patients with ICU medical drg patients */

proc sql;
create table work.fl_31_&i._lg_&sample (keep=&flkeep cardgns otptdgns ) as
        select  coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.hcpcs_cd, L.cardgns, L.otptdgns, L.flag, L.subflag, L.otptclm_id, L.expnsdt1, R.admsndt, R.dschrgdt
                from work.flcarotpt31_&i as L
                inner join
                work.exrhcathmedpar_&i  as R
                on L.bene_id = R.bene_id
                where (R.admsndt <= L.expnsdt1 <= R.dschrgdt) and  R.admsndt is not missing;
quit;

/* create measures by restricting above dataset by diagnosis */

data   flags.fl_31_&i._lg_&sample (keep=&flkeep)   flags.fl_31_&i._sm_&sample (keep=&flkeep) ;
        set work.fl_31_&i._lg_&sample;
        output flags.fl_31_&i._lg_&sample;
        if index(cardgns, ' 4233') + index(cardgns, ' 4160') + index(cardgns, ' 4162') + index(cardgns, ' 4168') +
                index(cardgns, ' 4169')+ index(cardgns, ' V728') +
                index(otptdgns, ' 4233') + index(otptdgns, ' 4160') + index(otptdgns, ' 4162') + index(otptdgns, ' 4168') +
                index(otptdgns, ' 4169')+ index(otptdgns, ' V728') =0
                then output flags.fl_31_&i._sm_&sample;
run;


%end;
%mend rhcath;
 %rhcath;

