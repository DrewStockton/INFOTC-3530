#!/bin/bash

# Select date using Zenity calender picker and store into a variable
# check to make sure date was selected
date_selected=$(zenity --calendar --title="Select a Date" --date-format="%Y-%m-%d")
if [[ -z "$date_selected" ]]; then
    zenity --error --text="No date selected. Exiting."
    exit 1
fi



# Select time (12-hour format) with zenity using --entry with HH:MM format and store into a variable
# check to make sure a valid format was entered
time_selected=$(zenity --entry --title="Select Time" --text="Enter time in HH:MM format" --entry-text="12:00")
if [[ -z "$time_selected" || ! "$time_selected" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
    zenity --error --text="Invalid time format. Exiting."
    exit 1
fi



# Select AM or PM with zenity --list and check to make sure it was selected
ampm=$(zenity --list --title="Select AM or PM" --radiolist --column="Pick" --column="AM/PM" TRUE "AM" FALSE "PM")
if [[ -z "$ampm" ]]; then
    zenity --error --text="No AM/PM selected. Exiting."
    exit 1
fi


# Convert 12-hour time to 24-hour time
# store the hour in a variable for hour
# store the minutes in a variable for minutes
hour=${time_selected%:*}
minute=${time_selected#*:}

if [[ "$ampm" == "PM" && "$hour" -ne 12 ]]; then
    hour=$((hour + 12))
elif [[ "$ampm" == "AM" && "$hour" -eq 12 ]]; then
    hour=0
fi
minute=$minute
hour=$hour





# Select script file using zenity and store it in a variable
# check to make sure it was selected 
script_file=$(zenity --file-selection --title="Select Script to Run")
if [[ -z "$script_file" ]]; then
    zenity --error --text="No script selected. Exiting."
    exit 1
fi



# Ask if the scheduled script needs DISPLAY and XAUTHORITY variables
# if you choose to use zenity to choose your files on the create_backup.sh you
# will need to use the display. Since the cronjob will run in the background
# you can use the DISPLAY and the XAURHORITY to display your gui
# use display="DISPLAY=:0" and xauthority="XAUTHORITY=/home/$USER/.Xauthority"
# to use your display
use_display=$(zenity --question --title="DISPLAY and XAUTHORITY" --text="Does this script require DISPLAY and XAUTHORITY for GUI use?" --ok-label="Yes" --cancel-label="No")
if [[ $? -eq 0 ]]; then
    display="DISPLAY=:0"
    xauthority="XAUTHORITY=/home/$USER/.Xauthority"
else
    display=""
    xauthority=""
fi


# Select repetition schedule using Zenity --list and --column will be 
# Once a day, Once a week, Once a month, Once a year
schedule=$(zenity --list --title="Select Repetition Schedule" --radiolist --column="Pick" --column="Frequency" TRUE "Once a day" FALSE "Once a week" FALSE "Once a month" FALSE "Once a year")
if [[ -z "$schedule" ]]; then
    zenity --error --text="No schedule selected. Exiting."
    exit 1
fi





# Calculate day and month for the initial run and store
# in a variable into day and variable for month
day=$(echo $date_selected | cut -d '-' -f 3)
month=$(echo $date_selected | cut -d '-' -f 2)




# Use a case to define cron job schedule based on user's selection
# of the repetition selected from your Zenity list
# each selection would store in a variable the syntax for
# Every day at the selected time "$minute $hour * * *"
# Every week on the selected day of the week "$minute $hour * * $weekday"
# Every month on the selected day"$minute $hour $day * *"
# Every year on the selected date "$minute $hour $day $month *"
case $repetition_schedule in
    "Once a day")
        cron_schedule="$minute $hour * * * $display $xauthority $script_file"
        ;;
    "Once a week")
        cron_schedule="$minute $hour * * $weekday $display $xauthority $script_file"
        ;;
    "Once a month")
        cron_schedule="$minute $hour $day * * $display $xauthority $script_file"
        ;;
    "Once a year")
        cron_schedule="$minute $hour $day $month * $display $xauthority $script_file"
        ;;
    *)
        zenity --error --text="Invalid repetition schedule selected. Exiting script."
        exit 1
        ;;
esac
# Add the cron job using the variable that was created in the case and the display as well as the script
(crontab -l 2>/dev/null; echo "$cron_schedule") | crontab -

# Show confirmation
zenity --info --text="Cron job scheduled successfully with the following schedule:\n\n$cron_schedule"
