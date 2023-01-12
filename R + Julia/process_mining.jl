#################
#   PSEUDOCODE    #
#################
#=
I want to:

=#

#####################
#   PACKAGE IMPORT  #
#####################
using CSV,
    DataFrames,
    DataFramesMeta,
    Dates,
    LibPQ,
    Missings,
    RCall,
    Tables,
    TableView

################
#   FUNCTIONS  #
################

# Connect to database and pull data
function database_pull(conn_url, query)
    # Create database connection
    conn = LibPQ.Connection(conn_url)

    # Query database and send results to dataframe
    df = @linq execute(conn, query) |> columntable() |> DataFrame()

    close(conn)

    return df
end

################
#   VARIABLES  #
################

conn_url = ""

query = ""

################
#   EXECUTION  #
################


# 1. Pull data from database
df = database_pull(conn_url, query)

@rput(df)

R"""
library(tidyverse)
library(bupaR)
library(petrinetR)
library(processanimateR)
"""

R"""
event_log = df %>%
mutate(activity_instance = 1:nrow(.)) %>%
eventlog(
        case_id = 'opportunity_id',
        activity_id = 'stage_name',
        activity_instance_id = "activity_instance",
        lifecycle_id = "status",
        timestamp = "event_at",
        resource_id = "name"
)
"""

R"event_log %>% summary"

R"event_log %>% process_map()"

R"animate_process(event_log)"
