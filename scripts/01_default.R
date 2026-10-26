# 01_default.R -- Question 4: R's untouched default scatterplot.
# Nothing is added to ggplot() + geom_point(): this is the "before" figure.
source("scripts/00_helpers.R")

p <- ggplot(earners, aes(age, earn_annual)) + geom_point()
ggsave("figures/default.svg", p)
cat("Saved figures/default.svg  (n =", nrow(earners), "earners)\n")
