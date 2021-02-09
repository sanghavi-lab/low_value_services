* Specifying input and output directory;
%macro dir;
        *output directory for low value service flag datasets;
        libname flags '/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/flags';
        *output directory for analysis datasets;
        libname lvs8 '/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/8lvs';
        libname out '/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out';
        libname ori '/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out';
        libname dat '/disk/agedisk3/medicare.work/newhouse-DUA28483/linding/data';

        %do i=2006 %to 2014;
        *input directory for claims;
        libname bsf&i "/disk/aging/medicare/data/&sample.pct/bsf/&i" access=readonly;
        libname car&i "/disk/aging/medicare/data/&sample.pct/car/&i" access=readonly;
        libname otpt&i "/disk/aging/medicare/data/&sample.pct/op/&i" access=readonly;
        libname mpar&i "/disk/aging/medicare/data/&sample.pct/med/&i" access=readonly;
        libname bet&i "/disk/nber10/data/betos/&i" access=readonly;
        libname clm&i ="/disk/aging/medicare/data/&sample.pct/bsf/&i" access=readonly;
        %end;

        options ls=120 nofmterr;
%mend dir;


*specifying macros for creating new denominator for top 8 low-value services;
*these macros are set up to extract excluded claims from the flagged low-value services including backscan, head, and spinj;

%macro denomm;
/* Some macros */
        /*number of measures */
        %let numflags=3;

        /*minimum year of searching */
        %let minyear=2007;

        /*maximum year of searching*/
        %let maxyear=2014;

        /*abbreviated names of the measures*/
        %let allflags='backscan','head','spinj';

        /*variables to keep at different steps*/
        %let carkeep=  bene_id clm_id hcpcs_cd expnsdt1 bene_dob sex dgnsall cncrprse chrnkdne chrnkidn ischmche strktiae cncrclre osteopre amie hypoth;
        %let otptkeep= bene_id clm_id hcpcs_cd rev_dt   bene_dob sex dgnsall cncrprse chrnkdne chrnkidn ischmche strktiae cncrclre osteopre amie hypoth;
        %let flkeep= bene_id hcpcs_cd expnsdt1 carclm_id otptclm_id flag;

        /*names of output datasets */
        
        %let workflcar=denom.flcar1_&i denom.flcar2_&i denom.flcar3_&i;
        %let workflotpt=denom.flotpt1_&i denom.flotpt2_&i denom.flotpt3_&i;

/*******************************************************/
/* Assign procedure and "condition" codes for each flag*/
/*******************************************************/

%macro flagcodes;
/* Assign baseline detection codes for each flag*/
         %do i=&minyear %to &maxyear ;
                /* procedure codes for detection*/
                %let prcd1= in ('72010', '72020', '72052', '72100', '72110', '72114', '72120', '72200', '72202', '72220',    '72131', '72132', '72133', '72141', '72142', '72146', '72147', '72148', '72149', '72156', '72157', '72158'); /*backscan*/
                %let prcd2= in ('70450', '70460', '70470', '70551', '70552', '70553') ; /*head*/
                %let prcd3= in('62311', '64483', '20552', '20553', '64493', '64475'); /*spinj*/
                                                '72131', '72132', '72133', '72141', '72142', '72146', '72147', '72148', '72149', '72156', '72157', '72158'); /*backscan*/
                /*condition codes for baseline exclusion/inclusion criteria */
                 %let cond1= index(dgnsall, ' 7213 ') + index(dgnsall, ' 72190 ') + index(dgnsall, ' 72210 ') + index(dgnsall, ' 72252 ') +
                                        index(dgnsall, ' 7226') + index(dgnsall, ' 72293 ') + index(dgnsall, ' 72402 ') + index(dgnsall, ' 7242') +
                                        index(dgnsall, ' 7243') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') + index(dgnsall, ' 72470 ') +
                                        index(dgnsall, ' 72471 ') + index(dgnsall, ' 72479 ') + index(dgnsall, ' 7385 ') + index(dgnsall, ' 7393 ') +
                                        index(dgnsall, ' 7394 ') + index(dgnsall, ' 846') + index(dgnsall, ' 8472')
                                        >0;  /*backscan*/
                 %let cond2= index(dgnsall, ' 30781 ') + index(dgnsall, ' 339') + index(dgnsall, ' 346') + index(dgnsall, ' 7840')> 0  and
                                         index(dgnsall, ' 33920 ') + index(dgnsall, ' 33921 ') + index(dgnsall, ' 33922 ') + index(dgnsall, ' 33943 ') = 0; /*head*/

                 %let cond3= index(dgnsall, ' 7213') + index(dgnsall, ' 72142') + index(dgnsall, ' 72190') + index(dgnsall, ' 72191') + index(dgnsall, ' 72210') + index(dgnsall, ' 7222') +
                                        index(dgnsall, ' 72252') + index(dgnsall, ' 7226') + index(dgnsall, ' 72270') + index(dgnsall, ' 72273') + index(dgnsall, ' 72280') +
                                        index(dgnsall, ' 72283') + index(dgnsall, ' 72293') + index(dgnsall, ' 72400') + index(dgnsall, ' 72402') + index(dgnsall, ' 72403') +
                                        index(dgnsall, ' 7242') + index(dgnsall, ' 7243') + index(dgnsall, ' 7244') + index(dgnsall, ' 7245') + index(dgnsall, ' 7246') +
                                        index(dgnsall, ' 72470') + index(dgnsall, ' 72471') + index(dgnsall, ' 72479') + index(dgnsall, ' 7384') + index(dgnsall, ' 7385') +
                                        index(dgnsall, ' 7393') + index(dgnsall, ' 7394') + index(dgnsall, ' 75612') + index(dgnsall, ' 8460') + index(dgnsall, ' 8461') +
                                        index(dgnsall, ' 8462') + index(dgnsall, ' 8463') + index(dgnsall, ' 8468') + index(dgnsall, ' 8469') + index(dgnsall, ' 8472') > 0    ; /*spinj*/
              

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

%mend denomm;
