#!/bin/bash
#SBATCH --job-name=export_for_R
#SBATCH --ntasks=1
#SBATCH --time=00:30:00
#SBATCH --qos=bbdefault
#SBATCH --mail-type=FAIL

# Export QIIME2 artifacts to R-readable formats
# Outputs: TSV files and Newick tree for phyloseq/R analysis

set -euo pipefail

# Load QIIME2
module purge
module load bluebear
module load QIIME2/2025.4

# Set working directory (defaults to current directory)
WORKDIR="${WORKDIR:-$(pwd)}"
OUTDIR="${WORKDIR}/exported_for_R"
mkdir -p "${OUTDIR}"

echo "=== Exporting QIIME2 artifacts for R analysis ==="
echo "Output directory: ${OUTDIR}"

# 1. Export feature table (ASV counts)
echo "Exporting feature table..."
qiime tools export \
    --input-path "${WORKDIR}/table-dada2.qza" \
    --output-path "${OUTDIR}/feature_table"

# Convert BIOM to TSV
biom convert \
    -i "${OUTDIR}/feature_table/feature-table.biom" \
    -o "${OUTDIR}/feature_table.tsv" \
    --to-tsv

# 2. Export taxonomy
echo "Exporting taxonomy..."
qiime tools export \
    --input-path "${WORKDIR}/taxonomy.qza" \
    --output-path "${OUTDIR}/taxonomy"

mv "${OUTDIR}/taxonomy/taxonomy.tsv" "${OUTDIR}/taxonomy.tsv"

# 3. Export phylogenetic tree
echo "Exporting phylogenetic tree..."
qiime tools export \
    --input-path "${WORKDIR}/sepp-tree.qza" \
    --output-path "${OUTDIR}/tree"

mv "${OUTDIR}/tree/tree.nwk" "${OUTDIR}/phylo_tree.nwk"

# 4. Export representative sequences
echo "Exporting representative sequences..."
qiime tools export \
    --input-path "${WORKDIR}/rep-seqs-dada2.qza" \
    --output-path "${OUTDIR}/rep_seqs"

mv "${OUTDIR}/rep_seqs/dna-sequences.fasta" "${OUTDIR}/rep_seqs.fasta"

# 5. Export alpha diversity metrics (if they exist)
echo "Exporting alpha diversity metrics..."
for metric in shannon observed_features faith_pd; do
    if [[ -f "${WORKDIR}/alpha_${metric}.qza" ]]; then
        qiime tools export \
            --input-path "${WORKDIR}/alpha_${metric}.qza" \
            --output-path "${OUTDIR}/alpha_${metric}"
        mv "${OUTDIR}/alpha_${metric}/alpha-diversity.tsv" "${OUTDIR}/alpha_${metric}.tsv"
        rm -rf "${OUTDIR}/alpha_${metric}"
    fi
done

# Clean up temporary directories
rm -rf "${OUTDIR}/feature_table" "${OUTDIR}/taxonomy" "${OUTDIR}/tree" "${OUTDIR}/rep_seqs"

echo ""
echo "=== Export complete ==="
echo "Files created in ${OUTDIR}:"
ls -la "${OUTDIR}"
echo ""
echo "Ready for R analysis with phyloseq!"
