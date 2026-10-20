#' Football Charts Keyless REST API & Probability Toolkit
#'
#' Base URL for the Football Charts v1 REST API.
#' @keywords internal
fc_base_url <- function() {
  getOption("footballcharts.base_url", "https://footballcharts-backend.onrender.com/api/v1")
}

#' List Available Football Leagues and Seasons
#'
#' Retrieves all 98 domestic and international football leagues covered by
#' Football Charts (<https://www.football-charts.com/developers>). No API key required.
#'
#' @return A data.frame of leagues with codes, country names, and available seasons.
#' @export
fc_leagues <- function() {
  url <- paste0(fc_base_url(), "/leagues/")
  res <- jsonlite::fromJSON(url)
  if (!is.null(res$leagues)) as.data.frame(res$leagues) else as.data.frame(res)
}

#' Fetch League Standings Table
#'
#' @param league Character league code (e.g. `"england"`, `"germany3"`, `"spain"`).
#' @param season Optional season string (e.g. `"2025-2026"`).
#' @return A data.frame containing the league table.
#' @export
fc_standings <- function(league, season = NULL) {
  q <- if (!is.null(season)) paste0("?season=", utils::URLencode(as.character(season), reserved = TRUE)) else ""
  url <- paste0(fc_base_url(), "/leagues/", utils::URLencode(league, reserved = TRUE), "/standings/", q)
  res <- jsonlite::fromJSON(url)
  if (!is.null(res$standings)) as.data.frame(res$standings) else as.data.frame(res)
}

#' Fetch Finished Match Results, Half-Time Scores, and Goal Minutes
#'
#' @param league Character league code (e.g. `"england"`, `"germany3"`, `"brazil"`).
#' @param season Optional season string (e.g. `"2025-2026"`).
#' @return A data.frame of finished matches with full-time score, half-time score, and goal minutes.
#' @export
fc_results <- function(league, season = NULL) {
  q <- if (!is.null(season)) paste0("?season=", utils::URLencode(as.character(season), reserved = TRUE)) else ""
  url <- paste0(fc_base_url(), "/leagues/", utils::URLencode(league, reserved = TRUE), "/results/", q)
  res <- jsonlite::fromJSON(url)
  if (!is.null(res$matches)) as.data.frame(res$matches) else as.data.frame(res)
}

#' Fetch Upcoming League Fixtures
#'
#' @param league Character league code (e.g. `"england"`, `"germany"`, `"italy"`).
#' @return A data.frame of upcoming scheduled fixtures.
#' @export
fc_fixtures <- function(league) {
  url <- paste0(fc_base_url(), "/leagues/", utils::URLencode(league, reserved = TRUE), "/fixtures/")
  res <- jsonlite::fromJSON(url)
  if (!is.null(res$fixtures)) as.data.frame(res$fixtures) else as.data.frame(res)
}

#' Compute Bivariate Dixon-Coles (1997) Score Probability Matrix
#'
#' Computes the exact `(max_goals + 1) x (max_goals + 1)` joint scoreline probability
#' matrix under the Dixon & Coles (1997) low-score correlation adjustment.
#' Interactive web reference: <https://www.football-charts.com/tools/dixon-coles-calculator>.
#'
#' @param lambda Numeric home expected goals (`> 0`).
#' @param mu Numeric away expected goals (`> 0`).
#' @param rho Numeric low-score dependence parameter (default `-0.11`).
#' @param max_goals Integer maximum goals per team to tabulate (default `10L`).
#' @return A numeric matrix with rows `0:max_goals` (home) and columns `0:max_goals` (away) summing to 1.
#' @export
fc_dixon_coles_matrix <- function(lambda, mu, rho = -0.11, max_goals = 10L) {
  g <- 0:as.integer(max_goals)
  M <- outer(stats::dpois(g, lambda), stats::dpois(g, mu))
  M[1, 1] <- M[1, 1] * max(0, 1 - lambda * mu * rho)
  M[2, 1] <- M[2, 1] * max(0, 1 + mu * rho)
  M[1, 2] <- M[1, 2] * max(0, 1 + lambda * rho)
  M[2, 2] <- M[2, 2] * max(0, 1 - rho)
  rownames(M) <- paste0("home_", g)
  colnames(M) <- paste0("away_", g)
  M / sum(M)
}

#' Exact O(n^2) Poisson-Binomial Shot-xG Convolution
#'
#' Computes the exact probability distribution of total goals scored from a vector
#' of individual shot xG probabilities `p_1, ..., p_n` via dynamic programming:
#' `P_i(k) = (1 - p_i) * P_{i-1}(k) + p_i * P_{i-1}(k - 1)`.
#'
#' @param shot_xg Numeric vector of shot conversion probabilities in `(0, 1)`.
#' @return Numeric vector of length `length(shot_xg) + 1` giving `P(Goals = 0..n)`.
#' @export
fc_poisson_binomial_pmf <- function(shot_xg) {
  shot_xg <- shot_xg[is.finite(shot_xg) & shot_xg > 0 & shot_xg < 1]
  n <- length(shot_xg)
  dp <- c(1, rep(0, n))
  for (i in seq_along(shot_xg)) {
    p <- shot_xg[i]
    dp[2:(i + 1)] <- dp[2:(i + 1)] * (1 - p) + dp[1:i] * p
    dp[1] <- dp[1] * (1 - p)
  }
  names(dp) <- as.character(0:n)
  dp
}

#' Remove Bookmaker Overround via the Power Method
#'
#' Solves `sum((1 / odds_i)^k) = 1` for constant-elasticity exponent `k > 1`
#' (Clarke, Kovalchik & Ingram 2017) to account for favourite-longshot bias.
#'
#' @param odds Numeric vector of decimal bookmaker odds (`> 1`).
#' @return A list with components `probs` (fair probabilities), `fair_odds`, and `k` (power exponent).
#' @export
fc_devig_power <- function(odds) {
  stopifnot(all(is.finite(odds)), all(odds > 1))
  q <- 1 / odds
  fn <- function(k) sum(q^k) - 1
  root <- stats::uniroot(fn, interval = c(0.05, 25), tol = 1e-10)
  k <- root$root
  probs <- (q^k) / sum(q^k)
  list(probs = probs, fair_odds = 1 / probs, k = k, margin = sum(q) - 1)
}

#' Remove Bookmaker Overround via Shin's (1993) Insider-Flow Model
#'
#' Solves for insider-trading share `z` under Shin (1993).
#'
#' @param odds Numeric vector of decimal bookmaker odds (`> 1`).
#' @return A list with components `probs` (fair probabilities), `fair_odds`, and `z` (Shin parameter).
#' @export
fc_devig_shin <- function(odds) {
  stopifnot(all(is.finite(odds)), all(odds > 1))
  q <- 1 / odds
  S <- sum(q)
  if (S <= 1.000001) {
    probs <- q / S
    return(list(probs = probs, fair_odds = 1 / probs, z = 0, margin = S - 1))
  }
  shin_p <- function(z) (sqrt(z^2 + 4 * (1 - z) * (q^2) / S) - z) / (2 * (1 - z))
  fn <- function(z) sum(shin_p(z)) - 1
  root <- stats::uniroot(fn, interval = c(0, 0.95), tol = 1e-10)
  z <- root$root
  probs <- shin_p(z)
  probs <- probs / sum(probs)
  list(probs = probs, fair_odds = 1 / probs, z = z, margin = S - 1)
}
