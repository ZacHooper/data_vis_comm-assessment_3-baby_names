library(dplyr)
library(ggplot2)
library(case)
library(tidyverse)
library(plotly)

# Read data
data <- read.csv("../data/data.csv")

# Cleaning
# Remove All Caps names
data$name = str_to_title(data$name)

# Madeleine in 2018 is mislabelled as MALE
data[which(data[,"name"] == "Madeleine" & data[,"year"] == 2018, arr.ind=TRUE), "sex"] <- "FEMALE"

# Charlie & Riley are listed as both Female and Male names, Handle this
data[which(data[,"name"] == "Riley" & data[,"sex"] == "FEMALE", arr.ind=TRUE), "name"] <- "Riley (f)"
data[which(data[,"name"] == "Riley" & data[,"sex"] == "MALE", arr.ind=TRUE), "name"] <- "Riley (m)"

data[which(data[,"name"] == "Charlie" & data[,"sex"] == "FEMALE", arr.ind=TRUE), "name"] <- "Charlie (f)"
data[which(data[,"name"] == "Charlie" & data[,"sex"] == "MALE", arr.ind=TRUE), "name"] <- "Charlie (m)"
write.csv(data, "../data/clean_data.csv")

# How to find either of these names - ie contains charlie...
data %>% filter(grepl("Charlie", name))


# Filter dataset based on list of names
n <- c("Zac","Jack","Oliver","Beau","Owen", "Kai", "Madeleine")
name_filter <- data %>% 
  filter(name %in% n)

ggplot(name_filter) +
  geom_line(aes(x=year, y=position, colour=name))


# Filter dataset based on gender
f_n <- c("Chloe","Charlotte","Luna") # Filtering by names to lesson mess while testing
gender_filter <- data %>% 
  filter(sex == "FEMALE",
         name %in% f_n)

ggplot(gender_filter) +
  geom_line(aes(x=year, y=position, colour=name))

# How many unique names are there
length(unique(data$name))

# How many years did a name get mentioned in the top 100
temp <- data
temp$year = as.factor(temp$year)

temp %>% 
  count(name) %>% 
  rename(years_in_top_100 = n)

# How many characters in names
names <- unique(data$name)
length_names <- nchar(names)
table(length_names)

# How has the length of names changed over time
# Doesn't factor in the actual expected mean so is slightly inaccurate
data %>% 
  group_by(year) %>% 
  summarise(name_length = mean(nchar(name))) %>% 
  ggplot() +
    geom_line(aes(x=year,y=name_length))

# What is the average rank of names
data %>% 
  group_by(name) %>% 
  summarise(avg_rank = mean(position)) %>% 
  arrange(avg_rank)

# Find Potential One hit wonders or high changes
temp3 <- data %>% 
  filter(sex == "FEMALE") %>% 
  group_by(name) %>% 
  summarise(avg_rank = mean(position),
            min_rank = min(position),
            max_rank = max(position),
            diff_rank = max_rank - min_rank) %>% 
  arrange(desc(diff_rank)) %>% 
  head(10)

ggplot(data %>% filter(name %in% temp3$name)) +
  geom_line(aes(x=year, y=position, colour=name))


# Working out the trend of the name
calculate_change <- function(thing, filter_name, current_year) {
  print(filter_name)
  print(current_year)
  # Given a dataset, name to filter on and a year. Calculate how much that name's position changed that year. 
  # Filter the full dataset for the name
  name_df <- thing %>% filter(name == filter_name)
  # Return 0 (no change) if first year name was in the top 100
  if (current_year == min(name_df$year)) {
    return (0)
  }
  
  if (curre)
  
  
  # Get the position for the previous year
  prev_pos <- name_df %>% filter(year == current_year - 1) %>% select(position)
  # Get the current position
  curr_pos <- name_df %>% filter(year == current_year) %>% select(position)
  
  if (filter_name == "Kai") {
    print(prev_pos)
    print(curr_pos)
  }
  return (prev_pos - curr_pos)
}

temp4 <- data
temp4$change = 0
for(i in 1:nrow(temp4 %>% filter(year > 2010))) {
  row <- temp4[i,]
  temp4[i,]$change = calculate_change(temp4, row$name, row$year)
}
View(temp4)

summary(temp4$change)

data$position = factor(data$position, levels = seq(100, 1), ordered = TRUE)

male_names <- data %>% filter(sex == "MALE")

names_sex <- data %>% distinct(name, sex)

plot_ly(data = male_names, type = "scatter", mode = "lines", 
        x = ~year, y = ~position, color = ~name)

top_10_male_in_08 <- data %>% 
  filter(year == 2008,
         sex == "MALE",
         position >= 10) %>% 
  select(name)

top_10_female_in_08 <- data %>% 
  filter(year == 2008,
         sex == "FEMALE",
         position >= 10) %>% 
  select(name)

my_names <- data.frame(name = c("Zac", "Chloe", "Riley"))

# Handle Both Gender Names
data %>% 
  distinct(name, sex) %>% 
  count(name) %>% 
  filter(n > 1)


updatemenus <- list(
  list(
    active = 0,
    x = -.125,
    type= 'buttons',
    buttons = list(
      list(
        label = "My Baby Names",
        method = "update",
        args = list(list(visible = apply(data %>% arrange(name) %>% distinct(name), 1, function(x) create_mask(my_names, x))))
      ),
      list(
        label = "Top 10 Males Names in 2008",
        method = "update",
        args = list(list(visible = apply(data %>% arrange(name) %>% distinct(name), 1, function(x) create_mask(top_10_male_in_08, x))))
      ),
      list(
        label = "Top 10 Female Names in 2008",
        method = "update",
        args = list(list(visible = apply(data %>% arrange(name) %>% distinct(name), 1, function(x) create_mask(top_10_female_in_08, x))))
      ),
      list(
        label = "All Names",
        method = "update",
        args = list(list(visible = TRUE))
      )
    )
  )
)

plot_ly(data) %>% 
  add_trace(x = ~year, y = ~position, color = ~name, mode = 'lines', type = 'scatter') %>% 
  layout(yaxis = list(zeroline = FALSE),
         xaxis = list(zeroline = FALSE, rangeslider = list(type = "date")),
         title = "Top 100 Victorian Baby Name",
         updatemenus=updatemenus)

data %>% filter(name %in% top_10_male_in_08$name)

test <- function (names, selected_sex, name, sex) {
  if (name %in% names && sex == selected_sex) {
    return (TRUE)
  }
  else {
    return (FALSE)
  }
}

create_mask <- function(name_list, sex, row) {
  if (row["name"] %in% name_list$name) {
    return (TRUE)
  }
  else {
    return (FALSE)
  }
}


apply(data %>% arrange(name) %>% distinct(name), 1, function(x, y) create_mask(top_10_male_in_08, "MALE", x))

data %>% distinct(name)

data %>% filter(name == "Madeleine")

data %>% filter(name %in% top_10_female_in_08$name,
                year == 2008) %>% 
  plot_ly(x = ~count, y = ~name)


# Name generator

# Reformat data with wanted information
generator_data <- data %>% 
  group_by(name, sex) %>% 
  summarise(worstPosition = max(position),
            bestPosition = min(position),
            avgPosition = mean(position))

# Generates a random name based on the critera given. 
#nCan generate more names with the n variable
nameGenerator <- function (gender = "BOTH", wp = 0, bp = 0, ap = 0) {
  filtered_data <- generator_data
  if (gender != "BOTH") {
    filtered_data <- filtered_data %>% filter(sex == gender)
  } 
  if (wp != 0) {
    filtered_data <- filtered_data %>% filter(worstPosition <= wp)
  }
  if (bp != 0) {
    filtered_data <- filtered_data %>% filter(bestPosition >= bp)
  }
  if (ap != 0) {
    filtered_data <- filtered_data %>% filter(avgPosition < ap)
  }
  
  return (filtered_data[sample.int(length(filtered_data$name), 1), "name"])
}

nameGenerator("BOTH")

data[sample.int(count(data)$n, 1), "name"]

data[sample.int(count(data %>% distinct(name))$n, 1),"name"]

count(data)$n

data %>% distinct(name)


# Names beginning with...
data %>% 
  mutate(s = substr(name, 1, 1)) %>% 
  count(s) %>% 
  plot_ly(x = ~s, y = ~n, type="bar")


# Trend lines
zac_data <- data %>% filter(name == "William")
zac_data %>% 
  plot_ly(x = ~year, y = ~position, type = "scatter", mode = "lines", name = "Position of Zac") %>% 
    add_trace(mode = 'lines',x = ~year,
              y = fitted(lm(zac_data$position ~ zac_data$year)),
              name = "Linear Trend")

lm(zac_data$position ~ zac_data$year)$coefficients[2]

data %>% 
  group_by(name) %>% 
  mutate(trend = lm(position ~ year)$coefficients[2]) %>% 
  arrange(trend)
