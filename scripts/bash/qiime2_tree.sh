#!/bin/bash
#SBATCH --job-name=qiime_sepp_6500
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=logs/sepp_6500_%j.out
#SBATCH --error=logs/sepp_6500_%j.err

set -euo pipefail

module purge
module load bear-apps/2023a
module load QIIME2/2025.4

# Use project tmp dir if set, otherwise create local tmp
export TMPDIR="${TMPDIR:-$(pwd)/tmp}"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"
mkdir -p "$TMPDIR"

mkdir -p logs

#####################################
# Sanity checks
#####################################
for f in table.qza rep-seqs.qza reference_data/sepp-refs-silva-128.qza; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing required file: $f"
    exit 1
  fi
done

#####################################
# Rarefy at depth 6500
#####################################
if [ ! -f table-rarefied-6500.qza ]; then
  qiime feature-table rarefy \
    --i-table table.qza \
    --p-sampling-depth 6500 \
    --o-rarefied-table table-rarefied-6500.qza
fi

#####################################
# SEPP fragment insertion
#####################################
if [ ! -f insertion-tree.qza ]; then
  qiime fragment-insertion sepp \
    --i-representative-sequences rep-seqs.qza \
    --i-reference-database reference_data/sepp-refs-silva-128.qza \
    --o-tree insertion-tree.qza \
    --o-placements insertion-placements.qza \
    --p-threads 8
fi

#####################################
# Root tree
#####################################
if [ ! -f rooted-tree.qza ]; then
  qiime phylogeny midpoint-root \
    --i-tree insertion-tree.qza \
    --o-rooted-tree rooted-tree.qza
fi

#####################################
# Alpha rarefaction (optional)
#####################################
if [ ! -f alpha-rarefaction-6500.qzv ]; then
  qiime diversity alpha-rarefaction \
    --i-table table.qza \
    --i-phylogeny rooted-tree.qza \
    --p-max-depth 6500 \
    --o-visualization alpha-rarefaction-6500.qzv
fi
