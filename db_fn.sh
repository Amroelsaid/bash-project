#!/bin/bash

# Function to check if a database exists
db_exists() {
    local db_name="$1"
    [[ -d "$DB_PATH/$db_name" ]]
}

# Function to list all databases
list_dbs() {
    echo "Databases:"
    ls -1 "$DB_PATH"
}

# Function to create a new database
create_db() {
    read -p "Enter database name: " db_name
    if [[ -z "$db_name" ]]; then
        echo "Database name is required."
        return 1
    fi
    if db_exists "$db_name"; then
        echo "Database '$db_name' already exists."
        return 1
    fi
    mkdir -p "$DB_PATH/$db_name"
    echo "Database '$db_name' created."
}

# Function to drop a database
drop_db() {
    read -p "Enter database name to drop: " db_name
    if db_exists "$db_name"; then
        rm -r "$DB_PATH/$db_name"
        echo "Database '$db_name' dropped."
    else
        echo "Database '$db_name' does not exist."
    fi
}

# Function to connect to a specific database
connect_db() {
    read -p "Enter database name to connect to: " db_name
    if db_exists "$db_name"; then
        echo "Connecting to database '$db_name'..."
        db_menu "$db_name"
    else
        echo "Database '$db_name' does not exist."
    fi
}
