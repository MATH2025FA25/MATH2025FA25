
# county_2023-builder.R
# Recreate 'county_2019' style dataset for ACS 2019–2023 (aka "2023") at county level
# Requires: tidycensus (>=1.6), dplyr, tidyr, stringr, purrr, readr

suppressPackageStartupMessages({
  library(tidycensus)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(readr)
})

# If needed, set your key once per machine (then restart R):
# census_api_key("6762aefaa427df4ee803e66ab02308becf2cc4a8", install = TRUE)

options(tigris_use_cache = TRUE)

ACS_YEAR <- 2023
DATASET  <- "acs5/profile"  # Data Profiles (DP02/DP03/DP04/DP05)

# -------------------------------------------------------------------
# 1) Discover variables by label patterns (resilient across years)
# -------------------------------------------------------------------
vars <- load_variables(ACS_YEAR, DATASET, cache = TRUE)  # columns: name, label, concept
# See: walker-data tidycensus docs for load_variables & get_acs usage. :contentReference[oaicite:0]{index=0}

pick_var <- function(pattern, df = vars, require_percent = FALSE) {
  # Accept a vector of regex patterns and return the first successful match.
  patterns <- unique(pattern)
  for (pat in patterns) {
    cand <- df %>%
      filter(str_detect(label, regex(pat, ignore_case = TRUE))) %>%
      mutate(
        score = case_when(
          require_percent & str_ends(name, "P") ~ 4L,
          require_percent & str_detect(label, fixed("Percent!!")) ~ 3L,
          !require_percent & !str_ends(name, "P") ~ 4L,
          !require_percent & str_ends(name, "P") ~ 1L,
          TRUE ~ 1L
        ),
        is_pr = if_else(str_detect(name, fixed("_PR_")), 0L, 1L),
        name_len = nchar(name)
      ) %>%
      arrange(desc(score), desc(is_pr), name_len, name)

    if (nrow(cand) == 0) {
      next
    }

    return(cand$name[1])
  }
  stop(paste0("No ACS variable matched any pattern: ", paste(patterns, collapse = ", ")))
}

# Helper to get both estimate and MOE codes when available (E/M or PE/PM)
pair_codes <- function(label_pattern, require_percent = FALSE) {
  anchor_pattern <- function(p) {
    left <- if (str_starts(p, fixed("^"))) "" else "^"
    right <- if (str_ends(p, fixed("$"))) "" else "$"
    paste0(left, p, right)
  }

  patterns <- map_chr(label_pattern, anchor_pattern)
  base_code <- pick_var(patterns, require_percent = require_percent)

  est_col <- case_when(
    str_ends(base_code, "E")  ~ base_code,
    str_ends(base_code, "M")  ~ str_replace(base_code, "M$", "E"),
    str_ends(base_code, "P")  ~ paste0(base_code, "E"),
    TRUE                      ~ paste0(base_code, "E")
  )

  moe_col <- case_when(
    str_ends(base_code, "E")  ~ str_replace(base_code, "E$", "M"),
    str_ends(base_code, "M")  ~ base_code,
    str_ends(base_code, "P")  ~ paste0(base_code, "M"),
    TRUE                      ~ paste0(base_code, "M")
  )

  list(code = base_code, est = est_col, moe = moe_col)
}

# -------------------------------------------------------------------
# 2) Define label patterns mirroring usdata::county_2019 fields
#     (DP02 = Social, DP03 = Economic, DP04 = Housing, DP05 = Demographic)
#     We match the *labels* shown by load_variables (which include "Percent!!..." trails)
# -------------------------------------------------------------------

# --- Core identifiers & totals ---
pop_codes  <- pair_codes(c("Estimate!!SEX AND AGE!!Total population",
                           "Estimate!!Total!!Total population"),
                         require_percent = FALSE)
# In DP05 the total population is usually DP05_0001E ("Estimate!!Total population"). :contentReference[oaicite:1]{index=1}

# --- Race / ethnicity percentages (DP05, Percent fields) ---
race_patterns <- list(
  white              = "^Percent!!RACE!!Total population!!One race!!White$",
  black              = "^Percent!!RACE!!Total population!!One race!!Black or African American$",
  native             = "^Percent!!RACE!!Total population!!One race!!American Indian and Alaska Native$",
  asian              = "^Percent!!RACE!!Total population!!One race!!Asian$",
  pac_isl            = "^Percent!!RACE!!Total population!!One race!!Native Hawaiian and Other Pacific Islander$",
  other_single_race  = "^Percent!!RACE!!Total population!!One race!!Some Other Race$",
  two_plus_races     = "^Percent!!RACE!!Total population!!Two or More Races$",
  hispanic           = "^Percent!!HISPANIC OR LATINO AND RACE!!Total population!!Hispanic or Latino( \\Q(of any race)\\E)?$",
  white_not_hispanic = "^Percent!!HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!White alone$"
)

race_codes <- imap(race_patterns, ~ pair_codes(.x, require_percent = TRUE))

# --- Age distribution / median age (DP05) ---
median_age_codes    <- pair_codes("^Estimate!!.*Median age \\(years\\)$", FALSE)
age_under_5_codes   <- pair_codes("^Percent!!.*!!Under 5 years$", TRUE)
age_over_85_codes   <- pair_codes("^Percent!!.*!!85 years and over$", TRUE)
age_over_18_codes   <- pair_codes("^Percent!!.*!!18 years and over$", TRUE)
age_over_65_codes   <- pair_codes("^Percent!!.*!!65 years and over$", TRUE)

# --- Household size / family size / travel time (DP02/DP03/DP04/DP05) ---
mean_work_travel_codes     <- pair_codes("^Estimate!!COMMUTING TO WORK!!.*Mean travel time to work \\(minutes\\)$", FALSE)
persons_per_household_codes<- pair_codes("^Estimate!!HOUSEHOLDS BY TYPE!!Total households!!Average household size$", FALSE)
avg_family_size_codes      <- pair_codes("^Estimate!!HOUSEHOLDS BY TYPE!!Total households!!Average family size$", FALSE)

# --- Housing unit structure types (DP04, Percent) ---
housing_one_unit_codes     <- pair_codes("^Percent!!UNITS IN STRUCTURE!!Total housing units!!1-unit, detached$", TRUE)
housing_two_plus_codes     <- pair_codes("^Percent!!UNITS IN STRUCTURE!!Total housing units!!2 or more units$", TRUE)
housing_mobile_codes       <- pair_codes("^Percent!!UNITS IN STRUCTURE!!Total housing units!!Mobile home, boat, RV, van, etc\\.$", TRUE)

# --- Income (DP03) ---
median_individual_income_codes   <- pair_codes("^Estimate!!INCOME AND BENEFITS .*!!PERSONAL INCOME .*!!Median earnings \\(dollars\\)$", FALSE)
median_individual_income_25p_codes <- pair_codes("^Estimate!!INCOME AND BENEFITS .*!!PERSONAL INCOME .*!!Population 25 years and over!!Median earnings \\(dollars\\)$", FALSE)
mean_household_income_codes      <- pair_codes("^Estimate!!INCOME AND BENEFITS .*!!Households!!Mean household income \\(dollars\\)$", FALSE)
per_capita_income_codes          <- pair_codes("^Estimate!!INCOME AND BENEFITS .*!!Per capita income in the past 12 months \\(in inflation-adjusted dollars\\)$", FALSE)
median_household_income_codes    <- pair_codes("^Estimate!!INCOME AND BENEFITS .*!!Households!!Median household income \\(dollars\\)$", FALSE)

# --- Education (DP02, Percent, age 25+) ---
hs_grad_codes          <- pair_codes("^Percent!!EDUCATIONAL ATTAINMENT!!Population 25 years and over!!High school graduate \\(includes equivalency\\)$", TRUE)
bachelors_codes        <- pair_codes("^Percent!!EDUCATIONAL ATTAINMENT!!Population 25 years and over!!Bachelor's degree or higher$", TRUE)

# --- Language at home (DP02, Percent of households) ---
spanish_codes          <- pair_codes("^Percent!!LANGUAGE SPOKEN AT HOME .*!!Households speaking Spanish$", TRUE)
indo_euro_codes        <- pair_codes("^Percent!!LANGUAGE SPOKEN AT HOME .*!!Households speaking other Indo-European languages$", TRUE)
asian_pac_codes        <- pair_codes("^Percent!!LANGUAGE SPOKEN AT HOME .*!!Households speaking Asian and Pacific Island languages$", TRUE)
other_lang_codes       <- pair_codes("^Percent!!LANGUAGE SPOKEN AT HOME .*!!Households speaking other languages$", TRUE)
limited_english_codes  <- pair_codes("^Percent!!LANGUAGE SPOKEN AT HOME .*!!Limited English-speaking households$", TRUE)

# --- Poverty (DP03, Percent) ---
poverty_all_codes      <- pair_codes("^Percent!!POVERTY STATUS IN THE PAST 12 MONTHS .*!!All people!!Below poverty level$", TRUE)
poverty_u18_codes      <- pair_codes("^Percent!!POVERTY STATUS IN THE PAST 12 MONTHS .*!!Under 18 years!!Below poverty level$", TRUE)
poverty_65p_codes      <- pair_codes("^Percent!!POVERTY STATUS IN THE PAST 12 MONTHS .*!!65 years and over!!Below poverty level$", TRUE)

# --- Veterans (DP02, Percent among civilian pop 18+) ---
veterans_codes         <- pair_codes("^Percent!!VETERAN STATUS!!Civilian population 18 years and over!!Veterans$", TRUE)

# --- Unemployment (DP03, Percent, ages 20-64 where available; fallback overall 16+) ---
# Try the 20 to 64 years unemployment rate label; if unavailable, use "In labor force!!Unemployment rate"
unemp_try1 <- safely(pair_codes)("^Percent!!EMPLOYMENT STATUS .*!!Age 20 to 64 years!!Unemployment rate$", TRUE)
if (is.null(unemp_try1$result)) {
  unemployment_codes <- pair_codes("^Percent!!EMPLOYMENT STATUS .*!!In labor force!!Unemployment rate$", TRUE)
} else {
  unemployment_codes <- unemp_try1$result
}

# --- Health insurance (DP03/DP02, Percent) ---
uninsured_all_codes    <- pair_codes("^Percent!!HEALTH INSURANCE COVERAGE .*!!Civilian noninstitutionalized population!!No health insurance coverage$", TRUE)
uninsured_u6_codes     <- pair_codes("^Percent!!HEALTH INSURANCE COVERAGE .*!!Under 6 years!!No health insurance coverage$", TRUE)
uninsured_u19_codes    <- pair_codes("^Percent!!HEALTH INSURANCE COVERAGE .*!!Under 19 years!!No health insurance coverage$", TRUE)
uninsured_65p_codes    <- pair_codes("^Percent!!HEALTH INSURANCE COVERAGE .*!!65 years and over!!No health insurance coverage$", TRUE)

# --- Technology access (DP02, Percent of households) ---
has_computer_codes     <- pair_codes("^Percent!!COMPUTERS AND INTERNET USE!!Households with a computer!!With a desktop or laptop$", TRUE)
has_smartphone_codes   <- pair_codes("^Percent!!COMPUTERS AND INTERNET USE!!Households with a smartphone$", TRUE)
broadband_codes        <- pair_codes("^Percent!!COMPUTERS AND INTERNET USE!!Broadband of any type subscription$", TRUE)

# --- Households (counts) ---
households_codes       <- pair_codes("^Estimate!!HOUSEHOLDS BY TYPE!!Total households$", FALSE)

# Collect all codes to request
collect_codes <- function(x) unlist(map(x, ~ .x[c("est","moe")] ), use.names = FALSE)
vars_to_get <- c(
  pop_codes,                          # pop, pop_moe
  collect_codes(race_codes),
  median_age_codes,
  age_under_5_codes, age_over_85_codes, age_over_18_codes, age_over_65_codes,
  mean_work_travel_codes, persons_per_household_codes, avg_family_size_codes,
  housing_one_unit_codes, housing_two_plus_codes, housing_mobile_codes,
  median_individual_income_codes, median_individual_income_25p_codes,
  mean_household_income_codes, per_capita_income_codes, median_household_income_codes,
  hs_grad_codes, bachelors_codes,
  households_codes,
  spanish_codes, indo_euro_codes, asian_pac_codes, other_lang_codes, limited_english_codes,
  poverty_all_codes, poverty_u18_codes, poverty_65p_codes,
  veterans_codes,
  unemployment_codes,
  uninsured_all_codes, uninsured_u6_codes, uninsured_u19_codes, uninsured_65p_codes,
  has_computer_codes, has_smartphone_codes, broadband_codes
) %>% unname() %>% discard(is.na) %>% unique()

# -------------------------------------------------------------------
# 3) Fetch the data (wide layout = one row per county)
# -------------------------------------------------------------------
acsw <- get_acs(
  geography   = "county",
  variables   = vars_to_get,
  year        = ACS_YEAR,
  survey      = "acs5",
  output      = "wide",
  cache_table = TRUE
)
# get_acs details & 5-year availability confirmed in tidycensus reference. :contentReference[oaicite:2]{index=2}

# -------------------------------------------------------------------
# 4) Parse GEO names and rename columns to match county_2019 semantics
# -------------------------------------------------------------------
# NAME looks like "Ada County, Idaho"
clean_names <- acsw %>%
  separate_wider_delim(NAME, delim = ", ", names = c("name", "state")) %>%
  transmute(
    state,
    name,
    fips = GEOID,

    # --- Totals & population
    pop              = !!sym(pop_codes$est),
    pop_moe          = !!sym(pop_codes$moe),

    # --- Race / ethnicity (percents)
    white            = !!sym(race_codes$white$est),
    white_moe        = !!sym(race_codes$white$moe),
    black            = !!sym(race_codes$black$est),
    black_moe        = !!sym(race_codes$black$moe),
    native           = !!sym(race_codes$native$est),
    native_moe       = !!sym(race_codes$native$moe),
    asian            = !!sym(race_codes$asian$est),
    asian_moe        = !!sym(race_codes$asian$moe),
    pac_isl          = !!sym(race_codes$pac_isl$est),
    pac_isl_moe      = !!sym(race_codes$pac_isl$moe),
    other_single_race= !!sym(race_codes$other_single_race$est),
    other_single_race_moe= !!sym(race_codes$other_single_race$moe),
    two_plus_races   = !!sym(race_codes$two_plus_races$est),
    two_plus_races_moe= !!sym(race_codes$two_plus_races$moe),
    hispanic         = !!sym(race_codes$hispanic$est),
    hispanic_moe     = !!sym(race_codes$hispanic$moe),
    white_not_hispanic = !!sym(race_codes$white_not_hispanic$est),
    white_not_hispanic_moe = !!sym(race_codes$white_not_hispanic$moe),

    # --- Age & medians
    median_individual_income = !!sym(median_individual_income_codes$est),
    median_individual_income_moe = !!sym(median_individual_income_codes$moe),
    median_individual_income_age_25plus = !!sym(median_individual_income_25p_codes$est),
    median_individual_income_age_25plus_moe = !!sym(median_individual_income_25p_codes$moe),

    median_age        = !!sym(median_age_codes$est),
    median_age_moe    = !!sym(median_age_codes$moe),
    age_under_5       = !!sym(age_under_5_codes$est),
    age_under_5_moe   = !!sym(age_under_5_codes$moe),
    age_over_85       = !!sym(age_over_85_codes$est),
    age_over_85_moe   = !!sym(age_over_85_codes$moe),
    age_over_18       = !!sym(age_over_18_codes$est),
    age_over_18_moe   = !!sym(age_over_18_codes$moe),
    age_over_65       = !!sym(age_over_65_codes$est),
    age_over_65_moe   = !!sym(age_over_65_codes$moe),

    # --- Households & families
    persons_per_household     = !!sym(persons_per_household_codes$est),
    persons_per_household_moe = !!sym(persons_per_household_codes$moe),
    avg_family_size           = !!sym(avg_family_size_codes$est),
    avg_family_size_moe       = !!sym(avg_family_size_codes$moe),
    households                = !!sym(households_codes$est),
    households_moe            = !!sym(households_codes$moe),

    # --- Travel time
    mean_work_travel       = !!sym(mean_work_travel_codes$est),
    mean_work_travel_moe   = !!sym(mean_work_travel_codes$moe),

    # --- Housing structures (percents)
    housing_one_unit_structures     = !!sym(housing_one_unit_codes$est),
    housing_one_unit_structures_moe = !!sym(housing_one_unit_codes$moe),
    housing_two_unit_structures     = !!sym(housing_two_plus_codes$est),
    housing_two_unit_structures_moe = !!sym(housing_two_plus_codes$moe),
    housing_mobile_homes            = !!sym(housing_mobile_codes$est),
    housing_mobile_homes_moe        = !!sym(housing_mobile_codes$moe),

    # --- Education (percents for 25+)
    hs_grad            = !!sym(hs_grad_codes$est),
    hs_grad_moe        = !!sym(hs_grad_codes$moe),
    bachelors          = !!sym(bachelors_codes$est),
    bachelors_moe      = !!sym(bachelors_codes$moe),

    # --- Language at home (percent households)
    households_speak_spanish                 = !!sym(spanish_codes$est),
    households_speak_spanish_moe             = !!sym(spanish_codes$moe),
    households_speak_other_indo_euro_lang    = !!sym(indo_euro_codes$est),
    households_speak_other_indo_euro_lang_moe= !!sym(indo_euro_codes$moe),
    households_speak_asian_or_pac_isl        = !!sym(asian_pac_codes$est),
    households_speak_asian_or_pac_isl_moe    = !!sym(asian_pac_codes$moe),
    households_speak_other                   = !!sym(other_lang_codes$est),
    households_speak_other_moe               = !!sym(other_lang_codes$moe),
    households_speak_limited_english         = !!sym(limited_english_codes$est),
    households_speak_limited_english_moe     = !!sym(limited_english_codes$moe),

    # --- Poverty (percent)
    poverty                 = !!sym(poverty_all_codes$est),
    poverty_moe             = !!sym(poverty_all_codes$moe),
    poverty_under_18        = !!sym(poverty_u18_codes$est),
    poverty_under_18_moe    = !!sym(poverty_u18_codes$moe),
    poverty_65_and_over     = !!sym(poverty_65p_codes$est),
    poverty_65_and_over_moe = !!sym(poverty_65p_codes$moe),

    # --- Income & earnings
    mean_household_income     = !!sym(mean_household_income_codes$est),
    mean_household_income_moe = !!sym(mean_household_income_codes$moe),
    per_capita_income         = !!sym(per_capita_income_codes$est),
    per_capita_income_moe     = !!sym(per_capita_income_codes$moe),
    median_household_income   = !!sym(median_household_income_codes$est),
    median_household_income_moe = !!sym(median_household_income_codes$moe),

    # --- Veterans (percent among civilian pop 18+)
    veterans       = !!sym(veterans_codes$est),
    veterans_moe   = !!sym(veterans_codes$moe),

    # --- Unemployment (percent)
    unemployment_rate     = !!sym(unemployment_codes$est),
    unemployment_rate_moe = !!sym(unemployment_codes$moe),

    # --- Health insurance (percent uninsured)
    uninsured                = !!sym(uninsured_all_codes$est),
    uninsured_moe            = !!sym(uninsured_all_codes$moe),
    uninsured_under_6        = !!sym(uninsured_u6_codes$est),
    uninsured_under_6_moe    = !!sym(uninsured_u6_codes$moe),
    uninsured_under_19       = !!sym(uninsured_u19_codes$est),
    uninsured_under_19_moe   = !!sym(uninsured_u19_codes$moe),
    uninsured_65_and_older   = !!sym(uninsured_65p_codes$est),
    uninsured_65_and_older_moe = !!sym(uninsured_65p_codes$moe),

    # --- Tech access (percent households)
    household_has_computer     = !!sym(has_computer_codes$est),
    household_has_computer_moe = !!sym(has_computer_codes$moe),
    household_has_smartphone   = !!sym(has_smartphone_codes$est),
    household_has_smartphone_moe = !!sym(has_smartphone_codes$moe),
    household_has_broadband    = !!sym(broadband_codes$est),
    household_has_broadband_moe= !!sym(broadband_codes$moe)
  )

# -------------------------------------------------------------------
# 5) Write to CSV
# -------------------------------------------------------------------
out_path <- "county_2023.csv"
write_csv(clean_names, out_path)
message("Wrote: ", normalizePath(out_path))
