# README for Fishback, Vickers, and Ziebarth (2023) "Labor Market Effects of Workweek Restrictions" (AEJMacro-2022-0188)

## Overview

The code in this replication package constructs the analysis file from a variety of data sources documented below using Stata. One main file runs all of the code to generate the data and all figures and tables in the paper and appendix. The replicator should expect the code to run for less than 10 minutes.

## Data Availability and Provenance Statements

### Statement about Rights

- [X] I certify that the authors of the manuscript have legitimate access to and permission to use the data used in this manuscript. 
- [X] I certify that the authors of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permissions are documented in the [LICENSE.txt](LICENSE.txt) file.

### License for Data

The data is licensed under a MIT license. 

### Summary of Availability

- [X] All data **are** publicly available.
- [ ] Some data **cannot be made** publicly available.
- [ ] **No data can be made** publicly available.

The data used to support the findings of this study have been deposited in the [OpenICPSR repository 191661](http://doi.org/10.3886/E191661V1). The data were collected by the authors and are available under a MIT license.

### Data Sources

#### Public use data collected by the authors

The following data used to support the findings of this study have been deposited in the "Data and Code for: Labor Market Effects of Workweek Restrictions: Evidence from the Great Depression" repository (openicpsr-191661). The data were collected by the authors, and are available under a MIT Non-commercial license.

1. The file `CoM_workweek.dta` was collected by CZV and NLZ from original schedules of the Census of Manufactures that are publicly available at the National Archives. There is identifying information for businesses in this dataset, but these records are publicly available so the data can be published without restrictions. The dataset can also be accessed through ICPSR using the DOI: https://doi.org/10.3886/ICPSR37114.v1.
2. The file `hee115.xlsx` contains data on employment, payrolls, hours, and wages in 115 industries the authors transcribed and originally published by National Recovery Administration (1936). The Source sheet in the file details the original source.
3. The file `industries.table.paper.2021.08.13.xlsx` contains details of the Codes of Fair Conduct the authors transcribed and originally published by the National Recovery Administration (1935). The Source sheet in the file details the original source.
4. The file `link_HEE115_CoM.xls`  contains links made by the authors between industries listed in `hee115.xslx` and `CoM_workweek.dta`.
 
#### Public use data sourced from elsewhere and provided

1. The file `moncycle.dta`  is FRED series IPB50001N (https://fred.stlouisfed.org/series/IPB50001N). It contains industrial production data. A copy of the data in Stata format is provided as part of this archive. The data are in the public domain.
2. The file `labor_input_ColeOhanian99.dta` is from Table 5 of Cole & Ohanian (1999) transcribed by the authors. Their original source for the data is Kendrick (1961).
3. The file `mfghee2.xlsx` provides industry-level data on employment, wages, and hours originally collected by National Industrial Conference Board (1938). We assembled this file using the publicly available datasets from the NBER Macrohistory Database (https://www.nber.org/research/data/nber-macrohistory-viii-income-and-employment) for the following industries and variables with the series title listed below:

Employment  

Auto:		m08144
Boot & Shoe:	m08103	
Chemical:	m08216a	
Leather:	m08102	
Paper:		m08104
Rubber:	m08220a	
Machine:	m08224	
Meat:		m08087
Iron & Steel:	m08015	
Wool:		m08232

Hours	

Auto:		m08201a
Boot & Shoe:	m08199a	 
Chemical:	m08214a	
Leather:	m08198a	
Paper:		m08234a
Rubber:	m08218a	
Machine:	m08222	
Meat:		m08196a
Iron & Steel:	m08208a	
Wool:		m08230a

Wages

Auto:		m08207a
Boot & Shoe:	m08205a	
Chemical:	m08215a	
Leather:	m08204a	
Paper:		m08235a
Rubber:	m08218a	
Machine:	m08223	
Meat:		m08202a
Iron & Steel:	m08210a	
Wool:		m08231a

#### Free use data with required registration, extract not provided

1. The paper uses data from the ICPSR Studies 35604 (DOI:  https://doi.org/10.3886/ICPSR35604.v1) and 35605 (https://doi.org/10.3886/ICPSR35605.v1). Data is subject to a redistribution restriction, but can be freely downloaded from https://www.icpsr.umich.edu/web/ICPSR/studies/35604# and https://www.icpsr.umich.edu/web/ICPSR/studies/35605#. Download the files in Stata format and put them in file in the directory `Data/Source`. The files should be named  `35604-0001-Data.dta`  and `35605-0001-Data.dta`, respectively.

## Dataset list

All files are in directory `Data/Source`.

| Data file | Source | Notes    |Provided |
|-----------|--------|----------|---------|
| `35604-0001-Data.dta` | ICPSR Study #35604 (Raff et al. 2015a)| Monthly hours for automobile industries | No| 
| `35605-0001-Data.dta`|ICPSR Study #35605 (Raff et al. 2015b)| Monthly hours for cotton goods industries | No| 
| `CoM_workweek` | ICPSR Study #37114  (Vickers and Ziebarth 2018)| Establishment level data | Yes| 
| `hee115.xlsx` | National Recovery Administration (1936)| Employment, Payrolls, Hours, and Wages in 115 Industries | Yes| 
| `industries.table.paper.2021.08.13.xlsx`| National Recovery Administration (1935)| Details of "Codes of Fair Competition" by industry | Yes|
| `labor_input_ColeOhanian99.dta` | Table 5 of Cole & Ohanian (1999) | Original source for that table is Kendrick (1961) | Yes| 
|  `link_HEE115_CoM.xls` | Authors created| Links between industries in `hee115.xslx` and `CoM_workweek`. The sheet "Employment" has the employment numbers we use to "deindex" the employment indexes.| Yes | 
| `mfghee2.xlsx`| National Industrial Conference Board (1938)| Industry-level data on employment, wages, and hours| Yes| 
| `moncycle.dta`|FRED series IPB50001N| Industrial production series, not seasonally adjusted| Yes| 

## Computational requirements

### Software Requirements

- Stata (code was last run with version 17. All packages from SSC repository are most up-to-date version as of 2023-5-11.)
  - `erepost` 
  - `egenmore` 
  - `estout` 
  - `reghdfe` 
  - `coefplot` 
  - `xttrans2` 
  - `ftools` 
  - `regsave` 
  - `carryforward`
  - `savesome`
  - the program `install_dependencies_subfolders.do` will install all dependencies locally and only needs to be run once.

### Memory and Runtime Requirements

The code was last run on a **M1 laptop with 16GB RAM and MacOS version 13.3.1**. It does not require any special hardware.

#### Summary

Approximate time needed to reproduce the analyses on a standard 2021 desktop machine:

- [X ] <10 minutes
- [ ] 10-60 minutes
- [ ] 1-2 hours
- [ ] 2-8 hours
- [ ] 8-24 hours
- [ ] 1-3 days
- [ ] 3-14 days
- [ ] > 14 days
- [ ] Not feasible to run on a desktop machine, as described below.

## Description of Code directory

- Programs in `Code/Build` will extract and reformat all datasets referenced above. 
  - Programs in `Code/Build/Helper` are additional do files that are not called directly by `runme.do`.
- Programs in `Code/Analyze` generate all tables and figures in the main body of the article. 
  - Programs in `Code/Analyze/Establishment` generate all tables and figures using the establishment-level dataset.
  - Programs in `Code/Analyze/Industry` generate all tables and figures using the industry-level dataset.
- The program `Code/Build/install_dependencies_subfolders.do` will populate the `programs/ado` directory with updated ado packages and create the subdirectories to place tables and figures.

### License for Code

The code is licensed under a MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

1. Unzip the replication file.
2. After opening Stata, change working directory to directory where files were unzipped to.
3. Run `Code/runme.do`

### Details

- `programs/install_dependencies_subdirectories.do`: will create all output directories, install needed ado packages. 
   - If wishing to update the ado packages used by this archive, change the parameter `update_ado` to `yes`. However, this is not needed to successfully reproduce the manuscript tables. 
- `Code/Build`:  
  - Order IS important if running programs in `Code/Build` individually.
  - The files in `Code/Build/Helper` are called by the files in `Code/Build` but not directly in the `Code/runme.do` file.
  - These programs were last run on 2023-5-11. 
- `Code/Analyze`.
   - Once the data have been built, the order of executing code in this directory is NOT important.  
   - These programs were last run on 2023-5-11. 

## List of tables and figures

The provided code reproduces:

- [X] All numbers provided in text in the paper
- [X] All tables and figures in the paper
- [ ] Selected tables and figures in the paper, as explained and justified below.

The line number reported is the line at which the output is written to file. 

- Manuscript

| Figure/Table #    | Program                  | Line Number | Output file                      | Note                            |
|-------------------|--------------------------|-------------|----------------------------------|---------------------------------|
| Table 1           |         Analyze/Industry/regs_Taylor_SSNRA                  |      76       | Tables/regs_Taylor_SSNRA1_IP                ||
| Table 2           |        Analyze/Industry/regs_DinD_PRA_industry                   |      95     | Tables/regs_DinD_PRA_industry_SSNRA_earn                       ||
| Table 3           |        Analyze/Industry/regs_DinD_PRA_industry  |         138       | Tables/regs_DinDinD_PRA_industry_SSNRA_earnB                      ||
| Figure 1          | Analyze/fig_ColeOhanian          |         11    | Figures/fig_ColeOhanian_labor_input.pdf                                  |         |
| Figure 2          | Analyze/compare_establishment_industry      |    60         | Figures/compare_establishment_industry_med_workweek_1933.pdf                      ||
| Figure 3          |   Analyze/Establishment/density_workweek_PRA   |    18         | Figures/density_PRA_imputed_workweek_ewemt.pdf         |    |
| Figure 4          |     Analyze/Establishment/plot_employment_byWorkweek  |         75    | Figures/plot_employment_byWorkweek_index_ewemt_all_bw1000            |      |
| Figure 5          |   Analyze/Establishment/chars_at_PRA_limit_Pre   |  60           | Figures/compare_at_PRA_limit_prePRA.pdf            |    |
| Figure 6          |    Analyze/Establishment/regs_bunching   |        113     | Figures/regs_bunching_DinD_aroundPRA           |      |
| Figure 7          |   Analyze/Industry/regs_DinD_PRA_industry   |     73        | Figures/regs_DinD_PRA_pretrends_SSNRA            | |

- Appendix 

| Figure/Table #    | Program                  | Line Number | Output file                      | Note                            |
|-------------------|--------------------------|-------------|----------------------------------|---------------------------------|
| Table 1           |  Analyze/Establishment/summary_stats  |        19     | Tables/summary_stats_inds                |
| Table 2           |  Analyze/Establishment/summary_stats  |       35      | Tables/summary_stats_ind_counts                ||
| Table 3           | n.a.   |     n.a.        | Data/Source/PRA_modifications                | Based  on `industries.table.paper.2021.08.13.xlsx` (NRA 1935)|
| Table 4           | Analyze/Industry/regs_Taylor_SSNRA   |      87       | Tables/regs_Taylor_SSNRA1_IP_balanced                 ||
| Table 5           |  Analyze/Industry/regs_Taylor_SSNRA    |      79       | Tables/regs_Taylor_SSNRA1_IP_level_ewemt                 ||
| Table 6           |  Analyze/Industry/regs_Taylor_SSNRA    |  95           | Tables/regs_Taylor_SSNRA1_IP_fullyBalanced                ||
| Table 7           |   Analyze/Industry/regs_Taylor_SSNRA   |      104       | Tables/regs_Taylor_SSNRA1_IP_wage                ||
| Table 8           |  Analyze/Industry/regs_DinD_PRA_industry    |     103        | Tables/regs_DinD_PRA_industry_SSNRA_workweek_prePRA_earn                 ||
| Table 9           |  Analyze/Industry/regs_DinD_PRA_industry    |      103       | Tables/regs_DinD_PRA_industry_NICB_earn                ||
| Figure 1          |   Analyze/Establishment/chars_at_PRA_limit_Pre   |    60         | Figures/compare_at_PRA_limit_bw4_prePRA.pdf                 ||
| Figure 2          |   Analyze/Establishment/missing_data_bySize  |       11     | Figures/missing_data_bySize_missing_imputed_workweek_1933_ewemt                ||
| Figure 3          |   Analyze/Establishment/missing_data_bySize  |         11    | Figures/missing_data_bySize_valid_imputed_workweek_1933_ewemt                 ||
| Figure 4          |   Analyze/Establishment/compare_workweek_vars  |  9           | Figures/compare_workweek_vars_diff_1933.pdf                ||
| Figure 5          | Analyze/compare_SSNRA_COM.do    |     50        | Figures/compare_SSNRA_COM_med_workweek.pdf                 ||
| Figure 6          |   Analyze/Industry/density_workweek_PRA_industry  |       23      | Figures/density_SSNRA_PRA_workweek_ewemt.pdf                 ||
| Figure 7          |   Analyze/Establishment/density_workweek_PRA  |      18       | Figures/density_PRA_imputed_workweek_six_ewemt.pdf                 ||
| Figure 8          |  Analyze/Establishment/regs_bunching   |      95       | Figures/regs_bunching_DinD_check1_aroundPRA                 ||
| Figure 9          |   Analyze/Establishment/regs_bunching   |      95       | Figures/regs_bunching_DinD_check2_aroundPRA                ||
| Figure 10         |   Analyze/Establishment/regs_bunching   |        95     | Figures/regs_bunching_DinD_check3_aroundPRA               ||
| Figure 11         |   Analyze/Industry/event_study_PRA_industry  |   49          | Figures/event_study_SSNRA_l_hourly_earn                ||

## References

Board of Governors of the Federal Reserve System (US), Industrial Production: Total Index [IPB50001N], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/IPB50001N, May 19, 2023.
Cole, Harold L. and Lee E. Ohanian, The Great Depression From a Neoclassical Perspective, Federal Reserve Bank of Minneapolis Quarterly Review, 1999, 23, 2–24.
Kendrick, John W., Productivity Trends in the United States, Princeton University Press, 1961.
National Industrial Conference Board, Wages, Hours, and Employment in the United States, July 1936—December 1937. Supplement to Conference Board Service Letter, National Industrial Conference Board, Inc., 1938.
National Recovery Administration, Codes of Fair Competition as Approved, Vol. 1-21, U.S. Government Printing Office, 1935.
National Recovery Administration, Employment, Payrolls, Hours, and Wages in 115 Selected Code Industries, U.S. Government Printing Office, 1936.
Raff, Daniel M. G., Bresnahan, Timothy F., Lee, Changkeun, and Levenstein, Margaret. United States Census of Manufactures, Motor Vehicle Industry, 1929-1935. Inter-university Consortium for Political and Social Research, 2015a. 
Raff, Daniel M. G., Bresnahan, Timothy F., Lee, Changkeun, and Levenstein, Margaret. United States Census of Manufactures, Cotton Goods Industry, 1929-1935. Inter-university Consortium for Political and Social Research, 2015b.
Vickers, Chris and Nicolas L. Ziebarth, United States Census of Manufactures, 1929-1935. ICPSR37114-v1, Inter-university Consortium for Political and Social Research, 2018.