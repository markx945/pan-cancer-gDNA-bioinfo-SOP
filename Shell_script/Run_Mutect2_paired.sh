#! /bin/bash

set -euo pipefail

# 显示帮助信息
function show_help {
    echo "Usage: $0 -i input_path [-o output_file]"
    echo
    echo "-i normal_bam_file    The path where to look for normal bam file."
    echo "-I tumor_bam_file    The path where to look for tumor bam file."
    echo "-o output_path   The path where to save the SNV and INDEL result. Usually the upper path of shell_script"
    echo "-f ref_genome    The path where to save the reference geneme file. fasta format."
    echo "-d dir_to_annovar    The path where to save the annovar software and annotation database."
    echo "-t Thread         The number of cpu used for analysing."

    echo "Example: $0 -i /path/to/normal_bam_file -I /path/to/tumor_bam_file -o /path/to/upper_path_of_shell_script -f /path/to/reference_genome"
    echo "Example: $0 -i ../mapping/M8_1_combined -I /path/to/tumor_bam_file -o ../ -f ../other_ref/hg38.fa -d ../other_ref/"
    exit 1
}

# 初始化输入和输出变量
normal_bam_file=""
tumor_bam_file=""
output_path=""
ref_genome=""
dir_to_annovar=""
Thread=""

# 解析命令行选项和参数
while getopts "hi:I:o:f:d:t:" opt; do
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
        ref_genome=$OPTARG
        ;;
    d)
        dir_to_annovar=$OPTARG
        ;;
    t)
        Thread=$OPTARG
        ;;
    *)
        show_help
        ;;
    esac
done


# ref_fasta="/home/cfff_r2636/data/reference/hg38/genome/hg38.fa"
ref_fasta=${ref_genome}
# ref_bed="/home/cfff_r2636/data/gDNA_231114/merged_10X_coverage.bed.gz"
out_dir="${output_path}/vcf_mutect2"
# nt="16"


normal_bam=${normal_bam_file}
tumor_bam=${tumor_bam_file}

Normal_full_filename=$(basename "$normal_bam_file")
Normal_sample=$(echo "$Normal_full_filename" | cut -d '.' -f 1)
Tumor_full_filename=$(basename "$tumor_bam_file")
Tumor_sample=$(echo "$Tumor_full_filename" | cut -d '.' -f 1)

mkdir -p ${out_dir}/${Tumor_sample}

# 运行GATK Mutect2
gatk Mutect2 \
    -R "${ref_fasta}" \
    -I "${tumor_bam}" \
    -I "${normal_bam}" \
    --native-pair-hmm-threads ${Thread} \
    -normal ${Normal_sample} \
    --tumor-sample ${Tumor_sample} \
    -O ${out_dir}/${Tumor_sample}/${Tumor_sample}.vcf

## 过滤vcf文件
gatk FilterMutectCalls \
    -V ${out_dir}/${Tumor_sample}/${Tumor_sample}.vcf \
    -R ${ref_fasta} \
    -O ${out_dir}/${Tumor_sample}/${Tumor_sample}.filter.vcf

## 获取PASS文件

find "$out_dir" -type f -name "*.filter.vcf" | while read file; do
    # 为每个文件生成一个新的输出文件名，添加".pass"标识
    output_file="${file%.filter.vcf}.pass.vcf"
    
    # 使用awk过滤每个文件
    # 保留以#开头的行（VCF头部）或第七列为PASS的行
    awk 'BEGIN{FS=OFS="\t"} /^#/ || $7 == "PASS"' "$file" > "$output_file"
    
    echo "Processed: $file -> $output_file"
done

### 注释文件
annotation_out_dir="${output_path}/annovar_mutect2"

# dir_to_annovar="/home/cfff_r2636/data/software/annovar/annovar"

mkdir -p ${annotation_out_dir}/${Tumor_sample}

perl ${dir_to_annovar}/table_annovar.pl \
    ${out_dir}/${Tumor_sample}/${Tumor_sample}.pass.vcf \
    ${dir_to_annovar}/humandb \
    -buildver hg38  \
    -out ${annotation_out_dir}/${Tumor_sample}/${Tumor_sample}  \
    -remove  \
    -protocol refGene,clinvar_20221231,gnomad40_exome,dbnsfp42c,cosmic99_v1  \
    -operation g,f,f,f,f  \
    -nastring .  \
    -vcfinput  \
    -thread 4

