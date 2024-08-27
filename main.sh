#!/bin/bash

DB_PATH="./db"  # Directory where databases and tables will be stored

# Source other scripts
source ./db_fn.sh
source ./table_fn.sh
source ./data_fn.sh

# Function to display the main#!/bin/bash
 menu
main_menu() {
    while true; do
        echo "Main Menu:"
        echo "1. Create Database"
        echo "2. List Databases"
        echo "3. Connect To Database"
        echo "4. Drop Database"
        echo "5. Exit"
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) create_db ;;
            2) list_dbs ;;
            3) connect_db ;;
            4) drop_db ;;
            5) exit 0 ;;
            *) echo "Invalid option, try again." ;;
        esac
    done
}

# Start the script
main_menu
