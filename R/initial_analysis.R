require(tidyverse) # data preparation
require(viridis) # fancy coloring
require(sqlmlutils) # utility functions

setwd("~/ml_services_demo")

# read data
rxSetComputeContext("local")

SqlConnectionString <- connectionInfo(
  server= "qwertz",
  database = "ebl"
)

table <- 'dbo.Payments'

sqlServerDS <- RxSqlServerData(
  sqlQuery = paste("SELECT * FROM", table),
  connectionString = SqlConnectionString)

payment <- rxImport(sqlServerDS) %>% 
  as_tibble()

plot <- function(.){
  p <- ggplot(., aes(x = key, y = value, fill = value)) +
    scale_fill_viridis(option = 'magma', begin = 0.2, end = 0.8) +
    geom_bar(stat = 'identity') +
    facet_wrap(~grouping) +
    coord_flip() +
    theme_bw() +
    theme(legend.position = 'none',
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          text = element_text(size = 16),
          plot.title = element_text(size = 28))
  return(p)
}  


# explore by sub segment
payment %>% 
  mutate(
    grouping = substr(SubSegment, 1, 4)
  ) %>% 
  group_by(grouping) %>% 
  summarise(
    AVG_Anz_Rechnungen = mean(Anzahl_Rechnungen),
    AVG_MIN_DSO = mean(MIN_DSO),
    AVG_MAX_DSO = mean(MAX_DSO),
    AVG_AVG_DSO = mean(AVG_DSO),
    AVG_AVG_LAST_3 = mean(AVG_DSO_LAST3),
    AVG_STDEV_DSO = mean(STDEV_DSO)
  ) %>% 
  gather(., ... = starts_with('AVG')) %>% 
  plot()


# explore by zahlungsbedingunen
payment %>% 
  mutate(
    grouping = Zahlungsbedingungen
  ) %>% 
  group_by(grouping) %>% 
  summarise(
    AVG_Anz_Rechnungen = mean(Anzahl_Rechnungen),
    AVG_MIN_DSO = mean(MIN_DSO),
    AVG_MAX_DSO = mean(MAX_DSO),
    AVG_AVG_DSO = mean(AVG_DSO),
    AVG_AVG_LAST_3 = mean(AVG_DSO_LAST3),
    AVG_STDEV_DSO = mean(STDEV_DSO)
  ) %>% 
  gather(., ... = starts_with('AVG')) %>% 
  plot()
  

# get attributes
payment_attributes <- payment %>% 
  select(AVG_DSO, STDEV_DSO, Anzahl_Rechnungen, PRECID, Zahlungsbedingungen) %>% 
  mutate(
    Zahlungsbedingung = ifelse(grepl('TN', Zahlungsbedingungen), gsub("TN", "", Zahlungsbedingungen), 0)
  ) %>% 
  transmute(
    customer_id = PRECID,
    sample_size = Anzahl_Rechnungen,
    sigma = STDEV_DSO,
    mu = AVG_DSO,
    threshold = as.numeric(Zahlungsbedingung)
  ) %>%
  mutate(
    prob_late = 1 - pnorm(q = threshold, mean = mu, sd = sigma),
    prob_5T = 1 - pnorm(q = 5, mean = mu, sd = sigma),
    prob_10T = 1 - pnorm(q = 10, mean = mu, sd = sigma),
    prob_15T = 1 - pnorm(q = 15, mean = mu, sd = sigma),
    prob_30T = 1 - pnorm(q = 30, mean = mu, sd = sigma),
    prob_60T = 1 - pnorm(q = 60, mean = mu, sd = sigma),
    prob_90T = 1 - pnorm(q = 90, mean = mu, sd = sigma),
    sample_size_large_enough = ifelse(sample_size > 29, 1, 0)
  ) 

plot_sample <- function(PRECID) {
  sample <- payment_attributes %>% 
    filter(customer_id == PRECID) 
  
  p <- ggplot(data = data.frame(x = c(0, 100)), aes(x)) +
    stat_function(fun = dnorm, n = 101, args = list(mean = sample$mu, sd = sample$sigma)) + ylab("") +
    scale_y_continuous(breaks = NULL) +
    geom_vline(xintercept = sample$threshold, color = 'red') +
    theme_bw()
  
  return(p)
}

plot_sample(PRECID = 5637540588)

payment_attributes %>% 
  filter(customer_id == 5637540588)


#' Get probabilities form gaussion
#' 
#' asdhf
#'
#' @param payment_data data frame with
#'
#' @return
#' @export
#'
#' @examples
get_probabilities <- function(payment_data) {
  require(tidyverse)
  require(stats)
  probs <- payment_data %>% 
    select(AVG_DSO, STDEV_DSO, Anzahl_Rechnungen, PRECID, Zahlungsbedingungen) %>% 
    mutate(
      Zahlungsbedingung = ifelse(grepl('TN', Zahlungsbedingungen), gsub("TN", "", Zahlungsbedingungen), 0)
    ) %>% 
    transmute(
      customer_id = PRECID,
      sample_size = Anzahl_Rechnungen,
      sigma = STDEV_DSO,
      mu = AVG_DSO,
      threshold = as.numeric(Zahlungsbedingung)
    ) %>%
    mutate(
      prob_late = 1 - pnorm(q = threshold, mean = mu, sd = sigma),
      prob_5T = 1 - pnorm(q = 5, mean = mu, sd = sigma),
      prob_10T = 1 - pnorm(q = 10, mean = mu, sd = sigma),
      prob_15T = 1 - pnorm(q = 15, mean = mu, sd = sigma),
      prob_30T = 1 - pnorm(q = 30, mean = mu, sd = sigma),
      prob_60T = 1 - pnorm(q = 60, mean = mu, sd = sigma),
      prob_90T = 1 - pnorm(q = 90, mean = mu, sd = sigma),
      sample_size_large_enough = ifelse(sample_size > 29, 1, 0)
    ) 
  
  return(probs)
}

dropSproc(SqlConnectionString, "usp_GetProbabilities_2")

createSprocFromFunction(
  SqlConnectionString, 
  name = "usp_GetProbabilities_2",
  func = get_probabilities, 
  inputParams = list(payment_data="dataframe")
)
 
# define normalize function; used throughout the script
#normalize <- function(x) {
#  return ((x - min(x)) / (max(x) - min(x)))
#}                       

## normalize the payment attributes
#payment_attributes_scaled <- apply(payment_attributes,2,function(x){normalize(x)})
#
## Elbow method for finding the optimal number of clusters
#set.seed(123)
#
## max number of cluster
#max_n_cluster <- 12
#
## get within similarity with different numbers of k
#ws <- sapply(1:max_n_cluster, function(k){
#  kmeans(payment_attributes_scaled, k, nstart=10, iter.max = 25)$tot.withinss
#})
#
## create data frame and define the color for the graph
#df <- data_frame(k = 1:max_n_cluster, tot.withinss = normalize(ws))
#col_dark <- viridis(option = 'magma', 1, begin = 0.3, end = 0.31)
#
## illustrate the "ellbow curve"
#ggplot(data = df, aes(x = k, y = tot.withinss)) +
#  geom_line(color = col_dark, size = 1.2) +
#  geom_point(color = col_dark, size = 4) +
#  scale_x_continuous(name = 'Number of k clusters', limits = c(1,12), breaks = c(0,2,4,6,8,10,12), labels = c(0,2,4,6,8,10,12)) +
#  ylab(label = 'Normalized within sum of squares') +
#  labs(title = 'Elbow method',
#       subtitle = 'Defining the best k to cluster payments') +
#  theme_bw() +
#  theme(text = element_text(size = 20),
#        plot.title = element_text(size = 28))
#
#
## get the clusters with the best k
#clusters <- kmeans(payment_attributes_scaled, 3, nstart=50,iter.max = 15 )
#
## add them to the data frame
#payment_clusters <- 
#  payment_attributes_scaled %>% 
#  as_tibble() %>% 
#  mutate(
#    cluster_id = as.factor(clusters$cluster)
#  )
#
#
#ggplot(payment_clusters, aes(x = AVG_DSO, y = STDEV_DSO, color = cluster_id)) +
#  geom_point()
#
#
#autoplot(prcomp(select(payment_clusters, -cluster_id)), 
#         data = payment_clusters, colour = 'cluster_id', scale = 0, shape = 'cluster_id', size = 2, 
#         frame = T, frame.type = 'norm', frame.colour = 'cluster_id', frame.fill = 'cluster_id') +
#  scale_color_viridis(option = 'magma', begin = 0.2, end = 0.8, discrete = T) +
#  scale_fill_viridis(option = 'magma', begin = 0.2, end = 0.8, discrete = T) +
#  labs(title = 'Payment clusters') +
#  theme_bw() +
#  theme(text = element_text(size = 20),
#        plot.title = element_text(size = 28),
#        legend.title = element_blank())
#