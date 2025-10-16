library(forecast)
library(dplyr)
library(ggplot2)

# --- 1) Build series ---
# Plain hourly
ot_ts  <- ts(df$OT, frequency = 24)

# Multiple seasonalities: daily (24) + weekly (24*7)
ot_msts <- msts(df$OT, seasonal.periods = c(24, 24*7))

# --- 2) Auto ARIMA on msts ---
fit_msts <- auto.arima(
  ot_msts,
  seasonal = TRUE,
  stepwise = FALSE,        # thorough search
  approximation = FALSE,   # exact AICc
  seasonal.test = "ocsb"
)
summary(fit_msts)
report(fit_msts)
checkresiduals(fit_msts)
Box.test(residuals(fit_msts), lag = 24,  type = "Ljung")
Box.test(residuals(fit_msts), lag = 24*7, type = "Ljung")

# --- 3) (Optional) Compare to single-seasonal ARIMA (daily only) ---
fit_ts <- auto.arima(
  ot_ts,
  seasonal = TRUE,
  stepwise = FALSE,
  approximation = FALSE,
  seasonal.test = "ocsb"
)
AICc(fit_ts); AICc(fit_msts)

# --- 4) Holdout comparison (last ~6 months) ---
h <- 24 * 30 * 6
n <- length(ot_msts)
train_idx <- seq_len(n - h)

y_train_msts <- ot_msts[train_idx]
y_test       <- ot_msts[-train_idx]  # same numeric values as df$OT tail

fit_train_ts   <- auto.arima(ts(as.numeric(y_train_msts), frequency = 24),
                             seasonal = TRUE, stepwise = FALSE,
                             approximation = FALSE, seasonal.test = "ocsb")

fit_train_msts <- auto.arima(
  msts(as.numeric(y_train_msts), seasonal.periods = c(24, 24*7)),
  seasonal = TRUE, stepwise = FALSE, approximation = FALSE, seasonal.test = "ocsb"
)

fc_ts   <- forecast(fit_train_ts,   h = h)
fc_msts <- forecast(fit_train_msts, h = h)

# Accuracy vs holdout
acc_ts   <- accuracy(fc_ts,   y_test)
acc_msts <- accuracy(fc_msts, y_test)
acc_ts
acc_msts

# --- 5) Quick visual of the better forecast ---
better <- ifelse(acc_msts["Test set","RMSE"] < acc_ts["Test set","RMSE"], "msts", "ts")
p_dat <- data.frame(
  date  = df$date[(n - h + 1):n],
  actual = as.numeric(y_test),
  ts_hat   = as.numeric(fc_ts$mean),
  msts_hat = as.numeric(fc_msts$mean)
)

ggplot(p_dat, aes(date, actual)) +
  geom_line() +
  geom_line(aes(y = if (better=="msts") msts_hat else ts_hat),
            linetype = 2) +
  labs(title = paste("Forecast vs Actual (", better, " model shown)", sep=""),
       x = "Date", y = "OT")
