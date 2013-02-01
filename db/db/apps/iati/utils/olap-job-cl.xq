import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace olap = "http://tools.aidinfolabs.org/api/olap" at "../lib/olap.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  

declare variable $local:corpus := request:get-parameter("corpus",());
declare variable $local:facet := request:get-parameter("facet",());

let $corpus := $local:corpus
let $facet := $local:facet
let $logit := log:write($corpus,"info","start",$facet)

let $login := config:login()
return
   if ($facet ne "")
   then olap:update-facet($corpus,$facet)
   else olap:update-facets($corpus)

