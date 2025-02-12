#!/bin/bash
#SBATCH --job-name=pdac_orf
#SBATCH --ntasks=64
#SBATCH --nodes=1 
#SBATCH --exclude=gpu1
#SBATCH --output=%x_%j.log 
#SBATCH --partition=normal 
#SBATCH -t 240:00:00 
module purge # 清除之前挂载的所有模块，我们可以使用conda进行包管理

### system var  
OPT_DIR="/master/wang_xian_geng/opt"  
SQANTI_DIR="${OPT_DIR}/SQANTI3-5.1"    
source ${OPT_DIR}/miniconda3_new/etc/profile.d/conda.sh  
conda activate sqanti3_v5.1 
export PYTHONPATH=$PYTHONPATH:${OPT_DIR}/cDNA_Cupcake/sequence/  
export PYTHONPATH=$PYTHONPATH:${OPT_DIR}/cDNA_Cupcake/  

SQANTI3_QC="${SQANTI_DIR}/sqanti3_qc.py"
SQANTI3_FILTER="${SQANTI_DIR}/sqanti3_filter.py"
CAGE="${SQANTI_DIR}/data/ref_TSS_annotation/human.refTSS_v3.1.hg38.bed"  
POLYA_MOTIF="${SQANTI_DIR}/data/polyA_motifs/mouse_and_human.polyA_motif.txt"  
POLYA_SITE="${SQANTI_DIR}/data/polyA_sites/atlas.clusters.2.0.GRCh38.96.bed"  
GFF3="${SQANTI_DIR}/data/fit/Homo_sapiens_GRCh38_Ensembl_86.gff3"  
SJ="${SQANTI_DIR}/data/my_sj/intropolis.v1.hg19_with_liftover_to_hg38.tsv.min_count_10.modified"
REF_GTF="/storage1/ref/gencode/gencode.v41.annotation.gtf"  
GENOME="/storage1/ref/gencode/GRCh38.p13.genome.fa"  


#### user var  
my_gtf="/cpu1/wang_xian_geng/pdac/cl/master/cl_6_2_talon.gtf" # 必是转换后gff3
gffread -T ${my_gtf} > /cpu1/wang_xian_geng/pdac/cl/master/cl_6_2_talon.gff3
my_gtf="/cpu1/wang_xian_geng/pdac/cl/master/cl_6_2_talon.gff3"
out_dir="/cpu1/wang_xian_geng/pdac/cl/master"  
out_name="cl_6_2"  
python ${SQANTI3_QC} ${my_gtf} ${REF_GTF} ${GENOME} -n 64 --saturation --report both --isoAnnotLite --gff3 ${GFF3} \
    --CAGE_peak ${CAGE} --polyA_motif_list ${POLYA_MOTIF} --polyA_peak ${POLYA_SITE} -c ${SJ} \
     -d ${out_dir} -o ${out_name}
rst="${out_dir}/${out_name}_classification.txt"
rst_gtf="${out_dir}/${out_name}_corrected.gtf"
rst_fa="${out_dir}/${out_name}_corrected.fasta"
# out_dir="/cpu1/wang_xian_geng/brca/isoseq/gff_qc"  
out_name="${out_name}_flt"
# 氨基酸序列依照cpat
python ${SQANTI3_FILTER} ML ${rst} -d ${out_dir} -o ${out_name} --gtf ${rst_gtf} --isoform ${rst_fa}

# ${out_name}_flt_filter.fa/gtf/
OPT_DIR="/master/wang_xian_geng/opt"  
source ${OPT_DIR}/miniconda3_new/etc/profile.d/conda.sh  
conda activate base

cpat_hex="/storage1/ref/cpat/Human_Hexamer.tsv"  
cpat_mdl="/storage1/ref/cpat/Human_logitModel.RData"  
pfam_dir="/storage1/ref/pfam/35"  
signalp="/master/wang_xian_geng/opt/signalp-4.1/signalp"  
iupred2a_dir="/master/wang_xian_geng/opt/iupred2a"  
spider="/master/wang_xian_geng/opt/SPIDER/spider.py"  
tmhmm="/master/wang_xian_geng/opt/tmhmm-2.0c/bin/tmhmm"


my_orf_translate="/master/wang_xian_geng/opt/my_bin/2022-11-18_orf-translate.R"
my_ptm_parse="/master/wang_xian_geng/opt/my_bin/2022-11-19_parse-raw-ptm.py"

prj_dir="/cpu1/wang_xian_geng/pdac/cl"
my_name="cl_6_2"
rna="${prj_dir}/master/${my_name}_flt.filtered.fasta"  
out_dir="${prj_dir}/orf"
db="/cpu1/wang_xian_geng/pdac/prt/db/ref_prt"
time_stamp=$(date +"%F")

# 生成的文件有
# .ORF_seqs.fa
# .r
# .ORF_prob.tsv
# .ORF_prob.best.tsv
# .no_ORF.txt

# 但是可复用的脚本要使用
cpat.py -x ${cpat_hex} --top-orf=1 -d ${cpat_mdl} -g ${rna} -o ${out_dir}/${my_name} 

${my_orf_translate} -i ${out_dir}/${my_name}.ORF_seqs.fa \
	-o ${out_dir}/${time_stamp}_${my_name}.fa --db ${db} --rds ${out_dir}/${time_stamp}_blast_rst.rds

ok_aa="${out_dir}/${time_stamp}_${my_name}.fa"
ok_aa_base="${out_dir}/${time_stamp}_${my_name}"

#### pfam
pfam_scan.pl -cpu 64 -as -fasta "${ok_aa}" \
	-dir ${pfam_dir} -outfile ${out_dir}/${time_stamp}.pfam 
cat ${out_dir}/${time_stamp}.pfam |grep -v "#"|grep -v '^$' > ${out_dir}/${time_stamp}_ok.pfam

#### signalp
# 至多两万
pyfasta split -n2 ${ok_aa}
${signalp} -f summary -T ${out_dir}/old "${ok_aa_base}.0.fa" > ${out_dir}/${time_stamp}.signalp.0	
${signalp} -f summary -T ${out_dir}/old "${ok_aa_base}.1.fa" > ${out_dir}/${time_stamp}.signalp.1	


##### deeploc2/spider/tmhmm
# 文件夹形式
deeploc2 -f "${ok_aa}" -o ${out_dir}/${time_stamp}_loc_accurate -m Accurate 
mv ${out_dir}/${time_stamp}_loc_accurate/*.csv ${out_dir}/${time_stamp}_loc_accurate.csv 
${spider} -i "${ok_aa}" -o ${out_dir}/${time_stamp}_drug.csv
${tmhmm} "${ok_aa}" -workdir old/ > ${out_dir}/${time_stamp}_tm.tsv



#### musite
conda activate ptm
MUSITE="/master/wang_xian_geng/opt/MusiteDeep_web/MusiteDeep/predict_multi_batch.py"
MODEL_DIR="/master/wang_xian_geng/opt/MusiteDeep_web/MusiteDeep/models"
PTM="Hydroxylysine;Hydroxyproline;Methylarginine;Methyllysine;N6-acetyllysine;N-linked_glycosylation;O-linked_glycosylation;Phosphoserine_Phosphothreonine;Phosphotyrosine;Pyrrolidone_carboxylic_acid;S-palmitoyl_cysteine;SUMOylation;Ubiquitination"
# 输出有
# ptm_predicted_num.txt
# ptm_results.txt
python ${MUSITE} -input "${ok_aa}" -output ${out_dir}/ptm -model-prefix "${MODEL_DIR}/${PTM}";
cat ${out_dir}/ptm_results.txt | grep -v "Position" > ${out_dir}/${time_stamp}_ptm.tsv
conda activate base
${my_ptm_parse} ${out_dir}/${time_stamp}_ptm.tsv ${out_dir}/${time_stamp}_ptm_ok.tsv other






