#!/bin/bash
#SBATCH --job-name=prt
#SBATCH --ntasks=64 
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=64 
#SBATCH --output=%x_%j.log 
#SBATCH --partition=normal 
#SBATCH -t 240:00:00 
module purge # 清除之前挂载的所有模块，我们可以使用conda进行包管理


cd $SLURM_SUBMIT_DIR

OPT_DIR="/master/wang_xian_geng/opt"  
source ${OPT_DIR}/miniconda3_new/etc/profile.d/conda.sh # 先保留原始的内容
conda activate prt

prt_dir="/cpu1/wang_xian_geng/pdac/prt"
cnf="../cnf/PDC000270_prt.cnf"
raw_dir="${prt_dir}/mzml/PDC000270"
id_dir="${prt_dir}/rst"
time_stamp=$(date +"%F")
my_aa="/cpu1/wang_xian_geng/pdac/cl/orf/cl_6_1/2024-01-17_cl_6_1.fa"
db_dir="${prt_dir}/db"
hrp="${db_dir}/UP000005640_9606.fasta"
db="${db_dir}/2024-01-23_ref_plus_cl_novel.pep.fa"

if [ ! -f ${db} ]; then
    bioawk -c fastx '{if($name~/TALON/){print ">"$name;print $seq}}' ${my_aa} > ${db_dir}/${time_stamp}_novel_cl.fa
    cat ${db_dir}/${time_stamp}_novel_cl.fa ${hrp} > ${db_dir}/2024-01-23_ref_plus_cl_novel.pep.fa
else
    echo "ok for ${db}"
fi



# PR_CNF="../prt/cnf/mod.cnf"
# cd /dataserver145/image/wangxiangeng/hcc/code
for asy in `cat $cnf`; do
  echo "processing $asy"
  #base=`basename -s .mzML $file`
  file="${raw_dir}/${asy}.mzML"
  if [ -f "${id_dir}/${asy}.mzid" ]; then
    echo "the file of ${base} has been processed!"
  else
    msgf_plus -s ${file} -d ${db} \
      -t 10ppm -thread 64 -tda 1 -m 3 -inst 1 -e 1 \
      -protocol 4 -ntt 2 -maxMissedCleavages 2 -o ${id_dir}/${asy}.mzid
  fi  

  if [ $? -eq 0 ]; then
    gzip $file &
  fi  

done
wait


OPT_DIR="/master/wang_xian_geng/opt"  
# source ${OPT_DIR}/miniconda3_new/etc/profile.d/conda.sh 
# conda activate base
#CNF="../prt/cnf/20220318_mzid.cnf"
CNF="/cpu1/wang_xian_geng/pdac/cl/cnf/PDC000270_prt.cnf" # 
MZID_DIR="/cpu1/wang_xian_geng/pdac/prt/rst"
OUT_DIR="/cpu1/wang_xian_geng/pdac/prt/rst"
ANNO="/cpu1/wang_xian_geng/pdac/cl/master/cl_6_1_talon_abundance_filtered.tsv"
for mzid in `cat $CNF`; do
  input="${MZID_DIR}/${mzid}"
  base=`basename $input .mzid`
  output="${OUT_DIR}/${base}.tsv"
  if [ ! -f $output ]; then 
    echo "processing $input"
    mzid2isoform.R  ${input}.mzid $ANNO $output --verbose --strict
  else
    echo "$input has been processed"
  fi
done

TIDY_FILE="${OUT_DIR}/2024-06-05_merge.tsv"
touch ${TIDY_FILE}
for mzid in `cat $CNF`; do
    input="${MZID_DIR}/${mzid}"
    base=`basename $input .mzid`
    output="${OUT_DIR}/${base}.tsv"
    tail -n+2 ${output} | cut -f 2- >> ${TIDY_FILE}
done