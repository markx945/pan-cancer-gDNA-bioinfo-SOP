#! /bin/bash

set -euo pipefail

READ1=""
READ2=""
THREADS=""
Output_path=""

while getopts "hi:I:o:t:" opt; do
    case "$opt" in
    h)
        show_help
        ;;
    i)
        READ1=$OPTARG
        ;;
    I)
        READ2=$OPTARG
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

set -x -e -u

# get arguments
STAR_INDEX_DIR="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/reference/STAR_reference/ctat_genome_lib_build_dir/ref_genome.fa.star.idx"
ANNOTATION_GTF="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/reference/STAR_reference/ctat_genome_lib_build_dir/ref_annot.gtf"
ASSEMBLY_FA="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/reference/STAR_reference/ctat_genome_lib_build_dir/ref_genome.fa"
BLACKLIST_TSV="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/arriba/arriba_v2.4.0/database/blacklist_hg38_GRCh38_v2.4.0.tsv.gz"
KNOWN_FUSIONS_TSV="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/arriba/arriba_v2.4.0/database/known_fusions_hg38_GRCh38_v2.4.0.tsv.gz"
TAGS_TSV="$KNOWN_FUSIONS_TSV" # different files can be used for filtering and tagging, but the provided one can be used for both
PROTEIN_DOMAINS_GFF3="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/arriba/arriba_v2.4.0/database/protein_domains_hg38_GRCh38_v2.4.0.gff3"
Dir_to_arriba="/cpfs01/projects-HDD/cfff-e44ef5cf7aa5_HDD/cfff_r2636/software/arriba/arriba_v2.4.0/"


# find installation directory of arriba
# BASE_DIR=$(dirname "$0")

# # align FastQ files (STAR >=2.7.10a recommended)
# STAR \
# 	--runThreadN "$THREADS" \
# 	--genomeDir "$STAR_INDEX_DIR" --genomeLoad NoSharedMemory \
# 	--readFilesIn "$READ1" "$READ2" --readFilesCommand zcat \
# 	--outStd BAM_Unsorted --outSAMtype BAM Unsorted --outSAMunmapped Within --outBAMcompression 0 \
# 	--outFilterMultimapNmax 50 --peOverlapNbasesMin 10 --alignSplicedMateMapLminOverLmate 0.5 --alignSJstitchMismatchNmax 5 -1 5 5 \
# 	--chimSegmentMin 10 --chimOutType WithinBAM HardClip --chimJunctionOverhangMin 10 --chimScoreDropMax 30 --chimScoreJunctionNonGTAG 0 --chimScoreSeparation 1 --chimSegmentReadGapMax 3 --chimMultimapNmax 50 |

# # tee Aligned.out.bam |

# # call arriba
# "$Dir_to_arriba/arriba" \
# 	-x /dev/stdin \
#     -u \
# 	-o ${Output_path}/fusions.tsv -O ${Output_path}/fusions.discarded.tsv \
# 	-a "$ASSEMBLY_FA" -g "$ANNOTATION_GTF" -b "$BLACKLIST_TSV" -k "$KNOWN_FUSIONS_TSV" -t "$TAGS_TSV" -p "$PROTEIN_DOMAINS_GFF3" 

# align FastQ files (STAR >=2.7.10a recommended)
STAR \
	--runThreadN "$THREADS" \
	--genomeDir "$STAR_INDEX_DIR" --genomeLoad NoSharedMemory \
	--readFilesIn "$READ1" "$READ2" --readFilesCommand zcat \
	--outStd BAM_Unsorted --outSAMtype BAM Unsorted --outSAMunmapped Within --outBAMcompression 0 \
	--outFilterMultimapNmax 50 --peOverlapNbasesMin 10 --alignSplicedMateMapLminOverLmate 0.5 --alignSJstitchMismatchNmax 5 -1 5 5 \
	--chimSegmentMin 10 --chimOutType WithinBAM HardClip --chimJunctionOverhangMin 10 --chimScoreDropMax 30 --chimScoreJunctionNonGTAG 0 --chimScoreSeparation 1 --chimSegmentReadGapMax 3 --chimMultimapNmax 50 |

tee Aligned.out.bam |

# call arriba
"$Dir_to_arriba/arriba" \
	-x /dev/stdin \
    -u \
	-o ${Output_path}/fusions.tsv -O ${Output_path}/fusions.discarded.tsv \
	-a "$ASSEMBLY_FA" -g "$ANNOTATION_GTF" -b "$BLACKLIST_TSV" -k "$KNOWN_FUSIONS_TSV" -t "$TAGS_TSV" -p "$PROTEIN_DOMAINS_GFF3" 

