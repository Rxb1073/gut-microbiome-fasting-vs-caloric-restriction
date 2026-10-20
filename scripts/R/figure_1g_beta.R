library(data.table)
library(dplyr)
library(stringr)
library(ggplot2)
library(tidyr)

# Read Bray-Curtis distance matrix
dm <- read.delim("distance-matrix.tsv",
                 sep = "\t", header = TRUE, check.names = FALSE,
                 stringsAsFactors = FALSE)

rownames(dm) <- dm[[1]]
dm <- dm[, -1]
bray_mat <- as.matrix(dm)
storage.mode(bray_mat) <- "numeric"

# Read metadata
meta <- data.table::fread("metadata_merged.tsv",
                          sep = "\t", data.table = FALSE, fill = TRUE, quote = "")

meta <- meta %>% mutate(across(where(is.character), ~ str_trim(.x)))

# Detect columns
sample_ids <- rownames(bray_mat)

overlap_counts <- sapply(meta, function(col) {
  if (is.character(col) || is.factor(col)) sum(as.character(col) %in% sample_ids, na.rm = TRUE) else 0
})
sample_col <- names(which.max(overlap_counts))

wk_hits <- sapply(meta, function(col) {
  x <- toupper(as.character(col))
  sum(grepl("^WK\\s*\\d+$", x) | grepl("^WK\\d+$", x), na.rm = TRUE)
})
time_col <- names(which.max(wk_hits))

subject_col <- if ("subject" %in% names(meta)) "subject" else {
  looks_like_subject <- sapply(meta, function(col) {
    sum(grepl("^SM\\d+_\\d+$", as.character(col)), na.rm = TRUE)
  })
  names(which.max(looks_like_subject))
}

group_col <- if ("Group" %in% names(meta)) "Group" else if ("group" %in% names(meta)) "group" else NA_character_

# Build analysis metadata
meta2 <- meta %>%
  transmute(
    sample   = as.character(.data[[sample_col]]),
    Time_raw = toupper(gsub("\\s+", "", as.character(.data[[time_col]]))),
    subject  = as.character(.data[[subject_col]]),
    Group    = if (!is.na(group_col)) as.character(.data[[group_col]]) else NA_character_
  ) %>%
  filter(!is.na(sample), sample != "", sample %in% sample_ids) %>%
  filter(!is.na(Time_raw), Time_raw != "") %>%
  mutate(
    Time_std = case_when(
      Time_raw %in% c("WK0", "WK00") ~ "Baseline",
      Time_raw %in% c("WK4", "WK04") ~ "Week4",
      Time_raw %in% c("WK8", "WK08") ~ "Week8",
      TRUE ~ NA_character_
    ),
    subject_core = str_replace(subject, "_\\d+$", "")
  )

# Baseline map
baseline_map <- meta2 %>%
  filter(Time_std == "Baseline") %>%
  group_by(subject_core) %>%
  summarise(baseline_sample = first(sample), .groups = "drop")

# Compute Bray-Curtis from baseline
df <- meta2 %>%
  filter(Time_std %in% c("Week4", "Week8")) %>%
  left_join(baseline_map, by = "subject_core") %>%
  mutate(
    BrayCurtis = bray_mat[cbind(sample, baseline_sample)],
    week = if_else(Time_std == "Week4", 4, 8)
  ) %>%
  filter(!is.na(baseline_sample), !is.na(BrayCurtis))

# Wilcoxon tests
p_week4 <- wilcox.test(BrayCurtis ~ Group, data = df %>% filter(week == 4))
p_week8 <- wilcox.test(BrayCurtis ~ Group, data = df %>% filter(week == 8))

# P-value annotations
p_annot <- data.frame(
  week  = c(4, 8),
  pval  = c(p_week4$p.value, p_week8$p.value)
) %>%
  mutate(label = paste0("p = ", formatC(pval, format = "f", digits = 4)))

y_max <- df %>%
  group_by(week) %>%
  summarise(y = max(BrayCurtis, na.rm = TRUE), .groups = "drop")

p_annot <- left_join(p_annot, y_max, by = "week") %>%
  mutate(
    y = y + 0.04,
    y_bracket = y - 0.01
  )

week_levels <- sort(unique(df$week))
p_annot <- p_annot %>%
  mutate(x = match(week, week_levels))

# Plot
df$Group <- factor(df$Group, levels = c("IF-P", "CR"))

p_beta <- ggplot(df, aes(x = factor(week), y = BrayCurtis, fill = Group)) +
  geom_boxplot(
    width = 0.60,
    outlier.shape = NA,
    colour = "black",
    linewidth = 0.9,
    position = position_dodge(width = 0.75)
  ) +
  geom_point(
    aes(fill = Group),
    position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.75),
    size = 2.0,
    shape = 21,
    colour = "black",
    stroke = 0.45,
    alpha = 0.9
  ) +
  scale_fill_manual(values = c("IF-P" = "#1FBFC1", "CR" = "#C13CBF")) +
  geom_segment(
    data = p_annot,
    aes(x = x - 0.22, xend = x + 0.22, y = y_bracket, yend = y_bracket),
    inherit.aes = FALSE,
    linewidth = 0.8
  ) +
  geom_text(
    data = p_annot,
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    size = 4.2
  ) +
  theme_classic() +
  labs(
    x = "Time (weeks)",
    y = "Bray-Curtis dissimilarity",
    fill = NULL
  )

ggsave("Figure_1g_beta.pdf", p_beta, width = 5.2, height = 4.2, dpi = 300)
ggsave("Figure_1g_beta.png", p_beta, width = 5.2, height = 4.2, dpi = 300)

cat("✅ Figure 1g saved: Figure_1g_beta.png/pdf\n")
cat("Week 4 p-value:", p_week4$p.value, "\n")
cat("Week 8 p-value:", p_week8$p.value, "\n")
