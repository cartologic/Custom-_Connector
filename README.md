# <span style="color: #004D8D;">Develop PowerBI Web Data Connector
Estimated Reading : 30 minutes

## <span style="color: #004D8D;">Introduction
**PowerBi** Custom connector enables you to connect to [***tabaqat's***](https://tabaqat.net/) URLs. These URLs are used  to retrieve our data and use it in building visuals.

If you are a Power User or an Advanced User of Power BI, you may have your own secret **M** recipes to connect to your own data sources and do complex data transformations.

Then, why don't you **package** them and distribute them by developing Power BI Custom Connector? There are some advantages to do it.

   * You can hide all the details of **M** code and just expose the most important functions so that everyone can easily use it.
   * Users (including you) can add another operation on top of your **M** code easily and they don't have to touch your code.
   * You can delegate authentication to connector.


## <span style="color: #004D8D;">Prerequisites
* [	Power BI Desktop ](https://powerbi.microsoft.com/en-us/desktop/)  <img src="/images/icons8-power-bi-48.png" alt="drawing" width="30" height="30" align="center" />

* [	Visual Studio 2017](https://visualstudio.microsoft.com/vs/older-downloads/)  <img src="images/icons8-visual-studio-code-2019-48.png" alt="drawing" width="30" height="30" align="center" />

* [	Power Query SDK](https://marketplace.visualstudio.com/items?itemName=Dakahn.PowerQuerySDK)  <img src="images/icons8-sdk-package-installation-kit-isolated-on-white-background-28.png" alt="drawing" width="30" height="30" align="center" />


Simply install them one by one by following wizards. 
___
## <span style="color: #004D8D;">how build you own URL ?
- Our API returns [**GeoJSON**](https://geojson.org/) format. You should be able to understand this format in order to decide which data to get and which to leave.
- Before start in **PowerBi** Desktop you need to get **URL** that gives you the data as a  GeoJSON file.

- We will return two tables inside **PowerBi** Desktop using our **tabaqat** API links :
```
https://data.tabaqat.net/geoserver/education-and-training/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=education-and-training%3Aeducation-and-training_m3wpO118771&outputFormat=application%2Fjson&access_token=
https://data.tabaqat.net/geoserver/education-and-training/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=education-and-training%3Aeducation-and-training_1YjB7179859&outputFormat=application%2Fjson&access_token={access_Token}
```
- The two API links contains data about **Riyadh** region. You can get these links using **tabaqat**. The links are missing access token at the end of each one. If you are a registered user at **tabaqat** you can get your access token and paste it at the end of the link after "**=**"

- After concate URL and access token , now you have full link that will return a GeoJSON file format that contains our data and use it in next steps .

- **Don't** worry if you read this and don't understand. Let us start with the steps to clarify everything

## <span style="color: #004D8D;">Let's start !

1-First navigate to [***tabaqat.net***](https://tabaqat.net/) and create an account if you don't have one.

![Register at tabaqat.net](images/register_tabaqat.png)

2-After registering click login and sign with your email and password.

![Sign in at tabaqat.net](images/register_tabaqat_2.png)

3-Change language to English.

![Change Language](images/change_language.png)

4-Click on **Key** then **Generate Key**. As a free user you have up to five keys to generate.

![toke_copy](images/toke_copy.png)

5-Head to **Map Services** and select the layer you want to load inside **PowerBi** and then click "Use" .

![](images/get_link.png)

6-Click on **MICROSOFT POWER BI** Then copy Url that contain your Generated access token .

![](images/access_token.png)

## <span style="color: #004D8D;">Start from Power BI desktop
1-Open **PowerBi** Desktop and Connect to Web.

![Open Power BI Desktop and Connect to Web](images/Open_Power_BI_Desktop.png)


2-Paste access token from [***tabaqat.net***](https://tabaqat.net/) that mentioned later here.

![Migrate URL and access token](images/Migrate_URL_and_access_token.PNG)

3-**PowerBi** will forward you automatically to **Power Query editor**.

![Power Query editor](images/Power_Query_editor.PNG)


4-Press on **Advanced Editor**.

![Press on Advanced Editor](images/Press_on_Advanced_Editor.PNG)

5-Copy [**M**](https://learn.microsoft.com/en-us/powerquery-m/) code from Advanced editor and put it in sticky note because you will use later.

![M Code](images/M_Code.PNG)

6-While you open **PowerBI Desktop**, make sure you change Data Extension policy in security settings.

![security settings](images/security_settings.PNG)


![security settings](images/security_settings_2.PNG)

## <span style="color: #004D8D;">Develop Custom Connector

Now We convert (develop) above **M** code into custom connector.

## <span style="color: #004D8D;">Create project

1-Open **Visual Studio** 2017 and click "Create New Project".

2-Select **Data Connector Project** . If you don't see this, make sure to install **Power Query SDK** and restart Visual Studio.

![security settings](images/Data_Connector_Project.PNG)

3-Name the project and press **Ok**.

![Name the project](images/Name_the_project.PNG)

4-Visual Studio generates many files, but you just need to pay attention to two files.

* **.pq** file : This is where I write code.
* **.query.pq** file : This is where I test the code.

5-Open pq file. The syntax should be familiar as it's **M** language!

## <span style="color: #004D8D;">Migrate M code into pq file

1-First of all, copy and paste the **Get_tabqat1** function. I place it below **shared** section. One difference is I use **;** at the end of function. As I already show the code above, I put picture below to clarify where I put my code .

```power query
Get_tabqat1 = () as table =>
        let
            DefaultRequestHeaders = [
                #"Accept" = "application/json;odata.metadata=minimal",
                #"OData-MaxVersion" = "4.0"
            ],
            source = Web.Contents("https://data.tabaqat.net/geoserver/transportation/transportation_rjAZr139504/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=transportation_rjAZr139504&outputFormat=application%2Fjson&access_token={YOUR_ACCESS_TOKEN}&AcceptLanguages=en", [ Headers=DefaultRequestHeaders ]),
            json = Json.Document(source),
            value = json[value],
            toTable = Table.FromList(value, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
        in 
            toTable;
```
<br />
<br />

![Get_tabqat_1 ](images/Get_tabqat1.PNG)


2-Next, migrate the rest of the code that we mention later by replaces existing code under shared keyword. Again, I place picture below.

![Migrate](images/Migrate.PNG)

#### That's it!

## <span style="color: #004D8D;">Test the code

1-Open *.query.pq file and confirm it calls the shared function.


2-Press F5 key to start test. The **M Query Output** window opens and asks credential first. Set **Anonymous** to credential type and click Set Credential.

![Set Credential](images/Set_Credential.PNG)

3-Press **F5** again and you see the data comes back.

![data](images/data.PNG)

 Now you build your first connector.

## <span style="color: #004D8D;">Deploy

Last step is to deploy the connector.

1-Navigate to the project folder | bin | Debug. You can find ***.mez file.** There is a plan to change file extension so it could be different in the future.


![mez](images/Mez.PNG)

2-Copy the file into **C:\users<user>\Documents\Power BI Desktop\Custom Connectors folder**. Create the folder if not exists.

![mez_2](images/mez_2.PNG)
#### That's it!


## <span style="color: #004D8D;">User in Power BI Desktop
1-Restart Power BI Desktop and start from **Get Data**.

2-Search for **"Custom_Connector"** and you should find your connector.

![Custom Connector](images/Custom_Connector.PNG)

3-You will see **<span style="color: #FF0000;">WARNNING</span>** when connecting but just continue.

![warning](images/warning.PNG)

4-Only **anonymous** authentication is available. Click Connect.

![anonymous](images/anonymous.PNG)

5-Load the data or continue to transform if you want.

![load](images/load.PNG)

6-If you want to see the data that loaded you will find it at the right in **PowerBi**.

![data_2](images/data_2.PNG)

7-Repeat all above steps with another **URL** with the same **access token**.

![URL](images/URL.PNG)

8-delete **.mez** file from **Custom Connectors folder** and rebuild the script ,after rebuild the script but **.mez** In Custom Connectors folder.

9-Restart **PowerBi** Desktop and connect to **Custom_Connector** connector again.

10-Now you want to load data from second **URL** !

11-Click on Transform data in **PowerBi** ,this step will forward you to power query editor.

![Transform](images/Transform.PNG)

12-Click on Advanced Editor advanced_editor.

![advanced editor](images/advanced_editor.PNG)

13-Copy **M** code and press **Done**.

![done](images/done.PNG)

14-from **New Sources** Click on **Blank Query** .

![blank](images/blank.PNG)

15-Click on Advanced Editor again and paste **M** code in it but this time will change in the name of function **Custom_Connector2** that will load the data from second **URL** and press **Done**.

![query](images/query.PNG)

16-Now you have two data sources from different URLs with the same access token.

![URL_2](images/URL_2.PNG)

17-Finally press on **�Close & Apply�** to load data in **PowerBi**.

![close](images/close.PNG)

18-to see data that loaded in **PowerBi** ,press on �Data�.

![final](images/final.PNG)

**Now you are ready to build visuals using PowerBi**.


19-To create Relationship between 2 tables ,press on model that appear on the left side ,
long prees on column that exsist in another table and match between them and finally press
**ok**.

![relationship](images/relationship.PNG)

20-Relationship will created automatic between 2 tables ,then prees **Ok**.

![many_to_many](images/many_to_many.PNG)
<br/>
<br/>
![relationship_2](images/relationship_2.PNG)

21-Build your visuals using the data.

![visual](images/visual.PNG)
<br/>
<br/>
![Create_Map](images/Create_Map.PNG)

