/*Add fixed-effects predictions to each low value service sample and split each sample into 101 sub-samples*/

/* Libname Statements */
 %include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/analysis/dir.sas";

 %dir;

*Merge fixed-effects predictions to each low value service sample;
 %macro outsamp(measure, outdat);

  data v01;  set ori.lvscle_&measure;

       proc sort nodupkey; by year bene_id npi;

  data v02; set ori.lvscle_&measure._fe;

       keep year bene_id npi predictions;

       proc sort nodupkey; by year bene_id npi;

  data &outdat; merge v01 v02(in=ok); by year bene_id npi;

       if ok;

 %mend;
 %outsamp(backscan, p01);
 %outsamp(cerv,     p02);
 %outsamp(ctdasym,  p03);
 %outsamp(head,     p04);
 %outsamp(psa,      p05);
 %outsamp(pth,      p06);
 %outsamp(spinj,    p07);
 %outsamp(t3,       p08);


 data ori.lvscle_8measures; set p01 p02 p03 p04 p05 p06 p07 p08;

      proc means n nmiss mean std min max maxdec=3;
           class service;
           var predications;

      proc freq;
           tables year service replicate npi_decile;

*Split each low value service sample into 101 sub-samples;
%macro sample(input);

data lvscle_8measures;
set out.lvscle_8measures;
run;

   %do i=1 %to 101;
      data lvs8.lvscle&i;
         set lvscle_8measures;
         if replicate=&i;
      run;
   %end;

%mend sample;

%sample

endsas;