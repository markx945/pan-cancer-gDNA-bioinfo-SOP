#! /bin/bash

set -euo pipefail

# 显示帮助信息
function show_help {
    echo "Usage: $0 -i normal_bam_file -I tumor_bam_file -o output_path -b bed_file -f ref_genome "
    echo
    echo "-i normal_bam_file    The path where to look for normal bam file."
    echo "-I tumor_bam_file    The path where to look for tumor bam file."
    echo "-o output_path   The path where to save the SNV and INDEL result. Usually the upper path of shell_script"
    echo "-b bed_file    The path where to save the bed file for WES or Panel sequencing"
    echo "-f ref_genome    The path where to save the reference geneme file. fasta format"
    echo "-a annotated_file    The path where to save the CNVkit reference file"
    echo "-t thread         Number of threads to use"
    echo
    echo "Example: $0 -i /path/to/normal_bam_file -I /path/to/tumor_bam_file -o /path/to/upper_path_of_shell_script -f /path/to/reference_genome -b /path/to/bed/file -a path/to/CNVkit/annotate/file"
    exit 1
}

# 解析命令行选项和参数
while getopts "hi:I:o:b:f:a:t:" opt; do
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
        out_dir=$OPTARG
        ;;
    b)
        bed_file=$OPTARG
        ;;
    f)
        ref_genome=$OPTARG
        ;;
    a)
        annotated_file=$OPTARG
        ;;
    t)
        Thread=$OPTARG
        ;;
    *)
        show_help
        ;;
    esac
done

normal_bam=${normal_bam_file}
tumor_bam=${tumor_bam_file}

Normal_full_filename=$(basename "$normal_bam_file")
Normal_sample=$(echo "$Normal_full_filename" | cut -d '.' -f 1)
Tumor_full_filename=$(basename "$tumor_bam_file")
Tumor_sample=$(echo "$Tumor_full_filename" | cut -d '.' -f 1)


mkdir -p ${out_dir}/${Tumor_sample}

## 利用CNVkit注释文件分割bed文件，生成中间文件
/home/cfff_r2636/.local/bin/cnvkit.py target ${bed_file} --annotate ${annotated_file} \
    --split --short-names \
    -o ${out_dir}/${Tumor_sample}/my_baits.bed
### 生成CNV参考文件
/home/cfff_r2636/.local/bin/cnvkit.py batch ${tumor_bam} --normal ${normal_bam} \
    --targets ${out_dir}/${Tumor_sample}/my_baits.bed \
    --fasta ${ref_genome} \
    --annotate ${annotated_file} \
    -p $Thread --drop-low-coverage \
    --output-dir ${out_dir}/${Tumor_sample}/${Tumor_sample}.reference.cnn

echo "${Tumor_sample} CNV analysis finished."