# install.packages(c("tidycensus", "dplyr", "purrr", "stringr", "tidyr", "readr"))
library(tidycensus)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(readr)

# ------------------------------------------------------------------------------
# 0) Setup
# ------------------------------------------------------------------------------
YEAR <- 2024          # ACS ENDYEAR (this will pull the 2020–2024 5-year)
SURVEY <- "acs5"

census_api_key("6762aefaa427df4ee803e66ab02308becf2cc4a8", install = TRUE)
options(tigris_use_cache = TRUE)

# Helper to fetch a single variable ID from a table/dataset by regex on its label.
pick_var <- function(year, dataset, label_regex) {
  vars <- load_variables(year, dataset, cache = TRUE)
  cand <- vars |>
    filter(str_detect(label, regex(label_regex, ignore_case = TRUE))) |>
    # prefer Percent estimates (PE) or main estimate (E) depending on concept
    arrange(desc(str_detect(name, "PE$")), desc(str_detect(name, "_E$")))
  if (nrow(cand) == 0) stop(sprintf("No match for /%s/ in %s %s", label_regex, dataset, year))
  cand$name[1]
}

# Helper to fetch multiple variables given a named list of label regex, from a single dataset.
pick_vars <- function(year, dataset, named_patterns) {
  map_chr(named_patterns, ~ pick_var(year, dataset, .x)) |>
    rlang::set_names(names(named_patterns))
}

# ------------------------------------------------------------------------------
# 1) Build a variable dictionary matching county_2019 concepts
#     Tables used:
#       - Population: B01003
#       - Demographic profile (race/age/household structure): DP05, DP04
#       - Age & sex, household size, family size, commuting: S0101, S1101, S0801
#       - Education: S1501
#       - Income (mean/median, per capita): S1901/S1903; individual earnings: S2002
#       - Poverty: S1701
#       - Unemployment: S2301 (20–64 years)
#       - Insurance: S2701
#       - Computer/Internet: S2801
#       - Language: S1601
# ------------------------------------------------------------------------------

# Population (count, plus MOE)
pop_vars <- c(pop = "B01003_001")  # estimate
# we'll also pull MOE automatically by using variables=..., output = "wide"

# Race / ethnicity percentages (DP05 profile table)
dp05_patterns <- c(
  white                 = "Percent!!Race alone.*Total population!!White(?!, Not Hispanic)",  # race alone/in combo
  black                 = "Percent!!Race alone.*Total population!!Black or African American",
  native                = "Percent!!Race alone.*Total population!!American Indian and Alaska Native",
  asian                 = "Percent!!Race alone.*Total population!!Asian",
  pac_isl               = "Percent!!Race alone.*Total population!!Native Hawaiian and Other Pacific Islander",
  other_single_race     = "Percent!!Race alone.*Total population!!Some other race",
  two_plus_races        = "Percent!!Race alone.*Total population!!Two or more races",
  hispanic              = "Percent!!HISPANIC OR LATINO.*Total population!!Hispanic or Latino.*Percent$",
  white_not_hispanic    = "Percent!!HISPANIC OR LATINO.*Not Hispanic or Latino!!White alone.*Percent$",
  median_age            = "^Estimate!!Total population!!Median age"
)

dp05_ids <- pick_vars(YEAR, "acs5/profile", dp05_patterns)

# Age shares (S0101)
s0101_patterns <- c(
  age_under_5  = "^Percent!!SEX AND AGE!!Under 5 years$",
  age_over_85  = "^Percent!!SEX AND AGE!!85 years and over$",
  age_over_18  = "^Percent!!SEX AND AGE!!18 years and over$",
  age_over_65  = "^Percent!!SEX AND AGE!!65 years and over$"
)
s0101_ids <- pick_vars(YEAR, "acs5/subject", s0101_patterns)

# Household size, family size, persons per household (S1101)
s1101_patterns <- c(
  persons_per_household = "^Estimate!!HOUSEHOLDS BY TYPE!!Households!!Average household size$",
  avg_family_size       = "^Estimate!!FAMILIES!!Average family size$",
  households            = "^Estimate!!HOUSEHOLDS BY TYPE!!Households!!Total households$"
)
s1101_ids <- pick_vars(YEAR, "acs5/subject", s1101_patterns)

# Housing structure types (DP04)
dp04_patterns <- c(
  housing_one_unit_structures = "Percent!!UNITS IN STRUCTURE!!Total housing units!!1-unit structures$",
  housing_two_unit_structures = "Percent!!UNITS IN STRUCTURE!!Total housing units!!Units in.*(2 units|3 or 4 units|5 to 9 units|10 to 19 units|20 or more units)$",
  housing_mobile_homes        = "Percent!!UNITS IN STRUCTURE!!Total housing units!!Mobile homes|boat|RV|van"
)
dp04_ids <- pick_vars(YEAR, "acs5/profile", dp04_patterns)

# Education (S1501)
s1501_patterns <- c(
  hs_grad   = "^Percent!!EDUCATIONAL ATTAINMENT!!Population 25 years and over!!High school graduate or higher$",
  bachelors = "^Percent!!EDUCATIONAL ATTAINMENT!!Population 25 years and over!!Bachelor's degree or higher$"
)
s1501_ids <- pick_vars(YEAR, "acs5/subject", s1501_patterns)

# Incomes (S1901/S1903); individual earnings (S2002)
s1901_patterns <- c(
  per_capita_income       = "^Estimate!!INCOME AND BENEFITS.*Per capita income.*\\(dollars\\)$",
  median_household_income = "^Estimate!!INCOME AND BENEFITS.*Median household income.*\\(dollars\\)$",
  mean_household_income   = "^Estimate!!INCOME AND BENEFITS.*Mean household income.*\\(dollars\\)$"
)
s1901_ids <- pick_vars(YEAR, "acs5/subject", s1901_patterns)

# Median individual income (earnings) overall and among 25+
s2002_patterns <- c(
  median_individual_income            = "^Median earnings.*Population 16 years and over with earnings$",
  median_individual_income_age_25plus = "^Median earnings.*Population 25 years and over with earnings$"
)
s2002_ids <- pick_vars(YEAR, "acs5/subject", s2002_patterns)

# Poverty (S1701)
s1701_patterns <- c(
  poverty                = "^Percent below poverty level!!Population for whom poverty status is determined$",
  poverty_under_18       = "^Percent below poverty level!!Under 18 years$",
  poverty_65_and_over    = "^Percent below poverty level!!65 years and over$"
)
s1701_ids <- pick_vars(YEAR, "acs5/subject", s1701_patterns)

# Unemployment (S2301) - rate among 20 to 64 years
s2301_patterns <- c(
  unemployment_rate = "^Unemployment rate!!Population 20 to 64 years$"
)
s2301_ids <- pick_vars(YEAR, "acs5/subject", s2301_patterns)

# Health insurance (S2701)
s2701_patterns <- c(
  uninsured                 = "^Percent Uninsured!!Civilian noninstitutionalized population$",
  uninsured_under_6         = "^Percent Uninsured!!Under 6 years$",
  uninsured_under_19        = "^Percent Uninsured!!Under 19 years$",
  uninsured_65_and_older    = "^Percent Uninsured!!65 years and over$"
)
s2701_ids <- pick_vars(YEAR, "acs5/subject", s2701_patterns)

# Computers & internet (S2801)
s2801_patterns <- c(
  household_has_computer   = "^With a computer:!!Percent of households with a computer$",
  household_has_smartphone = "^With a smartphone:!!Percent of households$",
  household_has_broadband  = "^With an Internet subscription!!Percent of households with a broadband Internet subscription$"
)
s2801_ids <- pick_vars(YEAR, "acs5/subject", s2801_patterns)

# Languages (S1601) – household speaks X
s1601_patterns <- c(
  households_speak_spanish                 = "^Percent!!LANGUAGE SPOKEN AT HOME.*Households speaking Spanish$",
  households_speak_other_indo_euro_lang    = "^Percent!!LANGUAGE SPOKEN AT HOME.*Households speaking other Indo-European languages$",
  households_speak_asian_or_pac_isl        = "^Percent!!LANGUAGE SPOKEN AT HOME.*Households speaking Asian and Pacific Island languages$",
  households_speak_other                   = "^Percent!!LANGUAGE SPOKEN AT HOME.*Households speaking other languages$",
  households_speak_limited_english         = "^Percent!!Limited English speaking households$"
)
s1601_ids <- pick_vars(YEAR, "acs5/subject", s1601_patterns)

# Commuting (S0801)
s0801_patterns <- c(
  mean_work_travel = "^Mean travel time to work.*\\(minutes\\)$"
)
s0801_ids <- pick_vars(YEAR, "acs5/subject", s0801_patterns)

# ------------------------------------------------------------------------------
# 2) Download data per table and assemble
# ------------------------------------------------------------------------------

# A convenience to fetch a named set and return wide E/M columns
get_table <- function(vars_named, dataset) {
  get_acs(
    geography = "county",
    variables = unname(vars_named),
    year = YEAR,
    survey = SURVEY,
    output = "wide",
    .data = dataset # ignored; kept for clarity
  ) |>
    rename(GEOID = GEOID, NAME = NAME) |>
    mutate(fips = GEOID)
}

# Pull each block
pop_df   <- get_acs(geography = "county", variables = pop_vars, year = YEAR, survey = SURVEY, output = "wide") |>
  transmute(fips = GEOID, NAME,
            pop = B01003_001E, pop_moe = B01003_001M)

dp05_df  <- get_table(dp05_ids, "acs5/profile")
s0101_df <- get_table(s0101_ids, "acs5/subject")
s1101_df <- get_table(s1101_ids, "acs5/subject")
dp04_df  <- get_table(dp04_ids, "acs5/profile")
s1501_df <- get_table(s1501_ids, "acs5/subject")
s1901_df <- get_table(s1901_ids, "acs5/subject")
s2002_df <- get_table(s2002_ids, "acs5/subject")
s1701_df <- get_table(s1701_ids, "acs5/subject")
s2301_df <- get_table(s2301_ids, "acs5/subject")
s2701_df <- get_table(s2701_ids, "acs5/subject")
s2801_df <- get_table(s2801_ids, "acs5/subject")
s1601_df <- get_table(s1601_ids, "acs5/subject")
s0801_df <- get_table(s0801_ids, "acs5/subject")

# ------------------------------------------------------------------------------
# 3) Reduce-join everything by GEOID, then rename columns to mirror county_2019
# ------------------------------------------------------------------------------

all_df <- pop_df |>
  reduce(
    .x = list(dp05_df, s0101_df, s1101_df, dp04_df, s1501_df, s1901_df, s2002_df,
              s1701_df, s2301_df, s2701_df, s2801_df, s1601_df, s0801_df),
    .f = ~ full_join(.x, .y, by = c("fips"))
  ) |>
  # Bring back NAME for state/county parsing
  left_join(select(pop_df, fips, NAME), by = "fips") |>
  # Split "County, State"
  separate_wider_delim(NAME, delim = ", ", names = c("name", "state"), too_few = "align_start") |>
  # Select/rename columns. For each picked variable, `get_acs(..., output="wide")` gives
  #   <VAR> E = estimate, M = MOE. We align to county_2019 names with _moe where present.
  transmute(
    state, name, fips,
    pop, pop_moe,

    # Race / ethnicity (percents & MOEs)
    white                 = !!sym(paste0(dp05_ids["white"], "E")),
    white_moe             = !!sym(paste0(dp05_ids["white"], "M")),
    black                 = !!sym(paste0(dp05_ids["black"], "E")),
    black_moe             = !!sym(paste0(dp05_ids["black"], "M")),
    native                = !!sym(paste0(dp05_ids["native"], "E")),
    native_moe            = !!sym(paste0(dp05_ids["native"], "M")),
    asian                 = !!sym(paste0(dp05_ids["asian"], "E")),
    asian_moe             = !!sym(paste0(dp05_ids["asian"], "M")),
    pac_isl               = !!sym(paste0(dp05_ids["pac_isl"], "E")),
    pac_isl_moe           = !!sym(paste0(dp05_ids["pac_isl"], "M")),
    other_single_race     = !!sym(paste0(dp05_ids["other_single_race"], "E")),
    other_single_race_moe = !!sym(paste0(dp05_ids["other_single_race"], "M")),
    two_plus_races        = !!sym(paste0(dp05_ids["two_plus_races"], "E")),
    two_plus_races_moe    = !!sym(paste0(dp05_ids["two_plus_races"], "M")),
    hispanic              = !!sym(paste0(dp05_ids["hispanic"], "E")),
    hispanic_moe          = !!sym(paste0(dp05_ids["hispanic"], "M")),
    white_not_hispanic    = !!sym(paste0(dp05_ids["white_not_hispanic"], "E")),
    white_not_hispanic_moe= !!sym(paste0(dp05_ids["white_not_hispanic"], "M")),

    # Age
    median_age            = !!sym(paste0(dp05_ids["median_age"], "E")),
    median_age_moe        = !!sym(paste0(dp05_ids["median_age"], "M")),
    age_under_5           = !!sym(paste0(s0101_ids["age_under_5"], "E")),
    age_under_5_moe       = !!sym(paste0(s0101_ids["age_under_5"], "M")),
    age_over_85           = !!sym(paste0(s0101_ids["age_over_85"], "E")),
    age_over_85_moe       = !!sym(paste0(s0101_ids["age_over_85"], "M")),
    age_over_18           = !!sym(paste0(s0101_ids["age_over_18"], "E")),
    age_over_18_moe       = !!sym(paste0(s0101_ids["age_over_18"], "M")),
    age_over_65           = !!sym(paste0(s0101_ids["age_over_65"], "E")),
    age_over_65_moe       = !!sym(paste0(s0101_ids["age_over_65"], "M")),

    # Household size & counts
    persons_per_household      = !!sym(paste0(s1101_ids["persons_per_household"], "E")),
    persons_per_household_moe  = !!sym(paste0(s1101_ids["persons_per_household"], "M")),
    avg_family_size            = !!sym(paste0(s1101_ids["avg_family_size"], "E")),
    avg_family_size_moe        = !!sym(paste0(s1101_ids["avg_family_size"], "M")),
    households                 = !!sym(paste0(s1101_ids["households"], "E")),
    households_moe             = !!sym(paste0(s1101_ids["households"], "M")),

    # Housing structure types
    housing_one_unit_structures     = !!sym(paste0(dp04_ids["housing_one_unit_structures"], "E")),
    housing_one_unit_structures_moe = !!sym(paste0(dp04_ids["housing_one_unit_structures"], "M")),
    housing_two_unit_structures     = !!sym(paste0(dp04_ids["housing_two_unit_structures"], "E")),
    housing_two_unit_structures_moe = !!sym(paste0(dp04_ids["housing_two_unit_structures"], "M")),
    housing_mobile_homes            = !!sym(paste0(dp04_ids["housing_mobile_homes"], "E")),
    housing_mobile_homes_moe        = !!sym(paste0(dp04_ids["housing_mobile_homes"], "M")),

    # Education
    hs_grad        = !!sym(paste0(s1501_ids["hs_grad"], "E")),
    hs_grad_moe    = !!sym(paste0(s1501_ids["hs_grad"], "M")),
    bachelors      = !!sym(paste0(s1501_ids["bachelors"], "E")),
    bachelors_moe  = !!sym(paste0(s1501_ids["bachelors"], "M")),

    # Income
    mean_household_income   = !!sym(paste0(s1901_ids["mean_household_income"], "E")),
    mean_household_income_moe = !!sym(paste0(s1901_ids["mean_household_income"], "M")),
    per_capita_income       = !!sym(paste0(s1901_ids["per_capita_income"], "E")),
    per_capita_income_moe   = !!sym(paste0(s1901_ids["per_capita_income"], "M")),
    median_household_income = !!sym(paste0(s1901_ids["median_household_income"], "E")),
    median_household_income_moe = !!sym(paste0(s1901_ids["median_household_income"], "M")),
    median_individual_income      = !!sym(paste0(s2002_ids["median_individual_income"], "E")),
    median_individual_income_moe  = !!sym(paste0(s2002_ids["median_individual_income"], "M")),
    median_individual_income_age_25plus     = !!sym(paste0(s2002_ids["median_individual_income_age_25plus"], "E")),
    median_individual_income_age_25plus_moe = !!sym(paste0(s2002_ids["median_individual_income_age_25plus"], "M")),

    # Poverty (percents)
    poverty                 = !!sym(paste0(s1701_ids["poverty"], "E")),
    poverty_moe             = !!sym(paste0(s1701_ids["poverty"], "M")),
    poverty_under_18        = !!sym(paste0(s1701_ids["poverty_under_18"], "E")),
    poverty_under_18_moe    = !!sym(paste0(s1701_ids["poverty_under_18"], "M")),
    poverty_65_and_over     = !!sym(paste0(s1701_ids["poverty_65_and_over"], "E")),
    poverty_65_and_over_moe = !!sym(paste0(s1701_ids["poverty_65_and_over"], "M")),

    # Unemployment (percent for ages 20–64)
    unemployment_rate      = !!sym(paste0(s2301_ids["unemployment_rate"], "E")),
    unemployment_rate_moe  = !!sym(paste0(s2301_ids["unemployment_rate"], "M")),

    # Insurance (percents)
    uninsured                 = !!sym(paste0(s2701_ids["uninsured"], "E")),
    uninsured_moe             = !!sym(paste0(s2701_ids["uninsured"], "M")),
    uninsured_under_6         = !!sym(paste0(s2701_ids["uninsured_under_6"], "E")),
    uninsured_under_6_moe     = !!sym(paste0(s2701_ids["uninsured_under_6"], "M")),
    uninsured_under_19        = !!sym(paste0(s2701_ids["uninsured_under_19"], "E")),
    uninsured_under_19_moe    = !!sym(paste0(s2701_ids["uninsured_under_19"], "M")),
    uninsured_65_and_older    = !!sym(paste0(s2701_ids["uninsured_65_and_older"], "E")),
    uninsured_65_and_older_moe= !!sym(paste0(s2701_ids["uninsured_65_and_older"], "M")),

    # Devices & broadband (percents)
    household_has_computer     = !!sym(paste0(s2801_ids["household_has_computer"], "E")),
    household_has_computer_moe = !!sym(paste0(s2801_ids["household_has_computer"], "M")),
    household_has_smartphone     = !!sym(paste0(s2801_ids["household_has_smartphone"], "E")),
    household_has_smartphone_moe = !!sym(paste0(s2801_ids["household_has_smartphone"], "M")),
    household_has_broadband     = !!sym(paste0(s2801_ids["household_has_broadband"], "E")),
    household_has_broadband_moe = !!sym(paste0(s2801_ids["household_has_broadband"], "M")),

    # Language (percents)
    households_speak_spanish                 = !!sym(paste0(s1601_ids["households_speak_spanish"], "E")),
    households_speak_spanish_moe             = !!sym(paste0(s1601_ids["households_speak_spanish"], "M")),
    households_speak_other_indo_euro_lang    = !!sym(paste0(s1601_ids["households_speak_other_indo_euro_lang"], "E")),
    households_speak_other_indo_euro_lang_moe= !!sym(paste0(s1601_ids["households_speak_other_indo_euro_lang"], "M")),
    households_speak_asian_or_pac_isl        = !!sym(paste0(s1601_ids["households_speak_asian_or_pac_isl"], "E")),
    households_speak_asian_or_pac_isl_moe    = !!sym(paste0(s1601_ids["households_speak_asian_or_pac_isl"], "M")),
    households_speak_other                   = !!sym(paste0(s1601_ids["households_speak_other"], "E")),
    households_speak_other_moe               = !!sym(paste0(s1601_ids["households_speak_other"], "M")),
    households_speak_limited_english         = !!sym(paste0(s1601_ids["households_speak_limited_english"], "E")),
    households_speak_limited_english_moe     = !!sym(paste0(s1601_ids["households_speak_limited_english"], "M")),

    # Commuting (minutes)
    mean_work_travel     = !!sym(paste0(s0801_ids["mean_work_travel"], "E")),
    mean_work_travel_moe = !!sym(paste0(s0801_ids["mean_work_travel"], "M"))
  )
# ------------------------------------------------------------------------------
# 3b) Reproducibility checks
# ------------------------------------------------------------------------------

# Expected number of counties (including independent cities)
expected_n <- 3142

# Check number of rows
n_rows <- nrow(all_df)
if (n_rows != expected_n) {
  warning(sprintf("Row count mismatch: got %d rows, expected %d", n_rows, expected_n))
} else {
  message("✓ Correct number of counties: ", n_rows)
}

# Check for unique FIPS
if (anyDuplicated(all_df$fips) > 0) {
  warning("Duplicate FIPS codes found!")
} else {
  message("✓ All FIPS codes are unique")
}

# Check for key columns present and not all missing
key_cols <- c("state", "name", "fips", "pop", "white", "black",
              "hs_grad", "bachelors", "poverty", "median_household_income",
              "unemployment_rate", "household_has_broadband")

missing_all <- key_cols[map_lgl(all_df[key_cols], ~ all(is.na(.x)))]
if (length(missing_all) > 0) {
  warning("Some key columns are entirely NA: ", paste(missing_all, collapse = ", "))
} else {
  message("✓ All key columns contain non-missing data")
}
# ------------------------------------------------------------------------------
# 4) Write CSV
# ------------------------------------------------------------------------------
write_csv(all_df, "county_2024.csv")

# The file "county_2024.csv" now mirrors the columns in usdata::county_2019,
# but populated with ACS 2020–2024 5-year estimates (endyear = 2024).


