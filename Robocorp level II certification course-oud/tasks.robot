*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Playwright
Library    Dialogs
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.FileSystem
Library    RPA.PDF


*** Keywords ***
Open the robot order website
    New Browser    chromium    headless=false    
    New Context    viewport={'width': 1920, 'height': 1080}     acceptDownloads=true
    New Page       https://robotsparebinindustries.com/#/robot-order
    

Get Orders
    RPA.HTTP.Download    url=https://robotsparebinindustries.com/orders.csv    overwrite=True    target_file=orders.csv
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click    text="OK"     #weghalen dialoogvenster met aantal knoppen

Go to order another robot
    Go to    https://robotsparebinindustries.com/#/robot-order

Fill the form
    [Arguments]    ${row}
    Log    ${row}[Order number]

    # Selecteer de juiste Head
    Select Options By    css=#head    value    ${row}[Head]

    # Selecteer de juiste Body
    ${BodyRadioButton}=   Catenate        SEPARATOR=    id-body-    ${row}[Body]
    Check Checkbox    //*[@id="${BodyRadioButton}"]

    # Invoer adres
    Type Text    //*[@id="address"]     ${row}[Address]

    # Invoer aantal Legs
    # identificatie van veld wijzigt van run op run, daarom vanaf Address veld naar boven navigeren met keyboard
    Keyboard Key    down    Shift
    Keyboard Key    down    Tab
    Keyboard Key    up      Shift
    Keyboard Input    type    ${row}[Legs]

Preview the robot
    # klik op preview knop
    Click    //*[@id="preview"]

Submit the order
    # klik op order knop, maar dat kan fout gaan dus meerdere pogingen
    Wait Until Keyword Succeeds    10x    3 s    Click    //*[@id="order"]

Maak directory als die nog niet bestaat
    [Arguments]    ${DirectoryNaam}
    ${TargetDirectory}=   Catenate        SEPARATOR=    ${OUTPUT_DIR}${/}    ${DirectoryNaam}
    # maak directory als die nog niet bestaat
    ${DirectoryExists}=    Does Directory Exist    ${TargetDirectory}   
    IF    ${DirectoryExists} == ${False}
        Create Directory    ${TargetDirectory}
    END
    [Return]    ${TargetDirectory}

    
Store the receipt as a PDF file
    [Arguments]    ${Ordernumber}
    # maak target naam
    ${TargetDirectory}=     Maak directory als die nog niet bestaat    receipts
    ${order_results_html}=    Get Property    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${order_results_html}    ${TargetDirectory}${/}${Ordernumber}.pdf
    [Return]     ${TargetDirectory}${/}${Ordernumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${Ordernumber}
     ${TargetDirectory}=     Maak directory als die nog niet bestaat    screenshots
    Take Screenshot     ${TargetDirectory}${/}${Ordernumber}     //*[@id="robot-preview-image"]
    [Return]     ${TargetDirectory}${/}${Ordernumber}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #     Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    # Create a ZIP file of the receipts
    Pause Execution     Succes!

Minimal task
    Log  Done.
