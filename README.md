# Map
The application starts off displaying a map at user's location.

1. User can long press at any point on the map to insert a marker. The app will automatically find directions to that point from user's location
3. The first route will be highlighted in blue. Others will be gray. User can tap on them to switch route.
4. ETA and steps instruction for the selected route will be displayed at bottom. User can drag it up to view more details.
5. User can tap on the Settings icon to switch between different map styles

## Known issues:

- The app doesn't handle the case where user denies permission. We could display message asking user to go to settings app to turn location on, etc.
- The route is a bit "jagged". It would be nice to apply some algorithm to the polyline to make the edges smoother.
- All the routes are inserted after the destination marker so they are now on top of the marker. Ideally we want to insert them below the marker. That would look nicer.

