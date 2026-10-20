#!/bin/bash
#SBATCH --job-name=train_silva_v4
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=logs/train_silva_%j.out
#SBATCH --error=logs/train_silva_%j.err

set -euo pipefail

#####################################
# Load QIIME2
#####################################
module purge
module load bear-apps/2023a
module load QIIME2/2025.4

#####################################
# Redirect TMP (CRITICAL)
#####################################
# Use project tmp dir if set, otherwise create local tmp
export TMPDIR="${TMPDIR:-$(pwd)/tmp}"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"
mkdir -p "$TMPDIR"


mkdir -p silva_training
cd silva_training

#####################################
# 1. Download SILVA 138 reference data
#####################################
wget -c https://data.qiime2.org/2022.8/common/silva-138-99-seqs.qza
wget -c https://data.qiime2.org/2022.8/common/silva-138-99-tax.qza

#####################################
# 2. Extract V4 region (515F/806R)
#####################################
qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer GTGCCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACHVGGGTWTCTAAT \
  --p-trunc-len 0 \
  --o-reads silva-138-99-515-806-seqs.qza

#####################################
# 3. Train classifier
#####################################
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva-138-99-515-806-seqs.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier silva-138-99-515-806-nb-classifier.qza

echo "✅ SILVA V4 classifier trained successfully!"
