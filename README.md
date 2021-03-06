Notes on the Schibsted Assignment
====================

### By Łukasz Wroczyński


Generally I decided for a basic but working approach.


Choice of supported OS versions and devices
---------------------

To make things simpler I chose to support only iOS 10. For a production app it would make sense to support at least two previous OS versions (8 and 9 in this case). This could be done by not using some of the most recent APIs (like NSPersistentContainer). As far as devices are concerned, only iPhone is supported. iPad support could be added for example by using a UISplitViewController.


Data processing and persistence
---------------------

I decided to store the recipes using Core Data. This gives off-line storage, integrates well with UITableView and makes searching easy. A single managed entity is used (Recipe). The list of ingredient names is stored in a single text field which is fine for such a simple App.

I chose to use a single ManagedObjectContext. Data downloading and processing (JSON and images) are done in background threads, so the main thread is used only for writing to the persistent store. I think the app is pretty much responsive during data fetching.

When looking at the data I realized that the recipe description contains sometimes some simple HTML markup: \<br\> tags and links to photos copyright owner. I decided not to go for a full blown WebView component to show it, but used NSAttributedString to get the text (including \<br\> linebreaks) and show it in a simple label.

The data is fetched automatically for the first time on startup. After that the user can trigger a refresh of the data manually.


Error handling
---------------------

I decided not to bother the user with pop-ups. If there is a problem (e.g. we can't connect to the server) then the recipe list will just be empty.


Tests
---------------------

I added some basic unit tests for processing of recipe data


Final remarks
---------------------

I'm aware that for productive usage the app would have to be still a bit enhanced (real logging instead of print statements, nicer UI, enhanced CoreData stack, crash reporting and analytics, some more comments etc.) but as they say: "leave well alone" and even the best developers need to get some sleep! ;)
