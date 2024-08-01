library(tidyverse)
library(data.table)


ukb <- fread("/path/to/ukb/data", stringsAsFactors=F, data.table=F) #502,366
sub_ukb = select(ukb, c("eid", "mineral_and_other_dietary_supplements_f6179_0_0"))

#Create column to label no fish oil and fish oil takers
sub_ukb = mutate(sub_ukb, Status = case_when((sub_ukb[,2] == 1) ~ "fishOil", 
                                     (sub_ukb[,2] == 2) ~ "nonFishOil",
                                     (sub_ukb[,2] == 3) ~ "nonFishOil",
                                     (sub_ukb[,2] == 4) ~ "nonFishOil",
                                     (sub_ukb[,2] == 5) ~ "nonFishOil",
                                     (sub_ukb[,2] == 6) ~ "nonFishOil",
                                     (sub_ukb[,2] == -7) ~ "nonFishOil",
                                     (sub_ukb[,2] == -3) ~ "N/A",
                                     (is.na(sub_ukb[,2])) ~ "N/A")) 

#fishOil: 155,787; nonFishOil: 340,383; NA: 6196


#Keep only participants that met filtering criteria
filtered <- as_tibble(import("/path/to/filtered/participants/file"))

sub_ukb <- filter(sub_ukb, (eid %in% filtered$IID)) #357,772

#Keep only filtered participants that have available genotype information
geno <- as_tibble(read.table("/path/to/genotype/file", 
        header = TRUE, stringsAsFactors = FALSE)) #I used chr.11 sample file as genotype file, 
																									#and kept only individuals present in this file

sub_ukb <- filter(sub_ukb, (eid %in% geno$ID_2)) #357,327

#Remove individuals with missing fish oil use 
sub_ukb = filter(sub_ukb, sub_ukb[, 'Status'] != "N/A") #356,181

sub_ukb$Status = replace(sub_ukb$Status, sub_ukb$Status == "nonFishOil", 0) 
sub_ukb$Status = replace(sub_ukb$Status, sub_ukb$Status == "fishOil", 1) 
sub_ukb$Status = as.numeric(sub_ukb$Status)


#Add covar and NMR data
nmr_covar = ukb %>% select(eid, sex_f31_0_0, age_when_attended_assessment_centre_f21003_0_0,
                           paste("genetic_principal_components_f22009_0_", 1:20, sep=""),
                           omega3_fatty_acids_f23444_0_0, 
                           omega3_fatty_acids_to_total_fatty_acids_percentage_f23451_0_0,
                           omega6_fatty_acids_f23445_0_0,
                           omega6_fatty_acids_to_total_fatty_acids_percentage_f23452_0_0,
                           omega6_fatty_acids_to_omega3_fatty_acids_ratio_f23459_0_0,
                           docosahexaenoic_acid_f23450_0_0, 
                           docosahexaenoic_acid_to_total_fatty_acids_percentage_f23457_0_0,
                           linoleic_acid_f23449_0_0, linoleic_acid_to_total_fatty_acids_percentage_f23456_0_0,
                           polyunsaturated_fatty_acids_f23446_0_0, 
                           polyunsaturated_fatty_acids_to_total_fatty_acids_percentage_f23453_0_0,
                           monounsaturated_fatty_acids_f23447_0_0,
                           monounsaturated_fatty_acids_to_total_fatty_acids_percentage_f23454_0_0,
                           polyunsaturated_fatty_acids_to_monounsaturated_fatty_acids_ratio_f23458_0_0) %>% as_tibble()


colnames(nmr_covar) <- c("eid", "sex", "age",
                         paste("PCA", 1:20, sep=""), "w3FA", "w3FA_TFAP",
                         "w6FA", "w6FA_TFAP", "w6_w3_ratio", "DHA","DHA_TFAP",
                         "LA", "LA_TFAP", "PUFA", "PUFA_TFAP", "MUFA", "MUFA_TFAP",
                         "PUFA_MUFA_ratio")

nmr_covar <- nmr_covar %>% mutate(age_by_sex = age * sex, .after=age2) 
 

#Merge with initial assessment
pheno = as_tibble(merge(sub_ukb, nmr_covar, by = 'eid'))
colnames(pheno)


#Remove missing NMR
colSums(is.na(pheno))

pheno <- drop_na(pheno, 'w6_w3_ratio')
pheno <- drop_na(pheno, 'PUFA_MUFA_ratio')


#nrow(pheno[pheno$Status == 0, ]) 136,349
#nrow(pheno[pheno$Status == 1, ]) 63,711

#Rank Inverse Normal Log Transformation of NMR metabolites
phenotypes <- c("w3FA", "w3FA_TFAP", "w6FA", "w6FA_TFAP", "w6_w3_ratio", "DHA","DHA_TFAP",
                "LA", "LA_TFAP", "PUFA", "PUFA_TFAP", "MUFA", "MUFA_TFAP", "PUFA_MUFA_ratio")

resdat_inv <- matrix(NA,nrow(pheno),length(phenotypes)) #no of phenotypes
colnames(resdat_inv)<-paste(phenotypes, "resinv", sep="_")


inversenormal <- function(x) { 
  # inverse normal if you have missing data 
  return(qnorm((rank(x,na.last="keep", ties.method="random")-0.5)/sum(!is.na(x)))) 
}

  for (x in 29:42){
    resdat_inv[,x-28] <- inversenormal(pheno[,x])
  }

resdat_inv <-as_tibble(as.data.frame(resdat_inv))
resdat_inv$eid <-pheno$eid

pheno <-left_join(pheno, resdat_inv, by="eid")

write_tsv(pheno, "/path/to/output/file.tsv", quote="none")
write_csv(pheno, "/path/to/output/file.csv", quote="none")
