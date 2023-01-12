#####################################
#   CREATE NEW FILE BASED ON THIS!  #
#####################################


#################
#   PSEUDOCODE  #
#################
#=
I want to:
Need to work more on data cleaning
- All opportunity events mapped to their origin type - e.g. applicant = New Applicant, sourced = New Lead
OR just group them together for one version and keep them separate in another. Group Prescreen, Tests, Block 1, Block 2, etc.
- Split the two subsets, it won't make sense to have both (maybe try with both first?)
- Work out how to index the different stages, so that New Applicant = 0, Automated Logic Test = 1, etc.
=#

#####################
#   PACKAGE IMPORT  #
#####################
using CSV,
    CategoricalArrays,
    DataFrames,
    DataFramesMeta,
    DotEnv,
    Dates,
    LibPQ,
    Missings,
    PlotlyJS,
    PrettyPrinting,
    RCall,
    Tables,
    TableView

# R packages
R"""
defaultW <- getOption("warn")

options(warn = -1)

library(beepr)

options(warn = defaultW)

"""

################
#   FUNCTIONS  #
################
# Connect to database and pull data
function database_pull(conn_url, query)
    # Create database connection
    conn = LibPQ.Connection(conn_url)

    # Query database and send results to dataframe
    df = @chain execute(conn, query) begin
                columntable()
                DataFrame()
            end

    close(conn)

    return df
end

################
#   VARIABLES  #
################
secrets = DotEnv.config(path = "dev.env")
DB_HOST = ENV["DB_LEVER_HOST"]
DB_DB = ENV["DB_LEVER_DB"]
DB_USER = ENV["DB_USER"]
DB_PASSWORD = ENV["DB_PASSWORD"]

conn_url = "host=$DB_HOST
            dbname=$DB_DB
            user=$DB_USER
            password=$DB_PASSWORD"

query =
"
SELECT second.opportunity_id,
       second.stages,
       'Stage' || ROW_NUMBER() OVER (PARTITION BY second.opportunity_id) AS stage_number

FROM (
     SELECT first.opportunity_id,
       first.stages,
       MIN(first.event_at) AS event_at

        FROM (
                 SELECT ope.opportunity_id,
                        ast.stage_name,
                        CASE
                            WHEN ope.archive_reason_id = 'NOT_APPLICABLE'
                                THEN ast.stage_name
                            WHEN ar.name = 'Klarna - Hired'
                                THEN 'Hired'
                            ELSE 'Archived'
                            END AS stages,
                        ope.event_at

                 FROM opportunity_progress_events ope

                          LEFT JOIN account_stages ast
                                    ON ast.account_stage_id = ope.account_stage_id

                          LEFT JOIN archive_reasons ar
                                    ON ar.archive_reason_id = ope.archive_reason_id

                          LEFT JOIN opportunities op
                                    ON op.opportunity_id = ope.opportunity_id

                          LEFT JOIN postings po
                                    ON po.posting_id = op.posting_id

                          LEFT JOIN job_department_teams jdt
                                    ON jdt.job_department_team_id = po.job_department_team_id
                 WHERE op.created_at > '2021-06-01'
                 AND jdt.name = 'Engineering'
                 AND op.archived_at IS NOT NULL

                 ORDER BY ope.opportunity_id, ope.event_at
             ) first

        GROUP BY 1, 2
        ORDER BY 1, 3
         ) second;
"

#####################
#   DATA INGESTION  #
#####################
# Pull data from database
df = database_pull(conn_url, query)

######################
#   DATA PROCESSING  #
######################
# Hardcode the placement of nodes
stages =
#Leads
["New lead",
"Reached out",
"Responded",
"GDPR Notice",
"Responded with Notice",
"Pre-Screen Call (Sourced)",
"Tests (Sourced)",
"Logic Test (Sourced)",
"PO Decision Required (Sourced)",
"Internal Reference Check (Sourced)",
#Applicants
"New applicant",
"Qualified for pre-screening (Applied)",
"Automated Logic Test",
"Automated Logic Test Completed",
"Passed Logic Test (Applied)",
"Logic Test (Applied)",
"Coding Test (Applied)",
"Pre-Screen Call (Applied)",
"Tests (Applied)",
"Internal Reference Check (Applied)",
"PO Decision Required (Applied)",
# Interview
"Block 1 Interviews",
"Block 2 Interviews",
"External Reference Check",
"Create Offer (only used by Service Delivery)",
"Offer Extended",
"Contract Signed",
"Hired",
"Archived"
]

stage_type =
[
"lead",
"lead",
"lead",
"lead",
"lead",
"lead",
"lead",
"lead",
"lead",
"lead",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"applicant",
"interview",
"interview",
"interview",
"interview",
"interview",
"interview",
"interview",
"interview"
]

node_color =
[
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"lightblue",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"purple",
"blue",
"blue",
"blue",
"blue",
"blue",
"blue",
"green",
"red"
]

ind =
[
0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28
]


x =
# Leads
[0.01, # New lead
0.1, # Reached out
0.2, # Responded
0.25, # GDPR Notice
0.2, # Responded with Notice
0.4, # Pre-Screen Call (Sourced)
0.45, # Tests (Sourced)
0.35, # Logic Test (Sourced)
0.4, # PO Decision Required (Sourced)
0.45, # Internal Reference Check (Sourced)
# Applicants
0.01, # New applicant
0.05, # Qualified for pre-screening (Applied)
0.1, # Automated Logic Test
0.2, # Automated Logic Test Completed
0.25, # Passed Logic Test (Applied)
0.25, # Logic Test (Applied)
0.35, # Coding Test (Applied)
0.4, # Pre-Screen Call (Applied)
0.45, # Tests (Applied)
0.5, # Internal Reference Check (Applied)
0.55, # PO Decision Required (Applied)
# Interview
0.6, # Block 1 Interviews
0.7, # Block 2 Interviews
0.75, # External Reference Check
0.75, # Create Offer (only used by Service Delivery)
0.8, # Offer Extended
0.9,# Contract Signed
0.99, # Hired
0.99 # Archived
]

y =
# Leads
[0.3, # New lead
0.2, # Reached out
0.1, # Responded
0.05, # GDPR Notice
0.1, # Responded with Notice
0.3, # Pre-Screen Call (Sourced)
0.4, # Tests (Sourced)
0.1, # Logic Test (Sourced)
0.1, # PO Decision Required (Sourced)
0.1, # Internal Reference Check (Sourced)
# Applicants
0.6, # New applicant
0.0, # Qualified for pre-screening (Applied)
0.7, # Automated Logic Test
0.8, # Automated Logic Test Completed
0.9, # Passed Logic Test (Applied)
0.7, # Logic Test (Applied)
0.8, # Coding Test (Applied)
0.6, # Pre-Screen Call (Applied)
0.5, # Tests (Applied)
0.8, # Internal Reference Check (Applied)
0.8, # PO Decision Required (Applied)
# Interview
0.6, # Block 1 Interviews
0.7, # Block 2 Interviews
0.75, # External Reference Check
0.77, # Create Offer (only used by Service Delivery)
0.8, # Offer Extended
0.9, # Contract Signed
0.95, # Hired
0.01 # Archived
]

coord_df = DataFrame(stages = stages, x = x, y = y, ind = ind, node_color = node_color, stage_type = stage_type)

#=
Get the list of unique stages from the data
Order the unique stages according to the numbering
Create a new numbering based on the stages
=#


cleaned_df = dropmissing(df, :stages)

df_slice = cleaned_df

# Get the list of unique stages from the data
unique_stages = @chain unique(df_slice.stages) DataFrame(stages = _) leftjoin(_, coord_df, on = :stages) sort(:ind)

stages = @chain collect(0:(nrow(unique_stages)-1)) DataFrame(ind_col = _) hcat(unique_stages, _)

upd_df = leftjoin(df_slice, stages, on = :stages)

unstacked_df = @chain upd_df select([:opportunity_id, :ind_col, :stage_number]) unstack(:stage_number, :ind_col)

sankey_pre_df = DataFrame(source = [], target = [], value = [])

for i in 2:(ncol(unstacked_df)-1)
    for_df = @chain unstacked_df begin
                    select([i, i+1])
                    groupby([1, 2])
                    combine(nrow => :count)
                    dropmissing()
                    rename([:source, :target, :value])
                end
    sankey_pre_df = vcat(sankey_pre_df, for_df)
end

sankey_df1 = @chain sankey_pre_df groupby([:source, :target]) combine(:value => sum => :value)

sankey_df_source_type = @chain stages select([:ind_col, :stage_type]) leftjoin(sankey_df1, _, on = :source => :ind_col) rename(:stage_type => :source_type)

sankey_df = @chain stages select([:ind_col, :stage_type]) leftjoin(sankey_df_source_type, _, on = :target => :ind_col) rename(:stage_type => :target_type)

                #If target is Archived, then red
f(a, b, c, d) = (b == (nrow(unique_stages)-1)) ? "rgba(255,0, 0, 0.1)" :
                # If target greater than source and source and target type are equal, green
                (a<b) & (c == d) ? "rgba(0, 255, 100, 0.8)" :
                # If target greater than source and source => target interview type are equal, green
                (a<b) & (c == "applicant") & (d == "interview") ? "rgba(0, 255, 255, 0.8)" :
                # If target greater than source and source => target interview type are equal, green
                (a<b) & (c == "lead") & (d == "interview") ? "rgba(0, 255, 255, 0.8)" :
                # If source great than target, orange
                (a>b) ? "rgba(0,0,0, 0.3)" :
                # If source and target type not equal, then orange
                (c != b) ? "rgba(255,215,0, 0.6)" :
                "rgba(0, 0, 255, 0.3)"

sankey_df[!, :link_color] = f.(sankey_df.source, sankey_df.target, sankey_df.source_type, sankey_df.target_type)



R"beep(1)"

recruitment_sankey = PlotlyJS.plot(
                            sankey(
                            arrangement = "freeform",
                            orientation = "h",
                            node = attr(
                              label = stages.stages,
                              x = stages.x,
                              y = stages.y,
                              color = stages.node_color
                            ),
                            link = attr(
                              source = sankey_df.source, # indices correspond to labels, eg A1, A2, A1, B1, ...
                              target = sankey_df.target,
                              value = sankey_df.value,
                              color = sankey_df.link_color
                          )),
                          Layout(height=1200,
                                width=3400,
                                title_text="Recruitment Sankey Diagram - 6 months", font_size=10)
                        )

open("./example.html", "w") do io
    PlotlyBase.to_html(io, recruitment_sankey.plot)
end
