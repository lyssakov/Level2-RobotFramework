*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Playwright
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Smartsheet
Library    RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Fill the form and save the receipt as a PDF file    ${orders}


*** Keywords ***
Open the robot order website
    Open Browser    https://robotsparebinindustries.com/#/robot-order    webkit

Get orders
    RPA.HTTP.Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    RPA.Tables.Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click    button[type="button"].btn.btn-dark

Fill the form and save the receipt as a PDF file
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Select Options By    select[id="head"]    value    ${order}[Head]
        Click    css=input[type="radio"][value="${order}[Body]"]
        Fill Text    input[type="number"]    ${order}[Legs]
        Fill Text    input[id="address"]    ${order}[Address]
        Click    button[id="preview"]
        ${img_path}=    Set Variable    ${OUTPUT_DIR}${/}img${/}order_robot_${order["Order number"]}.png
        Take Screenshot    selector=div#robot-preview-image    filename=${img_path}
        Wait Until Keyword Succeeds    5x    3 sec    Click    button[id="order"]
        ${alert_count}=    Get Element Count    css=div[class].alert.alert-danger
        WHILE    ${alert_count} > 0
            Click    button[id="order"]
            ${alert_count}=    Get Element Count    css=div[class].alert.alert-danger
        END
        Wait For Elements State    selector=id=receipt
        ${pdf_html}=    Get Property    id=receipt    outerHTML
        ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}Docs${/}order_result_${order["Order number"]}.pdf
        Html To Pdf    ${pdf_html}    ${pdf_path}
        Open Pdf    ${pdf_path}
        ${files}=    Create List    ${img_path}
        Add Files To Pdf    ${files}    ${pdf_path}    append=True
        Close Pdf    ${pdf_path}
        Click    button[id="order-another"]
    END
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Docs    ${OUTPUT_DIR}${/}Docs${/}pdfs.zip
