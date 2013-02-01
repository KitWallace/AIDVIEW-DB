import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  

declare variable $local:corpus external;

let $corpus :=  $local:corpus
let $login := config:login()
let $updateLog := log:write($corpus,"info","reindex activity","start")
let $update :=  xmldb:reindex(concat($config:data,$corpus))
let $updateLog := log:write($corpus,"info","reindex activity","end")
return ()

