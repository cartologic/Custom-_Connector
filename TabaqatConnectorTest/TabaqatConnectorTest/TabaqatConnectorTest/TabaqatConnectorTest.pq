//Connector Section Definition (Container) + Unique name
section TabaqatConnectorTest;
/* - DataSource.Kind is a unique identifier for your connector 
   - The Publish key links to additional metadata about 
    how your connector should be presented within Power BI.*/
[DataSource.Kind="TabaqatConnectorTest", Publish="TabaqatConnectorTest.Publish"]

/*  defining how your custom connector's data appears and behaves in Power BI, enabling users to navigate and retrieve
    data from your data source in an intuitive and structured manner.*/

shared TabaqatConnectorTest.Contents = Value.ReplaceType(NavigationTable.Nested, Meta_data);

 /*Main Connector Function
 Fetching Workspaces from 'Dirictus'
 takes an access_token as input and returns a table as output*/
NavigationTable.Nested = (access_token as text) as table =>
let
    
    workspacesUrl = "https://catalog.tabaqat.net/items/workspace?fields=name,translations.title&deep[translations][_filter][languages_code][_eq]=en-US&filter[status]=published",
    workspaceResponse = Web.Contents(workspacesUrl),// use Web.Contents to make an HTTP GET request (retrive json data about workspaces from tabaqat API)
    workspaceJson = Json.Document(workspaceResponse), // This makes the JSON data structured and queryable within Power Query.

    //Converts the JSON data into a Power Query table
    workspaceTable = Table.FromList(workspaceJson[data], Splitter.SplitByNothing(), null, null, ExtraValues.Error),

    /*Expands the columns within the JSON data to make the name and translations.title fields of each workspace
    directly accessible as columns in the table.*/
    workspaceExpand = Table.ExpandRecordColumn(workspaceTable, "Column1", {"name", "translations.title"}, {"Workspace Name", "Workspace Title"}),
    workspaceObjects = Table.ToRecords(workspaceExpand),// Converts the expanded workspace table into a list of records.
    //Transforming workspaces into navigation table
    objects = List.Transform(
        workspaceObjects,
        each {
            Text.Replace([Workspace Name], "-", " "),
            [Workspace Name] & "_layers",
            CreateNavTable([Workspace Name], access_token),
            "Folder",
            "Folder",
            false
        }
    ),
    NavTable = Table.ToNavigationTable(#table({"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}, objects), {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
    NavTable;

//----------------------------------------------------------------------------------------------------------

/*Fetching layers for each workspace
CreateNavTable is a helper function that fetches and processes the layers belonging to a given workspace.
involves making another web request.*/
CreateNavTable = (workspaceName as text, access_token as text) as table =>
    let
        layerUrl = "https://catalog.tabaqat.net/items/layer?fields=workspace.translations.title,workspace.name,name,translations.title&filter[status][_eq]=published&deep[translations][_filter][languages_code][_eq]=en-US&deep[workspace][translations][_filter][languages_code][_eq]=en-US&limit=1000&filter[workspace][name]=" & workspaceName,
        layerResponse = Web.Contents(layerUrl),//Makes an HTTP GET request
        layerJson = Json.Document(layerResponse), 
        layerTable = Table.FromList(layerJson[data], Splitter.SplitByNothing(), null, null, ExtraValues.Error),//Converts the JSON data into a Power Query table.
        layerExpand = Table.ExpandRecordColumn(layerTable, "Column1", {"name", "translations"}, {"Layer Id", "Translations"}),
        layerExpandTranslations = Table.ExpandListColumn(layerExpand, "Translations"),
        layerExpandTitle = Table.ExpandRecordColumn(layerExpandTranslations, "Translations", {"title"}, {"Layer Title"}),
        layerObjects = Table.ToRecords(layerExpandTitle),
        layerItems = List.Transform(
            layerObjects,
            each let
                workspaceNameText1 = Text.Replace(Text.BeforeDelimiter(Text.From([Layer Id]), "_"), "-", "-"),
                layerIdText = Text.From([Layer Id]),
                layertitletext = [Layer Title] as text,
                url = "https://data.tabaqat.net/geoserver/" & workspaceNameText1 & "/" & layerIdText & "/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=" & layerIdText & "&outputFormat=csv&AcceptLanguages=ar&access_token=" & access_token,
                csvData = Csv.Document(Web.Contents(url), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None])
            in
                [
                    Name = layertitletext,
                    Key = layerIdText,
                    Data = csvData,
                    ItemKind = "text",
                    ItemName = layertitletext,
                    IsLeaf = true
                ]
        ),
        NavTable = Table.ToNavigationTable(
            Table.FromRecords(layerItems),
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

//this function returns a table and also includes some metadata attributes such as a name for the function (Tabaqat Connector).
Meta_data = type function (
    access_token as (type text meta [
        Documentation.FieldCaption = "Add your access token here",
        Documentation.FieldDescription = "Text to display",
        Documentation.SampleValues = {""}
    ])  
    )
    as table meta [
        Documentation.Name = "Tabaqat Connector"
    ];


//----------------------------------------------------------------------------------------------------------

//function to add second level "url for each workspaces" ya ali 

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn,
            NavigationTable.NavigateToPreview = true // Enable navigation to preview when clicking on an item
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

//----------------------------------------------------------------------------------------------------------

// Data Source Kind description
TabaqatConnectorTest = [
    Authentication = [
        Anonymous = []
    ]//,
];
//----------------------------------------------------------------------------------------------------------
// Data Source UI publishing description
TabaqatConnectorTest.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { "Tabaqat", "Provides an example of how to provide function documentation" },
    CredentialPrompts = [
     
            Label = "Tabaqat Catalogs",
            Formula = "Catloges"
        ]
    
];
//----------------------------------------------------------------------------------------------------------

shared Tabaqat.Icons = [
     Icon16 = { Extension.Contents("Tabaqat16.png"), Extension.Contents("Tabaqat20.png"), Extension.Contents("Tabaqat24.png"), Extension.Contents("Tabaqat32.png") },
     Icon32 = { Extension.Contents("Tabaqat32.png"), Extension.Contents("Tabaqat40.png"), Extension.Contents("Tabaqat48.png"), Extension.Contents("Tabaqat64.png") }
    ];