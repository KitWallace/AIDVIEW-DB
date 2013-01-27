import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  

let $corpus := request:get-parameter("corpus","test")
let $context := 
    element context { element corpus {$corpus} }
let $packages :=  activity:ckan-packages($context) 
let $sets := activity:activitySets($context/corpus)
let $keys := for $key in distinct-values(($packages,$sets/package)) order by $key return $key
let $start := xs:integer(request:get-parameter("start",1))
let $n := xs:integer(request:get-parameter("n",20))
let $end := $start + $n - 1
let $logit :=  log:write_xml(element record {element corpus {$corpus}, element action {"ckanstart"} }) 
let $sets := 

 element activitySets {
    for $key in $keys[position() >= $start and position() <= $end]
    let $ckan:= $packages[.=$key]
    let $set:= $sets[package=$key]
    let $newset := 
        if (exists($ckan) and exists($set))  (: an existing package :)
        then 
             let $metadata := activity:ckan-activitySet($key)
             return
               if ($metadata/metadata_modified  > $set/download_modified)
               then  
                    element activitySet { 
                         element set {$key},
                         $metadata/publisher,
                         $metadata/host,
                         $metadata/metadata_modified,
                         $metadata/download_url,
                         element mode {"stale"},
                         element download_modified {$set/download-modified/string()}
                     }
               else element activitySet { 
                         element set {$key},
                         $metadata/publisher,
                         $metadata/host,
                         $metadata/metadata_modified,
                         $metadata/download_url,
                         element mode {"current"},
                         element download_modified {$set/download-modified/string()}
                         (:normally this would be just a copy since there has been no change :)
                     }
        else if (exists($ckan))
             then 
                  let $metadata := activity:ckan-activitySet($key)
                  return
                     element activitySet { 
                         element set {$key},
                         $metadata/publisher,
                         $metadata/host,
                         $metadata/metadata_modified,
                         $metadata/download_url,
                         element mode {"new"}
                     }
             
        else if (exists($set))
             then  element activitySet { 
                        element set {$key},
                        element publisher {substring-before($key,"-")},
                        $set/host,
                        element mode {"delete"}, 
                        element download_modified {$set/download-modified/string()}
                   }                         
        else ()
    return $newset
 }
 
let $login := xmldb:login("/db","admin","perdika")
let $store := xmldb:store(concat("/db/apps/iati/data/",$corpus),"newsets.xml",$sets)
let $logit := log:write_xml(element record {element corpus {$corpus}, element action {"ckanstop"},element data {count($sets/set)} })
return 
$store 