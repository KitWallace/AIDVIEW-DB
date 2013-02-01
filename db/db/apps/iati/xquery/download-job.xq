import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  

declare variable $local:corpus external;
declare variable $local:publisher external;
declare variable $local:set external;
declare variable $local:mode external;

(:
let $corpus := request:get-parameter ("corpus",())
let $publisher := request:get-parameter ("publisher",())
let $set := ""
let $mode := "update"
:)

let $corpus := $local:corpus
let $publisher:= $local:publisher
let $set := $local:set
let $mode := $local:mode

let $sets := 
   if ($set ne "")
   then activity:activitySet($corpus,$set)
   else if ($publisher ne "")
   then activity:publisher-activitySets($corpus,$publisher)
   else activity:activitySets($corpus)
   
let $login := config:login()
let $updateLog := log:write($corpus,"info","download","publisher",$publisher,count($sets),"start")
let $update :=  activity:download-activitySets($sets,<context><corpus>{$corpus}</corpus></context>, $mode = "download")
let $updateLog := log:write($corpus,"info","download","publisher",$publisher,"end")
return ()
