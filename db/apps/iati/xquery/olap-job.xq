import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace olap = "http://tools.aidinfolabs.org/api/olap" at "../lib/olap.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  

declare variable $local:corpus external;
declare variable $local:facet external;

let $corpus := $local:corpus
let $facet := $local:facet
let $logit := log:write($corpus,"info","start",$facet)
let $login := config:login()
return
   if ($facet ne "")
   then olap:update-facet($corpus,$facet)
   else olap:update-facets($corpus)


