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

# Inspect the first few rows
head(df)

# Check structure
str(df)

# 1) Slices
yr17   <- df %>% filter(date >= as.POSIXct("2017-01-01"), date < as.POSIXct("2018-01-01"))
zoom28 <- df %>% filter(date >= as.POSIXct("2017-06-01"), date < as.POSIXct("2017-06-29"))

# 2) Year view (2017)
yr17_long <- yr17 %>% select(date, OT, HUFL, HULL) %>%
  pivot_longer(-date, names_to="var", values_to="value")
library(ggplot2)

# Custom labels
labels_named <- c(
  "HUFL" = "HUFL (MW)",
  "HULL" = "HULL (MW)",
  "OT"   = "OT (°C)"
)

ggplot(yr17_long, aes(date, value, colour = var)) +
  geom_line(alpha = 0.7) +
  geom_point(aes(fill = var), shape = 22, size = 3, alpha = 0, show.legend = TRUE) +
  scale_fill_manual(values = c("HUFL" = "blue", "HULL" = "red", "OT" = "green"),
                    labels = labels_named) +
  scale_colour_manual(values = c("HUFL" = "blue", "HULL" = "red", "OT" = "green"),
                      labels = labels_named) +
  guides(
    colour = "none",  # hide the line legend
    fill = guide_legend(title = "Variable",
                        override.aes = list(shape = 22, size = 6, alpha = 1))
  ) +
  theme(
    legend.key.size = unit(8, "mm"),
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 12),
    legend.key = element_rect(fill = "white")
  ) +
  labs(title = "ETTh1 — OT vs HUFL vs HULL (2017)", x = "date", y = "value")

# 3) Zoom view (2–4 weeks)
zoom_long <- zoom28 %>% select(date, OT, HUFL, HULL) %>%
  pivot_longer(-date, names_to="var", values_to="value")
ggplot(zoom_long, aes(date, value, colour = var)) +
  geom_line(alpha = 0.7) +
  geom_point(aes(fill = var), shape = 22, size = 3, alpha = 0, show.legend = TRUE) +
  scale_fill_manual(values = c("HUFL" = "blue", "HULL" = "red", "OT" = "green"),
                    labels = labels_named) +
  scale_colour_manual(values = c("HUFL" = "blue", "HULL" = "red", "OT" = "green"),
                      labels = labels_named) +
  guides(
    colour = "none",
    fill = guide_legend(title = "var",
                        override.aes = list(shape = 22, size = 6, alpha = 1))
  ) +
  theme(
    legend.key.size = unit(8, "mm"),
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 12),
    legend.key = element_rect(fill = "white")
  ) +
  labs(title = "ETTh1 — 4-week zoom (2017-06)", x = "date", y = "value")

# 4) ACF/PACF on full series (use OT here)

# Original series
ot_ts <- ts(df$OT, frequency = 24)

# 1st difference (regular differencing)
ot_diff1 <- diff(ot_ts, differences = 1)

# Seasonal difference (daily, period=24)
ot_diff_season <- diff(ot_ts, lag = 24)

# Combined difference (first + seasonal)
ot_diff_both <- diff(diff(ot_ts, differences = 1), lag = 24)

# --- PLOTS ---

# Raw
ggAcf(ot_ts, lag.max = 24*7)  + ggtitle("ACF: OT (weekly, raw)")
ggPacf(ot_ts, lag.max = 24*7) + ggtitle("PACF: OT (weekly, raw)")

# First difference
ggAcf(ot_diff1, lag.max = 24*7)  + ggtitle("ACF: ΔOT (weekly)")
ggPacf(ot_diff1, lag.max = 24*7) + ggtitle("PACF: ΔOT (weekly)")

# Seasonal difference
ggAcf(ot_diff_season, lag.max = 24*7)  + ggtitle("ACF: OT seasonal diff (lag=24)")
ggPacf(ot_diff_season, lag.max = 24*7) + ggtitle("PACF: OT seasonal diff (lag=24)")

# Both differences
ggAcf(ot_diff_both, lag.max = 24*7)  + ggtitle("ACF: OT both diffs (d=1, D=1, period=24)")
ggPacf(ot_diff_both, lag.max = 24*7) + ggtitle("PACF: OT both diffs (d=1, D=1, period=24)")

eacf(ot_ts)
eacf(ot_diff1)
eacf(ot_diff_season)
eacf(ot_diff_both)

# 5) Hour-of-day & day-of-week profiles (full data)
prof <- df %>% mutate(hod = hour(date),
                      dow = wday(date, label = TRUE, week_start = 1))
# Hour-of-day mean
ggplot(prof, aes(hod, OT)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "OT — Hour-of-Day Mean", x = "Hour", y = "Mean OT")

# Day-of-week mean
ggplot(prof, aes(dow, OT)) +
  stat_summary(fun = mean, geom = "line", group = 1) +
  stat_summary(fun = mean, geom = "point") +
  labs(title = "OT — Day-of-Week Mean", x = "Day", y = "Mean OT")

# More accurate

hod_mean <- df %>% mutate(hod = hour(date)) %>%
  group_by(hod) %>% summarise(mean_OT = mean(OT, na.rm = TRUE), .groups="drop")

dow_mean <- df %>% mutate(dow = wday(date, label = TRUE, week_start = 1)) %>%
  group_by(dow) %>% summarise(mean_OT = mean(OT, na.rm = TRUE), .groups="drop")

# Bar plots
ggplot(hod_mean, aes(factor(hod), mean_OT)) + geom_col()
ggplot(dow_mean, aes(dow, mean_OT)) + geom_col()
