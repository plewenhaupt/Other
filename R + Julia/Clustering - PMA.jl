##Julia packages
using Pkg
Packages = ["Cairo",
            "Clustering",
            "DataFrames",
            "DataFramesMeta",
            "DataStructures",
            "ExcelReaders",
            "Fontconfig",
            "FreqTables",
            "Gadfly",
            "Lazy",
            "ORCA",
            "Pipe",
            "Plots",
            "PrettyPrinting",
            "Random",
            "RCall",
            "RData",
            "Statistics",
            "StatsBase",
            "TableView",
            "TSne"]

Pkg.add(Packages)

using Cairo,
    Clustering,
    DataFrames,
    DataFramesMeta,
    DataStructures,
    ExcelReaders,
    Fontconfig,
    FreqTables,
    Gadfly,
    Lazy,
    ORCA,
    Pipe,
    Plots,
    PrettyPrinting,
    Random,
    RCall,
    RData,
    Statistics,
    StatsBase,
    TableView,
    TSne

## OTHER CONFIG
#default plot size for Gadfly
set_default_plot_size(8inch, 6inch)

## LOAD R PACKAGES
R"source('~/Docs/Machine Learning/package_load_ml.R')"

## R data wrangling
R"source('~/Docs/Machine Learning/ML_data_wr.R')"

## IMPORT DATA SET
data_path = "/Users/peder/Docs/Machine Learning/df_julia.RData"
predata = RData.load(data_path)
data = predata["df_julia"]

## IMPORT DISTANCE MATRIX
distance_matrix_path = "/Users/peder/Docs/Machine Learning/gower_dist_julia.RData"
predata_dist = RData.load(distance_matrix_path)
gower_dist = predata_dist["gower_dist_julia"]

## TALLY OF VARIABLE PERMUTATIONS
R"names_minus_pin <- colnames($data)[2:9]"

#Create frequency table
R"freq_table = $data %>% group_by_at(vars(names_minus_pin)) %>% tally() %>% arrange(desc(n))"

@rget(freq_table)



## Plot the silhouette widths of different number of clusters -> choose the optimal
Random.seed!(5555)
sil_width = [0.0]

for i = 2:20
    clust_res = Clustering.kmedoids(gower_dist, i)
    push!(sil_width, Statistics.mean(silhouettes(clust_res.assignments, clust_res.counts, gower_dist)))
end

sil_plot = Gadfly.plot(x = 1:20, y = sil_width, Geom.line);

k = 8
clust_res = Clustering.kmedoids(gower_dist, k)

#Insert the assignments into the original dataframe
cluster_col = DataFrame(cluster = clust_res.assignments)
upd_data = hcat(data, cluster_col)

## CLOSEST AND FARTHEST CANDIDATES
#Most different candidates
max_distance = maximum(gower_dist)
most_different = findall(x -> x == max_distance, gower_dist)

#Remove duplicates of permutations
diffs = []

#Get the rows from the dataframe corresponding to the cartesian indices, sorted on Id
for i in 1:length(most_different)
    x = most_different[i][1]
    y = most_different[i][2]
    df = sort(data[[x,y], :], :Id)
    push!(diffs, df)
end


#Most alike candidates
most_alike = findall(x -> x == 0, gower_dist)
#Remove all the distance measures that are the same person, i.e. where the cartesian distance is not the same index

alike = []

for i in 1:length(most_alike)
    x = most_alike[i][1]
    y = most_alike[i][2]
    if x != y
        push!(alike, most_alike[i])
    end
end


## GROUP BY CLUSTERS
group_data = upd_data[:, 2:10]
data_grouped = DataFrames.groupby(group_data, :cluster)

clust_1 = data_grouped[1]

R"beep(5)"

##SUMMARY

#Function to ingest grouped dataframe and output a grid of charts
#function cluster_summary(grouped_df)
plot_vec = []
#1. Loop through SubDataFrames
for i in 1:length(data_grouped)

    df = data_grouped[i][:, 1:8]
    col_type = eltypes(df)
#2. loop through the columns
    for j in 1:size(df, 2)
        g = j
        global g
#3a. If column type is categorical or string, countmap to get tally and make bar chart of tally
        if occursin("String", string(col_type[j]))
            tally = countmap(df[:, j])
            cat_df = DataFrame(var_name = names(tally), n = collect(values(tally)))
            cat_plot = Gadfly.plot(cat_df, x = :var_name, y = :n,
                                    Geom.bar,
                                    Scale.y_continuous(maxvalue = maximum(clust_res.counts)),
                                    Guide.title(string("Cluster ", i)),
                                    Guide.xlabel(nothing)
                                    )
            push!(plot_vec, cat_plot)

#3b. If column type is numeric (Float64 or Int64), make histogram of values.
        elseif occursin(r"(Float|Int)", string(col_type[j]))
            num_plot = Gadfly.plot(x = df[:, j],
                                    Geom.histogram,
                                    Guide.title(string("Cluster ", i)),
                                    Guide.xlabel(nothing)
                                    )
            push!(plot_vec, num_plot)
        end
    end
end

#Create chart grids
plot_vec_row1 = []
for i in range(1, length(plot_vec), step = g)
    plot_row1 = plot_vec[i]
    push!(plot_vec_row1, plot_row1)
end

plot_arr_row1 = convert(Array{Plot}, plot_vec_row1)
row_1 = hstack(plot_arr_row1)
#end

#TODO: Find out how to create a hstack of plots in a vector

## R Summary
#This summary is not good enough. What I need is a function that returns
#visual summaries of the distribution of each variable, for each cluster.

R"pam_results <- $upd_data %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))"

R"summary <- pam_results$the_summary"

@rget(summary)

summary_dfs = []

for i in 1:length(summary)
    x = DataFrame(summary[i])
    push!(summary_dfs, x)
end

#TSNE
Y_1 = tsne(gower_dist, 3, 0, 5000, 50.0; distance = true)
R"beep(3)"
cluster_int = convert(Array{Int64}, cluster_col[:, 1])
cluster_cat = convert(CategoricalArray, cluster_int)
Y = DataFrame(x = Y_1[:, 1], y = Y_1[:, 2], z = Y_1[:, 3], cluster = cluster_cat)

## Visual TSne summary
Clr = Y[:, 4]
tsne_plot = Gadfly.plot(x = Y[:, 1], y = Y[:, 2], z = Y[:, 3],
                    Geom.point,
                    color = Clr,
                    Guide.colorkey(title="Cluster"),
                    Theme(point_size=2pt)
                    )
pyplot()
Plots.plot(x = Y_1[:, 1], y = Y_1[:, 2], z = Y_1[:, 3],st=:scatter,camera=(-30,30))

tsne3d = scatter3d()

R"beep(3)"

## DEV
