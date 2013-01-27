module namespace activity = "http://tools.aidinfolabs.org/api/activity";
import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";  
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace corpus= "http://tools.aidinfolabs.org/api/corpus" at "../lib/corpus.xqm";  
import module namespace codes = "http://tools.aidinfolabs.org/api/codes" at "../lib/codes.xqm";  
import module namespace olap = "http://tools.aidinfolabs.org/api/olap" at "../lib/olap.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace num = "http://kitwallace.me/num" at "/db/lib/num.xqm";
import module namespace jxml = "http://kitwallace.me/jxml" at "/db/lib/jxml.xqm";
import module namespace date = "http://kitwallace.me/date" at "/db/lib/date.xqm";
import module namespace hc= "http://expath.org/ns/http-client";


import module namespace activity-transform = "http://tools.aidinfolabs.org/api/activity-transform" at "../lib/pipeline1.xqm"; (:should be dynamically loaded :) 
(: import module namespace pipeline = "http://tools.aidinfolabs.org/api/pipeline" at "../lib/pipeline.xqm"; :)

declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";

declare function activity:hash($activity as element(iati-activity))  as xs:string{
   util:hash($activity,"MD5")
};

declare function activity:corpus($corpus as xs:string)  as element(iati-activity)* {
  collection(concat($config:data,$corpus,"/activities"))/iati-activity
};

declare function activity:activity($corpus as xs:string, $id as xs:string ) as element(iati-activity)? {
   collection(concat($config:data,$corpus,"/activities"))/iati-activity[iati-identifier = $id]
};

declare function activity:set-activities($corpus as xs:string ,$package as xs:string* ) {
 collection(concat($config:data,$corpus,"/activities"))/iati-activity[@iati-ad:activitySet = $package]
};

declare function activity:corpus($corpus as xs:string, $q as xs:string) as element(iati-activity)* {
  let $path := concat("collection(",$config:data,$corpus,"/activities)/iati-activity",$q)
  return util:eval($path)
};

declare function activity:activitySet-path($corpus) {
  concat($config:data,$corpus,"/sets/activitySets.xml")
};

declare function activity:activitySet-all($corpus as xs:string) as element(activitySets) {
  doc(activity:activitySet-path($corpus))/activitySets
};

declare function activity:corpus-publishers($corpus as xs:string)  as xs:string* {
   distinct-values(doc(activity:activitySet-path($corpus))//publisher)
};

declare function activity:activitySets($corpus as xs:string)  as element(activitySet) * {
   doc(activity:activitySet-path($corpus))//activitySet
};

declare function activity:publisher-activitySets($corpus as xs:string,$publisher as xs:string) as element(activitySet) * {
    doc(activity:activitySet-path($corpus))//activitySet[publisher = $publisher]
};

declare function activity:activitySet($corpus as xs:string,$package as xs:string)  as element(activitySet) * {
    doc(activity:activitySet-path($corpus))//activitySet[package = $package]
};

declare function activity:activitySet-with-url($context as element(context))   as element(activitySet) * {
    doc(activity:activitySet-path($context/corpus))//activitySet[metadata/download_url = $context/url]
};

declare function activity:download-required($activitySet as element(activitySet) ?) as xs:boolean {
    empty($activitySet/download-modified) 
    or (exists ($activitySet/metadata_modified) and (xs:dateTime($activitySet/download-modified) < xs:dateTime($activitySet/metadata_modified)))
};

declare function activity:activitySets-download-required($corpus as xs:string) as element(activitySet) * {
   doc(activity:activitySet-path($corpus))//activitySet[activity:download-required(.)]
};

declare function activity:publisher-activitySets-download-required($corpus as xs:string,$publisher as xs:string) as element(activitySet) * {
   doc(activity:activitySet-path($corpus))//activitySet[publisher=$publisher][activity:download-required(.)]
};

declare function activity:ckan-packages($context as element(context)) {
      let $url := concat($config:ckan-base,"/api/search/package?filetype=activity")
      let $list :=jxml:convert-url($url,<params><rough/></params>)
      let $max := $list/div/count
      return
          for $i in (1 to  ($max idiv 1000 ) + 1)
          let $start := ($i - 1)* 1000 
          let $url := concat($config:ckan-base,"/api/search/package?filetype=activity&amp;start=",xs:string($start),"&amp;limit=1000")
          let $list :=jxml:convert-url($url,<params><rough/></params>)
          return $list//results/item
};

(:
declare function activity:ckan-activitySets($context) {
let $allpackages := activity:ckan-packages($context)
let $packages :=
   element packages {
          if ($context/ckansubset)  then subsequence($allpackages,$context/start,$context/pagesize)
          else if ($context/ckanall) then  $allpackages
          else ()
    }
let $activitySets := activity:activitySets($context/corpus)
let $merged := activity:update-activitySets($context/corpus,$packages,$activitySets)
let $activitySet := element activitySets { $merged }
let $store := xmldb:store(concat($config:data,$context/corpus,"/sets"),"activitySets.xml",$activitySet)
return 
   $store
};
:)

declare function activity:ckan-activitySets($context) {
  let $packages := activity:ckan-packages($context)
  let $activitySets := activity:activitySets($context/corpus)
  let $merged := activity:update-activitySets($context/corpus,$packages,$activitySets)
  let $activitySets := element activitySets { $merged }
  let $store := xmldb:store(concat($config:data,$context/corpus,"/sets"),"activitySets.xml",$activitySets)
  return 
     $store
};

declare function activity:ckan-activitySet($package as xs:string) as element(activitySet) {
       let $meta-url := concat($config:ckan-base,"/api/rest/package/",$package)
       let $metadata := util:catch("*",jxml:convert-url($meta-url)/div,<error>extract failed</error>)
       let $url := $metadata/download_url
       return

         element metadata {
            element package {$package},
            element publisher {substring-before($package,"-")},
            element host {substring-before(substring-after($url,"//"),"/")},
            $url,
            $metadata/metadata_modified
         }       
};

(: may not need this if we depend solely on the registry :)
declare function activity:source-activitySet($url) {
    if ($url)
    then 
        let $request :=
          element hc:request {attribute method {"HEAD"}, attribute href {$url}, attribute timeout {"10"} } 
        let $result :=  util:catch("*",  hc:send-request($request) , ())
        let $meta := $result[1]
        let $status := $meta/@status/string()
        return
         if (empty($meta))
         then <error>http request failed</error>      
         else if ($status="200")
         then 
            let $last-modified := $meta/hc:header[@name="last-modified"]/@value/string()
            return        
               element source {
                  $url,
                  if (exists($last-modified))
                  then element source-last-modified {date:RFC-822-to-dateTime($last-modified)}  (: convert to xs:date :)
                  else ()
                }
         else <error>http Status {$status}</error>
    else ()
};

declare function activity:update-activitySets($corpus,$packages, $sets)  as item()* {
    for $key in 
         for $key in distinct-values(($packages,$sets/package)) order by $key return $key
    let $ckan:= $packages[.=$key]
    let $set:= $sets[package=$key]
    return
        if (exists($ckan) and exists($set))  (: an existing package :)
        then 
             let $metadata := activity:ckan-activitySet($key)
             return
                if (empty($metadata))
                then 
                     let $null  := log:write_xml( element record {
                                        $corpus,
                                        element task {"download"},
                                        element level{"error"}, 
                                        element package {$key} , 
                                        element message {"ckan access failed"}
                                        })

                     return 
                        ()
                       
                else 
                     element activitySet { 
                        $metadata/*,   
                        $set/download-modified
                     }
        else if (exists($ckan))  (: no existing set  :)
        then 
             let $metadata := activity:ckan-activitySet($key)
             return
                if (empty($metadata))
                then  let $null  := log:write_xml( element record {
                                        $corpus,
                                        element task {"download"},
                                        element level{"error"}, 
                                        element package {$key} , 
                                        element message {"ckan access failed"}
                                       })
                      return 
                        ()  (: ignore it since no metadata available :)
                           
                else 
                     element activitySet { 
                         $metadata/*
                   }  
        else if (exists($set)) 
        then 
             if ($set/publisher="external")
             then $set
             else   (: no longer on ckan :)
                 element activitySet {attribute mode {"delete"}, $set/*}  (: mark for deletion :)
        else log:write_xml( element record {
                                        $corpus,
                                        element task {"update"},
                                        element level{"error"}, 
                                        element package {$key} , 
                                        element message {"system logic error :activity"}
                                     })
};

declare function activity:download-activitySets($activitySets as element(activitySet)*, $context, $refresh) {
   for $activitySet in $activitySets     
   return 
       activity:download-activitySet($activitySet, $context, $refresh)   
};

declare function activity:download-activitySet ($activitySet as element(activitySet), $context,  $refresh) {
 if (empty($activitySet/ignore) and ($refresh or activity:download-required($activitySet)) or exists($activitySet/record))
 then
    let $activity-collection := concat($config:data,$context/corpus,"/activities")
    let $corpus-meta := corpus:meta($context/corpus)
    let $url := $activitySet/download_url
    let $response := util:catch("*", httpclient:get(xs:anyURI($url),false(),()),())
    let $headers := $response/httpclient:headers
    let $status := $response/@statusCode/string()
    return
    if (empty($headers))
    then let $null  := log:write_xml( element record {$context/corpus,
                                        element task {"download"},
                                        element level{"error"}, 
                                        $activitySet/package , 
                                        $url, 
                                        element message {"request failed"}
                                     })
         return ()
    else if  ($status ne "200")
    then let $null := log:write_xml( element record {
                                        $context/corpus,
                                        element task {"download"},
                                        element level{"error"}, 
                                        $activitySet/package , 
                                        $url, 
                                        element status {$status},
                                        element message {"request failed"}
                                     })
         return ()
     else 
     let $activities := $response/httpclient:body//iati-activity
     return 
      if (empty($activities))
      then  let $null := log:write_xml( element record {
                                        $context/corpus,
                                        element level{"warn"}, 
                                        element task {"download"},
                                        $activitySet/package , 
                                        $url, 
                                        element message {"empty"}
                                     })
                                     
         return ()
      else 
       let $download := 
         for $activity in $activities
             let $id := normalize-space($activity/iati-identifier)
             let $hash := activity:hash($activity)
             let $current-activity := collection($activity-collection)/iati-activity[iati-identifier = $id]
             return 
                if ( $refresh 
                     or empty($current-activity) 
                     or ($hash ne $activity/@iati-ad:hash)
                   )
                then 
                   (: transform and then store 
                   
                   let $pipeline := $corpus-meta/@pipeline
                   let $transformed-activity := 
                   if (exists($pipeline))
                   then pipeline:run-steps($pipeline, $activity,$context)
                   else $activity
                   :)   
                           
                    (:    running a compiled version of the pipeline in pipeline1.xml at present if a pipeline defined in the corpus :)
  
                    let $transformed-activity := 
                        if ($corpus-meta/pipeline)
                        then activity-transform:transform($activity,$context) 
                        else $activity
   
                    let $delete-old := 
                        for $activity in $current-activity
                        return
                           (:  update delete $activity[iati-ad:live]  :)
                       (:   let $null := log:write_xml( element record {
                                        $context/corpus,
                                        element task {"download"},
                                        element level{"info"}, 
                                        $activitySet/package , 
                                        $id, 
                                        element message {"deleted"}
                                     })
                                     
                          return :)
                              xmldb:remove($activity-collection,util:document-name($activity) )  
                            (: ? revert to actual deletion here with 2.0 because its much faster :)
                    let $store := activity:store-activity($activitySet,$context/corpus,$transformed-activity)
                   (: let $null := log:write_xml( element record {
                                        $context/corpus,
                                        element task {"download"},
                                        element level{"info"}, 
                                        $activitySet/package , 
                                        $id,
                                        element message {"added"}
                                     })
                                     :)

                    return $store
                else  ()
           (: log the number of activities stored :)
        
        let $null := log:write_xml( element record {
                                        $context/corpus,
                                        element task {"download"},
                                        element level{"info"}, 
                                        $activitySet/package , 
                                        element message {concat(count($download), " activities downloaded")}
                                   })
        let $dt := util:system-dateTime()
        let $update-date := 
             if ($activitySet/download-modified)
             then update replace $activitySet/download-modified with element download-modified {$dt}
             else update insert element download-modified {$dt} into  $activitySet
        let $update-corpus := corpus:activities-updated($context/corpus) 
        return $url
    else ()
};

declare function activity:external-activitySet($context)  as element(activitySet) {
        let $current-activitySet := activity:activitySet-with-url($context)
        let $source := activity:source-activitySet($context/url)
        let $activitySet := 
          if (exists ($current-activitySet))
          then 
           element activitySet {
               $current-activitySet/package,
               element publisher {"external"},
               element metadata {
                   element download_url {$context/url/string()}
               },
               $source
           }

         else 
          element activitySet {
            element package{ util:uuid() },
            element publisher {"external"},
            element metadata {
                   element download_url {$context/url/string()}
            },
            $source
         }
        
       let $package := 
           if (exists ($current-activitySet))
           then 
              let $update:= update replace $current-activitySet with $activitySet
              return $current-activitySet/package
           else 
              let $update := update insert $activitySet into activity:activitySet-all($context/corpus)
              return $activitySet/package
      let $set := activity:activitySet($context/corpus,$package)
      let $download := activity:download-activitySet($set,$context,true())
      return activity:activitySet($context/corpus,$package)
};


(:  store an activity 
  
:)
declare function activity:store-activity($activitySet as element(activitySet), $corpus as xs:string, $activity as element(iati-activity)) as xs:string {
    let $activity-collection := concat($config:data,$corpus,"/activities")
    let $id := normalize-space($activity/iati-identifier)
    let $filename := concat(util:uuid(),".xml")  (: iati-identifiers arnt valid file names in general and have versions :)
    let $activity := 
       element iati-activity {
           $activity/@*,
           attribute iati-ad:activitySet {$activitySet/package},
           attribute iati-ad:publisher {substring-before($activitySet/package,"-")},
           attribute iati-ad:activity-modified {util:system-dateTime()} ,
           attribute iati-ad:hash {activity:hash($activity)},
           element iati-identifier {$id},
           $activity/(* except iati-identifier)
        }
    let $store := xmldb:store($activity-collection,$filename,$activity)
    return
        $id
};


declare function activity:remove-activities ($activitySets as element(activitySet)*,$context) {
(:      let $dump := concat($config:base,"dump")  ):) 
      let $log := doc(concat($config:data,$context/corpus,"/log.xml"))/log
      let $datetime := util:system-dateTime()  
      for $activitySet in $activitySets
      let $delete-stamp := update delete $activitySet/download-modified 
      let $id := $activitySet/package
      let $activities := collection(concat($config:data,$context/corpus,"/activities"))/iati-activity[@iati-ad:activitySet= $activitySet/package]
      let $deletions :=
         for $activity in $activities
         let $id := string($activity/iati-identifier)
         let $file := util:document-name($activity)
         let $delete  := xmldb:remove(concat($config:data,$context/corpus,"/activities"), $file)  
         return $id
      let $log := 
         if (exists($deletions))
         then update insert element record {  attribute url {$activitySet/download_url}, attribute dateTime {$datetime},attribute action {"deleted"}} into $log
         else update insert element record {  attribute url {$activitySet/download_url}, attribute dateTime {$datetime},attribute action {"nothing to delete"}} into $log
      return  $deletions
};



(:  pages :)

declare function activity:page($activities, $context ,$path) {
   activity:page($activities, $context ,$path, $path)
}; 

declare function activity:page($activities, $context ,$path, $setpath) {
let $subset := subsequence($activities,$context/start,$context/pagesize)
return
  <div>
          {wfn:paging-with-path2($setpath,$context/start,$context/pagesize,count($activities))}
          <table class="sortable"> 
     
            <tr><th style="width:20%">Activity Identifier</th><th width="10%">Value</th><th>Title</th></tr>
            {for $activity in $subset
             return
                 <tr>
                    <td><a href="{$path}/{wfn:URL-encode($activity/iati-identifier)}">{$activity/iati-identifier/string()}</a></td>
                    <td>{if ($activity/@iati-ad:project-value) then num:format-number(xs:double($activity/@iati-ad:project-value),"$,000") else ()}</td>
                    <td>{$activity/title/string()}</td>
                 </tr> 
            }
         </table>           
  </div>
};

declare function activity:set-page($activitySets,$context,$path) {
let $subset := subsequence($activitySets,$context/start,$context/pagesize)
return
  <div>
          {wfn:paging-with-path2($path,$context/start,$context/pagesize,count($activitySets))}
          <table class="sortable"> 
            <tr><th>Publisher</th><th>CKAN</th><th>Set</th><th>URL</th><th>Activities</th><th>Metadata</th><th>Download</th></tr>
            {for $activitySet in $subset
             
             return
               if (exists($activitySet/publisher))
               then
                 <tr>
                   <td><a href="{$context/_root}corpus/{$context/corpus}/Publisher/{$activitySet/publisher}">{$activitySet/publisher/string()}</a></td>
                   <td>{if ($activitySet/publisher ne "external") then <a class="external" href="http://www.iatiregistry.org/dataset/{$activitySet/package}">CKAN</a> else ()}</td>
                   <td><a href="{$context/_root}corpus/{$context/corpus}/set/{$activitySet/package}/activity">{$activitySet/package/string()}</a></td>
                   <td><a href="{$activitySet/download_url}">url</a></td>
                   <td>{count(collection(concat($config:data,$context/corpus,"/activities"))/iati-activity[@iati-ad:activitySet= $activitySet/package])  }</td>
              
                   <td>{if ($activitySet/metadata_modified) then datetime:format-dateTime($activitySet/metadata_modified,"dd MMM yy") else ()}</td>
                   <td>{if ($activitySet/download-modified) then datetime:format-dateTime($activitySet/download-modified,"dd MMM yy") else ()}</td>
                   <td> {if (empty($activitySet/download-modified)) then "new"
                         else if (activity:download-required($activitySet)) then "stale" 
                         else "current"}
                   </td>
                   <td> {if (exists($activitySet/record))
                    then $activitySet/record/@message/string()
                    else ()
                    }
                   </td>
                   <td>
                   {if ($context/_isadmin) then <span><a href="{$context/_root}corpus/{$context/corpus}/set/{$activitySet/package}/download">Download</a> </span>else ()}
                   {if ($context/_isadmin) then <span><a href="{$context/_root}corpus/{$context/corpus}/set/{$activitySet/package}/update">Update</a></span> else ()}
                   {if ($context/_isadmin and $activitySet/download-modified) then <span><a href="{$context/_root}corpus/{$context/corpus}/set/{$activitySet/package}/delete">delete</a></span>
                    else ()
                    }
                  </td>
                 </tr>
                else 
                 <tr>
                   <td>Missing</td>
                   <td>{$activitySet/package/string()}</td>
                   <td><a href="http://www.iatiregistry.org/dataset/{$activitySet/package}">CKAN</a></td>
  
                 </tr>
            }
         </table>           
  </div>
};

declare function activity:package-page($context) {
 let $activitySets := activity:activitySets($context/corpus)
 let $packages := activity:ckan-packages($context) 
 let $count := count($packages)
 let $pagesize :=25
 return
  <table>
     <tr><th>range</th><th>#extracted</th><th>Extracted</th></tr>
     {for $i in (1 to xs:integer( $count div $pagesize) + 1)
      let $start := ($i - 1) * $pagesize + 1
      let $loaded := count(for $package in subsequence($packages,$start,$pagesize) 
                           where exists (activity:activitySet($context/corpus,$package)/metadata_modified)
                           return $package
                           )
      return
       <tr>
           <td>{$start} to {$start + $pagesize - 1}</td>
           <td>{$loaded}</td>
           <td><a href="{$context/_root}corpus/{$context/corpus}/ckansubset{if ($context/_isrest) then "?" else "&amp;"}start={$start}&amp;pagesize={$pagesize}">extract</a></td>
       </tr>
      }
  </table>
};


declare function activity:node-name($node,$name) {
if ($name/string() eq normalize-space($node) or $node/string() eq "") 
then concat ("/",$name) 
else if (empty($name))
then $node/string()
else concat($node," /",$name)
};

declare function activity:code-as-html($node,$codelist) {
  if ($node)
  then 
              <tr>
                <th>{string-join(tokenize($node/name(),"-")," ")}</th>
                <td>{$node/@code/string()}</td>
                <td>{(codes:code-value($codelist,$node/@code)/name/string(),concat("(",$node,")"))[1]}</td>
              </tr>
   else ()
};

declare function activity:transaction-summary($activity) {
  let $years := 2009 to 2013
  let $summaries :=
     for $year in $years
     return olap:sum-activities($activity, $year)
  return 
    if (exists($summaries))
    then
    <tr>
      <th>Transaction Summary</th>
      <td>Values in $USD [2012]</td>
      <td>
    <table border="1">
      <tr>
      <th></th>
      {for $year in $years
       where $summaries[@year=$year]
       return element th {$year}}
      </tr>
     {for $code in ("C","D","E","IF","IR","LR","PD","R","TB")  
      where exists($summaries[@code=$code])
      return
        <tr>
          <th>{codes:code-value("ValueType",$code)/name/string()}</th>
          {for $year in $years 
           let $value := $summaries[@year=$year][@code=$code]/@USD-value
           where $summaries[@year=$year]
           return 
             if ($value)
             then element td {wfn:value-in-ks($value)}
             else element td {}
          }
        </tr>
      }
    </table>
   </td>
   </tr>
   else ()
};

declare function activity:provider-activities($activity,$context) {
   let $provider-activities := distinct-values($activity/transaction/provider-org/@provider-activity-id)
   return
        if (exists($provider-activities) )
        then <tr>
                  <th>Provider activities</th>
                  <td/>
                  <td>{for $provider-activity in $provider-activities 
                       return (<a href="{$context/_root}corpus/{$context/corpus}/activity/{$provider-activity}">{$provider-activity}</a>,"&#160;")
                      }
                  </td>
             </tr>
     
     else ()
};

declare function activity:receiver-activities($activity,$context) {
   let $receiver-activities := distinct-values($activity/transaction/receiver-org/@receiver-activity-id)
   return
        if ($receiver-activities) 
        then <tr>
                  <th>Receiver activities</th>
                  <td/>
                  <td>{for $receiver-activity in $receiver-activities 
                       return (<a href="{$context/_root}corpus/{$context/corpus}/activity/{$receiver-activity}">{$receiver-activity}</a>,"&#160;")
                      }
                  </td>
             </tr>
     
     else ()
};

declare function activity:as-html($nodes as node()*, $context ) {
   for $node in $nodes
   return
     typeswitch ($node) 
       case element(iati-activity) return
          <div class="activity">
              <h1>{$node/iati-identifier/string()}  : {string(($node/title[@xml:lang='en'], $node/title)[1])}</h1>
              {let $table :=
              <table>
                <tr><th width="15%">Publisher</th>
                    <td><a href='{$context/_root}corpus/{$context/corpus}/Publisher/{substring-before($node/@iati-ad:activitySet,"-")}'>{substring-before($node/@iati-ad:activitySet,"-")}</a>
                    </td>
                </tr>
                <tr><th>Hierarchy </th> <td width="15%" ></td> <td>{codes:code-value("RelatedActivityType",$node/@hierarchy)/name/string()}</td> </tr>
                {if ($node/@iati-ad:project-value castable as xs:double)
                 then <tr><th>Project value </th> <td>USD</td><td>{num:format-number(xs:double($node/@iati-ad:project-value),"$,000")}</td></tr>
                 else ()
                }
                 {activity:as-html($node/title, $context)}
                 {activity:as-html($node/description, $context)}
                 {activity:as-html($node/activity-status, $context)}
                 {activity:as-html($node/activity-date, $context)}
                 {activity:code-as-html($node/collaboration-type, "CollaborationType")}
                 {activity:code-as-html($node/default-flow-type, "FlowType")}
                 {activity:code-as-html($node/default-aid-type, "AidType")}
                 {activity:code-as-html($node/default-tied-status, "TiedStatus")}
                 {activity:code-as-html($node/default-finance-type, "FinanceType")}
                 {activity:as-html($node/reporting-org, $context)}
                 {activity:as-html($node/activity-website,$context)}
                 {activity:as-html($node/contact-info,$context)} 
                 {activity:as-html($node/participating-org, $context)}
                 {activity:as-html($node/recipient-region, $context)}
                 {activity:as-html($node/recipient-country, $context)}
                 {activity:as-html($node/location,$context)}
                 {activity:as-html($node/sector, $context)}
                 {activity:as-html($node/related-activity, $context)}
                 {activity:transaction-summary($node)}
                 {activity:provider-activities($node,$context)}
                 {activity:receiver-activities($node,$context)}
                  {activity:as-html($node/document-link,$context)}
                 {activity:as-html($node/result,$context)}
                 
             
              </table> 
              return
               <table>
                 {for $row at $i in $table/tr
                  return
                    element tr {
                      if ($i mod 2 = 1) then attribute class {"bar"} else (),
                      $row/*
                    }
                 }
               </table>
             }
          </div>
        case element(activity-status) return
             let $name := codes:code-value("ActivityStatus",$node/@code)/name
             return <tr><th>Activity Status</th><td>{$node/@code/string()}</td><td>{$name/string()}</td></tr>
        case element(activity-date) return
              <tr>
                 <th>Date</th>
                 <td>{$node/@type/string()}</td>
                 <td>{let $date := ($node/@iso-date,$node)[1]
                      return 
                         if ($date castable as xs:date)
                         then datetime:format-date(xs:date($date),"dd MMM yyyy")
                         else $date
                      }
                 </td>
              </tr>
       
        case element(title) return
             let $lang := ($node/@xml:lang,"en")[1]
             let $name := codes:code-value("Language",$lang)/name
             return <tr><th>Title</th><td >{$name/string()}</td><td colspan="2">{$node/string()}</td></tr>
        case element(description) return
             let $lang := ($node/@xml:lang,"en")[1]
             let $name := codes:code-value("Language",$lang)/name
             return <tr><th>Description</th><td >{$name/string()}</td><td  colspan="2">{$node/string()}</td></tr>
        case element(reporting-org) return
             let $org := codes:code-value("OrganisationIdentifierFull",$node/@iati-ad:org)
             let $name := $org/name
             return 
                 <tr>
                    <th>Reporting</th>
                    <td><a href="{$context/_root}corpus/{$context/corpus}/facet/Reporter/code/{$node/@ref}">{$node/@ref/string()} </a> </td>
                    <td>
                    {activity:node-name($node,$name)}</td>
                    </tr>
        case element(participating-org) return
            let $org := codes:code-value("OrganisationIdentifierFull",$node/@iati-ad:org)
            let $name := $org/name
 
            return 
               if ($node/@iati-ad:funder)
               then 
                <tr>
                  <th>Funder</th>
                  <td><a href="{$context/_root}corpus/{$context/corpus}/facet/Funder/code/{$node/@ref}">{$node/@ref/string()}</a> </td>
                  <td>{activity:node-name($node,$name)}</td>
                </tr>
             else
                <tr>
                  <th>Participant</th>
                  <td>{$node/@role/string()}&#160;<a href="{$context/_root}corpus/{$context/corpus}/facet/Participant/code/{$node/@ref}">{$node/@ref/string()}</a> </td>
                  <td>{activity:node-name($node,())}</td>
                </tr>
              
        case element(recipient-country) return
             let $country := codes:code-value("Country",$node/@code)
             return 
               <tr>
                 <th>Country</th>
                 <td><a href="{$context/_root}corpus/{$context/corpus}/facet/Country/code/{$node/@code}">{$node/@code/string()}</a></td>
                 <td>{$country/name/string()}</td>
               </tr>
        case element(recipient-region) return
             let $region := codes:code-value("Region",$node/@code)
             return 
               <tr>
                 <th>Region</th>
                 <td><a href="{$context/_root}corpus/{$context/corpus}/facet/Region/code/{$node/@code}">{$node/@code/string()}</a></td>
                 <td>{$region/name/string()}</td>
               </tr>
        case element(sector) return
             let $sector := 
                if ($node/@vocabulary = "DAC")
                then codes:code-value("Sector",$node/@code)
                else if ($node/@vocabulary = "DAC-3")
                then codes:code-value("SectorCategory",$node/@code)
                else ()
             return 
               <tr>
                 <th>Sector : {string($node/@vocabulary)} </th>
                 <td>
                   {if ($node/@vocabulary = "DAC" and $node/@code)
                    then <a href="{$context/_root}corpus/{$context/corpus}/facet/Sector/code/{$node/@code}">{$node/@code/string()}</a>
                    else if ($node/@vocabulary = "DAC-3")
                    then <a href="{$context/_root}corpus/{$context/corpus}/facet/SectorCategory/code/{$node/@code}">{$node/@code/string()}</a>
                    else ()
                   }
                   &#160;{if ($node/@percentage) then concat(" (",$node/@percentage,"%)") else () }
                 </td>
                 <td>               
                   {($sector/name,$node)[1]/string()}
                </td>
               </tr>
         case element(activity-website) return
              <tr>
                <th>Activity Website</th>
                <td></td>
                <td><a class="external" href="{$node}">{$node/string()}</a></td>
              </tr>
        case element(contact-info) return
              <tr>
                <th>Contact</th>
                <td/>
                <td>
                  {string-join(($node/person-name,$node/organisation,$node/mailing-address),", ")}&#160;
                  <a class="external" href="mailto:{$node/email}">{$node/email/string()}</a>
                </td>
               </tr>
        case element(related-activity) return
              <tr>
                <th>{codes:code-value("RelatedActivityType",$node/@type)/name/string()}&#160;Activity</th>
                <td>
                <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($node/@ref)}">{$node/@ref/string()}</a>
                </td>
                <td>{$node/string()}</td>
              </tr>
        case element(location) return
              <tr>
                <th>Location</th>
                <td>{$node/name/string()}</td>
                <td>{$node/description/string()}
                {if ($node/coordinates)
                 then <a class="external" target="_blank" href="http://www.openstreetmap.org/?lat={$node/coordinates/@latitude}&amp;lon={$node/coordinates/@longitude} ({$node/name})&amp;zoom=10">Map</a>
                 else ()
                }</td>
              </tr>

       case element(document-link) return
              <tr>
                <th>Document</th>
                <td>{$node/@format/string()}</td>    
                <td> {codes:code-value("DocumentCategory",$node/category/@code)/name/string()}: <a class="external" href="{$node/@url}">{($node/title/string(),$node/text(),"Document")[1]}</a></td>
              </tr>
       case element(result) return
              <tr>
                <th>Result</th>
                <td>{$node/@type/string()}</td>    
                <td>{$node/indicator/title/string()} <br/>
                {$node/indicator/period/period-start/@iso-date/string()} to   {$node/indicator/period/period-end/@iso-date/string()} 
                : target {$node/indicator/period/target/@value/string()}: actual {$node/indicator/period/actual/@value/string()}</td>
              </tr>
            
       default return ()
};