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

    # Read schema to get column names and types
    local column_names=()
    local column_types=()
    while IFS=: read -r column_name column_type; do
        column_names+=("$column_name")
        column_types+=("$column_type")
    done < "$schema_file"

    echo "Available columns for insertion:"
    for i in "${!column_names[@]}"; do
        echo "$i: ${column_names[$i]} (${column_types[$i]})"
    done

    # Insert data
    while true; do
        local row_data=""
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
        done
        
        # Remove trailing comma and append to data file
        row_data=${row_data%,}
        echo "$row_data" >> "$data_file"

        echo "Data inserted into table '$table_name'."
        
        read -p "Do you want to add another row? (yes/no): " add_more
        if [[ "$add_more" != "yes" ]]; then
            break
        fi
    done
}