#!/bin/bash

# Function to check if a table exists
table_exists() {
    local db_name="$1"
    local table_name="$2"
    [[ -f "$DB_PATH/$db_name/$table_name.schema" ]]
}

# Function to insert data into a table
# Function to insert data into a table
insert_into_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name

    # Check if the table exists
    if ! table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    # Extract columns and types from schema
    local columns
    local pk_column
    read -r pk_column < "$DB_PATH/$db_name/$table_name.schema"
    columns=$(tail -n +2 "$DB_PATH/$db_name/$table_name.schema")

    # Read column names and types
    local column_names=()
    local column_types=()
    local primary_key_name=""

    while IFS=: read -r col_name col_type; do
        if [[ "$pk_column" == "primary_key:$col_name" ]]; then
            primary_key_name="$col_name"
        else
            column_names+=("$col_name")
            column_types+=("$col_type")
        fi
    done <<< "$columns"

    # Collect primary key value if a primary key is specified
    local data=""
    if [[ -n "$primary_key_name" ]]; then
        read -p "Enter value for primary key '$primary_key_name': " pk_value
        if grep -q "^$pk_value," "$DB_PATH/$db_name/$table_name.data.csv"; then
            echo "Primary key '$pk_value' already exists."
            return 1
        fi
        data="$pk_value,"
    fi

    # Collect data for other columns
    echo "Enter data for columns: ${column_names[*]}"
    for i in "${!column_names[@]}"; do
        local col_name="${column_names[$i]}"
        local col_type="${column_types[$i]}"

        read -p "$col_name ($col_type): " value

        # Validate the input based on column type
        if [[ "$col_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
            echo "Invalid input for $col_name: expected integer."
            return 1
        elif [[ "$col_type" == "string" && -z "$value" ]]; then
            echo "Invalid input for $col_name: expected non-empty string."
            return 1
        fi

        data+="$value,"
    done
    data=${data%,}  # Remove trailing comma

    # Insert data into table
    echo "$data" >> "$DB_PATH/$db_name/$table_name.data.csv"
    echo "Data inserted into table '$table_name'."
}



# Function to display table data
display_table_data() {
    local db_name="$1"
    
    # Request table name from user
    read -p "Enter table name: " table_name
    if [[ -z "$table_name" ]]; then
        echo "Table name cannot be empty."
        return 1
    fi

    local schema_file="$DB_PATH/$db_name/$table_name.schema"
    local data_file="$DB_PATH/$db_name/$table_name.data.csv"
    
    # Check if the schema and data files exist
    if [[ ! -f "$schema_file" ]]; then
        echo "Schema file for table '$table_name' does not exist."
        return 1
    fi

    if [[ ! -f "$data_file" ]]; then
        echo "Data file for table '$table_name' does not exist."
        return 1
    fi

    # Display the table header (column names)
    echo "Data from table '$table_name':"
    echo -n "Header: "
    local headers
    headers=$(awk -F':' '{print $1}' "$schema_file" | tr '\n' ',')
    echo "${headers%,}"  # Remove trailing comma
    
    # Display the data rows
    echo "Rows:"
    cat "$data_file"
}
