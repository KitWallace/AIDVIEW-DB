import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  

(: declare variable $local:corpus external; :)
let $local:corpus :=request:get-parameter("corpus",())

let $corpus :=  $local:corpus
let $login := config:login()
let $updateLog := log:write($corpus,"info","ckan","start")
let $update :=  activity:ckan-activitySets(<context><corpus>{$corpus}</corpus></context>)
let $updateLog := log:write($corpus,"info","ckan","end")
return ()

