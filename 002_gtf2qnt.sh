#!/bin/bash
#SBATCH --job-name=qnt_old
#SBATCH --ntasks=64 
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=64 
#SBATCH --output=%x_%j.log
#SBATCH --partition=normal 
#SBATCH -t 240:00:00 
module purge # 清除之前挂载的所有模块，我们可以使用conda进行包管理

OPT_DIR="/master/wang_xian_geng/opt"  
source ${OPT_DIR}/miniconda3_new/etc/profile.d/conda.sh  
conda activate rnaseq
prj_dir="/cpu1/wang_xian_geng/pdac"
base_dir="${prj_dir}/cl/rnaseq/old_idx"
#### purist

# -l IU
# -i
# -1/-2
# --seqBias
# --gcBias
# --posBias
cnf="${prj_dir}/cnf/purist_pe_125.cnf"
fq_dir="/storage2/pdac/rnaseq/purist/raw_fq"
out_dir="${base_dir}/purist"
idx="/cpu1/wang_xian_geng/share/dt/slm_idx/gentrome"
for i in $(cat $cnf); do
    if [ ! -f "${out_dir}/${i}/quant.sf" ]; then
 	    salmon quant -i ${idx} -l IU -1 ${fq_dir}/${i}_1.fq.gz -2 ${fq_dir}/${i}_2.fq.gz -p 64 --validateMappings -o ${out_dir}/${i} --seqBias --gcBias --posBias
    else
        echo "${i} done"
    fi
done


cnf="${prj_dir}/cnf/purist_se_66.cnf"
fq_dir="/storage2/pdac/rnaseq/purist/raw_fq"
out_dir="${base_dir}/purist"
# idx="${prj_dir}/cl/new_ref/cl_6_1_flt"
for i in $(cat $cnf); do
    if [ ! -f "${out_dir}/${i}/quant.sf" ]; then
	    salmon quant -i ${idx} -l U -r ${fq_dir}/${i}.fq.gz -p 64 --validateMappings -o ${out_dir}/${i} --seqBias --gcBias --posBias
    else
        echo "${i} done"
    fi    
done

#### ccle
cnf="${prj_dir}/cnf/ccle_41.cnf"
fq_dir="/storage2/ccle/rnaseq/pdac/raw_fq"
out_dir="${base_dir}/ccle"
# idx="${prj_dir}/isoseq/new_ref/pdac_4_2"
for i in $(cat $cnf); do
    if [ ! -f "${out_dir}/${i}/quant.sf" ]; then
	    salmon quant -i ${idx} -l IU -1 ${fq_dir}/${i}_1.fq.gz -2 ${fq_dir}/${i}_2.fq.gz -p 32 --validateMappings -o ${out_dir}/${i} --seqBias --gcBias --posBias
    else
        echo "${i} done"
    fi    
done

#### amc
cnf="${prj_dir}/cnf/2022-11-28_amc_106.cnf"
fq_dir="/storage2/pdac/rnaseq/amc/raw_fq"
out_dir="${base_dir}/amc"
# idx="${prj_dir}/isoseq/new_ref/pdac_4_2"
for i in $(cat $cnf); do
    if [ ! -f "${out_dir}/${i}/quant.sf" ]; then
	    salmon quant -i ${idx} -l U -r ${fq_dir}/${i}.fq.gz -p 32 --validateMappings -o ${out_dir}/${i} --seqBias --gcBias --posBias
    else
        echo "${i} done"
    fi    
done

#### changhai
cnf="${prj_dir}/cnf/changhai_62.cnf"
fq_dir="/storage2/pdac/rnaseq/changhai/raw_fq"
out_dir="${base_dir}/changhai"
# idx="${prj_dir}/isoseq/new_ref/pdac_4_2"
for i in $(cat $cnf); do
    if [ ! -f "${out_dir}/${i}/quant.sf" ]; then
	    salmon quant -i ${idx} -l IU -1 ${fq_dir}/${i}_1.fq.gz -2 ${fq_dir}/${i}_2.fq.gz -p 64 --validateMappings -o ${out_dir}/${i} --seqBias --gcBias --posBias
    else
        echo "${i} done"
    fi  
done
