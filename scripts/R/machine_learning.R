library(phyloseq)
library(randomForest)
library(tidyverse)

# Load data
phylo <- readRDS("phyloseq_object.rds")
ps_rare <- phylo

# Prepare data (Week 8 only)
otu <- as.data.frame(t(otu_table(ps_rare)))
metadata <- as.data.frame(sample_data(ps_rare))
week8 <- metadata$Time == "WK8"

# Create ml_data
ml_data <- data.frame(
  Group = metadata$PP_HH[week8],
  otu[week8, ]
)

# CONVERT TO FACTOR!
ml_data$Group <- factor(ml_data$Group)

# Train
set.seed(123)
rf_model <- randomForest(Group ~ ., data = ml_data, importance = TRUE, ntree = 1000)

# Results
print(rf_model)
cat("\n")

# Get accuracy
accuracy <- (1 - rf_model$err.rate[nrow(rf_model$err.rate), "OOB"]) * 100
cat(sprintf("Accuracy: %.1f%%\n\n", accuracy))

# Get top features - IMPROVED LABELING
importance_scores <- importance(rf_model)

# Get top 50 to have enough classified bacteria
top50_asvs <- head(rownames(importance_scores)[order(-importance_scores[,"MeanDecreaseAccuracy"])], 50)

# Get taxonomy
tax <- as.data.frame(tax_table(ps_rare))

# Add taxonomy with better labeling
top_data <- data.frame(
  ASV = top50_asvs,
  Importance = importance_scores[top50_asvs, "MeanDecreaseAccuracy"]
) %>%
  left_join(tax %>% rownames_to_column("ASV"), by = "ASV") %>%
  mutate(
    Label = case_when(
      !is.na(Genus) & Genus != "" & Genus != "uncultured" ~
        paste0(Family, " (", Genus, ")"),
      !is.na(Family) & Family != "" & Family != "uncultured" ~
        Family,
      !is.na(Order) & Order != "" & Order != "uncultured" ~
        paste0(Order, " (Order)"),
      !is.na(Class) & Class != "" & Class != "uncultured" ~
        paste0(Class, " (Class)"),
      TRUE ~ "Unclassified"
    )
  ) %>%
  filter(Label != "Unclassified") %>%  # Remove unclassified
  head(10)  # Get top 10 classified bacteria

# Create publication-quality plot
p <- ggplot(top_data, aes(x = reorder(Label, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "darkturquoise", alpha = 0.8) +
  geom_text(aes(label = sprintf("%.2f", Importance)), hjust = -0.1, size = 3) +
  coord_flip() +
  theme_bw() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    axis.text.y = element_text(size = 9),
    panel.grid.major.y = element_blank()
  ) +
  labs(
    title = "Random Forest: Top 10 Predictive Bacterial Features",
    subtitle = sprintf("Classification Accuracy: %.1f%%", accuracy),
    x = "Bacterial Feature",
    y = "Mean Decrease in Accuracy"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

# Save figure
ggsave("RF_Top10Features.png", p, width = 10, height = 8, dpi = 300)
ggsave("RF_Top10Features.pdf", p, width = 10, height = 8, dpi = 300)

cat("✅ Figure saved: RF_Top10Features.png/pdf\n")

# Show top features
cat("\nTop 10 Classified Features:\n")
print(top_data[, c("Label", "Family", "Importance")], row.names = FALSE)

# Check Christensenellaceae rank
christen_rank <- which(grepl("Christensenellaceae", top_data$Label))[1]
if(!is.na(christen_rank)) {
  cat(sprintf("\n🌟 Christensenellaceae ranked #%d in top 10!\n", christen_rank))
}
