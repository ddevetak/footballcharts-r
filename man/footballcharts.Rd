\name{footballcharts}
\alias{footballcharts}
\alias{fc_leagues}
\alias{fc_standings}
\alias{fc_results}
\alias{fc_fixtures}
\alias{fc_dixon_coles_matrix}
\alias{fc_poisson_binomial_pmf}
\alias{fc_devig_power}
\alias{fc_devig_shin}
\title{Client for the Football Charts Keyless Football Data and Probability API}
\description{
Access match results, half-time scores, goal-minute timestamps, standings,
upcoming fixtures, Dixon-Coles (1997) match probabilities, and 10,000-simulation
Monte Carlo season projections across 98 football leagues via the free, keyless
Football Charts REST API (\url{https://www.football-charts.com/developers}) and
interactive calculators (\url{https://www.football-charts.com/tools/dixon-coles-calculator}).
}
\usage{
fc_leagues()
fc_standings(league, season = NULL)
fc_results(league, season = NULL)
fc_fixtures(league)
fc_dixon_coles_matrix(lambda, mu, rho = -0.11, max_goals = 10L)
fc_poisson_binomial_pmf(shot_xg)
fc_devig_power(odds)
fc_devig_shin(odds)
}
\arguments{
  \item{league}{Character league code (for example \code{"england"}, \code{"germany3"}, \code{"spain"}).}
  \item{season}{Optional season string such as \code{"2025-2026"}.}
  \item{lambda}{Numeric home expected goals (\code{> 0}).}
  \item{mu}{Numeric away expected goals (\code{> 0}).}
  \item{rho}{Numeric Dixon-Coles low-score correlation parameter (default \code{-0.11}).}
  \item{max_goals}{Integer maximum goals per team to tabulate (default \code{10L}).}
  \item{shot_xg}{Numeric vector of individual shot xG probabilities in \code{(0, 1)}.}
  \item{odds}{Numeric vector of decimal bookmaker odds (\code{> 1}).}
}
\value{
Data frames for API endpoints (\code{fc_leagues}, \code{fc_standings}, \code{fc_results}, \code{fc_fixtures}),
a numeric probability matrix for \code{fc_dixon_coles_matrix}, a named probability vector for
\code{fc_poisson_binomial_pmf}, and a list of fair probabilities and parameters for
\code{fc_devig_power} and \code{fc_devig_shin}.
}
\examples{
M <- fc_dixon_coles_matrix(1.55, 1.15, rho = -0.11)
sum(M[row(M) > col(M)]) # Home win probability

pb <- fc_poisson_binomial_pmf(c(0.65, 0.50, 0.35))
fc_devig_power(c(2.10, 3.40, 3.60))
}
