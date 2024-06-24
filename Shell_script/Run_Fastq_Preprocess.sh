#!/bin/bash

set -euo pipefail

# 显示帮助信息
function show_help {
    echo "Usage: $0 -i input_path [-o output_file]"
    echo
    echo "-i input_path    The path where to look for raw fastq file."
    echo "-o output_path   The path where to save the fastqc result. Usually the upper path of shell_script"
    echo
    echo "Example1: $0 -i /path/to/rawfastq -o /path/to/upper_path_of_shell_script "
    echo "Example2: $0 -i ../Rawdata -o ../ "
    echo
    exit 1
}

# 初始化输入和输出变量
input_path=""
output_path=""
SAMPLE=""

# 解析命令行选项和参数
while getopts "hi:o:s:" opt; do
    case "$opt" in
    h)
        show_help
        ;;
    i)
        input_path=$OPTARG
        ;;
    o)
        output_path=$OPTARG
        ;;
    s)
        SAMPLE=$OPTARG
        ;;
    *)
        show_help
        ;;
    esac
done

# 读取路径下的所有文件夹并保存到数组中

TRIMMED_OUTPUT_PATH="${output_path}/clean_data"
FASTQC_OUTPUT_PATH="${output_path}/fastqc"
FASTQ_SCREEN_OUTPUT_PATH="${output_path}/fastq_screen"

FASTQ_CONF_FILE="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/reference/fastq_screen.conf"

# echo ${output_path} ${TRIMMED_OUTPUT_PATH}

FASTQ_1="${input_path}/${SAMPLE}/${SAMPLE}_R1.fastq.gz"
FASTQ_2="${input_path}/${SAMPLE}/${SAMPLE}_R2.fastq.gz"
FASTQ_1_MD5="${input_path}/${SAMPLE}/${SAMPLE}_R1.fastq.gz.md5"
FASTQ_2_MD5="${input_path}/${SAMPLE}/${SAMPLE}_R2.fastq.gz.md5"

cd ${input_path}/${SAMPLE}/
## 检查文件完整性
md5sum -c ${FASTQ_1_MD5} ${FASTQ_2_MD5} > ${input_path}/${SAMPLE}/${SAMPLE}.log

# fastp 
mkdir -p "${TRIMMED_OUTPUT_PATH}/${SAMPLE}"
fastp --thread 16 -i ${FASTQ_1} -I ${FASTQ_2} -o "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_1.trimmed.fq.gz" -O "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_2.trimmed.fq.gz" -h ${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.html -j ${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.json

# fastqc
mkdir -p "${FASTQC_OUTPUT_PATH}/${SAMPLE}"
fastqc "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_1.trimmed.fq.gz" "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_2.trimmed.fq.gz" -o "${FASTQC_OUTPUT_PATH}/${SAMPLE}"

# fastq_screen
mkdir -p "${FASTQ_SCREEN_OUTPUT_PATH}/${SAMPLE}"
fastq_screen --aligner bowtie2 --conf ${FASTQ_CONF_FILE} --top 100000 --threads 16 --outdir "${FASTQ_SCREEN_OUTPUT_PATH}/${SAMPLE}" "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_1.trimmed.fq.gz"
fastq_screen --aligner bowtie2 --conf ${FASTQ_CONF_FILE} --top 100000 --threads 16 --outdir "${FASTQ_SCREEN_OUTPUT_PATH}/${SAMPLE}" "${TRIMMED_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}_2.trimmed.fq.gz"

echo "Fastq preprocess finished."