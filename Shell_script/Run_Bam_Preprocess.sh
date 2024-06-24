#!/bin/bash

set -euo pipefail
# 显示帮助信息
function show_help {
    echo "Usage: $0 -i input_path [-o output_file]"
    echo
    echo "-i input_path    The path where to look for clean fastq file."
    echo "-o output_path   The path where to save the bam result. Usually the upper path of shell_script"
    echo "-f ref_genome    The path where to save the reference geneme file. fasta format"
    echo "-d dbsnp         The path where to save the known snp site file."
    echo
    echo "Example: $0 -i /path/to/cleanfastq -o /path/to/upper_path_of_shell_script -f /path/to/reference_genome -d /path/to/dbsnp_file"
    echo "Example2: $0 -i ../clean_data -o ../ -f ../other_ref/hg38.fa -d ../other_ref/dbsnp.vcf"
    exit 1
}

# 初始化输入和输出变量
input_path=""
output_path=""
ref_genome=""
dbsnp=""
SAMPLE=""
bedfile=""

# 解析命令行选项和参数
while getopts "hi:o:f:d:s:b:" opt; do
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
    f)
        ref_genome=$OPTARG
        ;;
    d)
        dbsnp=$OPTARG
        ;;
    s)
        SAMPLE=$OPTARG
        ;;
    b)
        bedfile=$OPTARG
        ;;    
    *)
        show_help
        ;;
    esac
done

# 继续假设配置变量已经设置
# REF="/home/cfff_r2636/data/reference/hg38/genome/hg38.fa"
# DBSNP="/home/cfff_r2636/data/reference/hg38/dbsnp/dbsnp_146.hg38.vcf.gz"

MAPPING_OUTPUT_PATH="${output_path}/mapping"
REF=${ref_genome}
DBSNP=${dbsnp}
QUALIMAP_OUTDIR="${output_path}/qualimap"

# bwa
mkdir -p "${MAPPING_OUTPUT_PATH}/${SAMPLE}"
bwa mem -M -R "@RG\\tID:${SAMPLE}\\tSM:${SAMPLE}\\tPL:ILLUMINA" -t 16 -K 10000000 "$REF" "${input_path}/${SAMPLE}/${SAMPLE}_1.trimmed.fq.gz" "${input_path}/${SAMPLE}/${SAMPLE}_2.trimmed.fq.gz" | \
samtools view -@ 16 -b - | \
samtools sort -@ 16 -o "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.sorted.bam" 

picard MarkDuplicates \
    I="${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.sorted.bam" \
    O="${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.dedup.bam" \
    M="${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.metrics.txt" \
    REMOVE_DUPLICATES=true

samtools index "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.dedup.bam"

# base_recalibrator
gatk BaseRecalibrator \
    -I "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.dedup.bam" \
    -R "$REF" \
    --known-sites "$DBSNP" \
    -O "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.recal_data.table"

# apply_bqsr
gatk ApplyBQSR \
    -R "$REF" \
    -I "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.dedup.bam" \
    --bqsr-recal-file "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.recal_data.table" \
    -O "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.recal.bam"

## add bai index
samtools index "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.recal.bam"

# qualimap
QUALIMAP_SAMPLE_OUTDIR="${QUALIMAP_OUTDIR}/${SAMPLE}"
mkdir -p "$QUALIMAP_SAMPLE_OUTDIR"
qualimap bamqc \
    -bam "${MAPPING_OUTPUT_PATH}/${SAMPLE}/${SAMPLE}.recal.bam" \
    -outformat PDF:HTML \
    -gff $bedfile \
    -nt 16 \
    -nr 500 \
    -nw 1500 \
    --java-mem-size=64G \
    -outdir "$QUALIMAP_SAMPLE_OUTDIR" 
