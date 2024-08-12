#!/bin/bash

############################################################
## Import serial numbers from a CSV into a Static Group
## Author: Simon I.
## Version: 2.4 (9th August 2024)
############################################################

#### VARIABLES: ############################################
# Set the CSV file path containing computer serial numbers
CSV_FILE="$1"

# Set the output log files
LOG_DIR="/private/tmp/csv_serialnumber_to_group_logs"
SUCCESS_LOG="$LOG_DIR/successful.log"
FAIL_LOG="$LOG_DIR/failed.log"
VERBOSE_LOG="$LOG_DIR/verbose.log"
###########################################################

#### FUNCTIONS: ###########################################
# Function to check if the file has a .csv extension
check_csv_extension() {
    local file_name="$1"
    ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
    TITLE="CSV File Check"

    if [[ "$file_name" == *.csv ]]; then
        echo "CSV file detected: $file_name" | tee -a "$VERBOSE_LOG"
        /usr/bin/osascript <<END
display dialog "CSV file detected: $file_name" buttons {"OK"} default button "OK" with icon POSIX file "$ICON" with title "$TITLE"
END
    else
        echo "Error: The provided file does not have a .csv extension: $file_name" | tee -a "$FAIL_LOG" "$VERBOSE_LOG"
        /usr/bin/osascript <<END
display dialog "Error: The provided file does not have a .csv extension: $file_name" buttons {"OK"} default button "OK" with icon POSIX file "$ICON" with title "$TITLE"
END
        exit 1
    fi
}

# Function to display the introductory prompt
intro_prompt() {
    if [[ ! -z "$CSV_FILE" ]]; then
        return
    fi

    ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
    RIGHT_BUTTON="Continue"
    TITLE="CSV to Jamf (Serial Number to Static Group)"

    INTRO_MESSAGE=$(/usr/bin/osascript<<END
display dialog "Welcome to the CSV to Jamf Importer!

This application allows you to import Mac computer serial numbers from a CSV file into a Jamf static group. You will be guided through a series of prompts to provide the necessary details." giving up after 999999 \
with icon POSIX file "$ICON" \
buttons {"$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"
END
)
}

# Function to wait for CSV file to be dropped in
wait_for_csv() {
    if [[ -z "$CSV_FILE" ]]; then
        echo "No CSV file provided. Exiting..."
        exit 1
    fi
}

# Function to visually prompt user questions
dialogs() {
    ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
    LEFT_BUTTON="Quit"
    RIGHT_BUTTON="Continue"
    TITLE="CSV to Jamf (Serial Number to Static Group)"

    # Dialog to show user the imported value from the CSV file
    CSV_CONTENTS="$(head -n 52 "$CSV_FILE")"
    DIALOG_SHOW_IMPORT=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Preview of the imported CSV file:

$CSV_CONTENTS" giving up after 999999 \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    return true
else
    return false
end if
END
)

    if [[ "$DIALOG_SHOW_IMPORT" == "false" ]]; then
        echo "User cancelled at CSV preview. Exiting..."
        exit 1
    fi

    # Dialog to prompt for static group number
    COMPUTER_GROUP_ID=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Enter the Static Group ID Number:" giving up after 999999 \
default answer "e.g., 99" \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    return text returned of the result
else
    return false
end if
END
)

    if [[ "$COMPUTER_GROUP_ID" == "false" ]]; then
        echo "User cancelled at Static Group ID prompt. Exiting..."
        exit 1
    fi

# Dialog to prompt for Jamf instance URL
    JAMF_SERVER=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Enter the Jamf URL:" giving up after 999999 \
default answer "https://your-jamf-server.com:8888" \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    set serverURL to text returned of the result
    -- Remove trailing slash if it exists
    if serverURL ends with "/" then
        set serverURL to text 1 thru -2 of serverURL
    end if
    return serverURL
else
    return false
end if
END
)

    if [[ "$JAMF_SERVER" == "false" ]]; then
        echo "User cancelled at Jamf URL prompt. Exiting..."
        exit 1
    fi

    # Dialog to prompt for username
    USERNAME=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Enter your Username:" giving up after 999999 \
default answer "your-username" \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    return text returned of the result
else
    return false
end if
END
)

    if [[ "$USERNAME" == "false" ]]; then
        echo "User cancelled at Username prompt. Exiting..."
        exit 1
    fi

    # Dialog to prompt for password
    PASSWORD=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Enter your Password:" giving up after 999999 \
default answer "" with hidden answer \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    return text returned of the result
else
    return false
end if
END
)

    if [[ "$PASSWORD" == "false" ]]; then
        echo "User cancelled at Password prompt. Exiting..."
        exit 1
    fi

    # Dialog to confirm the entered details
    CONFIRM_DIALOG=$(/usr/bin/osascript<<END
set QUESTION to \
display dialog "Please confirm the details before proceeding:

CSV File: $CSV_FILE

Static Group ID: $COMPUTER_GROUP_ID

Jamf URL: $JAMF_SERVER

Username: $USERNAME" giving up after 999999 \
with icon POSIX file "$ICON" \
buttons {"$LEFT_BUTTON", "$RIGHT_BUTTON"} default button "$RIGHT_BUTTON" \
with title "$TITLE"

if button returned of QUESTION is "$RIGHT_BUTTON" then
    return true
else
    return false
end if
END
)

    if [[ "$CONFIRM_DIALOG" == "false" ]]; then
        echo "User cancelled at confirmation dialog. Exiting..."
        exit
        1
    fi
}

# Function to generate the bearer token
generate_bearer_token() {
    GET_TOKEN=$(curl -s -u "$USERNAME":"$PASSWORD" "$JAMF_SERVER"/api/v1/auth/token -X POST -H "accept: application/json")
    BEARER_TOKEN=$(echo $GET_TOKEN | awk -F '[:,{"}]' ' {print $6} ')
}

# Function to remove the bearer token
invalidate_bearer_token() {
    echo "Invalidating bearer token..." | tee -a "$VERBOSE_LOG"
    RESPONSE_CODE=$(curl -w "%{http_code}" -H "Authorization: Bearer $BEARER_TOKEN" "$JAMF_SERVER/api/v1/auth/invalidate-token" -X POST -s -o /dev/null)
    if [[ "$RESPONSE_CODE" == 204 ]]; then
        echo "Token successfully invalidated." | tee -a "$VERBOSE_LOG"
    elif [[ "$RESPONSE_CODE" == 401 ]]; then
        echo "Token already invalid." | tee -a "$VERBOSE_LOG"
    else
        echo "An unknown error occurred invalidating the token." | tee -a "$VERBOSE_LOG"
    fi
}
############################################################

#### START: ################################################
# Create or truncate the log files
mkdir -p "$LOG_DIR"
> "$SUCCESS_LOG"
> "$FAIL_LOG"
> "$VERBOSE_LOG"

# Display introductory prompt
intro_prompt

# Generate the bearer token
wait_for_csv
check_csv_extension "$CSV_FILE"
dialogs
generate_bearer_token

# Read the CSV file and process each serial number
while IFS=, read -r SERIAL_NUMBER || [[ -n "$SERIAL_NUMBER" ]]
do
    # Build the XML payload for updating the computer group membership
    XML="<computer_group><id>$COMPUTER_GROUP_ID</id><computer_additions><computer><serial_number>$SERIAL_NUMBER</serial_number></computer></computer_additions></computer_group>"

    # Update the computer group using the JAMF API
    RESPONSE=$(curl -s -k -H "Authorization: Bearer $BEARER_TOKEN" "$JAMF_SERVER/JSSResource/computergroups/id/$COMPUTER_GROUP_ID" \
        -H "Content-Type: text/xml" \
        -X PUT -d "$XML")
    # Check if the API request was successful
    if [[ "$RESPONSE" == *"computer_group"* ]]; then
        echo "Successfully added computer with serial number: $SERIAL_NUMBER to group ID: $COMPUTER_GROUP_ID" | tee -a "$SUCCESS_LOG" "$VERBOSE_LOG"
    else
        echo "Failed to add computer with serial number: $SERIAL_NUMBER to group ID: $COMPUTER_GROUP_ID" | tee -a "$FAIL_LOG" "$VERBOSE_LOG"
        echo "Response: $RESPONSE" | tee -a "$VERBOSE_LOG"
    fi
done < "$CSV_FILE"

invalidate_bearer_token

# Open the log directory to review logs
open "$LOG_DIR"

SUCCESS_DIALOG=$(/usr/bin/osascript<<END
set SUCCESS_MESSAGE to "The import process is complete. You can review the logs for more information."
display dialog SUCCESS_MESSAGE buttons {"OK"} default button "OK" with title "Import Complete"
END
)

exit 0
