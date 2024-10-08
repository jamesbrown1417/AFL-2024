# Libraries
library(tidyverse)
library(rvest)
library(httr2)
library(jsonlite)
library(tidyjson)

# Function to fix team names
source("Functions/fix_team_names.R")

pointsbet_h2h_main <- function() {
  # URL of website
  pointsbet_url = "https://api.pointsbet.com/api/v2/competitions/7523/events/featured?includeLive=false&page=1"
  
  # Make request and get response
  pointsbet_response <-
    request(pointsbet_url) |>
    req_perform() |>
    resp_body_json()
  
  # List of matches and data
  events <- pointsbet_response$events
  
  # Loop through to get all data--------------------------------------------------
  
  # Create empty vectors
  match_names <- c()
  match_starts_at <- c()
  home_teams <- c()
  away_teams <- c()
  event_names <- c()
  outcome_names <- c()
  outcome_prices <- c()
  keys <- c()
  
  # Loop through events
  for (match in events) {
    for (market in match$specialFixedOddsMarkets) {
      for (outcome in market$outcomes) {
        # Append data to vectors
        match_names <- c(match_names, match$name)
        match_starts_at <- c(match_starts_at, match$startsAt)
        home_teams <- c(home_teams, match$homeTeam)
        away_teams <- c(away_teams, match$awayTeam)
        event_names <- c(event_names, market$eventName)
        outcome_names <- c(outcome_names, outcome$name)
        outcome_prices <- c(outcome_prices, outcome$price)
        keys <- c(keys, match$key)
      }
    }
  }
  
  # Output tibble
  pointsbet_data <-
    tibble(
      match = match_names,
      start_time = match_starts_at,
      home_team = home_teams,
      away_team = away_teams,
      event = event_names,
      outcome = outcome_names,
      price = outcome_prices
    ) |>
    mutate(match = paste(home_team, "v", away_team)) |>
    relocate(match, .before = start_time) |> 
    mutate(across(everything(), str_squish))
  
  #===============================================================================
  # Head to head markets
  #===============================================================================
  
  # Filter to head to head markets
  pointsbet_data_h2h <-
    pointsbet_data |>
    filter(event == "Match Result")
  
  # Home Teams
  pointsbet_data_h2h_home <-
    pointsbet_data_h2h |>
    filter(home_team == outcome) |>
    select(match,
           start_time,
           market = event,
           home_team,
           home_win = price) |> 
    mutate(home_team = fix_team_names(home_team))
  
  # Away Teams
  pointsbet_data_h2h_away <-
    pointsbet_data_h2h |>
    filter(away_team == outcome) |>
    select(match,
           start_time,
           market = event,
           away_team,
           away_win = price) |> 
    mutate(away_team = fix_team_names(away_team))
  
  # Combine
  pointsbet_h2h <-
    full_join(
      pointsbet_data_h2h_home,
      pointsbet_data_h2h_away,
      by = c("match", "start_time", "market")
    ) |>
    mutate(match = paste(home_team, "v", away_team)) |>
    mutate(market = "Head To Head") |>
    select(match,
           start_time,
           market_name = market,
           home_team,
           home_win,
           away_team,
           away_win) |>
    mutate(home_win = as.numeric(home_win),
           away_win = as.numeric(away_win)) |>
    mutate(margin = round((1 / home_win + 1 / away_win), digits = 3)) |>
    mutate(agency = "Pointsbet")
  
  # Write to csv
  write_csv(pointsbet_h2h, "Data/scraped_odds/pointsbet_h2h.csv")
}

##%######################################################%##
#                                                          #
####                   Run functions                    ####
#                                                          #
##%######################################################%##

# This runs both the props and head to head as they use same info
h2h_safe_pointsbet <- safely(pointsbet_h2h_main)

# Run functions
h2h_safe_pointsbet()
