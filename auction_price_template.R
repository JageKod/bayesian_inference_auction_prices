rm(list = ls())

#Load libraries and source files for R functions:
library(rstan)
library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(bayesplot)
library(cowplot)
library(gridExtra)
library(truncnorm)

setwd("C:/Users/John/Documents/R_projects/auction_prices")


date <- as.character(Sys.Date())

item_name <- 'example_item'

# input your data
data <- c(810,571,595,532,600,320,341,699) #example data

print(summary(data))


N <- length(data)

# Data to send to Stan:
data_in = list(
  N = N,  
  y = data,
  median = as.integer(median(data)),
  lower_bound = min(data)
)

######
# Compile and run stan file
######


mod1 <- stan_model("auction_price_comp_pool.stan")

init_fun <- function() {
  list(mu = median(data), sigma = sd(data))
}


# Sample:
fit1 <- sampling(object = mod1,
                 data = data_in,
                 init  = init_fun,
                 seed = 1234,
                 chains = 4,
                 iter = 2000,
                 warmup=500
                 # control = list(adapt_delta = 0.99)
)

saveRDS(fit1, sprintf("fit_%s_%s.rds", item_name,date))

# Print out sampling statement:
print(fit1)


# Posterior plots
# Convert fit1 to a an array
posterior <- as.data.frame(fit1)

hist(posterior$mu, main = "Posterior of μ (mean price)",
     xlab = "Price", col = "skyblue", breaks = 30)

hist(posterior$sigma, main = "Posterior of σ (std dev)",
     xlab = "Standard Deviation", col = "lightgreen", breaks = 30)


# Draw predictive prices from truncated normal
set.seed(123)
n <- nrow(posterior)

predicted_prices <- rtruncnorm(n,
                               a = min(data),
                               b = Inf,
                               mean = posterior$mu,
                               sd = posterior$sigma)

# Summary
quantile(predicted_prices, probs = c(0.1, 0.25, 0.5, 0.75, 0.9))


# better histogram
hist(predicted_prices,
     main = "Predicted Prices",
     col = "orange",
     breaks = 30,
     xlim = c(floor(min(predicted_prices)), ceiling(max(predicted_prices))),
     yaxt = "n",
     xaxt = "n")

axis(1, at = seq(floor(min(predicted_prices)), ceiling(max(predicted_prices)), by = 50))

