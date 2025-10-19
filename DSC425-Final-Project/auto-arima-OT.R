# =========================
# DSC 425
# ARIMA on ETTh1 (Hourly OT), 2017
# =========================

# --- Packages ---
library(readr)
library(dplyr)
library(ggplot2)
library(forecast)

# --- 0) Load & filter data (2017 only) ---
df <- read_csv("ETTh1.csv")
df <- df %>% filter(date >= as.POSIXct("2017-01-01"),
                    date <  as.POSIXct("2018-01-01"))

# --- 1) Build series (hourly, daily seasonality m=24) ---
ot_ts <- ts(df$OT, frequency = 24)

# --- 2) Fit seasonal ARIMA on full 2017 (reference model) ---
fit_ts <- auto.arima(
  ot_ts,
  seasonal        = TRUE,
  stepwise        = TRUE,
  approximation   = TRUE,
  seasonal.test   = "ocsb",
  max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
)

cat("\n=== Full-series model (reference) ===\n")
print(summary(fit_ts))
cat("\nCriteria: AIC =", fit_ts$aic, "  AICc =", fit_ts$aicc, "  BIC =", fit_ts$bic, "\n")

# Residual diagnostics (ACF/PACF + Ljung–Box at daily & weekly)
cat("\nLjung–Box (daily lag 24):\n")
print(Box.test(residuals(fit_ts), lag = 24,   type = "Ljung"))
cat("\nLjung–Box (weekly lag 168):\n")
print(Box.test(residuals(fit_ts), lag = 24*7, type = "Ljung"))

# Plot residual checks (ACF/PACF + normality) in the Viewer
checkresiduals(fit_ts)

# --- 3) Hold-out evaluation (last 7 days) ---
h <- 24 * 7
n <- length(ot_ts)

y_train <- window(ot_ts, end   = time(ot_ts)[n - h])
y_test  <- window(ot_ts, start = time(ot_ts)[n - h + 1])

fit_train <- auto.arima(
  y_train,
  seasonal        = TRUE,
  stepwise        = TRUE,
  approximation   = TRUE,
  seasonal.test   = "ocsb",
  max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
)

cat("\n=== Train-only model (before holdout forecast) ===\n")
print(summary(fit_train))
cat("\nTrain Criteria: AIC =", fit_train$aic, "  AICc =", fit_train$aicc, "  BIC =", fit_train$bic, "\n")

# Train residual diagnostics (useful in HW)
cat("\nTrain Ljung–Box (lag 24):\n")
print(Box.test(residuals(fit_train), lag = 24,   type = "Ljung"))
cat("\nTrain Ljung–Box (lag 168):\n")
print(Box.test(residuals(fit_train), lag = 24*7, type = "Ljung"))
checkresiduals(fit_train)

# Forecast next h hours and evaluate
fc <- forecast(fit_train, h = h)
acc_holdout <- accuracy(fc, y_test)
cat("\n=== Hold-out accuracy (last 7 days) ===\n")
print(acc_holdout)

# Plot: actual vs forecast on holdout (with 80/95% intervals)
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
  geom_ribbon(aes(ymin = lo80, ymax = hi80), alpha = 0.20) +
  geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.10) +
  labs(title = "Holdout: Forecast vs Actual (last 7 days)",
       x = "Hour (index in holdout)", y = "OT")

# --- 4) Expanding-window backtesting ---
# Evaluate 1-, 24-, and 168-step-ahead with daily rolling origins.
H <- c(1, 24, 168)     # horizons
initial_days <- 90      # initial training window (~90 days)
origin_step  <- 24      # advance origin by 24 hours (once per day)

initial <- 24 * initial_days

# Helper: fit -> forecast -> return h-step point forecast
fit_forecast_h <- function(y, h) {
  fit <- auto.arima(
    y,
    seasonal        = TRUE,
    stepwise        = TRUE,
    approximation   = TRUE,
    seasonal.test   = "ocsb",
    max.p = 3, max.q = 3, max.P = 1, max.Q = 1, max.order = 6
  )
  as.numeric(forecast(fit, h = h)$mean[h])
}

origins <- seq(from = initial, to = n - max(H), by = origin_step)

err_list <- lapply(H, function(.) numeric(length(origins)))
names(err_list) <- paste0("h", H)

for (i in seq_along(origins)) {
  o <- origins[i]        # last index in current training window
  y_tr <- ot_ts[1:o]
  for (k in seq_along(H)) {
    h_k <- H[k]
    y_hat <- fit_forecast_h(y_tr, h_k)
    y_act <- ot_ts[o + h_k]
    err_list[[k]][i] <- y_act - y_hat   # error = actual - forecast
  }
}

# Metrics by horizon
rmse <- sapply(err_list, function(e) sqrt(mean(e^2,    na.rm = TRUE)))
mae  <- sapply(err_list, function(e) mean(abs(e),      na.rm = TRUE))
# Safe MAPE (avoid div-by-zero): add small epsilon in denom
eps  <- 1e-8
mape <- sapply(seq_along(H), function(k) {
  idx <- seq_along(origins)
  acts <- ot_ts[origins + H[k]]
  mean(abs(err_list[[k]] / pmax(abs(acts), eps)), na.rm = TRUE) * 100
})

bt_summary <- data.frame(
  Horizon = paste0(H, "-step"),
  RMSE    = as.numeric(rmse),
  MAE     = as.numeric(mae),
  MAPE    = as.numeric(mape),
  row.names = NULL
)
cat("\n=== Expanding-window backtest summary ===\n")
print(bt_summary)

# Plot rolling 24-step (1-day ahead) errors across origins
err24_df <- data.frame(
  origin_idx = origins,
  error      = err_list[[which(H == 24)]]
)
ggplot(err24_df, aes(origin_idx, error)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = 3) +
  labs(title = "Expanding-window backtest: 24-step-ahead errors",
       x = "Time index (hourly)", y = "Error (actual - forecast)")
