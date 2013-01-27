import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";

declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";

let $corpus := request:get-parameter("corpus",())
let $activities := activity:corpus($corpus)

let $update := 
    for $activity in $activities
    let $hash := activity:hash($activity)
    return 
       if (exists($hash) and empty($activity/@iati-ad:hash))
       then let $update := update insert attribute iati-ad:hash {$hash} into $activity
            return $hash
       else ()
return
  element result {
      element activities {count($activities)},
      element numberUpdated{count($update)}
      
  }