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

    # Insert data loop
    while true; do
        local data=""

        # Collect primary key value if a primary key is specified
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

        # Ask if the user wants to add another row
        read -p "Do you want to add another row? (y/n): " add_another
        if [[ "$add_another" != "y" ]]; then
            break
        fi
    done
}



# Function to display table data

display_table_data() {
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

    # Prompt for filtering conditions
    local filter_conditions=""
    if [[ -n "$primary_key_name" ]]; then
        read -p "Enter value for primary key '$primary_key_name' to filter (or press Enter to skip): " filter_value
        if [[ -n "$filter_value" ]]; then
            filter_conditions="^$filter_value,"
        fi
    fi

    # Display data based on filtering conditions
    echo "Data from table '$table_name':"
    local data_file="$DB_PATH/$db_name/$table_name.data.csv"
    if [[ -f "$data_file" ]]; then
        if [[ -s "$data_file" ]]; then
            if [[ -n "$filter_conditions" ]]; then
                grep "$filter_conditions" "$data_file"
            else
                cat "$data_file"
            fi
        else
            echo "Table '$table_name' is empty."
        fi
    else
        echo "Data file for table '$table_name' does not exist."
    fi
}

# Function to select data from a table
select_from_table() {
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

    # Prompt for filtering conditions
    local filter_conditions=""
    if [[ -n "$primary_key_name" ]]; then
        read -p "Enter value for primary key '$primary_key_name' to filter (or press Enter to skip): " filter_value
        if [[ -n "$filter_value" ]]; then
            filter_conditions="^$filter_value,"
        fi
    fi

    # Display data based on filtering conditions
    echo "Data from table '$table_name':"
    local data_lines
    if [[ -n "$filter_conditions" ]]; then
        data_lines=$(grep "$filter_conditions" "$DB_PATH/$db_name/$table_name.data.csv")
    else
        data_lines=$(cat "$DB_PATH/$db_name/$table_name.data.csv")
    fi

    if [[ -n "$data_lines" ]]; then
        # Display column headers
        echo "${column_names[*]}"
        echo "$data_lines"
    else
        echo "No data found matching the provided conditions."
    fi
}

# Function to delete data from a table
delete_from_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if ! table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    local pk_column
    read -r pk_column < "$DB_PATH/$db_name/$table_name.schema"
    pk_column=${pk_column#primary_key:}

    if [[ -n "$pk_column" ]]; then
        read -p "Enter value for primary key '$pk_column': " pk_value
        if ! grep -q "^$pk_value," "$DB_PATH/$db_name/$table_name.data.csv"; then
            echo "Primary key '$pk_value' does not exist."
            return 1
        fi
        awk -F',' -v pk="$pk_value" '{ if ($1 != pk) print $0 }' "$DB_PATH/$db_name/$table_name.data.csv" > "$DB_PATH/$db_name/$table_name.tmp.csv"
        mv "$DB_PATH/$db_name/$table_name.tmp.csv" "$DB_PATH/$db_name/$table_name.data.csv"
        echo "Row with primary key '$pk_value' deleted."
    else
        echo "No primary key defined for the table."
        echo "Enter conditions to identify rows to delete (format: column_name=value):"
        local conditions
        read -p "Conditions: " conditions

        local filter_cmd="awk -F',' '"
        IFS=, read -r -a conditions_array <<< "$conditions"
        for cond in "${conditions_array[@]}"; do
            local col
            local val
            IFS='=' read -r col val <<< "$cond"
            local col_index
            col_index=$(head -n 1 "$DB_PATH/$db_name/$table_name.data.csv" | tr ',' '\n' | nl -v 0 | grep "$col" | awk '{print $1}')
            if [[ -z "$col_index" ]]; then
                echo "Column '$col' not found."
                return 1
            fi
            filter_cmd+="\$${col_index} == \"$val\" && "
        done
        filter_cmd+="1'"

        awk -F',' -v filter_cmd="$filter_cmd" '{ if (eval(filter_cmd)) print $0 }' "$DB_PATH/$db_name/$table_name.data.csv" > "$DB_PATH/$db_name/$table_name.tmp.csv"
        mv "$DB_PATH/$db_name/$table_name.tmp.csv" "$DB_PATH/$db_name/$table_name.data.csv"
        echo "Rows matching conditions deleted."
    fi
}

# Function to update data in a table
update_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if ! table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    local pk_column
    read -r pk_column < "$DB_PATH/$db_name/$table_name.schema"
    pk_column=${pk_column#primary_key:}

    if [[ -n "$pk_column" ]]; then
        read -p "Enter value for primary key '$pk_column': " pk_value
        if ! grep -q "^$pk_value," "$DB_PATH/$db_name/$table_name.data.csv"; then
            echo "Primary key '$pk_value' does not exist."
            return 1
        fi

        local columns
        columns=$(tail -n +2 "$DB_PATH/$db_name/$table_name.schema")

        local tmp_file="$DB_PATH/$db_name/$table_name.tmp.csv"
        > "$tmp_file"

        while IFS=, read -r id rest; do
            if [[ "$id" == "$pk_value" ]]; then
                echo "Enter new data for columns: "
                local data
                while IFS=: read -r column_name column_type; do
                    read -p "$column_name ($column_type): " value
                    if [[ "$column_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                        echo "Invalid input for $column_name: expected integer."
                        return 1
                    elif [[ "$column_type" == "date" && ! "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                        echo "Invalid input for $column_name: expected date in YYYY-MM-DD format."
                        return 1
                    elif [[ "$column_type" == "string" && -z "$value" ]]; then
                        echo "Invalid input for $column_name: expected non-empty string."
                        return 1
                    fi
                    data+="$value,"
                done <<< "$columns"
                data=${data%,}
                echo "$pk_value,$data" >> "$tmp_file"
            else
                echo "$id,$rest" >> "$tmp_file"
            fi
        done < "$DB_PATH/$db_name/$table_name.data.csv"

        mv "$tmp_file" "$DB_PATH/$db_name/$table_name.data.csv"
        echo "Data updated in table '$table_name'."
    else
        echo "No primary key defined for the table."
        echo "Enter conditions to identify rows to update (format: column_name=value):"
        local conditions
        read -p "Conditions: " conditions

        local filter_cmd="awk -F',' '"
        IFS=, read -r -a conditions_array <<< "$conditions"
        for cond in "${conditions_array[@]}"; do
            local col
            local val
            IFS='=' read -r col val <<< "$cond"
            local col_index
            col_index=$(head -n 1 "$DB_PATH/$db_name/$table_name.data.csv" | tr ',' '\n' | nl -v 0 | grep "$col" | awk '{print $1}')
            if [[ -z "$col_index" ]]; then
                echo "Column '$col' not found."
                return 1
            fi
            filter_cmd+="\$${col_index} == \"$val\" && "
        done
        filter_cmd+="1'"

        local tmp_file="$DB_PATH/$db_name/$table_name.tmp.csv"
        > "$tmp_file"

        while IFS=, read -r row; do
            if echo "$row" | eval "$filter_cmd" > /dev/null; then
                echo "Updating row matching conditions: $row"
                local updated_data
                local columns
                columns=$(head -n 1 "$DB_PATH/$db_name/$table_name.data.csv" | tr ',' '\n')
                for col in $columns; do
                    read -p "$col: " value
                    local col_type
                    col_type=$(grep "^$col:" "$DB_PATH/$db_name/$table_name.schema" | cut -d':' -f2)
                    if [[ "$col_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                        echo "Invalid input for $col: expected integer."
                        return 1
                    elif [[ "$col_type" == "date" && ! "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                        echo "Invalid input for $col: expected date in YYYY-MM-DD format."
                        return 1
                    elif [[ "$col_type" == "string" && -z "$value" ]]; then
                        echo "Invalid input for $col: expected non-empty string."
                        return 1
                    fi
                    row=$(echo "$row" | sed "s/\([^,]*\),\([^,]*\),/\1,$value,/") # Replace data
                done
                echo "$row" >> "$tmp_file"
            else
                echo "$row" >> "$tmp_file"
            fi
        done < "$DB_PATH/$db_name/$table_name.data.csv"

        mv "$tmp_file" "$DB_PATH/$db_name/$table_name.data.csv"
        echo "Data updated in table '$table_name'."
    fi
}