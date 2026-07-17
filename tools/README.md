# CivSnap municipality boundaries

CivSnap auto-assigns each report to a municipal corporation by testing the
report's GPS coordinates against polygons in
`lib/assets/data/tt_municipalities.geojson`
(`BoundaryService.findMunicipality`). That file currently ships as a
**placeholder** (rough rectangles), so assignments are approximate until you
drop in your real boundaries.

## Wire up your My Maps boundaries

1. **Export the KML** from your My Maps. Either open this URL in a browser and
   save the file:

   ```
   https://www.google.com/maps/d/kml?mid=1u2BhYRgf7OHjNfXq5BRZZ4l_F4tGm3A&forcekml=1
   ```

   …or in My Maps use ⋮ → **Export to KML/KMZ** → tick *Export as KML instead
   of KMZ*.

2. **Convert it** to the boundary GeoJSON:

   ```
   python3 tools/kml_to_geojson.py ~/Downloads/your-map.kml \
       -o lib/assets/data/tt_municipalities.geojson
   ```

3. **Match the names.** Each placemark's name becomes `properties.name`. That
   value must match the corresponding `corporations.name` row in Supabase
   (case-insensitive) so a `corporation_id` can be resolved. If a name can't
   match, set `properties.corporation_id` directly in the GeoJSON.

4. Rebuild the app. New reports whose coordinates fall inside a polygon are
   assigned to that corporation, notified, and audit-logged automatically.

## When a corporation says a report is in the wrong municipality

Open the CivSnap corporation dashboard → the report's **Reassign** button →
pick the correct corporation and add a note. That persists the new
`corporation_id`, notifies the receiving corporation, and records an audit
entry. Requires the columns added by
`supabase_civsnap_corporation_assignment.sql`.
