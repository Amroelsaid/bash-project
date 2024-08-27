#!/bin/bash

# Function to display the database menu
db_menu() {
    local db_name="$1"
    while true; do
        echo "Database Menu:"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert Into Table"
        echo "5. Select From Table"
        echo "6. Update Table"
        echo "7. Delete From Table"
        echo "8. Display Table Data"
        echo "9. Return to Main Menu"
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) create_table "$db_name" ;;
            2) list_tables "$db_name" ;;
            3) drop_table "$db_name" ;;
            4) insert_into_table "$db_name" ;;
            5) select_from_table "$db_name" ;;
            6) update_table "$db_name" ;;
            7) delete_from_table "$db_name" ;;
            8) display_table_data "$db_name" ;;
            9) break ;;
            *) echo "Invalid option, try again." ;;
        esac
    done
}

# Function to check if a table exists
table_exists() {
    local db_name="$1"
    local table_name="$2"
    [[ -f "$DB_PATH/$db_name/$table_name.schema" ]]
}

# Function to create a new table
create_table() {
    local db_name="$1"
    
    # Request table name from user
    read -p "Enter table name: " table_name
    if [[ -z "$table_name" ]]; then
        echo "Table name cannot be empty."
        return 1
    fi

    # Check if the table already exists
    if table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' already exists."
        return 1
    fi

    read -p "Enter number of columns: " num_columns
    if [[ ! "$num_columns" =~ ^[0-9]+$ ]] || [ "$num_columns" -le 0 ]; then
        echo "Invalid number of columns."
        return 1
    fi

    local columns=""
    local column_name
    local column_type
    local column_definitions

    for i in $(seq 1 $num_columns); do
        echo "Column $i:"
        read -p "Enter column name: " column_name
        read -p "Enter column type (string/int): " column_type
        if [[ "$column_type" != "string" && "$column_type" != "int" ]]; then
            echo "Invalid column type."
            return 1
        fi
        columns+="$column_name:$column_type\n"
    done

    # Ask if the user wants to specify a primary key
    read -p "Do you want to specify a primary key? (y/n): " pk_choice
    if [[ "$pk_choice" == "y" ]]; then
        read -p "Enter column name for primary key: " pk_column
        if ! echo -e "$columns" | grep -q "^$pk_column:"; then
            echo "Column '$pk_column' does not exist."
            return 1
        fi
        primary_key="primary_key:$pk_column"
    else
        primary_key=""
    fi

    # Write schema to file
    echo -e "$primary_key\n$columns" > "$DB_PATH/$db_name/$table_name.schema"
    touch "$DB_PATH/$db_name/$table_name.data.csv"
    echo "Table '$table_name' created in database '$db_name'."
}

# Function to list all tables in a database
list_tables() {
    local db_name="$1"
    echo "Tables in database '$db_name':"
    ls -1 "$DB_PATH/$db_name" | grep '.schema$' | sed 's/.schema$//'
}

# Function to drop a table
drop_table() {
    local db_name="$1"
    read -p "Enter table name to drop: " table_name
    if table_exists "$db_name" "$table_name"; then
        rm "$DB_PATH/$db_name/$table_name.schema"
        rm "$DB_PATH/$db_name/$table_name.data.csv"
        echo "Table '$table_name' dropped."
    else
        echo "Table '$table_name' does not exist."
    fi
}
