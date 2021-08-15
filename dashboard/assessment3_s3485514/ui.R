#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

clean_data <- read_csv("data/clean_data.csv")
male_names <- clean_data %>% filter(sex == "MALE") %>% distinct(name) %>% arrange(name)
female_names <- clean_data %>% filter(sex == "FEMALE") %>% distinct(name) %>% arrange(name)

# Define UI for application that draws a histogram
shinyUI(dashboardPage(
    dashboardHeader(title = "Basic dashboard"),
    dashboardSidebar(
        fluidPage(
            h3(textOutput("text_boy_girl_header", inline = TRUE)),
            radioButtons("gender", "",
                         list("Don't Know" = "BOTH",
                              "Boy" = "MALE",
                              "Girl" = "FEMALE")),
            h3(textOutput("text_pick_a_name_header", inline = TRUE)),
            fluidRow(
                selectInput(inputId = "nameSelect", label = "", selected = "",
                            choices = list("Male Names" = male_names$name,
                                           "Female Names" = female_names$name)),
                actionButton("nameGenerator", "Random Name")
            ),
            h3(textOutput("text_pick_my_names_list", inline = TRUE)),
            selectInput("names", "",
                        list("My Baby Names" = "myBabyNames",
                             "Top 10 Boys Names in 2008" = "top10Boy", 
                             "Top 10 Girls Names in 2008" = "top10Girl", 
                             "All Names" = "allNames"), selected = "top10Boy"),
            h3(textOutput("babyNamesHeader", inline = TRUE)),
            textOutput("babyNames"),
            textOutput("selection")
        )
    ),
    dashboardBody(
        fluidRow(box(plotlyOutput("rankByYear"), width = 12)),
        fluidRow(
            box(plotlyOutput("barplot"), width = 9),
            box(textOutput("trending"),
                br(""),
                actionButton("addToMyNames", "Add to My Names"), 
                br(""),
                width = 3),
        )
    )
))
