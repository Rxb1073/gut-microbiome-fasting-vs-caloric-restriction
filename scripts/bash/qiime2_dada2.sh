#!/bin/bash
#SBATCH --job-name=qiime2_dada2
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=logs/qiime2_dada2_%j.out
#SBATCH --error=logs/qiime2_dada2_%j.err

set -euo pipefail

echo "=== QIIME2 DADA2 Started: $(date) ==="
echo "Job ID: $SLURM_JOB_ID"

#####################################
# 1. Load environment
#####################################
module purge
module load bear-apps/2023a
module load QIIME2/2025.4


qiime --version

#####################################
# 2. DADA2 denoising
#####################################
echo "Running DADA2 denoising..."

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-paired-end.qza \
  --p-trunc-len-f 240 \
  --p-trunc-len-r 240 \
  --p-trim-left-f 20 \
  --p-trim-left-r 20 \
  --p-n-threads 16 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza

echo "✅ DADA2 complete!"

#####################################
# 3. Summarize results
#####################################
echo "Generating summaries..."

qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv

echo ""
echo "=== DADA2 Complete: $(date) ==="
echo "✅ Files created:"
echo "  - table.qza (ASV table)"
echo "  - rep-seqs.qza (representative sequences)"
echo "  - denoising-stats.qza (statistics)"
echo ""
echo "⚠️  NEXT STEPS:"
echo "1. Download denoising-stats.qzv to check quality"
echo "2. Run taxonomy classification"
echo "3. Build phylogenetic tree"

