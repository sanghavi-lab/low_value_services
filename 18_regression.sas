************************************************************************************************************;
* Run regressions with CAHPS score as the outcome variables and low value service composites as predictors *;
************************************************************************************************************; 

options ls=120 nofmterr;

%global po1; %let po1 = /data/Medicare_P01_2009/data/cahps_claims;

libname dat  "&po1/sasdata";
libname new  ".";

data one; set new.lvs_data_new;

     rename lvs_re = lvs_re_adj;

     ** Create Dichotomous comparing group of predictor LVS measures **;
     if rank5=1 then lvs_5th_1st=0; else if rank5=5 then lvs_5th_1st=1;

   run;
   
%macro test(pred);

   data a0; set one;

       if &pred =. then delete;
       *bene-level covariates;
       %let BeneChars = age_lt65 age_7074 age_7579 age_8084 age_ge85
                        medicaid less_8th some_hs somecoll collgrad collmore edu_mis
                        ghs_vygd ghs_good ghs_fair ghs_poor
                        mhs_vygd mhs_good mhs_fair mhs_poor ;

  *Run mixed linear model of binary outcome on low value service composites with other covariates;
  %macro runModel(depVar);
        
        proc surveyreg data=a0;
             class npi replicate;
             model &depVar = &pred &BeneChars replicate/solution clparm;
             cluster npi;
           ods select rDataSummary;
           ods output ParameterEstimates = p0;  
        run;

       data p0; set p0;
            if parameter='Intercept' then delete;
	 
       proc print data=p0(obs=1);
            var parameter estimate stderr lowerCL upperCL probt; 
            title "&pred for &depVar";
       run;

 %mend;
 %runModel(rate_care);
 %runModel(rate_md);
 %runModel(rate_spec);
 %runModel(ca_wt15mns);
 %runModel(mdcommunicat);
 %runModel(md_explain);
 %runModel(md_listen);
 %runModel(md_respect);
 %runModel(md_sptime);
 %runModel(timelyaccess);
 %runModel(ca_rtnasaw);
 %runModel(ca_illasaw);
 %runModel(sp_getappt);
 %runModel(testresults);
 %runModel(md_testfup);
 %runMOdel(md_testasan);

%mend;
*adjusted regression (with low value service composites obtained including fixed-effects predictions);
%Test(lvs_re_adj);
*unadjusted regression (with low value service composites obtained excluding fixed-effects predictions);
%test(lvs8_re_noadj);

endsas;



