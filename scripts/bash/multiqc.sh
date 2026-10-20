#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --output=logs/multiqc_%j.out
#SBATCH --error=logs/multiqc_%j.err

module purge
module load bear-apps/2024a
module load MultiQC/1.32-foss-2024a

echo "=== MultiQC Started: $(date) ==="


multiqc qc_results/fastqc \
  -o qc_results \
  -n multiqc_report.html \
  --title "Microbiome QC - PRJNA847971" \
  --force

if [ -f qc_results/multiqc_report.html ]; then
    echo "✅ SUCCESS: MultiQC report generated!"
    echo "Location: qc_results/multiqc_report.html"
fi

echo "=== MultiQC Complete: $(date) ==="

