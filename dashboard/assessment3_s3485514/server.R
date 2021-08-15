#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(readr)
library(ggplot2)
library(lubridate)
library(scales)

# Load data
clean_data <- read_csv("data/clean_data.csv")
clean_data$year <- as.Date(parse_date_time(clean_data$year, orders = "%Y"))
# Misc Name Lists

top_10_male_in_08 <- clean_data %>% 
    filter(year == as.Date("2008-01-01"),
           sex == "MALE",
           position >= 10) %>% 
    select(name) %>% 
    head(10)

top_10_female_in_08 <- clean_data %>% 
    filter(year == as.Date("2008-01-01"),
           sex == "FEMALE",
           position >= 10) %>% 
    select(name) %>% 
    head(10)

# Misc Functions
# Generates a random name based on the critera given. 
# Can generate more names with the n variable
nameGenerator <- function (gender = "BOTH", wp = 0, bp = 0, ap = 0) {
    filtered_data <- clean_data
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

filterDataForPlot <- function(rawData, gender, names) {
    filtered_data <- rawData
    if (gender != "BOTH") {
        filtered_data <- filtered_data %>% filter(sex == gender)
    }
    
    if (!is.null(names)) {
        filtered_data <- filtered_data %>% filter(name %in% names)
    }
    return (filtered_data)
}

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    global_state <- reactiveValues(my_baby_names = c(),
                                   active_data = clean_data,
                                   raw_data = clean_data,
                                   selected_name = "",
                                   trending = 0,
                                   names = "",
                                   names_list = c())
    
    getNames <- function(name_select) {
        # All Names by default
        return_names <- distinct(clean_data %>% select(name))
        
        # Display Top 10 Boys
        if (input$names == "top10Boy") {
            return_names <- top_10_male_in_08
        }
        
        # Display Top 10 Girls
        if (input$names == "top10Girl") {
            return_names <- top_10_female_in_08
        }
        
        # Display User's List of Baby Names
        if (input$names == "myBabyNames") {
            return_names <- clean_data %>% filter(name %in% global_state$my_baby_names) %>% select(name)
        } 
        return (return_names)
    }
    
    # Sidebar Text
    output$text_boy_girl_header <- renderText({
        "Are you having a boy or a girl?"
    })
    
    output$text_pick_a_name_header <- renderText({
        "Pick a name you like or use the button to generate a random one."
    })
    
    output$text_pick_my_names_list <- renderText({
        'Select the "My Baby Names" list.'
    })
    
    output$text_pick_selected_name <- renderText({
        "Click " + input$nameSelect + "'s line to the right."
    })
    
    output$babyNamesHeader <- renderText({
        "My Baby Names"
    })
    
    output$babyNames <- renderText({
        global_state$my_baby_names
    }, sep = ", ")
    
    output$text_other_lists <- renderText({
        "Other List's of Names"
    })
    
    # Name Generator
    observeEvent(input$nameGenerator, {
        random_name <- nameGenerator(input$gender)
        output$generatedName <- renderText({random_name$name})
        updateSelectInput(session, "nameSelect", selected = random_name)
    })
    
    
    # Main Plot
    output$rankByYear <- renderPlotly({
        print(global_state$names)
        data <- filterDataForPlot(clean_data, input$gender, global_state$names$name)
        print(data)

        # Set the variable to group the highlights on and initialise highlighting
        d <- highlight_key(data, ~name)
        
        # Builld ggplot
        p <- ggplot(d) +
            geom_line(aes(x = year, y = position, group = name, 
                           colour = name, text = paste("<b>Name</b> = ", name,
                                                     "<br><b>Year</b> = ", year(year),
                                                     "<br><b>Rank</b> = ", position,
                                                     "<br><b>Sex</b> = ", sex))) +
            scale_x_date(breaks="year", labels = date_format("%Y")) + 
            ylim(100,1) + 
            labs(title = "Top Victorian Baby Names from 2008 to 2020",
                 y = "Rank",
                 x = "Year") +
            theme_minimal()

        # Convert to plotly plot
        gg <- ggplotly(p, source = "lineplot", tooltip = "text") %>% 
            config(displayModeBar = F)
        
        # Format how highlighted line looks
        s <- attrs_selected(
            showlegend = FALSE,
            mode = "lines+markers",
            marker = list(symbol = "x")
        )
        
        # Add highlight logic to plot
        highlight(gg, on = "plotly_click", off = "plotly_doubleclick", selected = s, color = "red",
                  opacityDim = 0.8)
        
    })
    
    # Bar Chart of Count per Year
    output$barplot <- renderPlotly({
        s <- event_data("plotly_click", source = "lineplot")
        if (length(s) == 0) {
            plotly_empty()
        } else {
            data <- global_state$active_data %>% filter(name == global_state$selected_name[1])
            linear <- lm(data$count ~ data$year)
            global_state$trending <- linear$coefficients[2] * 365
            
            p <- ggplot(data) + 
                geom_bar(aes(x = year, y = count, text = paste("<b>Year</b> = ", year(year),
                                                               "<br><b>Rank</b> = ", position,
                                                               "<br><b>Count</b> = ", count)), 
                         stat = "identity") +
                geom_line(aes(x = year, y = fitted(linear, count)), colour = "Red") +
                labs(y = "Count", x = "Year") +
                scale_x_date(breaks="year", labels = date_format("%Y"), 
                             limits = as.Date(c("2007-01-01","2021-01-01"))) +
                theme_minimal()
            
            gg <- ggplotly(p, tooltip = "text") %>% 
                layout(title = list(
                    text = paste0('Number of Babies named ',global_state$selected_name,' in Victoria',
                                  '<br>','<sup>',
                                  'Trend is ', floor(global_state$trending), ' children per year',
                                  '</sup>'))) %>% 
                config(displayModeBar = F)
        }
    })
    
    output$trending <- renderText({
        isTrending = FALSE
        trend <- floor(global_state$trending)
        name <- global_state$selected_name[1]
        if (trend > 5) {
            isTrending = TRUE
            paste(name, "is trending with", trend, "additional children being named", 
                  name, "every year on year")
        } else if (trend > 0) {
            paste(name, "is getting more popular with a trend of", trend, 
                  "new children named", name, "every year on year")
        } else {
            paste(name, "is not trending and is losing", trend * -1, 
                  "new children named", name,"every year on year")
        }
            
    })
    
    output$selection <- renderText({
        s <- event_data("plotly_click", source = "lineplot")
        if (length(s) == 0) {
            print("Click a name")
        } else {
            name <- filterDataForPlot(global_state$active_data, input$gender, NULL) %>% 
                filter(year == s$x,
                       position == s$y * -1) %>%
                select("name")
            global_state$selected_name <- name$name[1]
        }
        invisible()
    })
    
    # Handle which list of names to display
    observeEvent(input$names, {
        global_state$names <- getNames(input$names)
    })
    
    # Add a selected name to the My Baby Names List
    observeEvent(input$nameSelect, {
        # Only add name if it isn't already in the list
        if (!is.element(input$nameSelect, global_state$my_baby_names)) {
            global_state$my_baby_names <- append(global_state$my_baby_names, input$nameSelect)
        }
    })
    
    observeEvent(input$addToMyNames, {
        # Only add name if it isn't already in the list
        if (!is.element(global_state$selected_name[1], global_state$my_baby_names)) {
            global_state$my_baby_names <- append(global_state$my_baby_names, global_state$selected_name[1])
        }
    })

})
