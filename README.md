# CSV into Jamf

## Overview

Welcome to the **CSV into Jamf** repository! This application is designed to streamline the process of importing Mac computer hostnames and serial numbers from a CSV file into Jamf static groups. Built with a Bash script and enhanced by a GUI frontend, this tool offers an intuitive and efficient way for Jamf engineers and administrators to manage their Mac devices.

![App Screenshot](https://github.com/simon-im-security/CSV-into-Jamf/blob/main/app_screenshot.png)

## Key Features

### 1. **GUI Frontend**
- **User-Friendly Interface**: The application uses `osascript` in combination with `Platypus` to create a series of dialogs that guide the user through the process, making it easy to input necessary details without touching the command line.
  
### 2. **CSV to Jamf Importer (Hostname)**
This feature allows you to import Mac computer hostnames from a CSV file into a Jamf static group. The script:

- **Prompts for User Inputs**: The GUI guides the user through entering the Jamf URL, static group ID, and credentials.
- **Validates CSV Input**: Ensures the CSV file is correctly formatted before processing.
- **Retrieves Serial Numbers**: Automatically fetches the serial number associated with each hostname from Jamf Pro.
- **Updates Jamf Static Groups**: Adds each computer to the specified static group using the retrieved serial numbers.
- **Logs Detailed Information**: Logs all actions, including successes and failures, for troubleshooting.

### 3. **CSV to Jamf Importer (Serial Number)**
This feature directly imports serial numbers from a CSV file into a Jamf static group. The script:

- **Prompts for User Inputs**: The GUI prompts for the Jamf URL, static group ID, and user credentials.
- **Validates CSV Input**: Checks the format of the provided CSV file.
- **Updates Jamf Static Groups**: Directly adds computers to the specified static group based on their serial numbers.
- **Logs Detailed Information**: Comprehensive logging ensures that every step is documented, helping with troubleshooting.

![CSV Format Example](https://github.com/simon-im-security/CSV-into-Jamf/blob/main/csv_example.png)

## Benefits for Jamf Engineers/Admins

As a Jamf engineer or admin, managing static groups can be a repetitive and error-prone task, especially when dealing with large numbers of devices. **CSV into Jamf** helps by:

- **Automating Tedious Tasks**: No more manual entry of hostnames or serial numbers into Jamf static groups. Just provide a CSV file, and the application handles the rest.
- **Reducing Errors**: By automating the process and logging every action, the application helps prevent and diagnose errors that could occur during manual entry.
- **Improving Efficiency**: Quickly import hundreds or thousands of devices into Jamf static groups, freeing up time for more critical tasks.
- **Ensuring Compliance**: Keep your device groups up-to-date with minimal effort, ensuring that policies and configurations are applied consistently across your fleet.

## Contribution

Contributions are welcome! If you have ideas for improvements or new features, feel free to submit a pull request or open an issue.

---

Thank you for using **CSV into Jamf**. We hope this tool helps make your Jamf management tasks easier and more efficient!
