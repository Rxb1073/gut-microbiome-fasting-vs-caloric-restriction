#!/bin/bash
#SBATCH --job-name=qiime2_taxonomy
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --output=logs/qiime2_taxonomy_%j.out
#SBATCH --error=logs/qiime2_taxonomy_%j.err

set -euo pipefail

echo "=============================================="
echo " QIIME2 TAXONOMY PIPELINE STARTED"
echo " Date: $(date)"
echo " Job ID: ${SLURM_JOB_ID:-NA}"
echo " Host: $(hostname)"
echo "=============================================="

#####################################
# 1. Load QIIME2 environment
#####################################
module purge
module load bear-apps/2023a
module load QIIME2/2025.4

#####################################
# Redirect temporary directory
#####################################
# Use project tmp dir if set, otherwise create local tmp
export TMPDIR="${TMPDIR:-$(pwd)/tmp}"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"
mkdir -p "$TMPDIR"

qiime --version

#####################################
# 2. Move to QIIME2 results directory
#####################################
mkdir -p logs

#####################################
# 3. Locate existing trained classifier
#####################################
CLASSIFIER_TRAINED=$(ls silva_training/*classifier*.qza 2>/dev/null | head -n 1)

if [ -z "$CLASSIFIER_TRAINED" ]; then
  echo "❌ No trained classifier found in silva_training/"
  echo "   Expected something like *classifier*.qza"
  exit 1
fi

echo "✅ Using trained classifier:"
echo "   $CLASSIFIER_TRAINED"

qiime tools peek "$CLASSIFIER_TRAINED"

#####################################
# 4. Run taxonomy classification
#####################################
echo "Running taxonomy assignment..."

qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER_TRAINED" \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs 4

echo "✅ Taxonomy classification complete."

#####################################
# 5. Create taxonomy table visualization
#####################################
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

echo "✅ taxonomy.qzv created."

#####################################
# 6. Create taxa bar plots
#####################################
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

echo "✅ taxa-bar-plots.qzv created."

#####################################
# 7. Finish
#####################################
echo "=============================================="
echo " QIIME2 TAXONOMY PIPELINE FINISHED"
echo " Date: $(date)"
echo "=============================================="



