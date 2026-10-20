#!/bin/bash
#SBATCH --job-name=qiime_alpha_6500
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=logs/alpha_6500_%j.out
#SBATCH --error=logs/alpha_6500_%j.err

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

# 0) Build rooted tree if missing
if [ ! -f rooted-tree.qza ]; then
  echo "rooted-tree.qza not found -> building tree from rep-seqs.qza"
  qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences rep-seqs.qza \
    --o-alignment aligned-rep-seqs.qza \
    --o-masked-alignment masked-aligned-rep-seqs.qza \
    --o-tree unrooted-tree.qza \
    --o-rooted-tree rooted-tree.qza
fi

# 1) Alpha rarefaction (max depth 6500)
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 6500 \
  --o-visualization alpha-rarefaction-6500.qzv

echo "✅ Alpha rarefaction completed"
