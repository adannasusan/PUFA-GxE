library(tidyverse)
library(rio)

phenotype = c("w3FA_resinv", "w3FA_TFAP_resinv", "w6FA_resinv", "w6FA_TFAP_resinv",
            "w6_w3_ratio_resinv", "DHA_resinv", "DHA_TFAP_resinv", "LA_resinv",
            "LA_TFAP_resinv", "PUFA_resinv", "PUFA_TFAP_resinv", "MUFA_resinv",
            "MUFA_TFAP_resinv", "PUFA_MUFA_ratio_resinv")

exposure = "fishOil"
for (pheno in phenotype) {

setwd(paste("/path/to/GWIS/output/", pheno, "/", sep = ""))
start = as_tibble(import(paste(pheno, "x", exposure, "-chr", "1", ".txt", sep = "")))

for (i in 2:22) {
        add = as_tibble(import(paste(pheno, "x", exposure, "-chr", i, ".txt", sep = ""))) 
        start = rbind(start, add)
}

write_tsv(start, paste("path/to/combined/files/output/", pheno, exposure, "ALL", ".txt", sep = ""), 
        quote="none")
print(paste("Done with: ", pheno, " x ", exposure, sep=""))
}
