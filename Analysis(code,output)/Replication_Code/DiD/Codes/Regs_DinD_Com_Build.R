
############################# DiD - COM ########################################

install.packages("pacman")
library(pacman)
p_load(haven, dplyr, lubridate, readr)

estab_df <- read_dta("/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1/Data/Generated/establishment_analysis_monthly.dta")
outfile <- "/Users/rfernex/Documents/Education/SciencesPo/Courses/M2/S1/Labor/Replication/191661-V1/Replication/DiD/C4_CoM_Alt/Data/"

# Construct calendar weeks for 1933 (we assume away time off) and hourly wage 
estab_df <- estab_df %>%
  mutate(
    month = as.integer(month),
    weeks_in_month_cal = ifelse(
      year == 1933 & month >= 1 & month <= 12,
      c(31,28,31,30,31,30,31,31,30,31,30,31)[month] / 7, 4.33),
    yearly_hours = as.numeric(ewemt) * as.numeric(weeks_in_month_cal) * as.numeric(imputed_workweek),
    hourly_wage = ifelse(!is.na(e005s) & !is.na(yearly_hours) & yearly_hours > 0, as.numeric(e005s) / yearly_hours, NA),
    l_hourly_wage = ifelse(!is.na(hourly_wage) & hourly_wage > 0, log(hourly_wage), NA),
    weekly_wage = hourly_wage * imputed_workweek,
    l_weekly_wage = ifelse(!is.na(weekly_wage) & weekly_wage > 0, log(weekly_wage), NA),
    l_ewemt = ifelse(!is.na(ewemt) & ewemt > 0, log(ewemt), NA),
    l_workweek = ifelse(!is.na(imputed_workweek) & imputed_workweek > 0, log(imputed_workweek), NA)
  )

# Build necessary variables and apply filters

# - Workweek pre PRA variable (used to compute treatment intensity)
prepra_above_share <- estab_df %>%
  filter(year == 1933, month >= 4, month < 7) %>%
  transmute(
    establishment_ID,
    above_ind = as.integer(as.numeric(imputed_workweek) > as.numeric(workweek_limit))
  ) %>%
  group_by(establishment_ID) %>%
  summarise(prePRA_above = sum(above_ind, na.rm = TRUE) / 3, .groups = "drop")

# - Wage pre PRA variable (compared to median to control for minimum wage effect)
pre_est <- estab_df %>%
  filter(year == 1933, month %in% c(4,5,6), !is.na(hourly_wage), hourly_wage > 0) %>%
  group_by(establishment_ID) %>%
  summarise(hourly_wage_prePRA = mean(hourly_wage, na.rm = TRUE), .groups = "drop")

med_hourly_wage_prePRA <- median(pre_est$hourly_wage_prePRA, na.rm = TRUE)

pre_est <- pre_est %>%
  mutate(
    aboveM_hourly_wage_prePRA = hourly_wage_prePRA > med_hourly_wage_prePRA,
    belowM_hourly_wage_prePRA = hourly_wage_prePRA < med_hourly_wage_prePRA
  )

# - Merge with main dataset
estab_1933 <- estab_df %>%
  filter(year == 1933, included_industry == 1, valid_imputed_workweek == 1,
         !is.na(l_hourly_wage), month >= 4, month <= 10, industry_code_num %in% c(118,119,216,1110,1112,1408)) %>%
         left_join(prepra_above_share, by = "establishment_ID") %>% 
         left_join(pre_est, by = "establishment_ID") %>%
         mutate(PRA_prePRA_above = as.numeric(PRA_period) * prePRA_above,
                PRA_aboveM_hourly_wage_prePRA = as.numeric(PRA_period) * aboveM_hourly_wage_prePRA,
                PRA_belowM_hourly_wage_prePRA = as.numeric(PRA_period) * belowM_hourly_wage_prePRA)

# Select and export for Stata 

# Build dataset
Establishment_DiD <- estab_1933 %>%
  mutate(weight_emp = as.numeric(ewemt)) %>%
  select(establishment_ID, year, month, industry_code_num, e005s, ewemt, l_ewemt,
    imputed_workweek, weeks_in_month_cal, l_workweek, workweek_limit, yearly_hours, hourly_wage, 
    l_hourly_wage, weekly_wage, l_weekly_wage, PRA_period, prePRA_above, PRA_prePRA_above, 
    aboveM_hourly_wage_prePRA, belowM_hourly_wage_prePRA, PRA_aboveM_hourly_wage_prePRA, 
    PRA_belowM_hourly_wage_prePRA)

write_dta(Establishment_DiD, paste(outfile,"establishment_1933_hourly_dataset.dta",sep = ""),version = 14)

