#' Summarise model forecasting scores
#'
#' @param scores A dataframe of model scores as produced by `score_model`
#' @param variables A character vector of variables names to group over. By default score type
#' and model is grouped over if present.
#' @param sel_scores A character vector indicating which scores to return information on. Defaults to all scores
#' @return A dataframe of summarised scores in a tidy format.
#' @export
#' @importFrom tidyr gather
#' @importFrom dplyr group_by summarise ungroup
#' @examples
#'
#' ## Example cases
#' cases <- EpiSoon::example_obs_cases %>%
#'     dplyr::mutate(timeseries = "Region 1") %>%
#'     dplyr::bind_rows(EpiSoon::example_obs_cases %>%
#'     dplyr::mutate(timeseries = "Region 2"))
#'
#'
#' ## Example Rts
#' rts <- EpiSoon::example_obs_rts %>%
#'     dplyr::mutate(timeseries = "Region 1") %>%
#'     dplyr::bind_rows(EpiSoon::example_obs_rts %>%
#'     dplyr::mutate(timeseries = "Region 2"))
#'
#' ## List of forecasting bsts models wrapped in functions.
#' models <- list("AR 3" =
#'                     function(...) {EpiSoon::bsts_model(model =
#'                     function(ss, y){bsts::AddAr(ss, y = y, lags = 3)}, ...)},
#'                "Semi-local linear trend" =
#'                function(...) {EpiSoon::bsts_model(model =
#'                     function(ss, y){bsts::AddSemilocalLinearTrend(ss, y = y)}, ...)})
#'
#'
#' ## Compare models
#' evaluations <- compare_timeseries(rts, cases, models,
#'                                   horizon = 7, samples = 10,
#'                                   serial_interval = example_serial_interval)
#'
#'
#'
#' ## Score across the default groups
#' summarise_scores(evaluations$rt_scores)
#'
#'
#' ## Also summarise across time horizon
#' summarise_scores(evaluations$rt_scores, "horizon", sel_scores = "crps")
#'
#' ## Instead summarise across region and summarise case scores
#' summarise_scores(evaluations$case_scores, "timeseries", sel_scores = "logs")
summarise_scores <- function(scores, variables = NULL, sel_scores = NULL) {


  default_groups <- "score"

  if (!is.null(scores[["model"]])) {
    default_groups <- c(default_groups, "model")
  }

  summarised_scores <- scores %>%
    tidyr::gather(key = "score", value = "value", dss, crps, logs, bias,
                  sharpness, calibration, median, iqr, ci)


  if (!is.null(sel_scores)) {
    summarised_scores <- summarised_scores %>%
      dplyr::filter(score %in% sel_scores)

  }

  summarised_scores <- summarised_scores %>%
    dplyr::group_by(.dots = c(variables, default_groups)) %>%
    dplyr::summarise(
      bottom = quantile(value, 0.025, na.rm = TRUE),
      lower =  quantile(value, 0.25, na.rm = TRUE),
      median =  median(value, na.rm = TRUE),
      mean = mean(value, na.rm = TRUE),
      upper = quantile(value, 0.75, na.rm = TRUE),
      top = quantile(value, 0.975, na.rm = TRUE),
      sd = sd(value, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()


  return(summarised_scores)
}
