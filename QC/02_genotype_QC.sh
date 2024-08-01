i=$SLURM_ARRAY_TASK_ID

ml PLINK/2.00a4-GCC-11.2.0

genoindir=("/path/to/UKB/genotype/data")
mfiscoredir=("/path/to/imputation/quality/file") #filtered to keep SNPs of imputation quality >0.5
outdir=("path/to/output")
mkdir -p $outdir

plink2 \
--bgen $genoindir/ukb_imp_chr"$i"_v3.bgen ref-first \
--sample $genoindir/ukb_imp_v3.sample \
--extract $mfiscoredir/uk"$i".txt \
--mind 0.05 \
--geno 0.02 \
--hwe 1e-06 \
--maf 0.01 \
--autosome \
--maj-ref \
--max-alleles 2 \
--exclude path/to/duplicate_snp_ids \
--keep path/to.filtered/participant/ids \
--export ind-major-bed \
--out "$outdir"/chr"$i"
