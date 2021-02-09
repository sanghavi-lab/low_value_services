/*Create ranks for NPI based on random effects: rank=quintiles 20/20, tertiles 30/30, quantiles 50/50
  Calculate mean provision of low value service by ranks of low value service composites for exhibit3*/

/* Libname Statements */
%let sample= 20;
%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/analysis/dir.sas";
%dir;

*Read in low value service composites and then rank NPI based on their values;
proc import datafile = "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/8lvs/npire.csv"
 out =re
 dbms = CSV replace;
 getnames=yes;
run;

data re(drop=_npi);
format npi $10.;
set re(rename=(npi=_npi));
npi=put(_npi,10.);
run;

proc sort data=re;
by re;
run;

%macro split(rank)
data re; 
   set re nobs=numobs; 
   length  rank 3.;
   rank=floor(_n_*&rank./(numobs+1))+1; 
run;

*Calculate NPI-level low value service provision rate stratifying on ranks;
data out.npi8lvs;
format npi $10.;
stop;
run;

*Calculate low value service provision rate for each NPI;
%macro byserv(serv);

proc sql;
create table &serv. as select distinct npi, mean(outcome) as &serv. 
from prach.lvscle_8measures_final
where service="&serv."
group by npi;
quit;

data out.npi8lvs;
merge out.npi8lvs
      &serv.;
by npi;
run;
      
%mend byserv;

%byserv(head)
%byserv(spinj)
%byserv(ctdasym)
%byserv(pth)
%byserv(psa)
%byserv(cerv)
%byserv(backscan)
%byserv(t3)

*Merge NPI-level low value service provision rate with NPI composite ranks;
proc sql;
create table out.lvs8_rerank as 
select r.*,
       m.* 
       from re as r, out.npi8lvs as m
       where (r.npi=m.npi);
quit;

*Calculate mean service provision rate by low value service composite ranks;
PROC MEANS DATA=out.lvs8_rerank noprint;
        class rank;
        VAR backscan cerv ctdasym head psa pth spinj t3;
        output out=mean8lvs mean= / autoname;
run;

data mean8lvs_npi;
set mean8lvs(drop=_freq_ _type_);
if rank^=.;
array temp {*} _NUMERIC_;
          do i=1 to dim(temp);
               temp{i}=temp{i}*100;
          end;
     drop i;
run;

proc print data=mean8lvs_npi noobs;
    title "npi level lvs quintiles";
run;

%mend split;


ods csv file="/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/csv/exhibit3.csv";

*rank=quintiles 20/20, tertiles 30/30, quantiles 50/50;
%split(5)
%split(3)
%split(2)

ods csvall close;