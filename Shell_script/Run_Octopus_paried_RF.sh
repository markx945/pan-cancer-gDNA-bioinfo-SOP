#! /bin/bash

set -euo pipefail

# 初始化输入和输出变量
normal_bam_file=""
tumor_bam_file=""
output_path=""
ref_genome=""
dir_to_annovar=""
Thread=""
bed_file=""
# forest_model=""

# 解析命令行选项和参数
while getopts "hi:I:o:f:d:t:b:" opt; do
    case "$opt" in
    h)
        show_help
        ;;
    i)
        normal_bam_file=$OPTARG
        ;;
    I)
        tumor_bam_file=$OPTARG
        ;;
    o)
        output_path=$OPTARG
        ;;
    f)
        ref_fasta=$OPTARG
        ;;
    d)
        dir_to_annovar=$OPTARG
        ;;
    t)
        Thread=$OPTARG
        ;;
    b)
        bed_file=$OPTARG
        ;;
    *)
        show_help
        ;;
    esac
done

Normal_full_filename=$(basename "$normal_bam_file")
Normal_sample=$(echo "$Normal_full_filename" | cut -d '.' -f 1)
Tumor_full_filename=$(basename "$tumor_bam_file")
Tumor_sample=$(echo "$Tumor_full_filename" | cut -d '.' -f 1)

octopus_output=${output_path}/vcf_octopus

mkdir -p ${octopus_output}/${Tumor_sample}
# octopus \
#     -R ${ref_fasta} \
#     -I ${normal_bam_file} ${tumor_bam_file} \
#     --sequence-error-model PCR.NOVASEQ \
#     -o ${octopus_output}/${Tumor_sample}/${Tumor_sample}_octopus_paired.vcf \
#     --threads $Thread \
#     --somatics-only \
#     --annotations AF FRF \
#     -N $Normal_sample \
#     -t ${bed_file}
octopus \
    -R ${ref_fasta} \
    -I ${normal_bam_file} ${tumor_bam_file} \
    --sequence-error-model PCR.NOVASEQ \
    -o ${octopus_output}/${Tumor_sample}/${Tumor_sample}_octopus_paired.vcf \
    --threads $Thread \
    --annotations AF FRF \
    -N $Normal_sample \
    -t ${bed_file}


find "$octopus_output" -type f -name "*.vcf" | while read file; do
    # 为每个文件生成一个新的输出文件名，添加".pass.somatic"标识
    output_file="${file%.vcf}.pass.vcf"
    
    # 使用awk过滤每个文件
    # 保留以#开头的行（VCF头部）或第七列为PASS且第八列包含SOMATIC的行
    awk 'BEGIN{FS=OFS="\t"} /^#/ || ($7 == "PASS" && $8 ~ /SOMATIC/)' "$file" > "$output_file"
    
    echo "Processed: $file -> $output_file"
done

## annotating vcf file
### 注释文件
annotation_output_path="${output_path}/annovar_octopus"

# dir_to_annovar="/home/cfff_r2636/data/software/annovar/annovar"

mkdir -p ${annotation_output_path}/${Tumor_sample}

perl ${dir_to_annovar}/table_annovar.pl \
    ${octopus_output}/${Tumor_sample}/${Tumor_sample}.pass.vcf \
    ${dir_to_annovar}/humandb \
    -buildver hg38  \
    -out ${annotation_output_path}/${Tumor_sample}/${Tumor_sample}  \
    -remove  \
    -protocol refGene,clinvar_20221231,gnomad40_exome,dbnsfp42c,cosmic99_v1  \
    -operation g,f,f,f,f  \
    -nastring .  \
    -vcfinput  \
    -thread 4