#! /bin/bash

set -euo pipefail

FASTQ_1=""
FASTQ_2=""
THREADS=""
Output_path=""

while getopts "hi:I:o:t:" opt; do
    case "$opt" in
    h)
        show_help
        ;;
    i)
        FASTQ_1=$OPTARG
        ;;
    I)
        FASTQ_2=$OPTARG
        ;;
	t)
        THREADS=$OPTARG
        ;;
	o)
        Output_path=$OPTARG
        ;;
    *)
        show_help
        ;;
    esac
done

dir_to_fusion="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/STAR-Fusion"
GENOME_LIB_DIR="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/reference/STAR_reference/ctat_genome_lib_build_dir"

OUTPUT_DIR=${Output_path}

mkdir -p "${OUTPUT_DIR}"

${dir_to_fusion}/STAR-Fusion --genome_lib_dir "$GENOME_LIB_DIR" \
    --left_fq "$FASTQ_1" \
    --right_fq "$FASTQ_2" \
    --output_dir "$OUTPUT_DIR" \
    --CPU ${THREADS}

FusionInspector_input="$OUTPUT_DIR"/star-fusion.fusion_predictions.abridged.tsv

${dir_to_fusion}/FusionInspector/FusionInspector --fusions ${FusionInspector_input} \
    --genome_lib_dir ${GENOME_LIB_DIR} \
    --left_fq ${FASTQ_1} \
    --right_fq ${FASTQ_2} \
    --output_dir ${OUTPUT_DIR}  \
    --CPU ${THREADS} \
    --vis
