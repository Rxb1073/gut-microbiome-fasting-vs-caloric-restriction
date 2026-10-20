# Generated Figures

This folder contains output figures from the R analysis scripts.

## Figures

| File | Description | Script |
|------|-------------|--------|
| Figure_1e_alpha_diversity.png | Alpha diversity (Faith's PD) boxplot | figure_generation.R |
| Figure_1g_beta_diversity.png | Beta diversity PCoA with PERMANOVA | figure_generation.R |
| Beta_Trajectory_PCoA.png | PCoA with individual trajectories (WK0→WK4→WK8) | beta_trajectory.R |
| RF_Top10Features.png | Random Forest feature importance | machine_learning.R |
| BeneficialBacteria_Boxplot.png | Christensenellaceae/Rikenellaceae/Ruminococcaceae boxplots | beneficial_bacteria.R |

## Regenerating Figures

```r
source("scripts/R/figure_1e_alpha.R")
source("scripts/R/figure_1g_beta.R")
source("scripts/R/beta_trajectory.R")
source("scripts/R/machine_learning.R")
source("scripts/R/beneficial_bacteria.R")
```
