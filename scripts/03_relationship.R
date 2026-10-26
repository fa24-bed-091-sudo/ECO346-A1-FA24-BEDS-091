# 03_relationship.R -- Question 3: earnings vs age, with weighted band means.
# This is the redesign of figures/default.svg (Question 4).
source("scripts/00_helpers.R")

# ---- band table: band, unweighted n, weighted mean (rounded to the rupee) ----
bands <- earners |>
  group_by(band_lo, band, band_mid) |>
  summarise(n = n(), wmean = wmean(earn_annual, hhweight), .groups = "drop") |>
  arrange(band_lo) |>
  mutate(wmean_r = round(wmean), thin = n < 30)

write_csv(bands |> transmute(band, midpoint = band_mid, n_earners = n, weighted_mean = wmean_r),
          "tables/band_table_R.csv")

top <- bands |> slice_max(wmean, n = 1)
m25 <- bands$wmean_r[bands$band == "25-29"]
m45 <- bands$wmean_r[bands$band == "45-49"]
n_out <- sum(earners$earn_annual < 1e4 | earners$earn_annual > 1e7)  # off-axis points

lab_brk <- 10^(4:7)
lab_txt <- c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")

title <- sprintf("Urban Sindh earners' average pay climbs with age to a peak at %s, then drops",
                 top$band)
cap <- sprintf(paste0("Source: PSLM 2019-20 person file merged with household file. ",
                      "Sample: Sindh urban earners aged 15-64 with annual earnings > 0 (n = %s).\n",
                      "Dots: individual earners (jittered +/-0.4 yr, alpha = 0.15); %d outside the Rs 10,000-10,000,000 axis not shown.\n",
                      "Markers: weighted mean (hhweight) of each 5-year band, at its midpoint; ",
                      "hollow markers = thin bands (fewer than 30 unweighted observations)."),
               format(nrow(earners), big.mark = ","), n_out)

set.seed(346)   # reproducible jitter
p <- ggplot() +
  geom_point(data = earners, aes(age, earn_annual),
             position = position_jitter(width = 0.4, height = 0),
             alpha = 0.15, size = 1.2, colour = "grey30") +
  geom_line(data = bands, aes(band_mid, wmean), colour = "firebrick", linewidth = 0.9) +
  geom_point(data = bands, aes(band_mid, wmean, shape = thin),
             colour = "firebrick", fill = "white", size = 3.6, stroke = 1.2) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), guide = "none") +
  annotate("label", x = top$band_mid, y = top$wmean * 1.9, size = 3.7,
           label = sprintf("Highest band mean:\nages %s, %s", top$band, rs(top$wmean_r)),
           colour = "firebrick", fill = "white") +
  annotate("segment", x = top$band_mid, xend = top$band_mid,
           y = top$wmean * 1.45, yend = top$wmean * 1.08, colour = "firebrick") +
  scale_y_log10(breaks = lab_brk, labels = lab_txt) +
  scale_x_continuous(breaks = seq(15, 65, 5)) +
  coord_cartesian(xlim = c(14.5, 64.5), ylim = c(1e4, 1e7)) +
  labs(title = title, caption = cap, x = "Age (years)", y = "Annual earnings (log scale)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12.5),
        plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
        plot.title.position = "plot", plot.caption.position = "plot",
        panel.grid.minor = element_blank())

ggsave("figures/relationship.svg", p, width = 9, height = 6)

res <- c(sprintf("Weighted mean, 25-29: %s", rs(m25)),
         sprintf("Weighted mean, 45-49: %s", rs(m45)),
         sprintf("Highest weighted-mean band: %s (%s)", top$band, rs(top$wmean_r)),
         sprintf("Thin bands (n<30): %s", ifelse(any(bands$thin), paste(bands$band[bands$thin], collapse = ", "), "none")),
         sprintf("Points outside axis range: %d", n_out))
writeLines(res, "tables/q3_results.txt"); cat(res, sep = "\n")
print(as.data.frame(bands |> select(band, n, wmean_r, thin)))
