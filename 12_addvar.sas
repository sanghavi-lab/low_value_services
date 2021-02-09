
/*Add HCC,CCW, and Zip-level variables to the low value service sample and create separate samples for each service.*/


%let sample= 20;
%include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
/* Libname Statements */
%dir;

 %macro comb(yr,hcc);
    *zip-level variables;
    data z0; set dat.benezip&yr;
 
         proc sort; by bene_id;
    *hcc scores;
    data hcc0; set dat.&hcc(keep=bene_id score_community hcc1--hcc177);

         rename score_community = hcc_t1;

         proc sort; by bene_id;
     *ccw variables;    
     data ccw00; set bsf&yr..bsfcc20&yr;
     
       %macro ccw(var,newvar);
            if &var >0 and &var < mdy(1,1,20&yr) then &newvar =1; else &newvar=0;
       %mend;
              %ccw(ALZHE,        ccw_alzh_demen);
              %ccw(ALZHE,        ccw_alzh);
              %ccw(AMIE,         ccw_ami);
              %ccw(ANEMIA_EVER,  ccw_anemia);
              %ccw(ASTHMA_EVER,  ccw_asthma);
              %ccw(ATRIALFE,     ccw_atrial_fib);
              %ccw(CNCRBRSE,     ccw_cancer_breast);
              %ccw(CNCRCLRE,     ccw_cancer_colorectal);
              %ccw(CNCENDME,     ccw_cancer_endometrial);
              %ccw(CNCRLNGE,     ccw_cancer_lung);
              %ccw(CNCRPRSE,     ccw_cancer_prostate);
              %ccw(CATARCTE,     ccw_cataract);
              %ccw(CHFE,         ccw_chf);
              %ccw(CHRNKDNE,     ccw_chronickidney);
              %ccw(COPDE,        ccw_copd);
              %ccw(DEPRSSNE,     ccw_depression);
              %ccw(DIABTESE,     ccw_diabetes);
              %ccw(GLAUCMAE,     ccw_glaucoma);
              %ccw(HIPFRACE,     ccw_hip_fracture);
              %ccw(HYPERL_EVER,  ccw_hyperl);
              %ccw(HYPERP_EVER,  ccw_hyperp);
              %ccw(HYPERT_EVER,  ccw_hypert);
              %ccw(HYPOTH_EVER,  ccw_hypoth);
              %ccw(ISCHMCHE,     ccw_ischemicheart);
              %ccw(OSTEOPRE,     ccw_osteoporosis);
              %ccw(RA_OA_E,      ccw_ra_oa);
              %ccw(STRKTIAE,     ccw_stroke_tia);
        
        data ccw0; set ccw00;
       
        %let ccw_vars = ccw_alzh_demen     ccw_alzh            ccw_ami        ccw_anemia       ccw_asthma      ccw_atrial_fib
                        ccw_cancer_breast  ccw_cancer_colorectal  ccw_cancer_endometrial  
                        ccw_cancer_lung    ccw_cancer_prostate    ccw_cataract
                        ccw_chf            ccw_chronickidney   ccw_copd       ccw_depression   ccw_diabetes    ccw_glaucoma
                        ccw_hip_fracture   ccw_hyperl          ccw_hyperp     ccw_hypert       ccw_hypoth      ccw_ischemicheart
                        ccw_osteoporosis   ccw_ra_oa           ccw_stroke_tia ;
         *calculate total number of chronic conditions;
         ccw_total = sum(ccw_alzh_demen,       ccw_alzh,           ccw_ami,                ccw_anemia,              ccw_asthma,
                         ccw_atrial_fib,       ccw_cancer_breast,  ccw_cancer_colorectal,  ccw_cancer_endometrial,  ccw_cancer_lung,
                         ccw_cancer_prostate,  ccw_cataract,       ccw_chf,                ccw_chronickidney,       ccw_copd,
                         ccw_depression,       ccw_diabetes,       ccw_glaucoma,           ccw_hip_fracture,        ccw_hyperl,
                         ccw_hyperp,           ccw_hypert,         ccw_hypoth,             ccw_ischemicheart,       ccw_osteoporosis,     
                         ccw_ra_oa,            ccw_stroke_tia );

            if ccw_total = 2 then ccw_eq2=1; else ccw_eq2=0;
            if ccw_total = 3 then ccw_eq3=1; else ccw_eq3=0;
            if ccw_total = 4 then ccw_eq4=1; else ccw_eq4=0;
            if ccw_total = 5 then ccw_eq5=1; else ccw_eq5=0;
            if ccw_total = 6 then ccw_eq6=1; else ccw_eq6=0;
            if ccw_total = 7 then ccw_eq7=1; else ccw_eq7=0;
            if ccw_total = 8 then ccw_eq8=1; else ccw_eq8=0; 

            if ccw_total >=6 then ccw_6up=1; else ccw_6up=0;
            if ccw_total >=9 then ccw_9up=1; else ccw_9up=0;
 
            keep bene_id &ccw_vars ccw_total ccw_eq2 ccw_eq3 ccw_eq4 ccw_eq5 ccw_eq6 ccw_eq7 ccw_eq8 ccw_6up ccw_9up;
        
            proc sort; by bene_id;

    data com&yr; merge z0(in=ok) hcc0 ccw0; by bene_id;

         if ok;
              
   %mend;
   %comb(2007, hcc2006);
   %comb(2008, hcc2007);
   %comb(2009, hcc2008);
   %comb(2010, hcc2009);
   %comb(2011, hcc2010);
   %comb(2012, hcc2011);
   %comb(2013, hcc2012);
   %comb(2014, hcc2013);


data dat.lvs_cohorts; set com07 com08 com09 com10 com11 com12 com13 com14;

     proc contents data=dat.lvs_cohorts;


 data t01; set dat.lvs_npisamp;

      proc sort nodupkey; by year bene_id; 

 data t02; set dat.lvs_cohorts(drop=zip5c);

      proc sort nodupkey; by year bene_id;

 data one; merge t01(in=a) t02(in=b); by year bene_id;

      if a and b;

  *create factor variable 'service' to indicate the type of low value service received;
  *create binary variable 'outcome' to indicate whether bene received the service;
  %macro outsamp(var, v1,v2,v3,v4,v5,v6,v7);

     data n01; set one;
      
          if denom_&var = 1;

          length service $10; 
          service = "&var";
          outcome = bin_&var;

     data n02; set n01;

          drop denom_&var denom_&v1 denom_&v2 denom_&v3 denom_&v4 denom_&v5 denom_&v6 denom_&v7
               bin_&var   bin_&v1   bin_&v2   bin_&v3   bin_&v4   bin_&v5   bin_&v6   bin_&v7;
     *create separate samples for each low value service;
     data ori.lvscle_&var; set n02;

          proc freq;
               tables service outcome;
               title "sample for &var ";

 %mend;
 %outsamp(backscan, cerv,     ctdasym, head,    psa,  pth, spinj, t3 );
 %outsamp(cerv,     backscan, ctdasym, head,    psa,  pth, spinj, t3 );
 %outsamp(ctdasym,  backscan, cerv,    head,    psa,  pth, spinj, t3 );
 %outsamp(head,     backscan, cerv,    ctdasym, psa,  pth, spinj, t3 );
 %outsamp(psa,      backscan, cerv,    ctdasym, head, pth, spinj, t3 );
 %outsamp(pth,      backscan, cerv,    ctdasym, head, psa, spinj, t3 );
 %outsamp(spinj,    backscan, cerv,    ctdasym, head, psa, pth,   t3 );
 %outsamp(t3,       backscan, cerv,    ctdasym, head, psa, pth,   spinj) ;  

endsas;




