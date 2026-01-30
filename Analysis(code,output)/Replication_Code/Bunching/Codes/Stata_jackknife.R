
######################## Jackknife estimator ###################################

# - Identifies top-5 industries by employment
# - Runs Stata do-file 5 times (full + leave-one-out)
# - Stacks results and creates a summary plot

################################################################################

#install.packages("pacman")
library(pacman)
p_load(haven, dplyr, readr, glue, purrr, ggplot2, tidyr, stringr, tibble, fs)

# Load the main dataset 
df_main <- read_dta("/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1/Data/Generated/establishment_analysis_monthly.dta")

# Restrict to observations included in the baseline
df_filt <- df_main |> filter(included_industry == 1, valid_imputed_workweek == 1)

# Compute industry totals and pick top-5 by employment size
top5_tbl <- df_filt |>
  group_by(industry_code_num) |>
  summarise(total_emp = sum(ewemt, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(total_emp)) |>
  slice_head(n = 5) |>
  mutate(rank = row_number())

# set output directory
outdir <- "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1/Replication/Bunching/C4_Jackknife"

# Define the function to run the Stata script for the bunching estimator
stata_bin <- "/Applications/StataNow/StataMP.app/Contents/MacOS/StataMP"

shq <- function(x) sprintf('"%s"', x)

run_LOO <- function(exclind) {
  outpath <- file.path(outdir, glue("Bunching_monthly_without{exclind}.csv"))
  upper_bound_tr <- 40
  lower_bound_tr <- 25
  bin_size <- 4
  results_label <- "_jackknife" 
  cmd <- glue('{stata_bin} -q -b do "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1/Replication/Bunching/Codes/regs_bunching_jackknife.do" {upper_bound_tr} {lower_bound_tr} {bin_size} "{results_label}" {exclind} "{outpath}"')
  message("Running: ", cmd)
  status <- system(cmd)
  if (status != 0) {
    stop(glue("Stata run failed for exclind={exclind}. Exit code: {status}"))
  }
  return(outpath)
}

# Computes bunching estimates with each leave one out fold
excl_vec <- c(as.integer(top5_tbl[[1]]))
files <- map_chr(excl_vec, run_LOO)

# Stack outputs and write a tidy combined CSV
read_one <- function(path) {
  df <- suppressMessages(read_csv(path, show_col_types = FALSE))
  df$source_file <- path
  df
}
all_runs <- map_dfr(files, read_one)


all_runs_plot <- all_runs

# Builds the x scale and order by date
year_num <- as.integer(str_extract(all_runs_plot$monthyear, "^[0-9]{4}"))
mon_num  <- as.integer(str_extract(all_runs_plot$monthyear, "(?<=m)[0-9]{1,2}$"))
all_runs_plot <- all_runs_plot |> 
    mutate(year_num = year_num, mon_num  = mon_num, ym_order = year_num * 12L + mon_num) |>
    arrange(ym_order) |>
    mutate(monthyear = factor(monthyear, levels = unique(monthyear)))
x_var <- "monthyear"


# Side label
all_runs_plot <- all_runs_plot |>
  mutate(side = if_else(bin_above_pra_cutoff == 1, "Above limit", "Below limit"))

# Compute jackknife aggregate across industries (exclude full-sample rows)
#    - mean of leave-one-out estimates by period and side
#    - jackknife SE 
jk_agg <- all_runs_plot |>
  filter(industry_excluded != 0) |>
  group_by(!!rlang::sym(x_var), side) |>
  summarise(
    jk_mean = mean(diff_in_diff_estimator, na.rm = TRUE),
    m       = sum(!is.na(diff_in_diff_estimator)),
    ssq     = sum((diff_in_diff_estimator - jk_mean)^2, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    # classic jackknife variance scaling
    jk_var = ifelse(m > 1, (m - 1) / m * ssq, NA_real_),
    jk_se  = sqrt(jk_var),
    ymin   = jk_mean - 1.96 * jk_se,
    ymax   = jk_mean + 1.96 * jk_se,
    ylab   = sprintf("%.3f", jk_mean)
  )

col_side <- c("Below limit" = "#1f77b4", "Above limit" = "#d62728")

# Builds the graph
p_jk <- ggplot(jk_agg, aes_string(x = x_var, y = "jk_mean", color = "side")) +
  geom_errorbar(aes(ymin = ymin, ymax = ymax), width = 0.15, size = 0.6) +
  geom_point(size = 2.1) +
  geom_text(
    aes(label = ylab),
    nudge_y = 0.02 * max(abs(jk_agg$jk_mean), na.rm = TRUE) + 0.02,
    size = 3,
    show.legend = FALSE
  ) +
  scale_color_manual(values = col_side, name = "Side of limit") +
  labs(
    title = "Aggregate Jackknife estimator with 95% CI",
    x = "Month",
    y = "Employment as % of July 1933"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "top",
    plot.title = element_text(face = "bold")
  ) 

# Exports the plot as png 
plot_path <- file.path(outdir, "DinD_points_with_CI_jackknife_aggregate.pdf")
ggsave(plot_path, p_jk, width = 8.2, height = 5.2)
print(p_jk)
message("Saved aggregate jackknife plot: ", plot_path)

png_path <- file.path(outdir, "DinD_points_with_CI_jackknife_aggregate.png")
ggsave(png_path, p_jk, width = 8.2, height = 5.2, dpi = 200)
message("Saved PNG preview: ", png_path)



