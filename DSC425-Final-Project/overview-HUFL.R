# Load required libraries
library(readr)     # for fast CSV reading
library(dplyr)     # for data manipulation
library(ggplot2)   # optional, for plotting
library(lubridate) # for date/time parsing
library(forecast)
library(tidyr)
library(TSA)

# Load the dataset
df <- read_csv("ETTh1.csv")

# 4) ACF/PACF on full series (use HUFL here)

# Original series
hufl_ts <- ts(df$HUFL, frequency = 24)

# 1st difference (regular differencing)
hufl_diff1 <- diff(hufl_ts, differences = 1)

# Seasonal difference (daily, period=24)
hufl_diff_season <- diff(hufl_ts, lag = 24)

# Combined difference (first + seasonal)
hufl_diff_both <- diff(diff(hufl_ts, differences = 1), lag = 24)

# --- PLOTS ---

# Raw
ggAcf(hufl_ts, lag.max = 24*7)  + ggtitle("ACF: HUFL (weekly, raw)")
ggPacf(hufl_ts, lag.max = 24*7) + ggtitle("PACF: HUFL (weekly, raw)")

# First difference
ggAcf(hufl_diff1, lag.max = 24*7)  + ggtitle("ACF: ΔHUFL (weekly)")
ggPacf(hufl_diff1, lag.max = 24*7) + ggtitle("PACF: ΔHUFL (weekly)")

# Seasonal difference
ggAcf(hufl_diff_season, lag.max = 24*7)  + ggtitle("ACF: HUFL seasonal diff (lag=24)")
ggPacf(hufl_diff_season, lag.max = 24*7) + ggtitle("PACF: HUFL seasonal diff (lag=24)")

# Both differences
ggAcf(hufl_diff_both, lag.max = 24*7)  + ggtitle("ACF: HUFL both diffs (d=1, D=1, period=24)")
ggPacf(hufl_diff_both, lag.max = 24*7) + ggtitle("PACF: HUFL both diffs (d=1, D=1, period=24)")

eacf(hufl_ts)
eacf(hufl_diff1)
eacf(hufl_diff_season)
eacf(hufl_diff_both)

# 5) Hour-of-day & day-of-week profiles (full data)
prof <- df %>% mutate(hod = hour(date),
                      dow = wday(date, label = TRUE, week_start = 1))
# Hour-of-day mean
ggplot(prof, aes(hod, HUFL)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "HUFL — Hour-of-Day Mean", x = "Hour", y = "Mean HUFL")

# Day-of-week mean
ggplot(prof, aes(dow, HUFL)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "HUFL — Day-of-Week Mean", x = "Day", y = "Mean HUFL")

# More accurate

hod_mean <- df %>% mutate(hod = hour(date)) %>%
  group_by(hod) %>% summarise(mean_HUFL = mean(HUFL, na.rm = TRUE), .groups="drop")

dow_mean <- df %>% mutate(dow = wday(date, label = TRUE, week_start = 1)) %>%
  group_by(dow) %>% summarise(mean_HUFL = mean(HUFL, na.rm = TRUE), .groups="drop")

# Bar plots
ggplot(hod_mean, aes(factor(hod), mean_HUFL)) + geom_col()
ggplot(dow_mean, aes(dow, mean_HUFL)) + geom_col()
