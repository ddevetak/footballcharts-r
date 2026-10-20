# footballcharts — R Client for the Keyless Football Charts API & Probability Toolkit

[![R-universe](https://ddevetak.r-universe.dev/badges/footballcharts)](https://ddevetak.r-universe.dev/footballcharts)

**`footballcharts`** provides zero-key R access to the [Football Charts REST API](https://www.football-charts.com/developers) across **98 domestic and international football leagues** (match results, half-time scores, exact goal-minute timestamps, standings, upcoming fixtures, [Dixon–Coles match probabilities](https://www.football-charts.com/predictions), and [10,000-simulation Monte Carlo season projections](https://www.football-charts.com/leagues)), alongside local mathematical functions matching the [Football Charts Dixon–Coles & Fair-Odds Calculator](https://www.football-charts.com/tools/dixon-coles-calculator).

## Installation

Install directly from [R-universe](https://ddevetak.r-universe.dev/footballcharts) (no GitHub PAT needed):

```r
install.packages("footballcharts", repos = c("https://ddevetak.r-universe.dev", "https://cloud.r-project.org"))
```

Or via `remotes`:

```r
remotes::install_github("ddevetak/footballcharts-r")
```

## Quick Start

```r
library(footballcharts)

# 1. Fetch finished matches with half-time scores and goal minutes (no API key required)
matches <- fc_results("germany3", season = "2025-2026")
head(matches)

# 2. Compute a Dixon & Coles (1997) bivariate score probability matrix
M <- fc_dixon_coles_matrix(lambda = 1.55, mu = 1.15, rho = -0.11)
home_win <- sum(M[row(M) > col(M)])
draw     <- sum(diag(M))
away_win <- sum(M[row(M) < col(M)])

# 3. Exact O(n^2) Poisson-Binomial shot-xG convolution
pb <- fc_poisson_binomial_pmf(c(0.65, 0.50, 0.35))

# 4. Strip bookmaker margin via Power (k) or Shin (z) de-vigging
fc_devig_power(c(2.10, 3.40, 3.60))
fc_devig_shin(c(2.10, 3.40, 3.60))
```

## Links & Open Data

- **Live Platform:** <https://www.football-charts.com>
- **Interactive Dixon–Coles, Shot-xG & De-Vig Calculator:** <https://www.football-charts.com/tools/dixon-coles-calculator>
- **Keyless REST API & MCP Server Docs:** <https://www.football-charts.com/developers>
- **Open CC-BY-4.0 Dataset (Zenodo):** <https://www.football-charts.com/data>
