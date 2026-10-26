"""04_second_language.py -- Question 5: Python re-computation of the band table
and redraw of the Question 3 figure. Run from the repository root:
    python scripts/04_second_language.py
Requires: pandas, numpy, matplotlib.  Run the R scripts first (it compares
its table with tables/band_table_R.csv)."""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator, FixedFormatter, NullLocator

if not os.path.isdir("data") and os.path.isdir("../data"):
    os.chdir("..")
os.makedirs("figures", exist_ok=True); os.makedirs("tables", exist_ok=True)

PROV_CODE, AREA_CODE = 3, 2          # variant 3 = Sindh urban

person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid", "hhweight", "prov_code", "urban_rural"])

d = person.merge(hh, on="hhid", how="left")
d = d[(d.prov_code == PROV_CODE) & (d.urban_rural == AREA_CODE) &
      d.age.between(15, 64) & d.earn_annual.notna() & (d.earn_annual > 0)].copy()

# Five-year bands built with integer arithmetic (no pd.cut: its default
# right-closed intervals would put age 20 into 15-19)
d["band_lo"] = 15 + 5 * ((d.age - 15) // 5)
d["band"] = d.band_lo.astype(int).astype(str) + "-" + (d.band_lo + 4).astype(int).astype(str)
d["mid"] = d.band_lo + 2

def wmean(g):  # sum(w x) / sum(w)
    return np.average(g.earn_annual, weights=g.hhweight)

bands = (d.groupby(["band_lo", "band", "mid"])
           .apply(lambda g: pd.Series({"n_earners": len(g), "wmean": wmean(g)}), include_groups=False)
           .reset_index().sort_values("band_lo"))
# R's round() and numpy's round() are both half-to-even; use numpy explicitly
bands["weighted_mean"] = np.round(bands.wmean).astype(int)
bands["n_earners"] = bands.n_earners.astype(int)
bands["thin"] = bands.n_earners < 30
out = bands[["band", "mid", "n_earners", "weighted_mean"]].rename(columns={"mid": "midpoint"})
out.to_csv("tables/band_table_python.csv", index=False)

# ---- compare with the R table, to the rupee ----
r = pd.read_csv("tables/band_table_R.csv")
agree = (r.reset_index(drop=True).equals(out.reset_index(drop=True)))
print("Band tables agree to the rupee:", agree)
m25_py = int(out.loc[out.band == "25-29", "weighted_mean"].iloc[0])
m25_r = int(r.loc[r.band == "25-29", "weighted_mean"].iloc[0])
print(f"25-29 weighted mean  R: Rs {m25_r:,}   Python: Rs {m25_py:,}")
print(out.to_string(index=False))

# ---- figure ----
rng = np.random.default_rng(346)
jit = d.age + rng.uniform(-0.4, 0.4, len(d))
top = bands.loc[bands.wmean.idxmax()]
n_out = int(((d.earn_annual < 1e4) | (d.earn_annual > 1e7)).sum())

fig, ax = plt.subplots(figsize=(9, 6))
ax.scatter(jit, d.earn_annual, s=14, color="0.3", alpha=0.15, linewidths=0)
ax.plot(bands.mid, bands.wmean, color="firebrick", lw=2, zorder=3)
for _, b in bands.iterrows():          # hollow markers for thin bands
    ax.plot(b.mid, b.wmean, "o", ms=9, mec="firebrick", mew=2, zorder=4,
            mfc="white" if b.thin else "firebrick")
ax.set_yscale("log"); ax.set_ylim(1e4, 1e7); ax.set_xlim(14.5, 64.5)
ticks = [1e4, 1e5, 1e6, 1e7]
ax.yaxis.set_major_locator(FixedLocator(ticks))
ax.yaxis.set_major_formatter(FixedFormatter(["Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000"]))
ax.yaxis.set_minor_locator(NullLocator())            # ggplot draws no minor log ticks here
ax.set_xticks(range(15, 66, 5))
ax.grid(True, color="0.9"); ax.set_axisbelow(True)
for s in ax.spines.values(): s.set_visible(False)
ax.tick_params(length=0)
ax.annotate(f"Highest band mean:\nages {top.band}, Rs {int(round(top.wmean)):,}",
            xy=(top.mid, top.wmean), xytext=(top.mid, top.wmean * 1.9), ha="center",
            color="firebrick", arrowprops=dict(arrowstyle="-", color="firebrick"),
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="firebrick", lw=0.6))
ax.set_xlabel("Age (years)"); ax.set_ylabel("Annual earnings (log scale)")
fig.suptitle(f"Urban Sindh earners' average pay climbs with age to a peak at {top.band}, then drops",
             x=0.01, ha="left", fontweight="bold", fontsize=12)
fig.text(0.01, 0.005,
         f"Source: PSLM 2019-20 person file merged with household file. Sample: Sindh urban earners aged 15-64 with annual earnings > 0 (n = {len(d):,}).\n"
         f"Dots: individual earners (jittered +/-0.4 yr, alpha = 0.15); {n_out} outside the Rs 10,000-10,000,000 axis not shown.\n"
         "Markers: weighted mean (hhweight) of each 5-year band, at its midpoint; hollow markers = thin bands (fewer than 30 unweighted observations).",
         fontsize=7, color="0.25", va="bottom", ha="left")
fig.tight_layout(rect=(0, 0.07, 1, 0.97))
fig.savefig("figures/relationship_python.svg")
print("Saved figures/relationship_python.svg")
