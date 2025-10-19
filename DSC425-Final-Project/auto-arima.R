library(readr)
library(dplyr)
library(ggplot2)
library(forecast)

# Load the dataset
df <- read_csv("ETTh1.csv")
df <- df %>% filter(date >= as.POSIXct("2017-01-01"), date < as.POSIXct("2018-01-01"))

# Inspect the first few rows
head(df)

# --- 1) Build series ---
ot_ts  <- ts(df$OT, frequency = 24)

# --- 2) Seasonal ARIMA ---
fit_ts <- auto.arima(
  ot_ts,
  seasonal = TRUE,
  stepwise = TRUE,
  approximation = TRUE,
  seasonal.test = "ocsb",
  max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
)
summary(fit_ts)
checkresiduals(fit_ts)
Box.test(residuals(fit_ts), lag = 24,   type = "Ljung")

# --- 3) Forecasts on a hold-out set ---
# Hold out the last 7 days (168 hours) for evaluation
h <- 24 * 7
n <- length(ot_ts)

y_train <- window(ot_ts, end = time(ot_ts)[n - h])
y_test  <- window(ot_ts, start = time(ot_ts)[n - h + 1])

# Fit on training only (same settings)
fit_train <- auto.arima(
  y_train,
  seasonal = TRUE,
  stepwise = TRUE,
  approximation = TRUE,
  seasonal.test = "ocsb",
  max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
)

# Forecast next h hours and evaluate
fc <- forecast(fit_train, h = h)
acc_holdout <- accuracy(fc, y_test)
acc_holdout

# Quick plot: actual vs forecast on holdout
plot_df <- data.frame(
  idx    = seq_along(y_test),
  actual = as.numeric(y_test),
  pred   = as.numeric(fc$mean),
  lo80   = as.numeric(fc$lower[,"80%"]),
  hi80   = as.numeric(fc$upper[,"80%"]),
  lo95   = as.numeric(fc$lower[,"95%"]),
  hi95   = as.numeric(fc$upper[,"95%"])
)
ggplot(plot_df, aes(idx, actual)) +
  geom_line() +
  geom_line(aes(y = pred), linetype = 2) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80), alpha = 0.2) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.1) +
  labs(title = "Holdout: Forecast vs Actual (last 7 days)", x = "Hour", y = "OT")

# --- 4) Expanding-window backtesting ---

# Backtest settings
H <- c(1, 24, 168)          # horizons: 1-step, 1-day, 1-week
initial_days  <- 90         # initial training window ~ 90 days
origin_step   <- 24         # move origin by 24 hours (once per day)

initial <- 24 * initial_days
n <- length(ot_ts)

# Helper: fit -> forecast for a given training vector and horizon h
fit_forecast_h <- function(y, h) {
  fit <- auto.arima(
    y,
    seasonal = TRUE,
    stepwise = TRUE,
    approximation = TRUE,
    seasonal.test = "ocsb",
    max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
  )
  as.numeric(forecast(fit, h = h)$mean[h])  # return the h-step-ahead point forecast
}

# Rolling origins (expanding window): indices of the last obs in the training set
origins <- seq(from = initial, to = n - max(H), by = origin_step)

# Collect errors per horizon
err <- lapply(H, function(hk) numeric(length(origins)))
names(err) <- paste0("h", H)

for (i in seq_along(origins)) {
  o <- origins[i]                 # last index of training window at this origin
  y_tr <- ot_ts[1:o]              # expanding window up to 'o'
  # compute each horizon's forecast and error
  for (k in seq_along(H)) {
    hk <- H[k]
    y_hat <- fit_forecast_h(y_tr, hk)
    y_act <- ot_ts[o + hk]
    err[[k]][i] <- y_act - y_hat   # error = actual - forecast
  }
}

# Metrics
rmse <- sapply(err, function(e) sqrt(mean(e^2, na.rm = TRUE)))
mae  <- sapply(err, function(e) mean(abs(e), na.rm = TRUE))

bt_summary <- data.frame(
  horizon = paste0(H, "-step"),
  RMSE = as.numeric(rmse),
  MAE  = as.numeric(mae),
  row.names = NULL
)
bt_summary

# Optional: visualize rolling 24-step (1-day ahead) errors over time
library(ggplot2)
err24_df <- data.frame(
  origin_idx = origins,
  error      = err[[which(H == 24)]]
)

ggplot(err24_df, aes(origin_idx, error)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = 3) +
  labs(
    title = "Expanding-window backtest: 24-step-ahead errors",
    x = "Time index (hourly)",
    y = "Error (actual - forecast)"
  )
