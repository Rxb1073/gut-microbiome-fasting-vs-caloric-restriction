library(tidyverse)
library(lme4)
library(lmerTest)

# Load metadata
meta <- read_tsv("metadata_merged_qiime_FINAL.tsv") %>%
  rename(sample_id = `sample-id`) %>%
  mutate(
    subject_id = factor(sub("_.*", "", subject)),
    Group = factor(Group, levels = c("CR", "IF-P")),
    Time  = factor(Time_num, levels = c("WK0", "WK4", "WK8"))
  )

# Load Observed ASVs
alpha_obs <- read_tsv("alpha-observed.tsv") %>%
  rename(sample_id = `...1`) %>%
  transmute(sample_id, value = observed_features)

df_obs <- meta %>%
  left_join(alpha_obs, by = "sample_id") %>%
  filter(!is.na(value))

# Mixed model for p-values
model_obs <- lmer(value ~ Group * Time + (1 | subject_id), data = df_obs)
anova_obs <- anova(model_obs, type = 3)

p_time  <- anova_obs["Time", "Pr(>F)"]
p_inter <- anova_obs["Group:Time", "Pr(>F)"]

p_label <- paste0(
  "Time: p = ", formatC(p_time, digits = 3, format = "f"), "\n",
  "Inter: p = ", formatC(p_inter, digits = 3, format = "f")
)

# Paper colors
group_cols <- c("CR" = "#B11273", "IF-P" = "#00BFC4")

# Plot
p_alpha <- ggplot(df_obs, aes(x = Time, y = value)) +
  geom_line(aes(group = subject_id), color = "grey60", linewidth = 0.6) +
  geom_point(aes(color = Group), size = 2.3) +
  geom_boxplot(
    aes(fill = Group),
    width = 0.6,
    outlier.shape = NA,
    color = "black",
    linewidth = 0.9
  ) +
  facet_wrap(~ Group, nrow = 1) +
  geom_text(
    data = tibble(Group = "CR"),
    aes(x = 0.5, y = max(df_obs$value) + 5, label = p_label),
    inherit.aes = FALSE,
    hjust = 0, vjust = 1, size = 3.6
  ) +
  scale_fill_manual(values = group_cols) +
  scale_color_manual(values = group_cols) +
  labs(x = "Time (weeks)", y = "Observed ASVs") +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "none",
    strip.background = element_rect(fill = "black", color = "black"),
    strip.text = element_text(color = "white", face = "bold"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    axis.title = element_text(face = "bold")
  )

ggsave("Figure_1e_alpha.pdf", p_alpha, width = 8, height = 6, dpi = 300)
ggsave("Figure_1e_alpha.png", p_alpha, width = 8, height = 6, dpi = 300)

cat("✅ Figure 1e saved: Figure_1e_alpha.png/pdf\n")
