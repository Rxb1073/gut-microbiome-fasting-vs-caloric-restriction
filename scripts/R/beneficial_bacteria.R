library(phyloseq)
library(tidyverse)
library(ggpubr)

# ============================================
# BENEFICIAL BACTERIA BOXPLOT WITH P-VALUES
# Compares Christensenellaceae, Rikenellaceae, Ruminococcaceae
# ============================================

# Load phyloseq object
ps <- readRDS("phyloseq_object.rds")

# Get metadata
metadata <- as.data.frame(sample_data(ps))

cat("=== KEY FINDING 2: Beneficial Bacteria (with p-values) ===\n")

# Collapse to family level
ps_family <- tax_glom(ps, taxrank = "Family", NArm = FALSE)
ps_rel <- transform_sample_counts(ps_family, function(x) {x/sum(x)})

# Extract beneficial families
beneficial_families <- c("Christensenellaceae", "Rikenellaceae", "Ruminococcaceae")

beneficial_data <- psmelt(ps_rel) %>%
  filter(Family %in% beneficial_families) %>%
  mutate(
    Group = factor(PP_HH, levels = c("CR", "IF-P")),
    Timepoint = factor(Time_num, levels = c(1, 2, 3),
                       labels = c("Week 0", "Week 4", "Week 8")),
    Family = factor(Family, levels = beneficial_families)
  )

# Calculate p-values for annotation
pval_data <- beneficial_data %>%
  group_by(Family, Timepoint) %>%
  summarise(
    pval = wilcox.test(Abundance[Group == "IF-P"],
                       Abundance[Group == "CR"])$p.value,
    max_y = max(Abundance * 100) * 1.1,
    .groups = 'drop'
  ) %>%
  mutate(
    significance = case_when(
      pval < 0.001 ~ "***",
      pval < 0.01 ~ "**",
      pval < 0.05 ~ "*",
      TRUE ~ ""
    ),
    label = sprintf("p = %.3f %s", pval, significance)
  )

# Print p-values
cat("\nStatistical tests (Wilcoxon) comparing IF-P vs CR:\n\n")
pval_data %>%
  filter(Family == "Christensenellaceae") %>%
  select(Timepoint, pval, significance) %>%
  print()
cat("\n")

# Create plot with p-values
p_beneficial <- ggplot(beneficial_data, aes(x = Timepoint, y = Abundance * 100, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_point(aes(fill = Group),
             position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.6),
             alpha = 0.6, size = 2, shape = 21, stroke = 0.3, color = "black") +
  # Add p-value labels
  geom_text(
    data = pval_data,
    aes(x = Timepoint, y = max_y,
        label = label,
        group = NULL, fill = NULL),
    size = 3.5,
    fontface = "bold",
    vjust = -0.5
  ) +
  facet_wrap(~Family, scales = "free_y", ncol = 3) +
  theme_bw() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    strip.text = element_text(face = "italic", size = 11),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 10),
    axis.text.y = element_text(size = 10)
  ) +
  labs(
    title = "Beneficial Bacteria Response to Dietary Interventions",
    x = "Time Point",
    y = "Relative Abundance (%)",
    fill = "Intervention"
  ) +
  scale_fill_manual(values = c("CR" = "magenta3", "IF-P" = "darkturquoise")) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15)))

# Save figures
ggsave("BeneficialBacteria_Boxplot.pdf", p_beneficial, width = 13, height = 6, dpi = 300)
ggsave("BeneficialBacteria_Boxplot.png", p_beneficial, width = 13, height = 6, dpi = 300)

cat("✅ Figure saved: BeneficialBacteria_Boxplot.png/pdf\n")

# Summary
cat("\n=== KEY FINDINGS ===\n")
cat("Christensenellaceae:\n")
christen_pvals <- pval_data %>% filter(Family == "Christensenellaceae")
for(i in 1:nrow(christen_pvals)) {
  sig <- if(christen_pvals$pval[i] < 0.05) "SIGNIFICANT" else "not significant"
  cat(sprintf("  %s: p = %.3f (%s)\n",
              christen_pvals$Timepoint[i],
              christen_pvals$pval[i],
              sig))
}
