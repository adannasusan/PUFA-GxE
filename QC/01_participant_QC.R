
library(tidyverse)
library(rio)

#Load dataset
ukb <- as_tibble(import("/path/to/ukb/data"))


#--------------------------------------------------------------------------------------------------------------------------------------------------------
#Remove withdrawn participants from dataset
withdrawn <-read.csv("/path/to/withdrawn/participants/file", header = FALSE)
ukb <- ukb[!(ukb$eid %in% withdrawn$V1), ] #502366

#Process Pan UKB data
pan <- read_tsv("/path/to/panUKB/file")
pan <- as_tibble(pan)
pan$s <- as.integer(pan$s)
table(pan$pop, useNA = "always")

bridge <- read.table("/path/to/file/to/convert/panUKB ids/to/UKB ids")
bridge <- as_tibble(bridge)
colnames(bridge) <- c("IID", "panID")

pan2 <- pan %>% select(s, pop) %>% left_join(bridge, by = c("s" = "panID"))

#--------------------------------------------------------------------------------------------------------------------------------------------------------
#Generate a list of participants who pass the following QC criteria:
#1. Genetic ethnicity = Caucasian VIA PAN UKBB
#2. Not an outlier for heterogeneity and missing genotype rate (poor quality genotype)
#3. No Sex chromosome aneuploidy
#4. Self-reported sex matches genetic sex
#5. Do not have high degree of genetic kinship (Ten or more third-degree relatives identified)
#6. Does not appear in "maximum_set_of_unrelated_individuals.MF.pl"


bd_QC <- ukb %>% select(eid, sex_f31_0_0, genetic_sex_f22001_0_0, ethnic_background_f21000_0_0,
                        outliers_for_heterozygosity_or_missing_rate_f22027_0_0, sex_chromosome_aneuploidy_f22019_0_0,
                        genetic_kinship_to_other_participants_f22021_0_0)

colnames(bd_QC) <- c("IID", "Sex", "Genetic_Sex", "Race",
                     "Outliers_for_het_or_missing", "SexchrAneuploidy",
                     "Genetic_kinship")

#1. Genetic ethnicity = Caucasian VIA PAN UKBB
#Join UKB cols with with Pan UKBB
bd_QC <- as_tibble(bd_QC) #502366
bd_QC <- bd_QC %>% inner_join(pan2, by = "IID") #448117

#Filter by Genetic ethnicity = Caucasian VIA PAN UKBB
bd_QC <- bd_QC[bd_QC$pop == "EUR", ] #426810
#bd_QC <- bd_QC[bd_QC$pop == "EUR" | bd_QC$Race == "White" | bd_QC$Race == "Any other white background" | bd_QC$Race == "British", ] #426810

#2. Not an outlier for heterogeneity and missing genotype rate (poor quality genotype)
bd_QC <- bd_QC %>%
    filter(is.na(Outliers_for_het_or_missing) | Outliers_for_het_or_missing != "Yes") #426810 

#3. No Sex chromosome aneuploidy
bd_QC <- bd_QC %>%
    filter(is.na(SexchrAneuploidy) | SexchrAneuploidy != "Yes") #426810 

#4. Self-reported sex matches genetic sex
#If Sex does not equal genetic sex, exclude participant
bd_QC <- bd_QC[bd_QC$Sex == bd_QC$Genetic_Sex, ] #426480

#5. Do not have high degree of genetic kinship (Ten or more third-degree relatives identified)
bd_QC <- bd_QC %>%
    filter(is.na(Genetic_kinship) |
               Genetic_kinship != "Ten or more third-degree relatives identified") #426480 
               
#6. Does not appear in "maximum_set_of_unrelated_individuals.MF.pl"
#Filter related file by those in QC
max_unrelated <- read.table("/path/to/relatedness/file")
max_unrelated <- as.integer(unlist(max_unrelated))
bd_QC <- bd_QC %>% filter(!IID %in% max_unrelated) #357772

QCkeepparticipants <- bd_QC %>% mutate(FID = IID) %>% select(FID, IID)

write.table(QCkeepparticipants, file = "/path/to/filtered/participants/output",
            row.names = FALSE, quote = FALSE)
