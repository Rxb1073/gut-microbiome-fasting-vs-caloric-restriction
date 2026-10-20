#!/bin/bash
#SBATCH --job-name=taxa_collapse
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=logs/taxa_collapse_%j.out
#SBATCH --error=logs/taxa_collapse_%j.err

set -euo pipefail

echo "=== Taxa Collapse to Family Level: $(date) ==="
echo "Job ID: $SLURM_JOB_ID"

# Load QIIME2
module purge
module load bear-apps/2023a
module load QIIME2/2025.4

# Navigate to results directory

# Check input files exist
echo "Checking input files..."
if [ ! -f table-rarefied-6500-matched.qza ]; then
    echo "❌ ERROR: table-rarefied-6500-matched.qza not found!"
    exit 1
fi

if [ ! -f taxonomy.qza ]; then
    echo "❌ ERROR: taxonomy.qza not found!"
    exit 1
fi

echo "✅ Input files found"

#####################################
# 1. Collapse to Family Level
#####################################

echo "Collapsing to family level (level 5)..."

qiime taxa collapse \
  --i-table table-rarefied-6500-matched.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 5 \
  --o-collapsed-table table-family-collapsed.qza

echo "✅ Family-level table created"

#####################################
# 2. Create visualization
#####################################

echo "Creating visualization..."

qiime feature-table summarize \
  --i-table table-family-collapsed.qza \
  --o-visualization table-family-collapsed.qzv

echo "✅ Visualization created"

#####################################
# 3. Export to TSV
#####################################

echo "Exporting to TSV format..."

mkdir -p exported-family-table

qiime tools export \
  --input-path table-family-collapsed.qza \
  --output-path exported-family-table

# Convert BIOM to TSV
biom convert \
  -i exported-family-table/feature-table.biom \
  -o exported-family-table/family-table.tsv \
  --to-tsv

echo "✅ TSV exported"

#####################################
# 4. Also export taxonomy for reference
#####################################

echo "Exporting taxonomy..."

mkdir -p exported-taxonomy

qiime tools export \
  --input-path taxonomy.qza \
  --output-path exported-taxonomy

echo "✅ Taxonomy exported"

#####################################
# Summary
#####################################

echo ""
echo "=== Taxa Collapse Complete: $(date) ==="
echo ""
echo "📁 Output files created:"
echo "   1. table-family-collapsed.qza (QIIME2 artifact)"
echo "   2. table-family-collapsed.qzv (visualization)"
echo "   3. exported-family-table/family-table.tsv (for R/MaAsLin2)"
echo "   4. exported-taxonomy/taxonomy.tsv (reference)"
echo ""
echo "✅ SUCCESS!"
echo ""
echo "🔍 Check family names:"
echo "   head exported-family-table/family-table.tsv"
echo ""
echo "📊 Next steps:"
echo "   1. Download family-table.tsv to your local machine"
echo "   2. Use it in MaAsLin2 instead of ASV table"
echo "   3. Compare family names to paper's supplementary data"
