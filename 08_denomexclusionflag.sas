*Contruct low-value service denominators, identify excluded claims and patients for backscan, head, and spinj;
*Backscan excluded claims contain diagnoses including cancer, trauma, intravenous drug abuse, neurological impairment, endocarditis, septicemia, tuberculosis, osteomyelitis, fever, weight loss, loss of appetite, night sweats, anemia, radiculitis and myelopathy;
*Head imaging excluded claims contain diagnosis including epilepsy, giant cell arteritis, head trauma, convulsions, altered mental status, nervous system symptoms (e.g. hemiplegia), disturbances of skin sensation, speech problems,  stroke/TIA, history of stroke, cancer or history of cancer;
*Spinal injection excluded claims contain etanercept, radiculopathy, and Epidural (not indwelling), facet, or trigger point injections for lower back pain associated with an inpatient stay (within 14 days);
*If a patient has any of the above claims in each year, then the patient will not qualify to be in the denominator;

%let sample= 20;
%let minyear=2007;
%let maxyear=2014;

%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/denom/denommacros.sas";
%denomm;
%include "/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/denom/dir.sas";
%dir;

/****************************************/
/* flag claims based on cpt, icd-9, CCW */
/****************************************/

/*
This initial flagging applies any exclusion/inclusion criteria for the sensitive version of our
measures that can be applied using the information in a single row of data.
*/

%macro flags1;
	%let expnsdt1=expnsdt1; /*this macro allows me to use the different service date variable name for the outpatient file without changing the conditions in flagcodes */
	%flagcodes;
	 %do i=&minyear  %to &maxyear; 
		data &workflcar;
			set prach.car&i._&sample (keep=&carkeep where = (expnsdt1>= mdy(1,1,&i)));
			array flags[&numflags] $12 _TEMPORARY_ (&allflags);
			 %do j= 1 %to &numflags;
			if  hcpcs_cd &&prcd&j._&i and  &&cond&j._&i  then do;
				flag=flags[&j];
				output denom.flcar&j._&i;
				end;	
			%end;
		run;
	%end;	

	%let expnsdt1=rev_dt; /*this macro allows me to use the different service date variable name for the outpatient file without changing the conditions in flagcodes */
	%flagcodes;
	 %do i=&minyear  %to &maxyear; 
		data &workflotpt;
			length flag $ 12;
			set prach.otpt&i._&sample (keep=&otptkeep where = (rev_dt>= mdy(1,1,&i)));
			array flags[&numflags] $12 _TEMPORARY_ (&allflags);
			%do j= 1 %to &numflags;
			if hcpcs_cd &&prcd&j._&i and &&cond&j._&i  then do;
				flag=flags(&j);
				output denom.flotpt&j._&i;
				end;	
			%end;
		run;
	 %end;	
    /* Merge carrier and outpatient flags and add subflags when they can be determined by single claim */
	 %do i=&minyear  %to &maxyear;
	 %do j=1 %to &numflags;
	 proc sql;
	create table denom.flcarotpt&j._&i  as
		select coalesce(L.bene_id, R.bene_id) as bene_id, coalesce(L.bene_dob, R.bene_dob) format=date9. as bene_dob, coalesce(L.hcpcs_cd, R.hcpcs_cd) as hcpcs_cd, 
		coalesce(L.expnsdt1, R.rev_dt) format=date9. as expnsdt1, coalesce(L.flag, R.flag) as flag, L.dgnsall as cardgns, R.dgnsall as otptdgns, 
		L.clm_id as carclm_id, R.clm_id as otptclm_id, 
		case when calculated flag='cncr'    and calculated hcpcs_cd in('77057', 'G0202') then "ckdmamm"
			 when calculated flag='cncr'    and (calculated hcpcs_cd in('G0104', 'G0105', 'G0106', 'G0120', 'G0120', 'G0121', 'G0122') or (calculated hcpcs_cd>='45330' and calculated hcpcs_cd <='45345') or  
												(calculated hcpcs_cd>='45378' and calculated hcpcs_cd <='45392')) then "colonosc"
			 when calculated flag='cncr'    and calculated hcpcs_cd in('G0328', '82270') then "occult"
			 when calculated flag='cncr'    and calculated hcpcs_cd in('G0123', 'G0124', 'G0141', 'G014', 'G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'P3001', 'Q0091') then "cerv"
			 when calculated flag='cncr'    and calculated hcpcs_cd in('G0102', 'G0103', '84152', '84153', '84154') then "psa"
			 when calculated flag='sync' then "head"
			 when calculated flag in('ctdsync', 'ctdasym') then  "ctd"  
			 when calculated flag='plant' and calculated hcpcs_cd in ('73620', '73630', '73650') then "plantx"
			 when calculated flag='plant' and calculated hcpcs_cd in ('73718', '73719', '73720') then "plantmri"
			 when calculated flag='plant' and calculated hcpcs_cd in ('76880', '76881', '76882') then "plantus"
			 else calculated flag end as subflag,
			 coalesce(L.cncrprse, R.cncrprse) format=date9. as cncrprse, coalesce(L.chrnkdne, R.chrnkdne) format=date9. as chrnkdne, 
			 coalesce(L.chrnkidn, R.chrnkidn) as chrnkidn, coalesce(L.ischmche, R.ischmche) format=date9. as ischmche,
			 coalesce(L.strktiae, R.strktiae) format=date9. as strktiae, coalesce(L.cncrclre, R.cncrclre) format=date9. as cncrclre,
			 coalesce(L.osteopre, R.osteopre) format=date9. as osteopre, coalesce(L.amie, R.amie) format=date9. as amie, 
			 coalesce(L.sex, R.sex) as sex
		from denom.flcar&j._&i. as L
		full join
		denom.flotpt&j._&i. as R
		on L.bene_id=R.bene_id and L.hcpcs_cd=R.hcpcs_cd and L.expnsdt1=R.rev_dt and L.flag=R.flag;
	quit;
	 %end;
	 %end;
     
%mend flags1;
%flags1;

/************************************/
/* Scan claims again for exclusions */
/************************************/

%let flkeep= bene_id hcpcs_cd expnsdt1 carclm_id otptclm_id flag subflag;
*scan for backscan exclusion claims;
%macro backscan;
%do i=2007  %to 2014;

*identify first diagnosis of back pain;
proc sql;
create table work.firstback_&i as 
	select bene_id, min(backdt) format=date9. as firstback from (
		select bene_id, expnsdt1 as backdt
		from denom.exbackscancar_&i 
		union all
		select bene_id, rev_dt as backdt 
		from denom.exbackscanotpt_&i 
		)
	where bene_id in (select bene_id from denom.flcarotpt2_&i)
	group by bene_id;
quit;

*identify exclusion claims that contain diagnoses including cancer, trauma, intravenous drug abuse;
*neurological impairment, endocarditis, septicemia, tuberculosis, osteomyelitis, fever, weight loss;
*loss of appetite, night sweats, anemia, radiculitis and myelopathy;

proc sql;
create table denom.backscan_ex_&i.(keep=&flkeep firstback) as
	select coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, L.hcpcs_cd, L.flag, L.subflag, R.firstback 
	from denom.flcarotpt1_&i as L
	inner join
	work.firstback_&i as R
	on L.bene_id=R.bene_id
	where index(otptdgns, ' 14') + index(otptdgns, ' 15') + index(otptdgns, ' 16') + index(otptdgns, ' 17') +
		index(otptdgns, ' 18') + index(otptdgns, ' 19') + index(otptdgns, ' 200') +  index(otptdgns, ' 201') + index(otptdgns, ' 202') + 
		index(otptdgns, ' 203') + index(otptdgns, ' 204') + index(otptdgns, ' 205') + index(otptdgns, ' 206') + index(otptdgns, ' 207') +
		index(otptdgns, ' 208') + index(otptdgns, ' 230') + index(otptdgns, ' 231') + index(otptdgns, ' 232') + index(otptdgns, ' 233') + index(otptdgns, ' 234') + 
		index(otptdgns, ' 235') + index(otptdgns, ' 236') + index(otptdgns, ' 237') + index(otptdgns, ' 238') + index(otptdgns, ' 239') +  
		index(otptdgns, ' 80') + index(otptdgns, ' 81') + index(otptdgns, ' 82') + index(otptdgns, ' 83') + index(otptdgns, ' 850') +
		index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') + 
		index(otptdgns, ' 854') + index(otptdgns, ' 86') + index(otptdgns, ' 905') + index(otptdgns, ' 906') + index(otptdgns, ' 907') +
		index(otptdgns, ' 908') + index(otptdgns, ' 909') + index(otptdgns, ' 92611 ') + index(otptdgns, ' 92612 ') + index(otptdgns, ' 929') +
		index(otptdgns, ' 952') + index(otptdgns, ' 958') + index(otptdgns, ' 959') + index(otptdgns, ' 3040')  + index(otptdgns, ' 3041') +
		index(otptdgns, ' 3042') + index(otptdgns, ' 3044') + index(otptdgns, ' 3054') + index(otptdgns, ' 3055') + index(otptdgns, ' 3056') + index(otptdgns, ' 3057') +
		index(otptdgns, ' 34460') + index(otptdgns, ' 7292') + index(otptdgns, ' 4210') + index(otptdgns, ' 4211') + index(otptdgns, ' 4219') +
		index(otptdgns, ' 038')  + index(otptdgns, ' 01') + index(otptdgns, ' 730')  + index(otptdgns, ' 7806') + index(otptdgns, ' 7830') +
		index(otptdgns, ' 7832') + index(otptdgns, ' 78079') + index(otptdgns, ' 7808') + index(otptdgns, ' 2859') + 
		index(otptdgns, ' 72142')  + index(otptdgns, ' 72191') + index(otptdgns, ' 72270')  + index(otptdgns, ' 72273') + index(otptdgns, ' 7244') +
		index(cardgns, ' 14') + index(cardgns, ' 15') + index(cardgns, ' 16') + index(cardgns, ' 17') +
		index(cardgns, ' 18') + index(cardgns, ' 19') + index(cardgns, ' 200') +  index(cardgns, ' 201') + index(cardgns, ' 202') + 
		index(cardgns, ' 203') + index(cardgns, ' 204') + index(cardgns, ' 205') + index(cardgns, ' 206') + index(cardgns, ' 207') +
		index(cardgns, ' 208') + index(cardgns, ' 230') + index(cardgns, ' 231') + index(cardgns, ' 232') + index(cardgns, ' 233') + index(cardgns, ' 234') +
		index(cardgns, ' 235') + index(cardgns, ' 236') + index(cardgns, ' 237') + index(cardgns, ' 238') + index(cardgns, ' 239') 	+  
		index(cardgns, ' 80') + index(cardgns, ' 81') + index(cardgns, ' 82') + index(cardgns, ' 83') + index(cardgns, ' 850') + 
		index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') + 
		index(cardgns, ' 854') + index(cardgns, ' 86') + index(cardgns, ' 905') + index(cardgns, ' 906') + index(cardgns, ' 907') +
		index(cardgns, ' 908') + index(cardgns, ' 909') + index(cardgns, ' 92611 ') + index(cardgns, ' 92612 ') + index(cardgns, ' 929') +
		index(cardgns, ' 952') + index(cardgns, ' 958') + index(cardgns, ' 959') + index(cardgns, ' 3040')  + index(cardgns, ' 3041') +
		index(cardgns, ' 3042') + index(cardgns, ' 3044') + index(cardgns, ' 3054') + index(cardgns, ' 3055') + index(cardgns, ' 3056') + index(cardgns, ' 3057') +
		index(cardgns, ' 34460') + index(cardgns, ' 7292') + index(cardgns, ' 4210') + index(cardgns, ' 4211') + index(cardgns, ' 4219') +
		index(cardgns, ' 038')  + index(cardgns, ' 01') + index(cardgns, ' 730')  + index(cardgns, ' 7806') + index(cardgns, ' 7830') +
		index(cardgns, ' 7832') + index(cardgns, ' 78079') + index(cardgns, ' 7808') + index(cardgns, ' 2859') +
		index(cardgns, ' 72142')  + index(cardgns, ' 72191') + index(cardgns, ' 72270')  + index(cardgns, ' 72273') + index(cardgns, ' 7244')
		^=0 or expnsdt1-firstback>=42;
quit;

%end;
%mend backscan;
 %backscan; 

*identify exclusion claims that contain diagnoses including epilepsy, giant cell arteritis, head trauma;
*convulsions, altered mental status, nervous system symptoms (e.g. hemiplegia) , disturbances of skin sensation;
*speech problems, stroke/TIA, history of stroke, cancer or history of cancer;
%macro head;
%do i=&minyear %to &maxyear;

data denom.head_ex_&i. (keep=&flkeep) ;
	set denom.flcarotpt2_&i;
	if index(otptdgns, ' 14') + index(otptdgns, ' 15') + index(otptdgns, ' 16') + index(otptdgns, ' 17') +
		index(otptdgns, ' 18') + index(otptdgns, ' 19') + index(otptdgns, ' 200') +  index(otptdgns, ' 201') + index(otptdgns, ' 202') + 
		index(otptdgns, ' 203') + index(otptdgns, ' 204') + index(otptdgns, ' 205') + index(otptdgns, ' 206') + index(otptdgns, ' 207') +
		index(otptdgns, ' 208') + index(otptdgns, ' 230') + index(otptdgns, ' 231') + index(otptdgns, ' 232') + index(otptdgns, ' 233') + index(otptdgns, ' 234') + 
		index(otptdgns, ' 235') + index(otptdgns, ' 236') + index(otptdgns, ' 237') + index(otptdgns, ' 238') + index(otptdgns, ' 239') + 
		index(otptdgns, ' 33920 ') + index(otptdgns, ' 33921 ') + index(otptdgns, ' 33922 ') + index(otptdgns, ' 33943 ') +
		index(otptdgns, ' 3463') + index(otptdgns, ' 3466') + index(otptdgns, ' 4465') +
		index(otptdgns, ' 345') + index(otptdgns, ' 43') + index(otptdgns, ' 800') + index(otptdgns, ' 801') + index(otptdgns, ' 802') + 
		index(otptdgns, ' 803') + index(otptdgns, ' 804') + index(otptdgns, ' 850') + index(otptdgns, ' 851') +
		index(otptdgns, ' 851') + index(otptdgns, ' 852') + index(otptdgns, ' 853') + index(otptdgns, ' 854') +
		index(otptdgns, ' 870') + index(otptdgns, ' 871') + index(otptdgns, ' 872') +	
		index(otptdgns, ' 873') + index(otptdgns, ' 9590') + index(otptdgns, ' 910') + index(otptdgns, ' 920') + 
		index(otptdgns, ' 921') + index(otptdgns, ' 7803') + index(otptdgns, ' 78097') +
		index(otptdgns, ' 781') + index(otptdgns, ' 7820') + index(otptdgns, ' 7845') + 
		index(otptdgns, ' 79953') + index(otptdgns, ' V1254 ') + index(otptdgns, ' V10') +
		index(cardgns, ' 14') + index(cardgns, ' 15') + index(cardgns, ' 16') + index(cardgns, ' 17') +
		index(cardgns, ' 18') + index(cardgns, ' 19') + index(cardgns, ' 200') +  index(cardgns, ' 201') + index(cardgns, ' 202') + 
		index(cardgns, ' 203') + index(cardgns, ' 204') + index(cardgns, ' 205') + index(cardgns, ' 206') + index(cardgns, ' 207') +
		index(cardgns, ' 208') + index(cardgns, ' 230') + index(cardgns, ' 231') + index(cardgns, ' 232') + index(cardgns, ' 233') + index(cardgns, ' 234') + 
		index(cardgns, ' 235') + index(cardgns, ' 236') + index(cardgns, ' 237') + index(cardgns, ' 238') + index(cardgns, ' 239') + 
		index(cardgns, ' 33920 ') + index(cardgns, ' 33921 ') + index(cardgns, ' 33922 ') + index(cardgns, ' 33943 ') +
		index(cardgns, ' 3463') + index(cardgns, ' 3466') + index(cardgns, ' 4465') +
		index(cardgns, ' 345') + index(cardgns, ' 43') + index(cardgns, ' 800') + index(cardgns, ' 801') + index(cardgns, ' 802') + 
		index(cardgns, ' 803') + index(cardgns, ' 804') + index(cardgns, ' 850') + index(cardgns, ' 851') +
		index(cardgns, ' 851') + index(cardgns, ' 852') + index(cardgns, ' 853') + index(cardgns, ' 854') +
		index(cardgns, ' 870') + index(cardgns, ' 871') + index(cardgns, ' 872') +	
		index(cardgns, ' 873') + index(cardgns, ' 9590') + index(cardgns, ' 910') + index(cardgns, ' 920') + 
		index(cardgns, ' 921') + index(cardgns, ' 7803') + index(cardgns, ' 78097') +
		index(cardgns, ' 781') + index(cardgns, ' 7820') + index(cardgns, ' 7845')  + 
		index(otptdgns, ' 79953') + index(cardgns, ' V1254 ') + index(cardgns, ' V10') ^= 0;
run;
%end;
%mend head;
 %head; 

%macro spinj;
%do i=&minyear  %to &maxyear;

*identify exclusion claims as Epidural (not indwelling), facet, or trigger point injections for lower back pain associated with an inpatient stay (within 14 days);
proc sql;
create table work.spinjinpt_&i as
	select  coalesce(L.bene_id, R.bene_id) as bene_id, L.carclm_id, L.otptclm_id, L.expnsdt1, R.admsndt, R.dschrgdt
		from denom.flcarotpt3_&i as L
		left join
		prach.medpar&i._&sample  as R
		on L.bene_id = R.bene_id
		where (((R.admsndt <= L.expnsdt1 <= R.dschrgdt) and R.admsndt is not missing)
		or ((R.dschrgdt < L.expnsdt1 <= R.dschrgdt+14) and R.dschrgdt is not missing));
quit;


*identify exclusion claims for etanercept and diagnoses indicating radiculopathy;
proc sql;
create table denom.spinj_ex_&i. as
	select * from denom.flcarotpt3_&i
	where (carclm_id is not missing and carclm_id in (select carclm_id from work.spinjinpt_&i)) or 
		(otptclm_id is not missing and otptclm_id in (select otptclm_id from work.spinjinpt_&i)) or 
        index(cardgns, ' 72142') + index(cardgns, ' 72191') + index(cardgns, ' 72270') + 
	    index(cardgns, ' 72273') + index(cardgns, ' 7243')+ index(cardgns, ' 7244') + 
	    index(otptdgns, ' 72142') + index(otptdgns, ' 72191') + index(otptdgns, ' 72270') + 
	    index(otptdgns, ' 72273') + index(otptdgns, ' 7243')+ index(otptdgns, ' 7244') ^=0;
quit;

%end;
%mend spinj;
%spinj;

*Combine backscan exlusion claims;
data denom.backscan_ex;
set denom.backscan_ex_2007 (in=in07)
    denom.backscan_ex_2008 (in=in08)
    denom.backscan_ex_2009 (in=in09)
    denom.backscan_ex_2010 (in=in10)
    denom.backscan_ex_2011 (in=in11)
    denom.backscan_ex_2012 (in=in12)
    denom.backscan_ex_2013 (in=in13)
    denom.backscan_ex_2014 (in=in14);
if in07 then year=2007;
else if in08 then year=2008;
else if in09 then year=2009;
else if in10 then year=2010;
else if in11 then year=2011;
else if in12 then year=2012;
else if in13 then year=2013;
else year=2014;
backscan_delete=1;
run;

proc sort data=denom.backscan_ex nodupkeys;
by bene_id year;
run;

*Combine head exclusion claims;
data denom.head_ex;
set denom.head_ex_2007 (in=in07)
    denom.head_ex_2008 (in=in08)
    denom.head_ex_2009 (in=in09)
    denom.head_ex_2010 (in=in10)
    denom.head_ex_2011 (in=in11)
    denom.head_ex_2012 (in=in12)
    denom.head_ex_2013 (in=in13)
    denom.head_ex_2014 (in=in14);
if in07 then year=2007;
else if in08 then year=2008;
else if in09 then year=2009;
else if in10 then year=2010;
else if in11 then year=2011;
else if in12 then year=2012;
else if in13 then year=2013;
else year=2014;
head_delete=1;
run;

proc sort data=denom.head_ex nodupkeys;
by bene_id year;
run;

*Combine spinj exclusion claims;
data denom.spinj_ex;
set denom.spinj_ex_2007 (in=in07)
    denom.spinj_ex_2008 (in=in08)
    denom.spinj_ex_2009 (in=in09)
    denom.spinj_ex_2010 (in=in10)
    denom.spinj_ex_2011 (in=in11)
    denom.spinj_ex_2012 (in=in12)
    denom.spinj_ex_2013 (in=in13)
    denom.spinj_ex_2014 (in=in14);
if in07 then year=2007;
else if in08 then year=2008;
else if in09 then year=2009;
else if in10 then year=2010;
else if in11 then year=2011;
else if in12 then year=2012;
else if in13 then year=2013;
else year=2014;
spinj_delete=1;
run;

proc sort data=denom.spinj_ex nodupkeys;
by bene_id year;
run;