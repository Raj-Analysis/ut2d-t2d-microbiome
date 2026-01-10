# Gut microbiome disparities reflect type-2 diabetes progression and medication status

## Overview

This repository contains the analysis scripts and notebooks used to process and analyze gut microbiome sequencing data for the manuscript:

**“Gut microbiome disparities reflect type-2 diabetes progression and medication status.”**

The code provided here supports reproducibility of the bioinformatics, statistical, and visualization workflows described in the manuscript.

---

## Repository contents

### Analysis notebooks
- **`Diversity-taxa-plots.ipynb`**  
  Visualization and statistical analysis of alpha and beta diversity metrics and taxonomic composition.

- **`Individual-taxa-plots-and-statistics.ipynb`**  
  Taxon-level abundance analysis, group comparisons, and associated statistical testing.

- **`Correlational-analysis-and-visualization.ipynb`**  
  Correlation analyses between microbial features and clinical or metabolic variables, including visualization.

- **`Multivariate-regression.ipynb`**  
  Multivariate regression models assessing associations between microbiome features, disease status, and covariates.

---

### Bioinformatics pipeline
- **`Microbiome-analysis-Indian-diabetes-cohort.sh`**  
  A fully documented, end-to-end QIIME 2–based analysis pipeline used for sequence processing, diversity analysis, taxonomic profiling, functional prediction (PICRUSt2), and differential abundance analysis (LEfSe).  

---

### Administrative files
- **`LICENSE`**  
  MIT License.

- **`README.md`**  
  This document.

---

## Software and environments

Analyses were conducted using multiple software environments due to tool compatibility requirements:

- **QIIME 2 v2023.5** – primary microbiome processing and diversity analyses  
- **QIIME 2 v2019.10** – PICRUSt2 full pipeline (embedded plugin)  
- **Standalone PICRUSt2** – KEGG pathway inference  
- **LEfSe** – differential abundance analysis  

Details and commands for switching between environments are documented directly within the pipeline script.

---

## Contact

For questions regarding the analysis workflow or code, please contact the corresponding author listed in the manuscript.
