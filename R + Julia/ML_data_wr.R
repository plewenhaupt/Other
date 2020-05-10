#########
# TODO  #
#########
#What to do with >50 numeric variables?
#What to do with the character variables?
# - Breakdown of each (# of unique) - I already have this in the grouped dfs, but how to visualize them?


#############
# PACKAGES  #
#############
source('~/Docs/Machine Learning/package_load_ml.R')

#############
# ETL input #
#############

################
# IMPORT DATA  #
################
file_path <- 'data_file.xlsx'

orig_data <- read_excel(file_path)

orig_data[orig_data == 'NULL'] <- NA

#Check ID length, to find new and missing rows
id <- orig_data$Id %>% as.list()
ln <- sapply(id, nchar)
len <- tibble(id = id, ln = ln) %>% filter(ln != 36)

#Filter data to include only rows with ID
orig_data <- orig_data %>% filter(nchar(Id) == 36)

#Get file info
info <- file.info(file_path)
bytes <- info[1,1]
megabytes <- info[1, 1]/10^6


##############################
# DATA DIMENSIONS AND TYPES  #
##############################
#Construct tibble with dimensions and data types
dim_tib <- tibble(rows = nrow(orig_data), columns = ncol(orig_data))
cols <- colnames(orig_data)
classes_grouped <- sapply(orig_data, class) %>% unlist() %>% tibble(class = .) %>% group_by(class) %>% tally()

##########################
# SPLIT DATA INTO TYPES  #
##########################
data_types <- classes_grouped[!base::grepl('^POSIX',classes_grouped$class), ] %>% select(class) %>% pull(.)

is_s <- lapply(data_types, function(x){
  paste0('is.', x)
})

type_dfs <- lapply(is_s, function(x){
  orig_data %>% select_if(eval(parse(text=x)))
})

################################
# UNIQUES VALUES PER VARIABLE  #
################################
uniques <- lapply(orig_data, unique)
unique_n <- lapply(uniques, length) %>% unlist()
uniques_char_collapsed <- lapply(uniques, function(x){
  y <- sort(x) 
  c <- as.character(y)
  d <- paste(c, collapse = ' ') %>% if_else(nchar(.) > 100, stri_sub(., 1, 100),.)
  
  return(d)
})

###################
# MISSING VALUES  #
###################
#Total values in data set
#No of missing
#No of complete

missing_totals <- tibble(Entity = c('Total dataset', 'Complete', 'Missing'), 
                         Data_points = c(pull(dim_tib[1, 1])*pull(dim_tib[1, 2]), naniar::n_complete(orig_data), naniar::n_miss(orig_data)),
                         Percent = c(100, naniar::pct_complete(orig_data), naniar::pct_miss(orig_data)))

classtib <- tibble(variable = colnames(orig_data), class = sapply(orig_data, class))

missing_summary <- naniar::miss_var_summary(orig_data) %>% dplyr::rename(missing_n = n_miss, missing_percent = pct_miss) %>% dplyr::mutate(n_complete = nrow(orig_data) - missing_n) %>% dplyr::arrange(variable)
variable_summary <- left_join(missing_summary, classtib, by = 'variable')
variable_summary$n_unique <- unique_n
variable_summary$uniques <- uniques_char_collapsed
all_na_cols <- variable_summary %>% select(variable, missing_n) %>% filter(missing_n == nrow(orig_data)) %>% select(variable) %>% unlist()
no_na_cols_data <- orig_data %>% select(-(all_na_cols))

#Save the cleaned data for Julia
save(no_na_cols_data, file = "no_na_cols_data.RData")

beep(4)

source('~/Docs/Machine Learning/Julia_clust_data.R')


