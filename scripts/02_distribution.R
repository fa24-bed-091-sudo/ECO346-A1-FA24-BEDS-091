# 02_distribution.R -- Question 2: weighted histogram of earnings, log10 scale.
source("scripts/00_helpers.R")

x <- earners$earn_annual; w <- earners$hhweight

# ---- numbers to report ----
n_earners <- nrow(earners)
med_w   <- wquant(x, w, 0.5)
med_u   <- median(x)                      # unweighted median
p10     <- wquant(x, w, 0.10)
p90     <- wquant(x, w, 0.90)
ratio   <- round(p90 / p10, 2)

# ---- histogram: bins 0.1 wide in log10 units, 4.0 to 7.0 ----
lx   <- log10(x)
keep <- lx >= 4 - 1e-9 & lx <= 7 + 1e-9
n_excl <- sum(!keep)

d <- earners[keep, ]
d$bin <- pmin(floor(round((log10(d$earn_annual) - 4) / 0.1, 9)), 29)   # 0..29 (7.0 goes in last bin)
hist <- d |>
  group_by(bin) |>
  summarise(wsum = sum(hhweight), .groups = "drop") |>
  right_join(tibble(bin = 0:29), by = "bin") |>
  mutate(wsum = coalesce(wsum, 0),
         density = wsum / sum(wsum) / 0.1,          # density per log10 unit
         left = 4 + 0.1 * bin, right = left + 0.1)

lab_brk <- c(4, 5, 6, 7)
lab_txt <- c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")
ymax <- max(hist$density)

title <- sprintf("Half of Sindh's urban earners make under %s a year; the top tenth make over %s",
                 rs(med_w), rs(p90))
cap <- sprintf(paste0("Source: PSLM 2019-20 person file (earnings) merged with household file (weights, province, area).\n",
                      "Sample: Sindh urban earners aged 15-64 with annual earnings > 0 (n = %s). ",
                      "%d earners outside Rs 10,000-Rs 10,000,000 excluded.\n",
                      "Weighted by hhweight; bins 0.1 wide in log10 units; density per log10 unit."),
               format(n_earners, big.mark = ","), n_excl)

p <- ggplot(hist) +
  geom_rect(aes(xmin = left, xmax = right, ymin = 0, ymax = density),
            fill = "grey55", colour = "white", linewidth = 0.3) +
  geom_vline(xintercept = log10(c(med_w, p90)), linetype = "dashed", colour = "firebrick") +
  annotate("text", x = log10(med_w), y = ymax * 1.05, hjust = 1.08,
           label = paste0("Weighted median\n", rs(med_w)), colour = "firebrick", size = 3.6) +
  annotate("text", x = log10(p90), y = ymax * 1.05, hjust = -0.08,
           label = paste0("Weighted 90th pct.\n", rs(p90)), colour = "firebrick", size = 3.6) +
  scale_x_continuous(breaks = lab_brk, labels = lab_txt, limits = c(4, 7), expand = c(0.04, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = title, caption = cap,
       x = "Annual earnings (log scale)", y = "Density per log10 unit") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12.5),
        plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
        plot.title.position = "plot", plot.caption.position = "plot",
        panel.grid.minor = element_blank(), panel.grid.major.x = element_blank())

ggsave("figures/distribution.svg", p, width = 9, height = 5.6)

# ---- report ----
res <- c(
  sprintf("Number of earners: %d", n_earners),
  sprintf("Weighted median: %s", rs(med_w)),
  sprintf("Unweighted median: %s", rs(med_u)),
  sprintf("Weighted 10th percentile: %s", rs(p10)),
  sprintf("Weighted 90th percentile: %s", rs(p90)),
  sprintf("P90/P10 ratio: %.2f", ratio),
  sprintf("Excluded outside Rs 10,000-10,000,000: %d", n_excl))
writeLines(res, "tables/q2_results.txt"); cat(res, sep = "\n")
