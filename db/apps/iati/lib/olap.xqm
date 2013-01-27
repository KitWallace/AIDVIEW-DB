module namespace olap = "http://tools.aidinfolabs.org/api/olap";

declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";
import module namespace corpus = "http://tools.aidinfolabs.org/api/corpus" at "../lib/corpus.xqm";
import module namespace codes = "http://tools.aidinfolabs.org/api/codes" at "../lib/codes.xqm";
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";  
import module namespace log= "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";
import module namespace num = "http://kitwallace.me/num" at "/db/lib/num.xqm";
import module namespace url = "http://kitwallace.me/url" at "/db/lib/url.xqm";

declare function olap:directory($corpus) {
  concat($config:data,$corpus,"/olap/")
};

declare function olap:directory($corpus,$facet) {
  concat($config:data,$corpus,"/olap/",$facet,".xml")
}; 

declare function olap:meta-facets($corpus) {
   doc(concat(olap:directory($corpus),"config.xml"))//facet
};

declare function olap:meta-facet($corpus,$facet as xs:string) {
   olap:meta-facets($corpus)[@name = $facet]
};

declare function olap:last-updated($corpus) {
   doc(concat(olap:directory($corpus),"Corpus.xml"))/facets/@dateTime/string()
};

declare function olap:is-stale($corpus) {
   empty(olap:last-updated($corpus)) or corpus:activities-last-updated($corpus) > olap:last-updated($corpus)
};

declare function olap:facet($corpus as xs:string,$facet as xs:string) {
    doc(olap:directory($corpus,$facet))/facets/*
};

declare function olap:facet-code($corpus as xs:string,$facet as xs:string,$code as xs:string) {
     doc(olap:directory($corpus,$facet))/facets/*[code = $code]
};

declare function olap:sum-activities($activities as element(iati-activity)*, $date-from , $date-to) {
   element transaction-summary {
      for $type in ("C","D","E","IF","IR","LR","PD","R","TB")  
      let $value := 
          sum($activities/*/value
             [@iati-ad:transaction-type = $type]
             [@iati-ad:transaction-date ge $date-from]
             [@iati-ad:transaction-date lt $date-to]
             /@iati-ad:USD-value
           )
      where $value ne 0.0
      return
        element summary {
         attribute code {$type},
         attribute date-from {$date-from},
         attribute date-to {$date-to},
         attribute USD-value {$value} 
      }
  }
}; 

declare function olap:sum-activities($activities as element(iati-activity)*, $year as xs:integer) {
let $date-from := concat($year,"-01-01")
let $date-to:= concat ($year + 1 ,"-01-01")
for $type in ("C","D","E","IF","IR","LR","PD","R","TB") 
      
      let $value := 
          sum($activities/*/value
             [@iati-ad:transaction-type=$type]
             [@iati-ad:transaction-date ge $date-from]
             [@iati-ad:transaction-date lt $date-to]
             /@iati-ad:USD-value
           )
      where $value ne 0.0
      return
        element summary {
         attribute code {$type},
         attribute year {$year},
         attribute USD-value {$value} 
      }
};

declare function olap:sum-activities($activities as element(iati-activity)*) {
   element transaction-summary {
      for $type in ("C","D","E","IF","IR","LR","PD","R","TB")  
      let $value := 
          sum($activities/*/value
             [@iati-ad:transaction-type=$type]
             /@iati-ad:USD-value
           )
      where $value ne 0.0
      return
        element summary {
         attribute code {$type},
         attribute USD-value {$value} 
      }
  }
};


declare function olap:corpus-statistics ($corpus) {
     let $activitySets := activity:activitySets($corpus)
     let $activities := activity:corpus($corpus)
     return 
        element Corpus {
           element code {$corpus},
           element activitySets {count($activitySets)},
           element activitySets-download {count($activitySets[download-modified])},
           element count-all {count($activities)},
           element count {count($activities[@iati-ad:include])}
        }
};

declare function olap:publisher-statistics( $corpus) {
     let $facet := olap:meta-facet($corpus,"Publisher")
     for $publisher in  activity:corpus-publishers($corpus)
     let $activitySets := activity:publisher-activitySets($corpus,$publisher)
     let $activities := activity:set-activities($corpus, $activitySets/package)
     return
        olap:compute-facet-occ($corpus,$activities,$facet,$publisher,$publisher)
};

declare function olap:compute-facet-occ($corpus,$activities,$facet,$code,$name) {
  element {$facet/@name} { 
    element code {$code},
    element name {string($name)},
    for $summary in $facet/summary
    return 
       if ($summary ="activities") then 
       (
         element value {sum ($activities/@iati-ad:project-value) },
         element count-all {count($activities)},
         element count {count($activities[@iati-ad:include])}
        )
       else if ($summary ="compliance") then 
        (
         element activities-with-locations {count($activities[location])},
         element activities-with-results {count($activities[result])},
         element activities-with-documents {count($activities[document-link])},
         element activities-with-conditions {count($activities[conditions])},
         element activities-with-DAC-sectors {count($activities[sector/@vocabulary="DAC"])}
        )
       else if ($summary="financial") then 
           for $year in xs:integer($summary/@from-year) to xs:integer($summary/@to-year)
           return  olap:sum-activities($activities , $year ) 
       else ()       
   }
};

(:  create the olap summary for a facet, guided by the facet description in the olap configuration file :)

declare function olap:compute-facet($corpus, $facet-name) {
let $facet:= olap:meta-facet($corpus,$facet-name)
let $group-exp := concat("distinct-values(collection('",$config:data,$corpus,"/activities')/iati-activity/",$facet/@element,"/",$facet/@path,")")
let $group-codes := util:eval($group-exp)
let $log := log:write($corpus,"info","olap update","facet",$facet-name,count($group-codes)," started")
for $code in $group-codes[. ne '']
   let $activities := 
      if ($facet/summary)
      then 
         let $exp := concat("collection('",$config:data,$corpus,"/activities')/iati-activity[",$facet/@element,"/",$facet/@path, " = $code]")
         return util:eval($exp,true())
      else ()
   let $name := if ($facet/@code) 
                then codes:code-value($facet/@code,$code)/name
                else  (: get the name from the text if th first  element- very crude mining -  :)
                    let $exp := concat("$activities[1]/",$facet/@element,"[",$facet/@path," = $code ][1]/text()")
                    return util:eval($exp,true())
   return
      olap:compute-facet-occ($corpus,$activities,$facet,$code,$name)
};

declare function olap:update-facet($corpus,$facet) {
  let $log := log:write($corpus,"info","olap started","facet",$facet)
  let $stats :=   
      if ($facet = "Corpus")
      then olap:corpus-statistics($corpus)
      else if ($facet="Publisher")
      then olap:publisher-statistics($corpus)
      else olap:compute-facet($corpus,$facet)
  let $file := element facets {attribute dateTime {current-dateTime()},$stats}
  let $log := log:write($corpus,"info","olap finished","facet",$facet, count($stats))
  return xmldb:store(olap:directory($corpus), concat($facet,".xml"), $file) 
};

declare function olap:update-facets($corpus) {  
let $facets := olap:meta-facets($corpus)
let $log := log:write($corpus,"info","olap update"," started")
let $results := 
   for $facet in ($facets[@path]/@name,"Publisher","Corpus")
   return olap:update-facet($corpus,$facet)
let $log := log:write($corpus,"info","olap update"," finished")
return $results
};

(:  not used but wont compile without ?? :)
declare function olap:update-corpus($context) {
   $context
};

(:  pages :)

declare function olap:summary-page($facet-occ,$facet) {
      <div>
         {          
         for $summary in $facet/summary
         return 
             if ($summary="activities") 
             then
               let $count-all := xs:integer($facet-occ/count-all)
               return
                 <div>
                 <h3>Activity summary</h3>
                 <table>
                    <tr><th>Total Activities </th><td>{$count-all}</td></tr>
                    <tr><th>Included Activities </th><td>{$facet-occ/count/text()} 
                 { if ($count-all > 0) then concat(" (",round($facet-occ/count div $count-all * 100 ),"%)") else () }
                 </td></tr>
                  {if ($summary/value) 
                   then <tr><th>Total Value(USD 2010)</th><td>{num:format-number(xs:double($facet-occ/value),"$,000")}</td></tr>
                   else ()
                  }
                 </table>
                 </div>
            else if ($summary = "sets")
            then 
               <div>
                <h3>Sets</h3>
                <table>
                  <tr><th>Number of Activity Sets</th><td>{$facet-occ/activitySets/text()}</td></tr>
                  <tr><th>Number downloaded </th><td>{$facet-occ/activitySets-download/text()}</td></tr>
                </table>   
               </div>
            else if ($summary = "compliance")
            then 
               let $count-all := xs:integer($facet-occ/count-all)
               return
                <div>
                <h3>Compliance</h3>
                 <table>
                  <tr><th>Activities with locations </th><td>{$facet-occ/activities-with-locations/text()}</td></tr>
                  <tr><th>Activities with DAC sectors </th><td>{$facet-occ/activities-with-DAC-sectors/text()}</td></tr>
                  <tr><th>Activities with results </th>
                        <td>{$facet-occ/activities-with-results/text()}</td>
                        <td>{round($facet-occ/activities-with-results div $count-all * 100 )}</td>
                  </tr>
                  <tr><th>Activities with documents </th>
                       <td>{$facet-occ/activities-with-documents/text()}</td>
                       <td>{round($facet-occ/activities-with-documents div $count-all * 100 )}</td>
                  </tr>
                  <tr><th>Activities with conditions </th>
                      <td>{$facet-occ/activities-with-conditions/text()}</td>
                      <td>{round($facet-occ/activities-with-conditions div $count-all * 100 )}</td>
                  </tr>
                </table>
               </div>
            else if ($summary="financial")
             then 
               let $years := $summary/(@from-year to @to-year)
               return
             <div>
              <h3>Financial Summary - all values in USD </h3>              
              <table border="1">
              <tr><th>Code</th><th>Transaction Type</th>{for $year in $years return <th>{$year}</th>}<th>Total</th></tr>
              {
               for $type in codes:codelist("ValueType")/*
               let $year-totals := 
                  for $year in $years       
                  return $facet-occ/summary[@code=$type/code][@year=$year]/@USD-value
               let $total := sum($year-totals)
               return 
                 if ($total ne 0)
                 then
                 <tr>
                   <td>{$type/code/string()}</td><td>{$type/name/string()}</td>
                   {for $year in $years
                    let $value := $facet-occ/summary[@code=$type/code][@year=$year]/@USD-value
                    return
                      if ($value)
                      then <td>{wfn:value-in-ks($value)}</td>
                      else <td/>
                   }
                   <td>{wfn:value-in-ks($total)}</td>
                </tr>
                else ()
               }
               </table>  
              </div>
            else ()
            }
       </div>
};

(: general facet pages :)

declare function olap:facet-list($context) {
<div>
    <div class="nav">
        {url:path-menu($context/_root,$context/_path,(),$config:map)}
    </div>
    <div> 
          <table class="sortable"> 
            <tr><th>Code</th><th>Name</th><th>Activities</th><th>Included</th><th>Value</th></tr>
            {
             for $facet-occ in olap:facet($context/corpus,$context/facet)
             order by $facet-occ/code
             return
                   <tr>
                      <th><a href="{$context/_root}corpus/{$context/corpus}/facet/{$context/facet}/code/{$facet-occ/code}">{$facet-occ/code/string()}</a></th>
                      <td>{$facet-occ/name/string()}</td>
                      <td>{$facet-occ/count-all/string()}</td>
                      <td>{$facet-occ/count/string()}</td>
                      {if ($facet-occ/value)
                       then <td>{num:format-number(xs:double($facet-occ/value),"$,000")}</td>
                       else ()
                       }
                   </tr>
            }
         </table> 
     </div>
</div>   
};

declare function olap:publisher-stats($context) {
 let $facet := olap:meta-facet($context/corpus,"Publisher") 
 let $facet-occ := olap:facet-code($context/corpus,"Publisher",$context/Publisher)
 return 
   if ($facet-occ)
   then olap:summary-page($facet-occ,$facet)
   else ()
};

declare function olap:facet-occ($context) {
 let $facet := olap:meta-facet($context/corpus,$context/facet) 
 let $value := $context/code
 let $facet-occ := olap:facet-code($context/corpus,$context/facet,$value)
 let $name := $facet-occ/name
 return
      <div> 
            <div class="nav">
                {url:path-menu($context/_root,$context/_path,("activity"),$config:map)}
                {if ($facet/@feed)
                 then ( " > ", <a href="{$context/_fullpath}.rss"  title="RSS feed for changes in the last {$config:rss-age} days">RSS</a>)
                 else ()
                 }
            </div>
            <h2>{$value} : {$name/string()}</h2>
            {olap:summary-page($facet-occ,$facet) } 
            {if ($facet/link)
             then 
           <div>
            <h3>Links</h3>
             <ul>
              {for $link in $facet/link
              let $href := replace($link/@href,"\{value\}",$value)
              return
               <li>
                 {if ($link/@iframe)
                 then <iframe src="{$href}" width="600" height="800" frameborder="0"/>
                 else <a class="external" href="{$href}">{$link/@label/string()}</a>
                 }
               </li>
              }
              </ul>
            </div>
             else ()
            }
</div>   
};

declare function olap:select-facet-activities($facet,$context) {
<div>
   {$facet}
   {$context}
</div>
};

declare function olap:facet-occ-activities( $context) as element(div) {
   let $facet := olap:meta-facet($context/corpus,$context/facet) 
   let $value := $context/code
   let $dir := concat($config:data,$context/corpus,"/activities")
   let $exp := concat("collection($dir)/iati-activity[",$facet/@element,"/",$facet/@path,"= $value]")
   let $activities :=  util:eval($exp)
   let $facet-occ := olap:facet-code($context/corpus,$context/facet,$value)
   return
       <div>
           <div class="nav">
              {url:path-menu($context/_root,$context/_path,(),$config:map)}
             </div>
           <h3>{$facet-occ/name/string()}</h3>
           {activity:page($activities,$context,concat($context/_root,"corpus/",$context/corpus,"/facet/",$context/facet,"/code/",$value,"/activity"))}        
       </div>
};


(: 
devised for a tree structure facet analysis - not yet needed - would need rework 
declare function olap:tree-group($activities as element(iati-activity)*, $facets as element(param)*, $corpus , $levels)  {
if (empty($facets))
then 
   element summary{
       element value { sum ($activities/@iati-ad:project-value) },
       element count {count($activities)},
       olap:sum-activities($activities)
   }
else
let $facet := $facets[1]
let $facet := element facet {$facet/@name/string()}
let $sub-facets := subsequence($facets,2)
let $group-exp := concat("distinct-values($activities/",$facet/@path,")")
let $group-codes := util:eval($group-exp)
return
for $group-code in $group-codes
let $code := codes:code-value($facet/@name,$group-code,$corpus)
let $exp := concat("$activities[",$facet/@path, " eq $group-code]")
let $group-activities := util:eval($exp)
let $level :=
        element level {
            $facet,
            $code/name,
            element code {$group-code}
         } 
let $levels  := ($levels,$level)
return
   if (empty($sub-facets))
   then 
     let $e := if (empty($levels/facet)) then error ((),"x",$levels) else ()
     return
     element {concat(string-join($levels/facet,"-"),"-summary")} {
       for $level in $levels
       return (
              element {concat($level/facet,"-code")} {$level/code/string()},
              element {concat($level/facet,"-name")} {$level/name/string()}
               ),
       element value {sum ($group-activities/@iati-ad:project-value) },
       element count {count($group-activities)},
       olap:sum-activities($group-activities)
   }
   else 
       olap:tree-group($group-activities,$sub-facets,$corpus,$levels) 

};

declare function olap:group($activities as element(iati-activity)*, $facet as element(param)*, $corpus )  {
if (empty($facet))
then 
   element summary{
       element value { sum ($activities/@iati-ad:project-value) },
       element count {count($activities)},
       olap:sum-activities($activities)
   }
else
let $facet := $facet/@name/string()
let $group-exp := concat("distinct-values($activities/",$facet/@path,")")
let $group-codes := util:eval($group-exp)
return
for $group-code in $group-codes
let $code := codes:code-value($facet/@name,$group-code,$corpus)
let $exp := concat("$activities[",$facet/@path, " eq $group-code]")
let $group-activities := util:eval($exp)
return
     element {$facet} {   
       element code {$group-code},
       element name {$code/name/string()},
       element value {sum ($group-activities/@iati-ad:project-value) },
       element count {count($group-activities)},
       olap:sum-activities($group-activities)
    }
};

:)
