# Create phyloseq object from QIIME2 exports
# Run this FIRST, from the repository root, before the other R analysis scripts.
#
# Outputs (written to the repository root, ignored by .gitignore):
#   phyloseq_object.rds              -> beneficial_bacteria.R, beta_trajectory.R, machine_learning.R
#   alpha-observed.tsv               -> figure_1e_alpha.R
#   distance-matrix.tsv              -> figure_1g_beta.R
#   metadata_merged.tsv              -> figure_1g_beta.R
#   metadata_merged_qiime_FINAL.tsv  -> figure_1e_alpha.R

library(phyloseq)
library(tidyverse)

cat("=== Creating phyloseq object from QIIME2 exports ===\n\n")

qiime_path <- "results/qiime2"

# ---- ASV table -------------------------------------------------------------
# Exported from biom, so line 1 is a '# Constructed from biom file' comment.
asv_table <- read.delim(file.path(qiime_path, "tables", "asv-table.tsv"),
                        skip = 1, row.names = 1, check.names = FALSE)
asv_mat <- as.matrix(asv_table)
cat("ASV table:", nrow(asv_mat), "ASVs x", ncol(asv_mat), "samples\n")

# ---- Taxonomy --------------------------------------------------------------
taxonomy <- read.delim(file.path(qiime_path, "taxonomy.tsv"),
                       row.names = 1, check.names = FALSE)
tax_split <- strsplit(as.character(taxonomy$Taxon), "; ")
tax_mat <- do.call(rbind, lapply(tax_split, function(x) {
  x <- gsub("^[dpcofgs]__", "", x)   # strip rank prefixes
  length(x) <- 7                     # pad to 7 levels
  x
}))
colnames(tax_mat) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
rownames(tax_mat) <- rownames(taxonomy)
cat("Taxonomy:", nrow(tax_mat), "taxa\n")

# ---- Metadata --------------------------------------------------------------
# Use the full sample sheet: the downstream scripts need subject, PP_HH,
# Time and Time_num, which results/qiime2/qiime2-sample-groups.tsv does not carry.
metadata <- read.delim("metadata/metadata.tsv",
                       row.names = 1, check.names = FALSE)
cat("Metadata:", nrow(metadata), "samples x", ncol(metadata), "variables\n")

required <- c("subject", "PP_HH", "Group", "Time", "Time_num")
missing  <- setdiff(required, colnames(metadata))
if (length(missing)) stop("metadata/metadata.tsv is missing: ", paste(missing, collapse = ", "))

# Keep only samples present in both the ASV table and the metadata
shared <- intersect(colnames(asv_mat), rownames(metadata))
cat("Samples shared between ASV table and metadata:", length(shared), "\n")
if (length(shared) == 0) stop("No overlap between ASV table columns and metadata row names.")
asv_mat  <- asv_mat[, shared, drop = FALSE]
metadata <- metadata[shared, , drop = FALSE]

# ---- Build phyloseq object -------------------------------------------------
ps <- phyloseq(
  otu_table(asv_mat, taxa_are_rows = TRUE),
  tax_table(tax_mat),
  sample_data(metadata)
)

cat("\nPhyloseq object created:\n")
print(ps)

saveRDS(ps, "phyloseq_object.rds")
cat("\nSaved: phyloseq_object.rds\n")

# ---- Intermediates for the figure scripts ----------------------------------
alpha_obs <- read.delim(file.path(qiime_path, "alpha-diversity", "observed_features.tsv"),
                        check.names = FALSE)
names(alpha_obs)[1] <- "sample_id"
write_tsv(alpha_obs, "alpha-observed.tsv")
cat("Saved: alpha-observed.tsv\n")

dm <- read.delim(file.path(qiime_path, "beta-diversity", "bray_curtis_distance.tsv"),
                 check.names = FALSE)
names(dm)[1] <- "sample_id"
write_tsv(dm, "distance-matrix.tsv")
cat("Saved: distance-matrix.tsv\n")

meta_out <- metadata %>% rownames_to_column("sample-id")
write_tsv(meta_out, "metadata_merged.tsv")
write_tsv(meta_out, "metadata_merged_qiime_FINAL.tsv")
cat("Saved: metadata_merged.tsv\n")
cat("Saved: metadata_merged_qiime_FINAL.tsv\n")

cat("\n=== All input files created. Ready to run the analysis scripts. ===\n")
