#!/bin/bash
#SBATCH --job-name=cl_6
#SBATCH --ntasks=64 
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=64 
#SBATCH --output=cl_6.log 
#SBATCH --partition=normal 
#SBATCH -t 240:00:00 
#module purge # 清除之前挂载的所有模块，我们可以使用conda进行包管理
#cd $SLURM_SUBMIT_DIR


## 原始数据处理
# 环境参数
CONDA_DIR="/master/wang_xian_geng/opt/miniconda3_new"
ENV="isoseq"
source "${CONDA_DIR}/etc/profile.d/conda.sh"
conda activate ${ENV}

# 参考参数
PRIMER="/storage1/ref/isoseq_primer.fa" 
#>NEB_6p
#GCAATGAAGTCGCAGGGTTGGGG
#>Clontech_6p
#AAGCAGTGGTATCAACGCAGAGTACATGGGG
#>NEB_Clontech_3p
#GTACTCTGCGTTGATACCACTGCTT
REF_FA="/storage1/ref/gencode/GRCh38.p13.genome.fa"
REF="/storage1/ref/gencode/GRCh38.p13.genome.mmi"
REF_ANNO="/storage1/ref/gencode/gencode.v41.annotation.gtf"

# 项目配置参数：唯一要改的内容
CNF="/cpu1/wang_xian_geng/pdac/cl/cnf/cl_6.cnf"
BAM_DIR="/cpu1/wang_xian_geng/pdac/cl/isoseq"
OUT_DIR="${BAM_DIR}"
GFF_DIR="${BAM_DIR}"




echo "now we start raw data analysis"
for assay in `cat ${CNF}`; do 
   if [ ! -f ${GFF_DIR}/${assay}.MD.sam ]; then
    ccs ${BAM_DIR}/${assay}.subreads.bam ${OUT_DIR}/${assay}.ccs.bam --min-rq 0.9 -j 64
    lima ${OUT_DIR}/${assay}.ccs.bam $PRIMER ${OUT_DIR}/${assay}.fl.bam --isoseq --peek-guess -j 64
    # RDPYR18124839_A.fl.NEB_6p--NEB_Clontech_3p.bam
    isoseq3 refine ${OUT_DIR}/${assay}.fl.*--NEB_Clontech_3p.bam $PRIMER ${OUT_DIR}/${assay}.flnc.bam -j 64 # 避免两个5'的问题
    isoseq3 cluster ${OUT_DIR}/${assay}.flnc.bam ${OUT_DIR}/${assay}.clustered.bam --verbose --use-qvs -j 64
    pbmm2 align ${REF} ${OUT_DIR}/${assay}.clustered.hq.bam ${OUT_DIR}/${assay}.aligned.bam -j 64 --preset ISOSEQ --sort --log-level INFO
    isoseq3 collapse ${OUT_DIR}/${assay}.aligned.bam ${GFF_DIR}/${assay}.collapsed.gff -j 64 --log-level INFO
    samtools calmd ${OUT_DIR}/${assay}.aligned.bam $REF_FA > ${GFF_DIR}/${assay}.MD.sam
   else
      echo "isoseq3 done for ${assay}"
   fi
done


## talon合并数据库
source /master/wang_xian_geng/opt/env/cityu36_py36/bin/activate


# 项目配置参数：唯一要改的内容
# IN_DIR="../gff" # GFF_DIR
NEW_OUT_DIR="/cpu1/wang_xian_geng/pdac/cl/master"
# CNF="../cnf/20221026_sam_35.cnf"
TALON_CONFIG="/cpu1/wang_xian_geng/pdac/cnf/2024-01-03_cl_tln.cnf" # 需要改正


# mkdir gff_merge/sam   

# t cores
# 

for i in $(cat $CNF); do
       talon_label_reads --f ${GFF_DIR}/${i}.MD.sam  --g $REF_FA --t 64 --ar 20 --deleteTmp --o ${NEW_OUT_DIR}/${i}  
       # Output: ${assay}_labeled.sam; ${assay}_read_labels.tsv
done

# # --f CONFIG_FILE       Dataset config file: dataset name, sample description, platform, sam file (comma-delimited)  
talon_initialize_database --f ${REF_ANNO} --g hg38 --a gencode41 --o ${NEW_OUT_DIR}/cl_6
echo "now we move to merge"
# # 20221026-好像还是只能单线程运行
talon --f ${TALON_CONFIG} \
      --db ${NEW_OUT_DIR}/cl_6.db \
      --build hg38 \
      --t 64 \
      --o ${NEW_OUT_DIR}/cl_6

# #### 不过滤      

talon_summarize --db ${NEW_OUT_DIR}/cl_6.db --v --o ${NEW_OUT_DIR}/cl_6_all
talon_abundance --db ${NEW_OUT_DIR}/cl_6.db -a gencode41 --build hg38 --o ${NEW_OUT_DIR}/cl_6_all

# #### 过滤两个样本

talon_filter_transcripts --db ${NEW_OUT_DIR}/cl_6.db \
    -a gencode41 \
    --maxFracA 0.5 \
    --minCount 1 \
    --minDatasets 2 \
    --o ${NEW_OUT_DIR}/cl_6_2_filter.csv  
  
talon_create_GTF --db ${NEW_OUT_DIR}/cl_6.db \
    --whitelist ${NEW_OUT_DIR}/cl_6_2_filter.csv -a gencode41 --build hg38 --o ${NEW_OUT_DIR}/cl_6_2  
  
  
talon_abundance --db ${NEW_OUT_DIR}/cl_6.db \
    --whitelist ${NEW_OUT_DIR}/cl_6_2_filter.csv \
    -a gencode41 --build hg38 --o ${NEW_OUT_DIR}/cl_6_2 

# #### 过滤一个样本
talon_filter_transcripts --db ${NEW_OUT_DIR}/cl_6.db \
    -a gencode41 \
    --maxFracA 0.5 \
    --minCount 1 \
    --minDatasets 1 \
    --o ${NEW_OUT_DIR}/cl_6_1_filter.csv  
  
talon_create_GTF --db ${NEW_OUT_DIR}/cl_6.db \
    --whitelist ${NEW_OUT_DIR}/cl_6_1_filter.csv -a gencode41 --build hg38 --o ${NEW_OUT_DIR}/cl_6_1  
  
  
talon_abundance --db ${NEW_OUT_DIR}/cl_6.db \
    --whitelist ${NEW_OUT_DIR}/cl_6_1_filter.csv \
    -a gencode41 --build hg38 --o ${NEW_OUT_DIR}/cl_6_1 

