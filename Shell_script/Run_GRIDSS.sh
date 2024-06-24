#! /bin/bash
set -euo pipefail


# 解析命令行选项和参数
while getopts "hi:I:o:b:f:t:" opt; do
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
        ref_fasta=$OPTARG
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

## run gridss

gridss \
  -r ${ref_fasta} \
  -j /home/cfff_r2636/data/software/GRIDSS/gridss-2.13.2-gridss-jar-with-dependencies.jar \
  -o ${out_dir}/${Tumor_sample}/${Tumor_sample}_gridss.vcf \
  -b /home/cfff_r2636/data/software/GRIDSS/gridss/example/ENCFF356LFX.bed \
  -w ${out_dir}/${Tumor_sample} \
  ${normal_bam} \
  ${tumor_bam}


# gridss_somatic_filter \
#   --pondir /home/cfff_r2636/data/software/GRIDSS/sv \
#   --input ${out_dir}/${Tumor_sample}/${Tumor_sample}_gridss.vcf \
#   --output ${out_dir}/${Tumor_sample}/${Tumor_sample}_gridss_high_conf_somatic.vcf.gz \
#   --fulloutput ${out_dir}/${Tumor_sample}/high_and_low_confidence_somatic.vcf.gz \
#   -n 1 \
#   -t ${Thread}

#   --scriptdir $(dirname $(which gridss_somatic_filter)) \



