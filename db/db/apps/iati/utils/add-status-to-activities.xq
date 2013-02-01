import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";

declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";

let $corpus := request:get-parameter("corpus",())
let $activities := activity:corpus($corpus)
let $update := 
    for $activity in $activities
    let $status := $activity/activity-status[1]
    let $code := $status/@code
    return 
       if (exists($code) and $code castable as xs:integer and empty($status/@iati-ad:activity-status))
       then update insert attribute iati-ad:activity-status {xs:integer($code)} into $status
       else ()
return
  element numberUpdated{count($update)}