/*Assign Physician to BENEs based on total amount of allowed charges on outpatient primary care claims*/ 

%let sample= 20;
%include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
/* Libname Statements */
%dir;

%macro outnpi;
%do i=&minyear %to &maxyear;
   ************************************;
   * Assign NPI to Carrier (Line) file;
   ************************************;

   proc sql;
        create table work.carrier0&i as
        select bene_id,
               left(PRF_NPI) as NPI length=10,
               hcpcs_cd as HCPCS,
               LALOWCHG as allowchg,
               HCFASPCL as prvdr_spclty,
               EXPNSDT2 as LastExpDate
        from car&i..carl&i;
     quit;

   *Identify PCP and non-PCP based on specialty code on outpatient primary care claims;
   data work.carrier&i;
   set work.carrier0&i;

           if (NPI in ("0000000000") or verify(NPI, "0123456789") > 0 or substr(NPI, 1, 1) notin ("1","2")) then delete;

           attrib PC_Serv label = "Service classified as outpatient primary care";
           pc_serv= ((HCPCS >= "99201" and HCPCS <= "99215") or
                     (HCPCS in ("G0402", "G0438", "G0439")));

           attrib PCS_by_PCP label = "PC service by PCP";
           pcs_by_pcp= (PC_Serv and prvdr_spclty in ("01", "08", "11", "38"));

           attrib PCS_by_Non label = "PC service by non-PCP";
           pcs_by_non= (PC_Serv and prvdr_spclty notin ("01", "08", "11", "38"));

           if pc_serv=1;

       run;

  proc sql;
       create table work.npi_carrier&i as
       select Bene_ID,
              NPI,
              AllowChg,
              PCS_by_PCP,
              PCS_by_Non,
       case when PCS_by_PCP = 1 then LastExpDate else . end as Last_by_PCP,
       case when PCS_by_Non = 1 then LastExpDate else . end as Last_by_Non
         from work.carrier&i;

   ************************************;
   * Create Bene-NPI-level data set.  *;
   ************************************;

   *Get sum of allowed charges and most recent service date at each NPI*;
    create table work.NPI_TotalChg_S1 as
    select Bene_ID,
           NPI,
           1 as Rcvd_PCS_by_PCP,
           round(sum(AllowChg), 0.01) as NPI_TotalChg,
           max(Last_by_PCP) as Most_Recent format=DATE7.,
           count(*) as n
     from  work.npi_carrier&i
     where PCS_by_PCP = 1
     group by Bene_ID, NPI;

    create table work.NPI_TotalChg_S2 as
    select Bene_ID,
           NPI,
           0 as Rcvd_PCS_by_PCP,
           round(sum(AllowChg), 0.01) as NPI_TotalChg,
           max(Last_by_Non) as Most_Recent format=DATE7.,
           count(*) as n
      from work.npi_carrier&i
     where PCS_by_Non = 1
     group by Bene_ID, NPI;

    create table work.NPI_TotalChg as
    select *
     from  NPI_TotalChg_S1
    union all corresponding
   select *
     from NPI_TotalChg_S2;

   quit;


  **********************************************************;
  * Narrow to one NPI per Bene based on most spending      *;
  **********************************************************;

   proc sort data = work.NPI_TotalChg;
        by Bene_ID descending Rcvd_PCS_by_PCP descending NPI_TotalChg descending Most_Recent;
   run;

   proc sort data = work.NPI_TotalChg nodupkey out = work.Bene_Assoc_NPI;
        by Bene_ID;
   run;


data work.outnpi&i;
set work.Bene_Assoc_NPI;
year_claims = &i;
rename Rcvd_PCS_by_PCP = PCP;

%end;
 %mend;

%outnpi;

data out.claims_npi_&sample;
set outnpi2007 outnpi2008 outnpi2009 outnpi2010 outnpi2011 outnpi2012 outnpi2013 outnpi2014;

       label most_recent = 'Date of Most Recent Doctor Visit';
       label NPI_TotalChg = 'Total Amount charged by the NPI';

       proc freq; tables pcp;
       proc contents varnum;
run;

proc print data=out.claims_npi_&sample(obs=20);
run;

/* clear work directory */
proc datasets lib=work
nolist kill;
quit;
run;

endsas;
