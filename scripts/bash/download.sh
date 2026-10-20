#!/bin/bash
#SBATCH --job-name=microbiome_dl
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=4G
#SBATCH --output=logs/dl_%j.out
#SBATCH --error=logs/dl_%j.err

# 1. Setup environment
mkdir -p logs fastq_files
echo "=== ENA Data Download Started: $(date) ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on: $(hostname)"

# 2. Get metadata from ENA
curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJNA847971&result=read_run&fields=run_accession,fastq_ftp,fastq_bytes,fastq_md5" \
-o ena_file_info.tsv

# 2b. Extract accession list (needed for QIIME2 later!)
cut -f1 ena_file_info.tsv | tail -n +2 > SRR_Acc_List.txt
echo "Accessions: $(wc -l < SRR_Acc_List.txt)"

# 3. Prepare download list
cut -f2 ena_file_info.tsv | tail -n +2 | tr ';' '\n' | sed 's|^|ftp://|' > download_urls.txt
TOTAL_FILES=$(wc -l < download_urls.txt)
echo "Files to download: $TOTAL_FILES"

# Calculate expected size
TOTAL_BYTES=$(cut -f3 ena_file_info.tsv | tail -n +2 | tr ';' '\n' | awk '{sum+=$1} END {print sum}')
TOTAL_GB=$(echo "scale=2; $TOTAL_BYTES/1024/1024/1024" | bc)
echo "Expected size: ${TOTAL_GB} GB"

# 4. Perform parallel download
echo "Downloading files..."
cd fastq_files
cat ../download_urls.txt | xargs -n 1 -P 8 wget -q -c -T 20 -t 3
cd ..

# 5. Verify file count
DOWNLOADED=$(ls -1 fastq_files/*.fastq.gz 2>/dev/null | wc -l)
echo "Downloaded: $DOWNLOADED / $TOTAL_FILES files"
echo "Actual size: $(du -sh fastq_files | cut -f1)"

if [ $DOWNLOADED -ne $TOTAL_FILES ]; then
echo "⚠️ WARNING: File count mismatch!"
exit 1
fi

# 6. Integrity Verification (MD5 checksums)
echo "=== Verifying MD5 Checksums ==="
awk -F'\t' 'NR>1 {
split($2, paths, ";");
split($4, hashes, ";");
for(i in paths) {
split(paths[i], parts, "/");
filename=parts[length(parts)];
print hashes[i] " fastq_files/" filename
}
}' ena_file_info.tsv > checksums.md5

if md5sum -c checksums.md5 --status; then
echo "✅ ALL FILES VERIFIED: MD5 hashes match."
else
echo "⚠️ WARNING: Some files are corrupted!"
md5sum -c checksums.md5 | grep "FAILED"
exit 1
fi

echo "=== Download Complete: $(date) ==="
echo "✅ SUCCESS: All files downloaded and verified!"
echo "Next step: Run FastQC"

