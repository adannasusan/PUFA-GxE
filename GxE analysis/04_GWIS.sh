ml GEM/1.5.1-foss-2022a

genodir=("/path/to/genotype/files/in/bgen/format")
pheno=("/path/to/file/containing/ids/phenotypes/exposure/covariates")
outdir=("/path/to/output/directory")
mkdir -p $outdir

phenotypes=("w3FA_resinv" "w3FA_TFAP_resinv" "w6FA_resinv" "w6FA_TFAP_resinv" "w6_w3_ratio_resinv" "DHA_resinv"
            "DHA_TFAP_resinv" "LA_resinv" "LA_TFAP_resinv" "PUFA_resinv" "PUFA_TFAP_resinv" "MUFA_resinv" "MUFA_TFAP_resinv"  
					  "PUFA_MUFA_ratio_resinv") #rank-inverse normal transformed phenotypes

for j in ${phenotypes[@]} 
        do

mkdir -p $outdir/$j

echo running "$j"

GEM \
--bgen $genodir/chr"$i".bgen \
--sample $genodir/chr"$i".sample \
--pheno-file $pheno \
--sampleid-name eid \
--pheno-name $j \
--covar-names sex age age_by_sex PCA1 PCA2 PCA3 PCA4 PCA5 \
PCA6 PCA7 PCA8 PCA9 PCA10 \
--robust 1 \
--exposure-names Status \
--thread 16 \
--output-style meta \
--out $outdir/$j/"$j"xfishOil-chr"$i".txt

done
