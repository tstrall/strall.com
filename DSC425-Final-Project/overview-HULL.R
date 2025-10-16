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

# 4) ACF/PACF on full series (use HULL here)

# Original series
hull_ts <- ts(df$HULL, frequency = 24)

# 1st difference (regular differencing)
hull_diff1 <- diff(hull_ts, differences = 1)

# Seasonal difference (daily, period=24)
hull_diff_season <- diff(hull_ts, lag = 24)

# Combined difference (first + seasonal)
hull_diff_both <- diff(diff(hull_ts, differences = 1), lag = 24)

# --- PLOTS ---

# Raw
ggAcf(hull_ts, lag.max = 24*7)  + ggtitle("ACF: HULL (weekly, raw)")
ggPacf(hull_ts, lag.max = 24*7) + ggtitle("PACF: HULL (weekly, raw)")

# First difference
ggAcf(hull_diff1, lag.max = 24*7)  + ggtitle("ACF: ΔHULL (weekly)")
ggPacf(hull_diff1, lag.max = 24*7) + ggtitle("PACF: ΔHULL (weekly)")

# Seasonal difference
ggAcf(hull_diff_season, lag.max = 24*7)  + ggtitle("ACF: HULL seasonal diff (lag=24)")
ggPacf(hull_diff_season, lag.max = 24*7) + ggtitle("PACF: HULL seasonal diff (lag=24)")

# Both differences
ggAcf(hull_diff_both, lag.max = 24*7)  + ggtitle("ACF: HULL both diffs (d=1, D=1, period=24)")
ggPacf(hull_diff_both, lag.max = 24*7) + ggtitle("PACF: HULL both diffs (d=1, D=1, period=24)")

eacf(hull_ts)
eacf(hull_diff1)
eacf(hull_diff_season)
eacf(hull_diff_both)

# 5) Hour-of-day & day-of-week profiles (full data)
prof <- df %>% mutate(hod = hour(date),
                      dow = wday(date, label = TRUE, week_start = 1))
# Hour-of-day mean
ggplot(prof, aes(hod, HULL)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "HULL — Hour-of-Day Mean", x = "Hour", y = "Mean HULL")

# Day-of-week mean
ggplot(prof, aes(dow, HULL)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "HULL — Day-of-Week Mean", x = "Day", y = "Mean HULL")

# More accurate

hod_mean <- df %>% mutate(hod = hour(date)) %>%
  group_by(hod) %>% summarise(mean_HULL = mean(HULL, na.rm = TRUE), .groups="drop")

dow_mean <- df %>% mutate(dow = wday(date, label = TRUE, week_start = 1)) %>%
  group_by(dow) %>% summarise(mean_HULL = mean(HULL, na.rm = TRUE), .groups="drop")

# Bar plots
ggplot(hod_mean, aes(factor(hod), mean_HULL)) + geom_col()
ggplot(dow_mean, aes(dow, mean_HULL)) + geom_col()

