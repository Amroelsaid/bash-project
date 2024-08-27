#!/bin/bash

DB_PATH="./db"  # Directory where databases and tables will be stored

# Function to check if a database exists
db_exists() {
    local db_name="$1"
    [[ -d "$DB_PATH/$db_name" ]]
}

# Function to check if a table exists
table_exists() {
    local db_name="$1"
    local table_name="$2"
    [[ -f "$DB_PATH/$db_name/$table_name.schema" ]]
}

# Function to display the main menu
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
        echo "6. Delete From Table"
        echo "7. Update Table"
        echo "8. Return to Main Menu"
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) create_table "$db_name" ;;
            2) list_tables "$db_name" ;;
            3) drop_table "$db_name" ;;
            4) insert_into_table "$db_name" ;;
            5) select_from_table "$db_name" ;;
            6) delete_from_table "$db_name" ;;
            7) update_table "$db_name" ;;
            8) break ;;
            *) echo "Invalid option, try again." ;;
        esac
    done
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

# Function to list all databases
list_dbs() {
    echo "Databases:"
    ls -1 "$DB_PATH"
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

# Function to create a new table
create_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if [[ -z "$table_name" ]]; then
        echo "Table name is required."
        return 1
    fi
    if table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' already exists."
        return 1
    fi
    
    read -p "Is there a primary key? (y/n): " has_pk
    if [[ "$has_pk" == "y" ]]; then
        read -p "Enter primary key column name: " pk_column
    else
        pk_column=""
    fi

    echo "Enter column names and types (e.g., name:string age:int):"
    local columns
    while IFS=":" read -r col_name col_type; do
        if [[ -z "$col_name" || -z "$col_type" ]]; then
            break
        fi
        if [[ ! "$col_type" =~ ^(int|string|date)$ ]]; then
            echo "Invalid type $col_type. Valid types are: int, string, date."
            return 1
        fi
        columns+="$col_name:$col_type"$'\n'
    done

    echo "primary_key:$pk_column" > "$DB_PATH/$db_name/$table_name.schema"
    echo "$columns" >> "$DB_PATH/$db_name/$table_name.schema"
    
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

# Function to insert data into a table
insert_into_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if ! table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' does not exist."
        return 1
    fi
    
    local columns
    local pk_column
    read -r pk_column < "$DB_PATH/$db_name/$table_name.schema"
    pk_column=${pk_column#primary_key:}
    columns=$(tail -n +2 "$DB_PATH/$db_name/$table_name.schema")

    echo "Enter data for columns: "
    local data
    IFS=$'\n'
    for col in $(echo "$columns" | awk -F':' '{print $1}'); do
        local col_type
        col_type=$(grep "^$col:" "$DB_PATH/$db_name/$table_name.schema" | cut -d':' -f2)
        read -p "$col ($col_type): " value
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
        data+="$value,"
    done <<< "$columns"
    data=${data%,}

    if [[ -n "$pk_column" ]]; then
        local pk_value
        read -p "Enter value for primary key '$pk_column': " pk_value
        if grep -q "^$pk_value," "$DB_PATH/$db_name/$table_name.data.csv"; then
            echo "Primary key '$pk_value' already exists."
            return 1
        fi
        echo "$pk_value,$data" >> "$DB_PATH/$db_name/$table_name.data.csv"
    else
        echo "$data" >> "$DB_PATH/$db_name/$table_name.data.csv"
    fi
    echo "Data inserted into table '$table_name'."
}

# Function to select data from a table
select_from_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if ! table_exists "$db_name" "$table_name"; then
        echo "Table '$table_name' does not exist."
        return 1
    fi
    
    local columns
    columns=$(tail -n +2 "$DB_PATH/$db_name/$table_name.schema")
    local column_names
    column_names=$(echo "$columns" | awk -F':' '{print $1}' | tr '\n' ' ')

    echo "Enter conditions to filter rows (format: column_name=value):"
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

    awk -F',' -v OFS=',' '
    BEGIN {
        print "Data:"
    }
    ' "$DB_PATH/$db_name/$table_name.data.csv" | eval "$filter_cmd"
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

# Start the script by displaying the main menu
main_menu
