library(phyloseq)
library(ggplot2)
library(tidyverse)
library(vegan)

# ============================================
# BETA DIVERSITY TRAJECTORY (PCoA with Time)
# Shows individual sample trajectories over WK0 → WK4 → WK8
# ============================================

# Load phyloseq object
ps <- readRDS("phyloseq_object.rds")

# Get metadata
metadata <- as.data.frame(sample_data(ps))

# Transform to relative abundance
ps_rel <- transform_sample_counts(ps, function(x) x/sum(x))

# Calculate Bray-Curtis distances
bray_dist <- phyloseq::distance(ps_rel, method = "bray")

# PERMANOVA test
metadata_ordered <- metadata[labels(bray_dist), ]
permanova <- adonis2(bray_dist ~ PP_HH * Time_num,
                     data = metadata_ordered,
                     permutations = 999)

cat("\n=== PERMANOVA Results ===\n")
print(permanova)
cat("\n")

# Extract p-values
group_pval <- permanova$`Pr(>F)`[1]
time_pval <- permanova$`Pr(>F)`[2]
interaction_pval <- permanova$`Pr(>F)`[3]

# Format p-values for display
format_pval <- function(p) {
  if(is.na(p)) return("p = NA")
  else if(p < 0.001) return("p < 0.001")
  else if(p < 0.01) return("p < 0.01")
  else if(p < 0.05) return(sprintf("p = %.3f", p))
  else return(sprintf("p = %.3f", p))
}

# PCoA ordination
pcoa <- ordinate(ps_rel, method = "PCoA", distance = bray_dist)

# Create data frame with coordinates
pcoa_data <- data.frame(
  PC1 = pcoa$vectors[,1],
  PC2 = pcoa$vectors[,2],
  SampleID = rownames(pcoa$vectors)
) %>%
  left_join(
    metadata %>%
      rownames_to_column("SampleID") %>%
      select(SampleID, PP_HH, Time_num, subject),
    by = "SampleID"
  ) %>%
  mutate(
    Group = factor(PP_HH, levels = c("CR", "IF-P")),
    Timepoint = factor(Time_num, levels = c(1, 2, 3),
                       labels = c("WK0", "WK4", "WK8"))
  )

# Calculate variance explained
var_exp <- round(pcoa$values$Relative_eig[1:2] * 100, 1)

# Create subtitle with p-values
subtitle_text <- sprintf(
  "PERMANOVA: Intervention %s, Time %s, Interaction %s",
  format_pval(group_pval),
  format_pval(time_pval),
  format_pval(interaction_pval)
)

# Create plot with trajectory lines
p_trajectory <- ggplot(pcoa_data, aes(x = PC1, y = PC2, color = Group, shape = Timepoint)) +
  geom_point(size = 4, alpha = 0.7) +
  # Add trajectory lines connecting same subject over time
  geom_path(aes(group = interaction(subject, Group)),
            alpha = 0.3, linewidth = 0.5) +
  # Add 95% confidence ellipses per group
  stat_ellipse(aes(group = Group),
               type = "norm", linetype = 2, linewidth = 0.8) +
  theme_bw() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, size = 10),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right",
    legend.text = element_text(size = 10)
  ) +
  labs(
    x = paste0("PC1 (", var_exp[1], "%)"),
    y = paste0("PC2 (", var_exp[2], "%)"),
    color = "Intervention",
    shape = "Time Point"
  ) +
  scale_color_manual(values = c("CR" = "magenta3", "IF-P" = "darkturquoise")) +
  scale_shape_manual(values = c(16, 17, 15))  # circle, triangle, square

# Save figures
ggsave("Beta_Trajectory_PCoA.pdf", p_trajectory, width = 11, height = 8, dpi = 300)
ggsave("Beta_Trajectory_PCoA.png", p_trajectory, width = 11, height = 8, dpi = 300)

cat("✅ Beta trajectory figure saved: Beta_Trajectory_PCoA.png/pdf\n")
cat(sprintf("   Variance explained: PC1 = %s%%, PC2 = %s%%\n", var_exp[1], var_exp[2]))
