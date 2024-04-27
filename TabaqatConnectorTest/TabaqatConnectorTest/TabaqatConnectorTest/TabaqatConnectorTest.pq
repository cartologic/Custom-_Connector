[version = "1.0.0"]
section TabaqatConnector;
/* - DataSource.Kind is a unique identifier for your connector 
   - The Publish key links to additional metadata about 
    how your connector should be presented within Power BI.*/
[DataSource.Kind="TabaqatConnector", Publish="TabaqatConnector.Publish"]

/*  defining how your custom connector's data appears and behaves in Power BI, enabling users to navigate and retrieve
    data from your data source in an intuitive and structured manner.*/
shared TabaqatConnector.Contents = Value.ReplaceType(NavigationTable.Nested, Meta_data);
//----------------------------------------------------------------------------------------------------------
// Define the Meta_data function, which provides metadata about the connector.
Meta_data = type function (
    // Define the input parameter access_token with metadata.
    access_token as (type text meta [
        // Specify the field caption for the access_token parameter.
        Documentation.FieldCaption = "API Key-for more info, visit: platform.tabaqat.net ",

        // Provide a description for the access_token parameter.
        Documentation.FieldDescription = "Api Key",

        // Provide sample values for the access_token parameter.
        Documentation.SampleValues = {"tabaqat-xxxxxxxxxxxxxxxxxxxxx"}
    ])  
) as table meta [
    Documentation.Name = "Tabaqat Connector",
    // Define the TestConnection function to validate the access token.
    TestConnection = (dataSourcePath) =>
        let
            // Validate the access token by calling the ValidateAccessToken function.
            isValidToken = ValidateAccessToken("access token"),

            // Create a result record indicating the success or failure of the test connection.
            result = [
                TestConnectionResult = if isValidToken then "Success" else "Invalid access token"
            ]
        in
            // Return the result
            result
];

//----------------------------------------------------------------------------------------------------------
// Define the ValidateAccessToken function, which validates the provided access token.
ValidateAccessToken = (access_token as text) as logical =>
    let
        // Construct the URL for token validation using the provided access token.
        tokenValidationUrl = "https://gogateway.tabaqat.net/verify-token?access_token=" & access_token,

        // Make an HTTP GET request to the token validation endpoint.
        validationResponse = Web.Contents(tokenValidationUrl),

        // Parse the JSON response into a structured record.
        validationJson = Json.Document(validationResponse),

        // Check if the access token is valid by verifying specific fields in the JSON response.
        isValidToken = validationJson[active_key] = true and validationJson[wfs] = true
    in
        // Return a logical value indicating whether the access token is valid.
        isValidToken;

//----------------------------------------------------------------------------------------------------------
 /*Main Connector Function
 Fetching Workspaces from 'Dirictus'
 takes an access_token as input and returns a table as output*/
NavigationTable.Nested = (access_token as text) as table =>
let
    // Validate the access token.
    isValidToken = ValidateAccessToken(access_token),

    // Define the navTable variable to store the resulting navigation table.
    navTable = 
    if isValidToken then
        let
            // Define the URL to fetch workspace data
            workspacesUrl = "https://catalog.tabaqat.net/items/workspace?fields=name,translations.title&deep[translations][_filter][languages_code][_eq]=en-US&filter[status]=published",
            
            // use Web.Contents to make an HTTP GET request (retrive json data about workspaces from tabaqat API)
            workspaceResponse = Web.Contents(workspacesUrl),

            // This makes the JSON data structured and queryable within Power Query.
            workspaceJson = Json.Document(workspaceResponse),

            //Converts the JSON data into a Power Query table
            workspaceTable = Table.FromList(workspaceJson[data], Splitter.SplitByNothing(), null, null, ExtraValues.Error),

            /*Expands the columns within the JSON data to make the name and translations.title fields of each workspace
            directly accessible as columns in the table.*/
            workspaceExpand = Table.ExpandRecordColumn(workspaceTable, "Column1", {"name", "translations.title"}, {"Workspace Name", "Workspace Title"}),
            
            // Converts the expanded workspace table into a list of records.
            workspaceObjects = Table.ToRecords(workspaceExpand),

            //Transforming workspaces into navigation table
            objects = List.Transform(
                workspaceObjects,
                each {
                    Text.Replace([Workspace Name], "-", " "),// Adjust workspace name format if needed.
                    [Workspace Name] & "_layers", // Define key for layers of each workspace.
                    CreateNavTable([Workspace Name], access_token), // Fetch layers and create navigation table.
                    "Folder",  // Define the item kind as a folder.
                    "Folder", // Define the item name as a folder.
                    false // Indicate that the item is not a leaf (it contains sub-items).
                }
            ),
            // Convert the list of workspace objects into a navigation table.
            NavTable = Table.ToNavigationTable(#table({"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}, objects), {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
        in
            // Return the navigation table.
            NavTable
    else
          // Return an error if the access token is invalid.
          error "Invalid access token or usage limit exceeded. For more information, visit: platform.tabaqat.net"
in
    // Return the resulting navigation table.
    navTable;
//----------------------------------------------------------------------------------------------------------
//function to add second level "url for each workspaces" ya ali 

Table.ToNavigationTable = (
    // Input parameters for the function
    table as table, // Input table to be converted
    keyColumns as list, // List of key columns for the navigation table
    nameColumn as text, // Name of the column containing item names
    dataColumn as text, // Name of the column containing data
    itemKindColumn as text, // Name of the column containing item kinds
    itemNameColumn as text, // Name of the column containing item names
    isLeafColumn as text // Name of the column indicating whether an item is a leaf

) as table =>
    let
        // Get the type of the input table
        tableType = Value.Type(table),

        // Add key columns to the table type
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta
        [
            // Set metadata attributes for navigation table
            NavigationTable.NameColumn = nameColumn, // Specify the name column
            NavigationTable.DataColumn = dataColumn,// Specify the name column
            NavigationTable.ItemKindColumn = itemKindColumn, // Specify the item kind column
            Preview.DelayColumn = itemNameColumn, // Specify the item name column for preview
            NavigationTable.IsLeafColumn = isLeafColumn,// Specify the isLeaf column
            NavigationTable.NavigateToPreview = true // Enable navigation to preview when clicking on an item
        ],
        // Replace the type of the input table with the new table type
        navigationTable = Value.ReplaceType(table, newTableType)
    in
      // Return the navigation table
      navigationTable;

//----------------------------------------------------------------------------------------------------------
/*Fetching layers for each workspace
CreateNavTable is a helper function that fetches and processes the layers belonging to a given workspace.
involves making another web request.*/
CreateNavTable = (workspaceName as text, access_token as text) as table =>
    let
        // Construct the URL to fetch layer data for the given workspace
        layerUrl = "https://catalog.tabaqat.net/items/layer?fields=workspace.translations.title,workspace.name,name,translations.title&filter[status][_eq]=published&deep[translations][_filter][languages_code][_eq]=en-US&deep[workspace][translations][_filter][languages_code][_eq]=en-US&limit=1000&filter[workspace][name]=" & workspaceName,
        //Makes an HTTP GET request
        layerResponse = Web.Contents(layerUrl),

        // Parse the JSON response into a structured Power Query table
        layerJson = Json.Document(layerResponse),

        //Converts the JSON data into a Power Query table.
        layerTable = Table.FromList(layerJson[data], Splitter.SplitByNothing(), null, null, ExtraValues.Error),

        // Expand the columns within the JSON data to access layer properties
        layerExpand = Table.ExpandRecordColumn(layerTable, "Column1", {"name", "translations"}, {"Layer Id", "Translations"}),
        layerExpandTranslations = Table.ExpandListColumn(layerExpand, "Translations"),
        layerExpandTitle = Table.ExpandRecordColumn(layerExpandTranslations, "Translations", {"title"}, {"Layer Title"}),

        // Convert the expanded table into a list of records
        layerObjects = Table.ToRecords(layerExpandTitle),

        // Transform each layer record into a format suitable for navigation table
        layerItems = List.Transform(
            layerObjects,
            each let
                // Extract the workspace name and layer ID from the record
                workspaceNameText1 = Text.Replace(Text.BeforeDelimiter(Text.From([Layer Id]), "_"), "-", "-"),
                layerIdText = Text.From([Layer Id]),
                layertitletext = [Layer Title] as text,

                // Construct the URL to fetch layer data in CSV format
                url = "https://data.tabaqat.net/geoserver/" & workspaceNameText1 & "/" & layerIdText & "/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=" & layerIdText & "&outputFormat=csv&AcceptLanguages=ar&access_token=" & access_token,
                
                // Fetch layer data in CSV format
                csvData = Csv.Document(Web.Contents(url), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),

                // Check if there is any error in fetching CSV data.
                isError = Value.Is(csvData, type table) = false or Table.RowCount(csvData) = 0
            in
                if layerIdText <> "agriculture-and-fishing_e478l719725" then
                    [
                        Name = layertitletext, // Set the name as an empty string for second-level items
                        Key = layerIdText,
                        Data = csvData,
                        ItemKind = "text",
                        ItemName = layertitletext,
                        IsLeaf = true
                    ]
                else
                    // Return null for a specific layer ID (optional handling).
                    null
        ),
        // Remove any null items from the list of layer items.
        layerItemsFiltered = List.RemoveNulls(layerItems),
        // Convert the list of layer items into a navigation table.
        NavTable = Table.ToNavigationTable(
            Table.FromRecords(layerItemsFiltered),
            {"Key"},
            "Name",
            "Data",
            "ItemKind",
            "ItemName",
            "IsLeaf"
        )
    in
        NavTable;

//----------------------------------------------------------------------------------------------------------

// Data Source Kind description
TabaqatConnector = [
    // Specify the authentication method for the connector.
    Authentication = [
        // Define an authentication method named "Anonymous" with no parameters.
        Anonymous = []
    ]

];

//----------------------------------------------------------------------------------------------------------
// Data Source UI publishing description
TabaqatConnector.Publish = [
    // Specify whether the connector is in beta mode (false indicates it's not in beta).
    Beta = false,

    // Specify the category of the connector in the Power BI UI.
    Category = "Other",

    // Specify the text to display on the connector button in Power BI.
    ButtonText = { "Tabaqat", "Import data from Tabaqat platform" },

    // Provide a URL for users to learn more about the connector.
    LearnMoreUrl = "https://tabaqat.net/apps.html",

    // Specify the source image for the connector icon in Power BI.
    SourceImage = Tabaqat.Icons,

    // Specify the source type image for the connector in Power BI.
    SourceTypeImage = Tabaqat.Icons

];

//----------------------------------------------------------------------------------------------------------
// Define the icons for the Tabaqat connector
Tabaqat.Icons = [
    Icon16 = { Extension.Contents("icon16.png"), Extension.Contents("icon20.png"), Extension.Contents("icon24.png"), Extension.Contents("icon32.png") },
    Icon32 = { Extension.Contents("icon32.png"), Extension.Contents("icon40.png"), Extension.Contents("icon48.png"), Extension.Contents("icon64.png") }
];
