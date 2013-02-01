
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm"; 
declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";

let $corpus := request:get-parameter("corpus",())
return 
 element corpus {
    element name {$corpus},
    element activities-updated {max(activity:corpus($corpus)/xs:dateTime(@iati-ad:activity-modified))}
 }