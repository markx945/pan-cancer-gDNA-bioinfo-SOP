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

dir_to_Neusomatic="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/Neusomatic/neusomatic/neusomatic"
Neusomatic_model="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/Neusomatic/neusomatic/neusomatic/models/NeuSomatic_v0.1.4_standalone_SEQC-WGS-GT50-SpikeWGS10.pth"

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


Neusomatic_output=${output_path}/vcf_neusomatic

mkdir -p ${Neusomatic_output}/${Tumor_sample}

python3.7 ${dir_to_Neusomatic}/python/preprocess.py \
	--mode call \
	--reference ${ref_fasta} \
	--region_bed ${bed_file} \
	--tumor_bam ${tumor_bam_file} \
	--normal_bam ${normal_bam_file} \
	--work ${Neusomatic_output}/${Tumor_sample}/work_call \
	--min_mapq 10 \
	--num_threads ${Thread} \
	--scan_alignments_binary ${dir_to_Neusomatic}/bin/scan_alignments

python3.7 ${dir_to_Neusomatic}/python/call.py \
	--candidates_tsv ${Neusomatic_output}/${Tumor_sample}/work_call/dataset/*/candidates*.tsv \
	--reference ${ref_fasta} \
	--out ${Neusomatic_output}/${Tumor_sample} \
	--checkpoint ${Neusomatic_model} \
	--num_threads ${Thread} \
	--batch_size 100 

python3.7 ${dir_to_Neusomatic}/python/postprocess.py \
	--reference ${ref_fasta} \
	--tumor_bam ${tumor_bam_file} \
	--pred_vcf ${Neusomatic_output}/${Tumor_sample}/pred.vcf \
	--candidates_vcf ${Neusomatic_output}/${Tumor_sample}/work_call/work_tumor/filtered_candidates.vcf \
	--output_vcf ${Neusomatic_output}/${Tumor_sample}/${Tumor_sample}_NeuSomatic.vcf \
	--work ${Neusomatic_output}/${Tumor_sample} 

## 过滤文件
find ${Neusomatic_output}/${Tumor_sample} -type f -name "*_NeuSomatic.vcf" | while read file; do
    # 为每个文件生成一个新的输出文件名，添加".pass"标识
    output_file="${file%_NeuSomatic.vcf}.pass.vcf"
    
    # 使用awk过滤每个文件
    # 保留以#开头的行（VCF头部）或第七列为PASS的行
    awk 'BEGIN{FS=OFS="\t"} /^#/ || $7 == "PASS"' "$file" > "$output_file"
    
    echo "Processed: $file -> $output_file"
done

###
## annotating vcf file
### 注释文件
annotation_output_path="${output_path}/annovar_Neusomatic_S"

# dir_to_annovar="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/annovar/annovar"

mkdir -p ${annotation_output_path}/${Tumor_sample}

perl ${dir_to_annovar}/table_annovar.pl \
    ${Neusomatic_output}/${Tumor_sample}/${Tumor_sample}.pass.vcf \
    ${dir_to_annovar}/humandb \
    -buildver hg38  \
    -out ${annotation_output_path}/${Tumor_sample}/${Tumor_sample}  \
    -remove  \
    -protocol refGene,clinvar_20221231,gnomad40_exome,dbnsfp42c,cosmic99_v1  \
    -operation g,f,f,f,f  \
    -nastring .  \
    -vcfinput  \
    -thread 4







