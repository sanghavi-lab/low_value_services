*create new denominators as ndenom_lvsname;
*the new denominators are a subset of the original denominators denom_lvsname;
*for backscan, head, spinj:exclude patients who are excluded in the numerator for low-value service detection following the exclusion criteria of specific and sensitive measures combined;
*for cerv, pth: exclude patients according to the low-value service detection following the exclusion criteria of specific and sensitive measures combined;
*ctdasym, psa: exclude patients based on presence of chronic conditions in earlier years;
*t3: demoninator does not change;

%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/denom/dir.sas";
%dir;

*extract bene-year level low-value service files to merge with exclusion flags for each service;
%macro serv(service);
 data denom.bene_pcp_final_&service.;
 set prach.bene_pcp_final(drop=fl_: dfl_:);
 if denom_&service.=1;
 run;
%mend serv;

%serv(backscan)
%serv(cerv)
%serv(ctdasym)
%serv(head)
%serv(pth)
%serv(spinj)
%serv(t3)

*for psa, use the ccw indicator(dfl_prost) that are already in the sample;
data denom.bene_pcp_final_psa(drop=dfl_:);
set prach.bene_pcp_final(drop=fl_: rename=(dfl_prost=psa));
if denom_psa=1;
run;

*keep only bene_id, year, and exclusion flags for constructing denominator;
data denom.head_ex_nodup;
set denom.head_ex(keep=bene_id year head_delete);
run;
data denom.backscan_ex_nodup;
set denom.backscan_ex(keep=bene_id year backscan_delete);
run;
data denom.spinj_ex_nodup;
set denom.spinj_ex(keep=bene_id year spinj_delete);
run;
data denom.cerv_ex_nodup;
set denom.cerv_ex(keep=bene_id year cerv_delete);
run;
data denom.hica_nodup;
set denom.hica(keep=bene_id year hica);
run;
data denom.stroke_nodup;
set denom.stroke(keep=bene_id year no_stroke);
run;

*merge exclusion flags with bene-year level files;
*backscan;
proc sql;
	create table denomt.bene_pcp_denom_backscan as
	select A.*,H.backscan_delete
    from denom.bene_pcp_final_backscan as A
    left join denom.backscan_ex as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

*cerv;
proc sql;
	create table denomt.bene_pcp_denom_cerv as
	select A.*,H.cerv_delete
    from denom.bene_pcp_final_cerv as A
    left join denom.cerv_ex as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

*ctdasym;
proc sql;
	create table denomt.bene_pcp_denom_ctdasym as
	select A.*,H.no_stroke
    from denom.bene_pcp_final_ctdasym as A
    left join denom.stroke as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

*head;
proc sql;
	create table denomt.bene_pcp_denom_head as
	select A.*,H.head_delete
    from denom.bene_pcp_final_head as A
    left join denom.head_ex as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

*pth;
proc sql;
	create table denomt.bene_pcp_denom_pth as
	select A.*,H.hica
    from denom.bene_pcp_final_pth as A
    left join denom.hica as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

*spinj;
proc sql;
	create table denomt.bene_pcp_denom_spinj as
	select A.*,H.spinj_delete
    from denom.bene_pcp_final_spinj as A
    left join denom.spinj_ex as H
	on A.bene_id=H.bene_id and A.year=H.year;
quit;

proc sort data=denom.bene_pcp_final_psa;
by bene_id year;
run;
proc sort data=denom.bene_pcp_final_t3;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_pth;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_cerv;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_backscan;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_spinj;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_ctdasym;
by bene_id year;
run;
proc sort data=denomt.bene_pcp_denom_head;
by bene_id year;
run;

*prepare final dataset by concatenating 8 services;
data denomt.bene_pcp_final_all;
merge denomt.bene_pcp_denom_pth
	  denom.bene_pcp_final_psa
	  denomt.bene_pcp_denom_cerv
	  denomt.bene_pcp_denom_head
	  denomt.bene_pcp_denom_ctdasym
	  denomt.bene_pcp_denom_spinj
	  denomt.bene_pcp_denom_backscan
	  denom.bene_pcp_final_t3;
by bene_id year;
run;

*create new set of denominators based on the exclusion flags;
data denomt.bene_pcp_denom_newdenom;
set denomt.bene_pcp_denom_all;
ndenom_head=(denom_head=1 and head_delete^=1);
ndenom_spinj=(denom_spinj=1 and spinj_delete^=1);
ndenom_backscan=(denom_backscan=1 and backscan_delete^=1);
ndenom_cerv=(denom_cerv=1 and cerv_delete^=1);
ndenom_pth=(denom_pth=1 and hica^=1);
ndenom_psa=(denom_psa=1 and psa^=1);
ndenom_ctdasym=(denom_ctdasym=1 and no_stroke=1);
ndenom_t3=denom_t3;
run;

data denomt.bene_pcp_newdenom_sub;
set denomt.bene_pcp_newdenom(keep=bene_id year ndenom_:);
run;

*merge new denominator flags to original sample;
proc sql;
create table denomt.bene_pcp_final_ex as 
select l.*, r.ndenom_backscan,r.ndenom_cerv,r.ndenom_ctdasym,r.ndenom_head,r.ndenom_pth,r.ndenom_psa,r.ndenom_spinj,ndenom_t3
from prach.bene_pcp_final as l left join
     denomt.bene_pcp_newdenom_sub as r
on l.bene_id=r.bene_id and l.year=r.year;
quit;



