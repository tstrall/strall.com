# =========================
# DSC 425
# ARIMA on ETTh1 (Hourly OT), 2017
# =========================

# --- Packages ---
library(readr)
library(dplyr)
library(ggplot2)
library(forecast)
library(lubridate)

# --- 0) Load & filter data (2017 only) ---
df <- read_csv("ETTh1.csv")
df <- df %>% filter(date >= as.POSIXct("2017-01-01"),
                    date <  as.POSIXct("2018-01-01"))

fit <- Arima(df$HULL, order=c(1,1,1), seasonal=c(1,1,1))

summary(fit)
checkresiduals(fit)

# Add seasonal structure

fit_sarima <- Arima(df$OT,
                    order=c(0,1,1),
                    seasonal=list(order=c(0,1,1), period=24),
                    method="CSS-ML")
summary(fit_sarima)
checkresiduals(fit_sarima)

# Backtesting with rolling forecasts

# Define forecast function wrapping your fitted model structure
fcast_fun <- function(x, h) {
  fit <- Arima(x, order=c(0,1,1),
               seasonal=list(order=c(0,1,1), period=24),
               method="CSS-ML")
  forecast(fit, h=h)
}

# Cross-validate with 24-hour horizon
e <- tsCV(df$OT, fcast_fun, h=24)

# Error metrics
rmse <- sqrt(mean(e^2, na.rm=TRUE))
mae  <- mean(abs(e), na.rm=TRUE)
cat("1-day ahead RMSE:", rmse, "  MAE:", mae, "\n")
