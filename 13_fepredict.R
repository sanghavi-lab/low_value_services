# Run fixed-effects models separately for each low value service to predict outcome variable of whether patient received the service on odds ratio scale.

Load libraries
library(foreign)
library(xtable)
library(MatrixModels)
library(data.table)
library(plyr)
library(reshape2)
library(dplyr)
library(Hmisc)
library(lme4)
library(lmtest)

message ("------------Libraries Loaded------------")
system("date")
message ("---------------------------")

# run model for 101 samples
for (i in 1:101){

#backscan
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_backscan",i,".Rdata"))
lvscle_backscan<- get(paste0("lvscle_backscan",i))

#Recode race
lvscle_backscan$race <- ifelse(lvscle_backscan$race=="1","white",lvscle_backscan$race)
lvscle_backscan$race <- ifelse(lvscle_backscan$race=="2","black",lvscle_backscan$race)
lvscle_backscan$race <- ifelse(lvscle_backscan$race=="4","asian",lvscle_backscan$race)
lvscle_backscan$race <- ifelse(lvscle_backscan$race=="5","hispanic",lvscle_backscan$race)
lvscle_backscan$race <- ifelse(lvscle_backscan$race %in% c("6","0","3"),"other",lvscle_backscan$race)

#Create age squared
lvscle_backscan$age2 <- lvscle_backscan$age^2

#Recode sex
lvscle_backscan$female <- 0
lvscle_backscan$female <- ifelse(lvscle_backscan$sex=="2",1,lvscle_backscan$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_backscan_noNA <- lvscle_backscan[!is.na(lvscle_backscan$zip5_college) & !is.na(lvscle_backscan$zip5_in_poverty) & !is.na(lvscle_backscan$zip5_hhinc_mdn) & !is.na(lvscle_backscan$HRRNum),]

#Run fixed-effect model
M10_backscan <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_backscan_noNA,family=binomial())
saveRDS(M10_backscan,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_backscan.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_backscan_noNA$predictions <- predict(M10_backscan,type="link",newdata=lvscle_backscan_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_backscan",i,".Rda")
save(lvscle_backscan_noNA,file=lvsfile)

#spinj
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_spinj",i,".Rdata"))
lvscle_spinj<- get(paste0("lvscle_spinj",i))

#Recode race
lvscle_spinj$race <- ifelse(lvscle_spinj$race=="1","white",lvscle_spinj$race)
lvscle_spinj$race <- ifelse(lvscle_spinj$race=="2","black",lvscle_spinj$race)
lvscle_spinj$race <- ifelse(lvscle_spinj$race=="4","asian",lvscle_spinj$race)
lvscle_spinj$race <- ifelse(lvscle_spinj$race=="5","hispanic",lvscle_spinj$race)
lvscle_spinj$race <- ifelse(lvscle_spinj$race %in% c("6","0","3"),"other",lvscle_spinj$race)

#Create age squared
lvscle_spinj$age2 <- lvscle_spinj$age^2

#Recode sex
lvscle_spinj$female <- 0
lvscle_spinj$female <- ifelse(lvscle_spinj$sex=="2",1,lvscle_spinj$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_spinj_noNA <- lvscle_spinj[!is.na(lvscle_spinj$zip5_college) & !is.na(lvscle_spinj$zip5_in_poverty) & !is.na(lvscle_spinj$zip5_hhinc_mdn) & !is.na(lvscle_spinj$HRRNum),]

#Run fixed-effect model
M10_spinj <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_spinj_noNA,family=binomial())
saveRDS(M10_spinj,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_spinj.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_spinj_noNA$predictions <- predict(M10_spinj,type="link",newdata=lvscle_spinj_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_spinj",i,".Rda")
save(lvscle_spinj_noNA,file=lvsfile)

#cerv
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_cerv",i,".Rdata"))
lvscle_cerv<- get(paste0("lvscle_cerv",i))

#Recode race
lvscle_cerv$race <- ifelse(lvscle_cerv$race=="1","white",lvscle_cerv$race)
lvscle_cerv$race <- ifelse(lvscle_cerv$race=="2","black",lvscle_cerv$race)
lvscle_cerv$race <- ifelse(lvscle_cerv$race=="4","asian",lvscle_cerv$race)
lvscle_cerv$race <- ifelse(lvscle_cerv$race=="5","hispanic",lvscle_cerv$race)
lvscle_cerv$race <- ifelse(lvscle_cerv$race %in% c("6","0","3"),"other",lvscle_cerv$race)

#Create age squared
lvscle_cerv$age2 <- lvscle_cerv$age^2

#Recode sex
lvscle_cerv$female <- 0
lvscle_cerv$female <- ifelse(lvscle_cerv$sex=="2",1,lvscle_cerv$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_cerv_noNA <- lvscle_cerv[!is.na(lvscle_cerv$zip5_college) & !is.na(lvscle_cerv$zip5_in_poverty) & !is.na(lvscle_cerv$zip5_hhinc_mdn) & !is.na(lvscle_cerv$HRRNum),]

#Run fixed-effect model
M10_cerv <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_cerv_noNA,family=binomial())
saveRDS(M10_cerv,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_cerv.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_cerv_noNA$predictions <- predict(M10_cerv,type="link",newdata=lvscle_cerv_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_cerv",i,".Rda")
save(lvscle_cerv_noNA,file=lvsfile)

#ctdasym
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_ctdasym",i,".Rdata"))
lvscle_ctdasym<- get(paste0("lvscle_ctdasym",i))

#Recode race
lvscle_ctdasym$race <- ifelse(lvscle_ctdasym$race=="1","white",lvscle_ctdasym$race)
lvscle_ctdasym$race <- ifelse(lvscle_ctdasym$race=="2","black",lvscle_ctdasym$race)
lvscle_ctdasym$race <- ifelse(lvscle_ctdasym$race=="4","asian",lvscle_ctdasym$race)
lvscle_ctdasym$race <- ifelse(lvscle_ctdasym$race=="5","hispanic",lvscle_ctdasym$race)
lvscle_ctdasym$race <- ifelse(lvscle_ctdasym$race %in% c("6","0","3"),"other",lvscle_ctdasym$race)

#Create age squared
lvscle_ctdasym$age2 <- lvscle_ctdasym$age^2

#Recode sex
lvscle_ctdasym$female <- 0
lvscle_ctdasym$female <- ifelse(lvscle_ctdasym$sex=="2",1,lvscle_ctdasym$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_ctdasym_noNA <- lvscle_ctdasym[!is.na(lvscle_ctdasym$zip5_college) & !is.na(lvscle_ctdasym$zip5_in_poverty) & !is.na(lvscle_ctdasym$zip5_hhinc_mdn) & !is.na(lvscle_ctdasym$HRRNum),]

#Run fixed-effect model
M10_ctdasym <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_ctdasym_noNA,family=binomial())
saveRDS(M10_ctdasym,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_ctdasym.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_ctdasym_noNA$predictions <- predict(M10_ctdasym,type="link",newdata=lvscle_ctdasym_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_ctdasym",i,".Rda")
save(lvscle_ctdasym_noNA,file=lvsfile)

#head
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_head",i,".Rdata"))
lvscle_head<- get(paste0("lvscle_head",i))

#Recode race
lvscle_head$race <- ifelse(lvscle_head$race=="1","white",lvscle_head$race)
lvscle_head$race <- ifelse(lvscle_head$race=="2","black",lvscle_head$race)
lvscle_head$race <- ifelse(lvscle_head$race=="4","asian",lvscle_head$race)
lvscle_head$race <- ifelse(lvscle_head$race=="5","hispanic",lvscle_head$race)
lvscle_head$race <- ifelse(lvscle_head$race %in% c("6","0","3"),"other",lvscle_head$race)

#Create age squared
lvscle_head$age2 <- lvscle_head$age^2

#Recode sex
lvscle_head$female <- 0
lvscle_head$female <- ifelse(lvscle_head$sex=="2",1,lvscle_head$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_head_noNA <- lvscle_head[!is.na(lvscle_head$zip5_college) & !is.na(lvscle_head$zip5_in_poverty) & !is.na(lvscle_head$zip5_hhinc_mdn) & !is.na(lvscle_head$HRRNum),]

#Run fixed-effect model
M10_head <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_head_noNA,family=binomial())
saveRDS(M10_head,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_head.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_head_noNA$predictions <- predict(M10_head,type="link",newdata=lvscle_head_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_head",i,".Rda")
save(lvscle_head_noNA,file=lvsfile)

#psa
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_psa",i,".Rdata"))
lvscle_ps<- get(paste0("lvscle_ps",i))

#Recode race
lvscle_psa$race <- ifelse(lvscle_psa$race=="1","white",lvscle_psa$race)
lvscle_psa$race <- ifelse(lvscle_psa$race=="2","black",lvscle_psa$race)
lvscle_psa$race <- ifelse(lvscle_psa$race=="4","asian",lvscle_psa$race)
lvscle_psa$race <- ifelse(lvscle_psa$race=="5","hispanic",lvscle_psa$race)
lvscle_psa$race <- ifelse(lvscle_psa$race %in% c("6","0","3"),"other",lvscle_psa$race)

#Create age squared
lvscle_psa$age2 <- lvscle_psa$age^2

#Recode sex
lvscle_psa$female <- 0
lvscle_psa$female <- ifelse(lvscle_psa$sex=="2",1,lvscle_psa$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_psa_noNA <- lvscle_psa[!is.na(lvscle_psa$zip5_college) & !is.na(lvscle_psa$zip5_in_poverty) & !is.na(lvscle_psa$zip5_hhinc_mdn) & !is.na(lvscle_psa$HRRNum),]

#Run fixed-effect model
M10_psa <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_psa_noNA,family=binomial())
saveRDS(M10_psa,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_psa.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_psa_noNA$predictions <- predict(M10_psa,type="link",newdata=lvscle_psa_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_psa",i,".Rda")
save(lvscle_psa_noNA,file=lvsfile)

#pth
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_pth",i,".Rdata"))
lvscle_pth<- get(paste0("lvscle_pth",i))

#Recode race
lvscle_pth$race <- ifelse(lvscle_pth$race=="1","white",lvscle_pth$race)
lvscle_pth$race <- ifelse(lvscle_pth$race=="2","black",lvscle_pth$race)
lvscle_pth$race <- ifelse(lvscle_pth$race=="4","asian",lvscle_pth$race)
lvscle_pth$race <- ifelse(lvscle_pth$race=="5","hispanic",lvscle_pth$race)
lvscle_pth$race <- ifelse(lvscle_pth$race %in% c("6","0","3"),"other",lvscle_pth$race)

#Create age squared 
lvscle_pth$age2 <- lvscle_pth$age^2

#Recode sex
lvscle_pth$female <- 0
lvscle_pth$female <- ifelse(lvscle_pth$sex=="2",1,lvscle_pth$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_pth_noNA <- lvscle_pth[!is.na(lvscle_pth$zip5_college) & !is.na(lvscle_pth$zip5_in_poverty) & !is.na(lvscle_pth$zip5_hhinc_mdn) & !is.na(lvscle_pth$HRRNum),]

#Run fixed-effect model
M10_pth <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_pth_noNA,family=binomial())
saveRDS(M10_pth,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_pth.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_pth_noNA$predictions <- predict(M10_pth,type="link",newdata=lvscle_pth_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_pth",i,".Rda")
save(lvscle_pth_noNA,file=lvsfile)

#t3
load(paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_t3",i,".Rdata"))
lvscle_t3<- get(paste0("lvscle_t3",i))

#Recode race
lvscle_t3$race <- ifelse(lvscle_t3$race=="1","white",lvscle_t3$race)
lvscle_t3$race <- ifelse(lvscle_t3$race=="2","black",lvscle_t3$race)
lvscle_t3$race <- ifelse(lvscle_t3$race=="4","asian",lvscle_t3$race)
lvscle_t3$race <- ifelse(lvscle_t3$race=="5","hispanic",lvscle_t3$race)
lvscle_t3$race <- ifelse(lvscle_t3$race %in% c("6","0","3"),"other",lvscle_t3$race)

#Create age squared
lvscle_t3$age2 <- lvscle_t3$age^2

#Recode sex
lvscle_t3$female <- 0
lvscle_t3$female <- ifelse(lvscle_t3$sex=="2",1,lvscle_t3$female)

#Make sure zip-level variables and HRR variable are not missing
lvscle_t3_noNA <- lvscle_t3[!is.na(lvscle_t3$zip5_college) & !is.na(lvscle_t3$zip5_in_poverty) & !is.na(lvscle_t3$zip5_hhinc_mdn) & !is.na(lvscle_t3$HRRNum),]

#Run fixed-effect model
M10_t3 <- glm(outcome ~ age + age2 + female + factor(race) + ccw_alzh_demen + ccw_alzh + ccw_ami + ccw_anemia
+ ccw_asthma + ccw_atrial_fib + ccw_cancer_breast + ccw_cancer_colorectal + ccw_cancer_endometrial + ccw_cancer_lung
+ ccw_cancer_prostate + ccw_cataract + ccw_chf + ccw_chronickidney + ccw_copd + ccw_depression
+ ccw_diabetes + ccw_glaucoma + ccw_hip_fracture + ccw_hyperl + ccw_hyperp + ccw_hypert
+ ccw_hypoth + ccw_ischemicheart + ccw_osteoporosis + ccw_ra_oa + ccw_stroke_tia + ccw_6up + hcc_t1 + mcaid
+ factor(year) + zip5_hhinc_mdn + zip5_in_poverty + zip5_college + factor(HRRNum),data=lvscle_t3_noNA,family=binomial())
saveRDS(M10_t3,"/disk/agedisk4/medicare.work/newhouse-DUA28483/sanghav/out/M10_lvscle_t3.RDS")

#Create variable predictions to store predicted values of outcome
lvscle_t3_noNA$predictions <- predict(M10_t3,type="link",newdata=lvscle_t3_noNA)
lvsfile=paste0("/disk/agedisk3/medicare.work/newhouse-DUA28483/sibylpan-dua28483/LVSCode/fe/out/8lvs/lvscle_t3",i,".Rda")
save(lvscle_t3_noNA,file=lvsfile)


message ("------------All Done------------")
system("date")
message ("---------------------------")
