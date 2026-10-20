#!/bin/bash
#SBATCH --job-name=qiime_resume_after_sepp
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=logs/resume_after_sepp_%j.out
#SBATCH --error=logs/resume_after_sepp_%j.err

set -euo pipefail

echo "=== Resuming QIIME2 pipeline after SEPP: $(date) ==="

module purge
module load bear-apps/2023a
module load QIIME2/2025.4

mkdir -p logs

#####################################
# 1. Filter feature table to SEPP tree
#####################################
if [ ! -f table-rarefied-6500-filtered.qza ]; then
  qiime fragment-insertion filter-features \
    --i-table table-rarefied-6500.qza \
    --i-tree insertion-tree.qza \
    --o-filtered-table table-rarefied-6500-filtered.qza \
    --o-removed-table table-rarefied-6500-removed.qza
fi

#####################################
# 2. Summarize filtered table
#####################################
if [ ! -f table-rarefied-6500-filtered.qzv ]; then
  qiime feature-table summarize \
    --i-table table-rarefied-6500-filtered.qza \
    --o-visualization table-rarefied-6500-filtered.qzv
fi

#####################################
# 3. Alpha rarefaction (uses rooted tree)
#####################################
if [ ! -f alpha-rarefaction-6500.qzv ]; then
  qiime diversity alpha-rarefaction \
    --i-table table-rarefied-6500-filtered.qza \
    --i-phylogeny insertion-tree.qza \
    --p-max-depth 6500 \
    --o-visualization alpha-rarefaction-6500.qzv
fi

#####################################
# 4. (Optional) Rename tree for clarity
#####################################
if [ ! -f rooted-tree.qza ]; then
  cp insertion-tree.qza rooted-tree.qza
fi

echo "=== Resume step complete: $(date) ==="
ls -lh table-rarefied-6500-filtered.qza rooted-tree.qza *.qzv
