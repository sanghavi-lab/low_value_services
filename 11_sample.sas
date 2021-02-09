/*Select NPIs that have both CAHPS surveys and low value service claims
  Split analytical sample into 101 random samples stratifying on deciles of NPIs created based on the number of benes per NPI*/

%let sample= 20;
%include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
/* Libname Statements */
%dir;

 data a00; set ori.bene_pcp_final_ex;

      keep bene_id npi age sex race state_cd medspend_all mcaid 
           female white black asian hispanic NPI_TotalChg Most_Recent 
           year year2007 year2008 year2009 year2010 year2011 year2012 year2013  
           bin_backscan  denom_backscan   bin_cerv      denom_cerv
           bin_ctdasym   denom_ctdasym    bin_head      denom_head
           bin_psa       denom_psa        bin_pth       denom_pth
           bin_spinj     denom_spinj      bin_t3        denom_t3 ;

      proc sort; by npi;

 *Calculate number of distinct benes in the low value service sample for each NPI;
 proc sql;
      create table a0 as
      select bene_id, npi,
             count(distinct bene_id) as nbene_npi
      from   a00
      group by npi;
 quit;

 proc sort data=a0; by npi;

 data c0; set new.cahps_npi;

      proc sort; by npi;

*Select NPIs that are both present in the CAHPS sample and the low value service claims sample;
 data one; merge a0(in=a) c0(in=b); by npi;

      if a and b;  

      proc sort; by npi;

   proc freq data=one noprint;
        tables npi /out=n00;

   data n0; set n00(keep=npi count); 
 
        rename count = nbene_npi;
  
        proc sort; by npi;

   *Create NPI deciles based on the per NPI number of distinct benes in the low value service sample;
   proc rank data=n0 out=n01 groups=10;
         var nbene_npi;
       ranks npi_decile;

  *Create random samples of NPI stratifying on NPI deciles;
  %macro outsamp(num, nsamp);

    data t00; set n01;

         if npi_decile=&num;

         ran_n = ranuni(88);

         proc rank data=t00 out=t0 groups = 100;
               var ran_n;
             ranks ran_group;
 
         proc sort data=t0; by ran_group;

         proc surveyselect data     = t0
                           method   = srs
                           sampsize = &nsamp
                           seed     = 4000 
                            out     = t01; 
              strata ran_group;
         run;

     data t_&num; set t01;

  %mend;
  %outsamp(0, 100);
  %outsamp(1,  99);
  %outsamp(2, 100);
  %outsamp(3, 100);
  %outsamp(4,  99);
  %outsamp(5, 100);
  %outsamp(6, 100);
  %outsamp(7, 100);
  %outsamp(8, 100);
  %outsamp(9, 100);

  data one; set t_0 t_1 t_2 t_3 t_4 t_5 t_6 t_7 t_8 t_9;

       ran_group = ran_group + 1;

       proc sort nodupkey; by npi;

  proc sort data=n01; by npi;

  data two; merge n01(keep=npi npi_decile) one(drop=npi_decile); by npi;
      
       if ran_group=. then ran_group = 101;

  data p0; set two(keep = npi npi_decile ran_group 
                   rename = (ran_group = replicate));

       proc freq data=p0;
            tables replicate;

       proc freq data=p0(where=(replicate=101));
            tables npi_decile;
            title 'npi_decile for replicate 101';

       proc sort; by npi;

  *Merge NPI random sample to low value service sample to get service-level random sample;
  data dat.lvs_npisamp; merge a00(in=a) p0(in=b); by npi;

       if a and b;

       proc contents data=dat.lvs_npisamp;

endsas;

