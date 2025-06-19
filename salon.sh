#!/bin/bash

# Define a variable for the PSQL command with specific flags for output formatting.
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

# Display the welcome message for the salon.
echo -e "\n~~~~~ MY SALON ~~~~~\n"

# Define the main menu function, which is the core of the script's interaction.
MAIN_MENU() {
  # If a message is passed as an argument, display it (e.g., for error messages).
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Greet the user.
  echo "Welcome to My Salon, how can I help you?"

  # Retrieve the list of services from the database, sorted by service_id.
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  
  # Loop through the retrieved services and display them as a numbered list.
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  # Prompt the user to select a service by entering the corresponding number.
  read SERVICE_ID_SELECTED

  # Validate that the input is a number. If not, show an error and restart the menu.
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "That is not a valid service number."
  else
    # Check if the selected service ID exists in the database.
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    
    # If the service ID does not exist, show an error and restart the menu.
    if [[ -z $SERVICE_NAME ]]
    then
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      # Prompt the user for their phone number.
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      # Check if the phone number exists in the customers table.
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      
      # If the phone number is not found, prompt the user to enter their name.
      if [[ -z $CUSTOMER_NAME ]]
      then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME

        # Insert the new customer into the customers table.
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      fi

      # Retrieve the customer_id of the user based on the phone number.
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
      
      # Prompt the user to enter the time they would like the service.
      echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
      read SERVICE_TIME

      # Insert the appointment into the appointments table.
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
      
      # Confirm the appointment to the user.
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

# Call the main menu function to start the script.
MAIN_MENU
