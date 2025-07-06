#! /bin/bash

# Connect to the salon database. You created the database and tables in psql terminal. Yoou run following in bash.
PSQL="psql -U postgres -d salon -t --no-align -c"

# Display services menu
echo -e "\nWelcome to My Salon!\n"

DISPLAY_SERVICES() {
  # Run a SQL query to get the service_id and name of all services, ordered by ID
  # The result looks like this:
  # 1|cut
  # 2|color
  # 3|shave
  # This whole multiline string is stored in the Bash variable SERVICES
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # Echo the SERVICES string, and pipe each line into a loop
  # IFS="|" tells read to split each line using the pipe (|) character
  # Each line will be split into two variables: ID (e.g., 1) and NAME (e.g., cut)
  echo "$SERVICES" | while IFS="|" read ID NAME
  do
    # $ID = the service ID from the database (e.g., 1, 2, 3)
    # $NAME = the name of the service (e.g., cut, color, shave)
    # Print each service in the format: 1) cut, 2) color, etc.
    echo "$ID) $NAME"
  done
}

GET_SERVICE() {
  # Start an infinite loop to repeatedly ask the user to pick a valid service
  while true
  do
    # Call the DISPLAY_SERVICES function to show the list of available services
    DISPLAY_SERVICES

    # Prompt the user to enter the number of the service they want
    echo -e "\nPlease select a service by entering the number:"

    # Read the user's input into the variable SERVICE_ID_SELECTED
    # Example: if the user enters 1, then SERVICE_ID_SELECTED=1
    read SERVICE_ID_SELECTED

    # Run a SQL query to get the service name for the entered ID
    # The result is stored in SERVICE_NAME
    # Example: if the user entered 1, SERVICE_NAME might be 'cut'
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

    # Check if SERVICE_NAME is not empty
    # If it has a value (i.e., the service exists), break out of the loop
    if [[ -n $SERVICE_NAME ]]
    then
      break  # Valid service selected, exit the loop
    else
      # If SERVICE_NAME is empty (invalid ID), show error and repeat
      echo -e "\nInvalid service. Please try again.\n"
    fi
  done
}

# Call the GET_SERVICE function to display services and get a valid selection
GET_SERVICE

# Prompt the user to enter their phone number
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE
# CUSTOMER_PHONE now holds the phone number entered by the user, e.g., "555-555-5555"

# Query the database to find the customer's name based on the entered phone number
# If the phone number exists, CUSTOMER_NAME will hold their name, e.g., "Fabio"
# If the phone number does not exist, CUSTOMER_NAME will be empty
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

# Check if CUSTOMER_NAME is empty (i.e., phone number not found in the database)
if [[ -z $CUSTOMER_NAME ]]
then
  # Since the phone number is new, ask for the customer's name
  echo -e "\nWhat's your name?"
  read CUSTOMER_NAME
  # Insert the new customer record into the customers table with the provided phone and name
  INSERT_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
fi

# Retrieve the customer_id for the customer with the given phone number
# This works for both new and existing customers
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

# Prompt the user for the appointment time, referencing the selected service and customer's name
echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME
# SERVICE_TIME now holds the desired appointment time, e.g., "10:30"

# Insert a new appointment record with customer_id, service_id, and time into the appointments table
INSERT_APPT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

# Confirm the appointment to the user with a personalized message
echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
