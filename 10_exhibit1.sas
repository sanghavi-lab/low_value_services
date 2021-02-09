/*calculate rates of low-value care utilization as a percentage of qualifying patients who received the service
  numerator: counts of low-value care use at the bene-year level
  denominator:continously enrolled FFS benes from the 20 pct master beneficiary summary files*/

%let sample= 20;
%include "/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/LVS_Code/dir.sas";
/* Libname Statements */
%dir;

*Create 1) % benes and 2) no. of benes in each low value service denominator for exhibit 1;
%macro denom(var,stat,output);

proc means data=prach.bene_pcp_final_ex(keep= &var.);
var &var.;
output out=lvs&output. &stat.= / autoname;
run;

data lvs&output.;
set lvs&output. (drop=_freq_ _type_);
array temp {*} _NUMERIC_;
          do i=1 to dim(temp);
               temp{i}=temp{i}*100;
          end;
     drop i;
run;

proc transpose data=lvs&output.
               out=out.lvs&output.;
run;

%mend denom;

*1) percentage in denominator: the percentage of benes in each low value service denominator;
*numerator: benes in each low value service denominator;
*denominator: continously enrolled FFS benes from the 20 pct master beneficiary summary files; 
%denom(denom_:,mean,denom)
*2) count in denominator: the number of benes in each low value service denominator;
%denom(denom_:,sum,denomcount)

*create 1) % benes and 2) no. of benes who received low value services;
*1) percentage: the percentage of benes in each low value service denominator who received the service;
   *numerator: benes who received low value services;
   *denominator: benes in each low value service denominator; 
*2) count : the number of benes who received each low value service;

data pctreceived;
format mean sum 8.;
stop;
run;

%macro lvsreceived(type);
proc sql;
create table &type. as
  select mean(bin_&type)*100 as mean_&type.,
         sum(bin_&type.) as sum_&type.
from prachi.bene_pcp_final_ex  where denom_&type.=1; 
*treat benes who received the low value service but are not in the denominator as if they did not receive the service;
quit;

data pctreceived;
merge pctreceived &type. ;
run;

%mend lvsreceived;

%lvsreceived(psa)
%lvsreceived(colon)
%lvsreceived(cerv)
%lvsreceived(cncr)
%lvsreceived(bmd)
%lvsreceived(pth)
%lvsreceived(preopx)
%lvsreceived(preopec)
%lvsreceived(pft)
%lvsreceived(preopst)
%lvsreceived(vert)
%lvsreceived(arth)
%lvsreceived(rhinoct)
%lvsreceived(sync)
%lvsreceived(renlstent)
%lvsreceived(stress)
%lvsreceived(pci)
%lvsreceived(backscan)
%lvsreceived(head)
%lvsreceived(eeg)
%lvsreceived(ctdsync)
%lvsreceived(ctdasym)
%lvsreceived(cea)
%lvsreceived(homocy)
%lvsreceived(hyperco)
%lvsreceived(ivc)
%lvsreceived(spinj)
%lvsreceived(t3)
%lvsreceived(plant)
%lvsreceived(vitd)
%lvsreceived(rhcath)

proc transpose data=pctreceived
               out=out.pctreceivedbin;
run;


ods csvall file="/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/out/csv/lvsuse_meancount_bin.csv";

proc print data=out.lvsdenomcount noobs;
title "The number of patients who qualify for each LVS";
run;

proc print data=out.lvsdenom noobs;
title "The percentage of patients who qualify for each LVS";
run;

proc print data= out.pctreceivedbin;
title "The count and percentage of benes who received LVS";
run;
ods csvall close;
