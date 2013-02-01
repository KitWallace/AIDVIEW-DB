import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  

let $context := 
    element context { element corpus {"test"} }
let $packages :=  activity:ckan-packages($context) 
let $sets := activity:activitySets($context/corpus)
let $keys := distinct-values(($packages,$sets/package))
return
 element result {
    count($packages),
    count($sets),
    count($keys),
    for $key in 
         (for $key in $keys order by $key return $key) [position() < 10]
    let $ckan:= $packages[.=$key]
    let $set:= $sets[package=$key]
    return
    
        element package {
          $ckan, $set
        }

}
