*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Desktop
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             my_python_file.py


*** Variables ***
${URL}                          https://robotsparebinindustries.com/#/robot-order
${CSV_FILE_URL}                 https://robotsparebinindustries.com/orders.csv
${CSV_FILE_NAME}                orders.csv
${MODAL_BTN}                    css:.btn.btn-dark
${MODAL_CONTENT}                class:modal-content
${ORDER_BTN}                    id:order
${ORDER_ANOTHER_BTN}            id:order-another
${ALERT_DANGER}                 css:.alert.alert-danger
${ALERT_SUCCESS}                id:receipt
${ORDER_ID}                     class:badge.badge-success
${IMAGE_LOCATOR}                //*[@id="robot-preview-image"]
${GLOBAL_RETRY_AMOUNT}          5x
${GLOBAL_RETRY_INTERVAL}        1s
${OUTPUT_TEMP_DIR}              ${OUTPUT_DIR}${/}temp
${OUTPUT_TEMP_RECEIPT_DIR}      ${OUTPUT_TEMP_DIR}${/}receipt


*** Tasks ***
Suite setup
    Cleanup temporary PDF directory
    Set up directories

Order robots from RobotSpareBin Industries Inc
    ${orders}=    Get Orders
    Log    ${orders}
    Open order page and keep checking until success
    FOR    ${order}    IN    @{orders}
        Close modal
        Fill the form and submit order    ${order}
        Store the receipt as a PDF file    ${order}
        Order another robot
    END
    Create ZIP package from PDF files
    [Teardown]    Close All Browsers


*** Keywords ***
# Setup

Cleanup temporary PDF directory
    Remove Directory    ${OUTPUT_TEMP_DIR}    ${True}

Set up directories
    Create Directory    ${OUTPUT_TEMP_DIR}
    Create Directory    ${OUTPUT_TEMP_RECEIPT_DIR}

# Create orders

Get Orders
    Download    ${CSV_FILE_URL}    overwrite=${True}
    ${orders}=    Read Table From CSV    ${CSV_FILE_NAME}
    RETURN    ${orders}

Open order page and keep checking until success
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Open Order Page    ${URL}

Open order page
    [Arguments]    ${website}
    Open Available Browser    ${website}    browser_selection=Edge
    Wait Until Element Is Visible    ${ORDER_BTN}
    Wait Until Element Is Visible    ${MODAL_CONTENT}

Close modal
    Click Button    ${MODAL_BTN}
    Wait Until Element Is Not Visible    ${MODAL_CONTENT}

Fill the form and submit order
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    id-body-${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Submit order

Submit order
    Click Button    ${ORDER_BTN}
    Check alert and click order button

Check alert and click order button
    ${alert_status}=    Does Page Contain Element    ${ALERT_DANGER}
    Log    ${alert_status}
    IF    ${alert_status} == $True
        Click Button    ${ORDER_BTN}
        Check alert and click order button
    END

Order another robot
    Wait Until Element Is Visible    ${ORDER_ANOTHER_BTN}
    Click Button    ${ORDER_ANOTHER_BTN}
    Wait Until Element Is Visible    ${ORDER_BTN}
    Wait Until Element Is Visible    ${MODAL_CONTENT}

# Create and store the receipt

Store the receipt as a PDF file
    [Arguments]    ${order}
    ${image}=    Take screenshot of robot    ${order}
    Change image size    ${image}
    ${pdf}=    Make receipts information as PDF    ${order}
    ${id_number}=    Get Text    ${ORDER_ID}
    ${new_pdf}=    Create List
    ...    ${pdf}
    ...    ${image}
    ${output_file}=    Set Variable    ${OUTPUT_TEMP_RECEIPT_DIR}${/}${id_number}.pdf
    Add Files To Pdf    ${new_pdf}    ${output_file}

Make receipts information as PDF
    [Arguments]    ${order}
    Wait Until Element Is Visible    ${ALERT_SUCCESS}
    ${order_number}=    Set Variable    ${order}[Order number]
    ${receipt_html}=    Get Element Attribute    ${ALERT_SUCCESS}    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_TEMP_DIR}${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Take screenshot of robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[1]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[2]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]/img[3]
    ${order_number}=    Set Variable    ${order}[Order number]
    ${image_path}=    Screenshot
    ...    ${IMAGE_LOCATOR}
    ...    ${OUTPUT_TEMP_DIR}${/}image_${order_number}.png
    RETURN    ${image_path}

Change image size
    [Arguments]    ${image_path}
    ${size}=    Set Variable    (100, 100)
    Resize Image    ${image_path}    ${image_path}    ${size}

# ZIP package

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_TEMP_RECEIPT_DIR}
    ...    ${zip_file_name}
