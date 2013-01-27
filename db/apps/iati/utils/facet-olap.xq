import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";
import module namespace olap = "http://tools.aidinfolabs.org/api/olap" at "../lib/olap.xqm";
declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";


let $corpus := request:get-parameter("corpus","test")
let $facet-name := request:get-parameter("facet","Region")
let $facet := olap:meta-facet($corpus,$facet-name)
let $context := element context {element corpus {$corpus}}
let $run-start := util:system-time()
let $stats :=  olap:compute-facet($facet, $context)
let $store := olap:store-stats($corpus,$facet-name,$stats)
let $run-end := util:system-time()
let $run-milliseconds := (($run-end - $run-start) div xs:dayTimeDuration('PT1S'))  * 1000 
return 
 element result {
       $context,
       element time {$run-milliseconds},
       $store
 }
       

