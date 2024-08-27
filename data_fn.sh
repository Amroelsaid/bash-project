#!/bin/bash

# Function to check if a table exists
table_exists() {
    local db_name="$1"
    local table_name="$2"
    [[ -f "$DB_PATH/$db_name/$table_name.schema" ]]
}

# Function to insert data into a table
insert_into_table() {
    local db_name="$1"
    
    # Request table name from user
    read -p "Enter table name: " table_name
    if [[ -z "$table_name" ]]; then
        echo "Table name cannot be empty."
        return 1
    fi

    local schema_file="$DB_PATH/$db_name/$table_name.schema"
    local data_file="$DB_PATH/$db_name/$table_name.data.csv"
    
    # Check if the table exists
    if [[ ! -f "$schema_file" ]]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    # Read schema to get column names, types, and primary key
    local column_names=()
    local column_types=()
    local primary_key=""
    while IFS=: read -r column_name column_type; do
        if [[ $column_name == "primary_key" ]]; then
            primary_key=$column_type
        else
            column_names+=("$column_name")
            column_types+=("$column_type")
        fi
    done < "$schema_file"

    # Insert data
    while true; do
        local row_data=""
        local pk_value=""

        # Collect data for each column
        for i in "${!column_names[@]}"; do
            local column_name="${column_names[$i]}"
            local column_type="${column_types[$i]}"
            
            read -p "Enter data for column '${column_name}' (${column_type}): " value
            
            # Validate data based on column type
            if [[ "$column_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Invalid input for column '${column_name}': expected integer."
                return 1
            elif [[ "$column_type" == "string" && -z "$value" ]]; then
                echo "Invalid input for column '${column_name}': expected non-empty string."
                return 1
            fi
            
            row_data+="$value,"
            
            # Check primary key
            if [[ "$column_name" == "$primary_key" ]]; then
                pk_value="$value"
            fi
        done
        
        # Remove trailing comma and check for primary key uniqueness
        row_data=${row_data%,}
        if [[ -n "$pk_value" ]]; then
            if grep -q "^$pk_value," "$data_file"; then
                echo "Primary key value '$pk_value' already exists."
                return 1
            fi
        fi

        echo "$row_data" >> "$data_file"
        echo "Data inserted into table '$table_name'."
        
        read -p "Do you want to add another row? (yes/no): " add_more
        if [[ "$add_more" != "yes" ]]; then
            break
        fi
    done
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
