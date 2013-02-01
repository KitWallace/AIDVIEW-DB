import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";
declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";


let $corpus := request:get-parameter("corpus","test")

let $run-start := util:system-time()
let $count := count(collection(concat($config:data,$corpus,"/activities"))/iati-activity[@iati-ad:live])
let $run-end := util:system-time()
let $run-milliseconds := (($run-end - $run-start) div xs:dayTimeDuration('PT1S'))  * 1000 
return 
<result>{$corpus};{$count};{$run-milliseconds}</result>

