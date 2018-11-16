# External Links to Advance
Linking into Advance from an external site is not well supported, but can be accomplished with a bit of custom javascript.

## Instructions
1. Put the entity_link_redirect.js file in the Advance Web folder. To keep custom javascript seperate from the vanilla Advance scripts, we keep our javascript in a folder like so: ```C:\inetpub\wwwroot\Advance2016\ud_javascript\entity_link_redirect.js```
1. The entity_link_redirect.js file needs to be included in Advance Web so it can look for the URL params and perform the redirect. Put it into a form on the application called AWA Home Page (app ID 5042), which can be accomplished in Congifugration Utility.
1. You can link to Advance using the following link syntax and it should work correctly: ```https://advance.hogwarts.edu/Advance2016/default.aspx?page_id=50002&app_id=5020&id_number=0000243862``` Replace the page_id and app_id to an appropriate value, as needed.
