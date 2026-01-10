#!/bin/bash
# ============================================================
# QIIME 2 Microbiome Analysis Pipeline
# Platform: PacBio CCS (single-end)
# QIIME 2 version: 2023.5
# Study: Indian diabetes cohort
# ============================================================

set -e  # Stop if any command fails

# -----------------------------
# 1. Import PacBio CCS sequences
# -----------------------------

qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path manifest \
  --output-path pacbio_single_end_ccs.qza \
  --input-format SingleEndFastqManifestPhred33V2


# -----------------------------
# 2. Denoising with DADA2-CCS
# -----------------------------
# Primer and adapter trimming with quality filtering

qiime dada2 denoise-ccs \
  --i-demultiplexed-seqs pacbio_single_end_ccs.qza \
  --p-front AGRGTTYGATYMTGGCTCAG \
  --p-adapter RGYTACCTTGTTACGACTT \
  --p-max-ee 5 \
  --p-trunc-q 5 \
  --p-max-mismatch 5 \
  --p-n-threads 4 \
  --output-dir dada2_ccs_ee5


# -----------------------------
# 3. Core diversity metrics
# -----------------------------
# Sampling depth selected based on rarefaction curves

qiime diversity core-metrics \
  --i-table dada2_ccs_ee5/table.qza \
  --p-sampling-depth 11322 \
  --m-metadata-file metadata.tsv \
  --output-dir diversity_metrics


# Additional alpha diversity (Chao1)

qiime diversity alpha \
  --i-table dada2_ccs_ee5/table.qza \
  --p-metric chao1 \
  --o-alpha-diversity diversity_metrics/chao1_vector.qza


# -----------------------------
# 4. Alpha diversity significance
# -----------------------------
# Non-parametric Kruskal–Wallis test

qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity_metrics/faith_pd_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization diversity_metrics/faith_pd_group_significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity_metrics/chao1_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization diversity_metrics/chao1_group_significance.qzv


# -----------------------------
# 5. Beta diversity significance
# -----------------------------
# PERMANOVA with pairwise comparisons

qiime diversity beta-group-significance \
  --i-distance-matrix diversity_metrics/bray_curtis_distance_matrix.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column Group \
  --p-pairwise \
  --o-visualization diversity_metrics/bray_curtis_group_significance.qzv


# -----------------------------
# 6. Taxonomic profiling
# -----------------------------

qiime feature-table group \
  --i-table dada2_ccs_ee5/table.qza \
  --p-axis sample \
  --m-metadata-file metadata.tsv \
  --m-metadata-column Group \
  --p-mode mean-ceiling \
  --o-grouped-table taxa/grouped_table.qza


# Collapse taxonomy at multiple levels (SILVA 138)

qiime taxa collapse \
  --i-table taxa/grouped_table.qza \
  --i-taxonomy taxonomy/silva_taxonomy.qza \
  --p-level 2 \
  --o-collapsed-table taxa/grouped_L2.qza

qiime taxa collapse \
  --i-table taxa/grouped_table.qza \
  --i-taxonomy taxonomy/silva_taxonomy.qza \
  --p-level 5 \
  --o-collapsed-table taxa/grouped_L5.qza

qiime taxa collapse \
  --i-table taxa/grouped_table.qza \
  --i-taxonomy taxonomy/silva-138-99-515-806-nb-classifier.qza \
  --p-level 6 \
  --o-collapsed-table taxa/grouped_L6.qza


# Convert to relative abundance

qiime feature-table relative-frequency \
  --i-table taxa/grouped_L2.qza \
  --o-relative-frequency-table taxa/grouped_L2_relative.qza

qiime feature-table relative-frequency \
  --i-table taxa/grouped_L5.qza \
  --o-relative-frequency-table taxa/grouped_L5_relative.qza

qiime feature-table relative-frequency \
  --i-table taxa/grouped_L6.qza \
  --o-relative-frequency-table taxa/grouped_L6_relative.qza


# -----------------------------
# 7. Functional profiling (PICRUSt2)
# -----------------------------
# PICRUSt2 requires QIIME 2 version 2019.10
# Analysis performed in a separate conda environment

echo "Switching to QIIME 2 2019.10 environment for PICRUSt2..."

# Deactivate current QIIME 2 environment (2023.5)
conda deactivate

# Activate QIIME 2 2019.10
conda activate qiime2-2019.10

# Run PICRUSt2 full pipeline
qiime picrust2 full-pipeline \
  --i-table dada2_ccs_ee5/table.qza \
  --i-seq dada2_ccs_ee5/representative_sequences.qza \
  --p-threads 20 \
  --output-dir picrust2_out \
  --verbose

# -----------------------------
# 8. Functional pathway inference (Standalone PICRUSt2)
# -----------------------------
# Standalone PICRUSt2 used for KEGG pathway reconstruction
# Installation: https://huttenhower.sph.harvard.edu/picrust/

echo "Switching to standalone PICRUSt2 environment for pathway analysis..."

conda deactivate
conda activate picrust2

pathway_pipeline.py \
  -i picrust2_out/KO-metagenome/ko_metagenome.txt \
  -o picrust2_out/KEGG_pathways \
  --no_regroup \
  --map /home/user/Programs/PICRUSt2/default_files/KEGG_pathways_to_KO.tsv

# Deactivate standalone PICRUSt2 environment
conda deactivate

# -----------------------------
# 9. Differential abundance analysis (LEfSe)
# -----------------------------
# LEfSe is executed in a standalone environment
# Installation: https://huttenhower.sph.harvard.edu/lefse/

echo "Switching to LEfSe environment for differential abundance analysis..."

# Activate LEfSe environment
conda activate lefse

# Step 1: Format input for LEfSe
# -c 2: class column
# -u 1: subclass column (if applicable)
# -o 1000000: normalization value

format_input.py \
  input/four_group_comparison.txt \
  lefse_input.in \
  -c 2 \
  -u 1 \
  -o 1000000

# Step 2: Run LEfSe with LDA score threshold = 3.0
run_lefse.py \
  lefse_input.in \
  lefse_results.res \
  -l 3.0

# Deactivate LEfSe environment
conda deactivate

# ============================================================
# End of pipeline
# ============================================================
