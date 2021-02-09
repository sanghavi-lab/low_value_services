*Part 1;
**********************************;
*Obtain carrier, outpatient, and MedPAR claims that should be excluded from denominators for cerv, pth;
*If patient has any of the above claims in each year (pth), in each year and the previous year(cerv), then patient will not qualify to be in the denominator;
*Cerv exclusion claims contains diagnosis of cervical cancer or dysplasia, female genital cancers, abnormal Papanicolaou findings, or human papillomavirus positivity;
*Pth exclusion claims contains diagnosis of hypercalcemia;
*Part 2;
**********************************;
*Obtain chronic condition indicators for strokes and TIA to define ctdasym denominators;
*If patient's date on the ccw indicator is earlier than the beginning of the year, the patient does not qualify to be in the denominator for ctdasym within that year;


%let sample= 20;
%let minyear=2007;
%let maxyear=2014;

%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/denom/denommacros.sas";
%denomm;
%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/denom/dir.sas";
%dir;

*part 1;
*Identify exlusion claims in the carrier claims;
%macro excludecar;
%let expnsdt1=expnsdt1;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id expnsdt1;
        %let excar= denom.ercar_&i (keep=&basevars)
                                denom.excervcar_&i (keep=&basevars)
                                denom.excncrpthcar_&i (keep=&basevars)
                                denom.expthcar_&i (keep=&basevars)
                                denom.exrhinoctcar_&i (keep=&basevars)
                                denom.exbackscancar_&i (keep=&basevars);

        data &excar;
                set prach.car&i._&sample (keep=bene_id expnsdt1 hcpcs_cd dgnsall betos chrnkdne chrnkidn);

                /*ER visits */
                        if  hcpcs_cd in ('99281', '99282', '99283', '99284', '99285') then output denom.ercar_&i;

                /*Cervical cancer, abnormal pap etc. */
                        if index(dgnsall, ' 180') + index(dgnsall, ' 184') + index(dgnsall, ' 2190') + index(dgnsall, ' 2331') +
                        index(dgnsall, ' 2332') + index(dgnsall, ' 2333') + index(dgnsall, ' 6221') + index(dgnsall, ' 7950') +
                        index(dgnsall, ' 7951') + index(dgnsall, ' V1040 ') + index(dgnsall, ' V1041') + index(dgnsall, ' V1322') > 0
                        then output  denom.excervcar_&i;

                /*Dialysis for cncr, pth */
                        if betos in('P9A', 'P9B') & expnsdt1-chrnkdne>0 then output denom.excncrpthcar_&i;


                /*PTH hypercalcemia for ckd patients */
                        if index(dgnsall, ' 27542 ')>0 & chrnkidn in(1,3)
                        then output denom.expthcar_&i;

                /* Sinusitis diagnosis for rhinoct */
                        if index(dgnsall, ' 461') + index(dgnsall, ' 473') >0
                        then output denom.exrhinoctcar_&i;

                /* back pain diagnosis for backscan*/
                        if index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                        index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 72403 ') + index(dgnsall, ' 7242') +
                        index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                        index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                        index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472') >0
                        then output denom.exbackscancar_&i;

        run;
%end;
%mend excludecar;
 %excludecar;

*Identify exlusion claims in the outpatient claims;
%macro excludeotpt;
        %let expnsdt1 = rev_dt;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id rev_dt chrnkidn;
        %let exotpt= denom.erotpt_&i (keep=&basevars rev_cntr)
                                 denom.excervotpt_&i (keep=&basevars)
                                 denom.excncrpthotpt_&i (keep=&basevars)
                                 denom.expthotpt_&i (keep=&basevars)
                                 denom.exrhinoctotpt_&i (keep=&basevars )
                                 denom.exbackscanotpt_&i (keep=&basevars );

        data &exotpt;
        set prach.otpt&i._&sample (keep=bene_id rev_dt hcpcs_cd rev_cntr dgnsall betos chrnkdne chrnkidn );

                /*ER visits */
                        if hcpcs_cd in ('99281', '99282', '99283', '99284', '99285')
                        or rev_cntr in ('0450', '0451', '0452', '0456', '0459')
                        or rev_cntr='0981' then output denom.erotpt_&i;

                /*Cervical cancer, abnormal pap etc. */
                        if index(dgnsall, ' 180') + index(dgnsall, ' 184') + index(dgnsall, ' 2190') + index(dgnsall, ' 2331') +
                        index(dgnsall, ' 2332') + index(dgnsall, ' 2333') + index(dgnsall, ' 6221') + index(dgnsall, ' 7950') +
                        index(dgnsall, ' 7951') + index(dgnsall, ' V1040 ') + index(dgnsall, ' V1041') + index(dgnsall, ' V1322') > 0
                        then output  denom.excervotpt_&i;

                /*Dialysis for cncr, pth */
                        if betos in('P9A', 'P9B') & rev_dt-chrnkdne>0 then output denom.excncrpthotpt_&i;

                /*PTH hypercalcemia for ckd patients */
                        if index(dgnsall, ' 27542 ')>0 & chrnkidn in(1,3)
                        then output denom.expthotpt_&i;

                /* Sinusitis diagnosis for rhinoct */
                        if index(dgnsall, ' 461') + index(dgnsall, ' 473') >0
                        then output denom.exrhinoctotpt_&i;

                /* back pain diagnosis for backscan*/
                        if index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                         index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 7242') +
                         index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                         index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                         index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472')  >0
                        then output denom.exbackscanotpt_&i;

        run;
 %end;
%mend excludeotpt;
 %excludeotpt;

*Identify exlusion claims in the MedPAR claims;
%macro excludemedpar;

%do i=&minyear  %to &maxyear;
        %let basevars = bene_id admsndt;
        %let exmedpar= denom.ermedpar_&i (keep=&basevars) denom.exrhcathmedpar_&i (keep=&basevars dschrgdt drg_cd icuindcd);

        data &exmedpar;
        set prach.medpar&i._&sample (keep=bene_id admsndt type_adm src_adms er_amt dschrgdt icuindcd drg_cd);

                /*ER visits */
                        if type_adm='1' | src_adms='7' | er_amt >0 then output denom.ermedpar_&i;

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
                        then output denom.exrhcathmedpar_&i;

                        if  mdy(10,1,2007)<=dschrgdt and mdy(1,1,&i)<=dschrgdt and icuindcd ~='' and not((drg_cd>='001' & drg_cd <='003') | (drg_cd>='005' & drg_cd <='008') | drg_cd ='010' | (drg_cd>='020' & drg_cd<='033') | (drg_cd>='037' & drg_cd<='042')|
                        (drg_cd>='113' & drg_cd<='117') | (drg_cd>='129' & drg_cd <='139') | (drg_cd>='163' & drg_cd <='168') |( drg_cd>='215'  & drg_cd<='245')|
                        (drg_cd>='252' & drg_cd<='264') | (drg_cd>='266' & drg_cd <='267') | (drg_cd>='326' & drg_cd <='358') | (drg_cd>='405' & drg_cd<='425') | (drg_cd>='453' & drg_cd <='520') |
                        (drg_cd>='570' & drg_cd<='585') | (drg_cd>='614' & drg_cd <='630') | (drg_cd>='652' & drg_cd<='675') | (drg_cd>='707' & drg_cd <='718') |
                        (drg_cd>='820' & drg_cd<='830') | (drg_cd>='853' & drg_cd <='858') | (drg_cd='876') | (drg_cd>='901' & drg_cd<='909') |
                        (drg_cd>='927' & drg_cd<='929') | (drg_cd>='939' & drg_cd <='941') | (drg_cd>='955' & drg_cd<='959') | (drg_cd>='969' & drg_cd<='970') |
                        (drg_cd>='981' & drg_cd <='989'))

                        then output denom.exrhcathmedpar_&i;

        run;
 %end;
%mend excludemedpar;
 %excludemedpar;

*Combine cerv exlusion claims;
%macro cerv;

%do i=2007 %to 2014;

data cervcar&i;
set denom.excervcar_&i(keep=bene_id);
year=&i;
run;
data cervotpt&i;
set denom.excervotpt_&i(keep=bene_id);
year=&i;
run;

data cerv&i.;
set cervcar&i cervotpt&i;
cerv_delete=1;
run;

proc sort data=cerv&i. nodupkeys;
by bene_id year;
run;

%end;
data denom.cerv_ex;
set cerv2007
    cerv2008
    cerv2009
    cerv2010
    cerv2011
    cerv2012
    cerv2013
    cerv2014;
run;
%mend cerv;

%cerv;

*Combine pth exlusion claims;
%macro hica;

%do i=2007 %to 2014;

data pthcar&i;
set denom.expthcar_&i(keep=bene_id);
year=&i;
run;
data pthotpt&i;
set denom.expthotpt_&i(keep=bene_id);
year=&i;
run;

data hica&i.;
set pthcar&i pthotpt&i;
hica=1;
run;

proc sort data=hica&i. nodupkeys;
by bene_id year;
run;

%end;
data denom.hica;
set hica2007
    hica2008
    hica2009
    hica2010
    hica2011
    hica2012
    hica2013
    hica2014;
run;
%mend hica;

%hica;

*part 2;
*Get ccw indicator for stroke;
%macro stroke;

%do i=2007 %to 2014;

data denom.stroke&i.;
  set bsf&i..bsfcc&i.(keep=bene_id strktiae);
  year=&i.;
run;

data denom.stroke&i.;
set denom.stroke&i;
format STRKTIAE date9.;
stroke=(not missing(strktiae) and strktiae < mdy(1, 1, &i));
no_stroke=1-stroke;
run;

%end;

data denom.stroke;
set denom.stroke2007
    denom.stroke2008
    denom.stroke2009
    denom.stroke2010
    denom.stroke2011
    denom.stroke2012
    denom.stroke2013
    denom.stroke2014;
run;

%mend stroke;
%stroke;

proc sort data=denom.stroke nodupkeys;
by bene_id year;
run;
