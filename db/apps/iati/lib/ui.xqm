xquery version "3.0";
module namespace ui = "http://tools.aidinfolabs.org/api/ui";
declare namespace iati-ad = "http://tools.aidinfolabs.org/api/AugmentedData";

import module namespace rules = "http://tools.aidinfolabs.org/api/rules" at "../lib/rules.xqm";
import module namespace codes = "http://tools.aidinfolabs.org/api/codes" at "../lib/codes.xqm";  
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm";   
import module namespace pipeline = "http://tools.aidinfolabs.org/api/pipeline" at "../lib/pipeline.xqm";  
import module namespace olap = "http://tools.aidinfolabs.org/api/olap" at "../lib/olap.xqm";  
import module namespace api = "http://tools.aidinfolabs.org/api/api" at "../lib/api.xqm";  
import module namespace sys= "http://tools.aidinfolabs.org/api/sys" at "../lib/sys.xqm";  
import module namespace admin = "http://tools.aidinfolabs.org/api/admin" at "../lib/admin.xqm";  
import module namespace log= "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace rss = "http://tools.aidinfolabs.org/api/rss" at "../lib/rss.xqm";  
import module namespace jobs = "http://tools.aidinfolabs.org/api/jobs" at "../lib/jobs.xqm";
import module namespace test = "http://tools.aidinfolabs.org/api/test" at "../lib/test.xqm";
import module namespace corpus= "http://tools.aidinfolabs.org/api/corpus" at "../lib/corpus.xqm";
import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";
import module namespace url = "http://kitwallace.me/url" at "/db/lib/url.xqm";

(: 
this very large selection is the dispatcher for HTML page requests - 
the if ()then ..else structure would be better implement in XQuery 3 using a switch statement 
or a table lookup and eval 
:)


declare function ui:content($context) { 

  if (not($config:islive)) then ui:offline($context)
  else switch ($context/_signature) 
     case "" return ui:home($context)
     case "corpus" return ui:all-corpus($context)
     case "corpus/*" return ui:corpus($context)
     case "corpus/*/search" return ui:corpus-search($context)
     case "corpus/*/Publisher"  return ui:publishers($context)
     case "corpus/*/Publisher/*" return  ui:publisher($context)
 (:  caee "corpus/*/profile" return ui:publisher-profile($context) :)
     case "corpus/*/Publisher/*/set" return  ui:set-page($context, activity:publisher-activitySets($context/corpus,$context/Publisher))
     case "corpus/*/Publisher/*/set/*"  return  ui:set-activity-page($context, activity:set-activities($context/corpus,$context/set))
     case "corpus/*/Publisher/*/set/*/activity" return  ui:set-activity-page($context, activity:set-activities($context/corpus,$context/set))
     case "corpus/*/Publisher/*/set/*/activity/*" return  ui:activity-page($context, activity:activity($context/corpus,$context/activity),false())
 
     case "corpus/*/set" return   ui:set-page($context, activity:activitySets($context/corpus))
     case "corpus/*/set/*" return   ui:set-page($context, activity:activitySet($context/corpus,$context/set)) 
     case "corpus/*/set/*/activity" return   ui:set-activity-page($context,  activity:set-activities($context/corpus,$context/set))
     case "corpus/*/set/*/activity/*" return  ui:activity-page($context, activity:activity($context/corpus,$context/activity),false())
     case "corpus/*/facet" return  ui:corpus-facets($context)       
     case "corpus/*/facet/*" return  olap:facet-list($context)        
     case "corpus/*/facet/*/code" return  olap:facet-list($context)        
     case "corpus/*/facet/*/code/*" return   olap:facet-occ($context)       
     case "corpus/*/facet/*/code/*/activity" return  olap:facet-occ-activities($context)       
     case "corpus/*/facet/*/code/*/activity/*" return  ui:activity-page($context, activity:activity($context/corpus,$context/activity),false())
     case "corpus/*/activity" return  ui:activities-page($context,activity:corpus($context/corpus))
     case "corpus/*/activity/*" return  ui:activity-page($context, activity:activity($context/corpus,$context/activity),true())
     case "corpus/*/activity/*/full" return  ui:activity-full($context) 
     case "corpus/*/activity/*/profile" return  ui:activity-profile($context)
     case "corpus/*/activity/*/profile/*/errors" return  ui:activity-profile-errors($context) 
     case "corpus/*/activity/*/profile/*/full" return  ui:activity-profile-full($context)
     case "corpus/*/activity/*/profile/*/summary"return   ui:activity-profile-summary($context)
     case "corpus/*/select"  return ui:corpus-select($context)
     case "profile" return  ui:profiles($context)
     case "profile/*"  return ui:profile($context)
     case "corpus/*/activity/*/profile/*" return  ui:profile($context)
     case "codelist" return  ui:codelists($context) 
     case "codelist/*/metadata" return  ui:codelist-metadata($context) 
     case "codelist/*/rules" return  ui:codelist-rules($context) 
     case "codelist/*" return  ui:codelist($context)
     case "codelist/*/version/*/lang/*" return  ui:codelist-version($context)
     case "codelist/*/lang/*" return  ui:codelist-language($context)
     case "ruleset" return  ui:rulesets($context) 
     case "ruleset/*" return  ui:ruleset($context)
     case "rule/*" return  ui:rule($context) 
     case "pipeline" return  ui:pipelines($context)
     case "pipeline/*" return  ui:pipeline($context)
 (:    case "element/*"  return  ui:elements($context) :)
     case "doc" return   ui:documents($context)   (: depricated :)
     case "doc/*" return  ui:document($context)  (:depricated :)
     case "about" return  ui:documents($context)
     case "about/*" return  ui:document($context)   
     case "load" return  
                 if ($context/pin = $config:pin ) 
                 then ui:load-url(element context { $context/(* except corpus), element corpus {"vstore"}, element mode {"refresh"} } )
                 else ()

     default return
        if ($context/_isadmin) 
        then  switch ($context/_signature)
           case  "jobs" return  ui:page($context,jobs:html-list($context))
           case  "reindex" return  ui:page($context, admin:reindex() )    
           case  "initialize" return   ui:page($context,admin:initialize())
           case  "codelist-cache" return  ui:codelist-cache($context)
           case  "resources" return  ui:resources($context)
           case  "resources/*/view" return  ui:page($context, sys:view-resources($context/resources) )
           case  "resources/*/export" return   ui:page($context, sys:zip-resources($context/resources))
           case  "test" return   ui:page($context,test:list-tests($context))
           case  "test/*" return ui:page($context,test:do-testSet($context/test))
           case  "systemProperties" return  ui:page($context,wfn:element-to-nested-table(sys:system-properties()) )     
           case  "corpus/*/reindex" return  ui:page($context,jobs:start-reindex($context/corpus))
  (:         case  "corpus/*/cacheorgs" return   ui:cache-org-codes($context) :)
           case  "corpus/*/olap" return  ui:page($context,jobs:start-olap($context))
           case  "corpus/*/ckan" return  ui:page($context,activity:package-page($context))
           case  "corpus/*/ckanall"return  ui:page($context,jobs:start-ckan($context/corpus))
           case  "corpus/*/download" return  ui:page($context,jobs:start-download($context/corpus,"","","download") )
           case  "corpus/*/update" return  ui:page($context,jobs:start-download($context/corpus,"","","update") )
           case  "corpus/*/clear" return  ui:page($context,corpus:clear($context/corpus))   
           case  "corpus/*/browseLog" return  ui:page($context,log:html($context))
           case  "corpus/*/browseAPILog" return  ui:page($context,api:view-log($context))
           case  "corpus/*/export/*"return   ui:corpus-export($context)   
           case  "corpus/*/report" return  ui:set-page($context, activity:activitySets-download-required($context/corpus))
           case  "corpus/*/Publisher/*/download" return  ui:publisher-download($context,true())
           case  "corpus/*/Publisher/*/update"  return ui:publisher-download($context,false())
           case  "corpus/*/Publisher/*/delete" return  ui:remove-activities($context, activity:publisher-activitySets($context/corpus,$context/Publisher))
           case  "corpus/*/load" return  ui:load-url(element context {$context/*, element mode {"refresh"} } )
           case  "corpus/*/set/*/download" return  ui:set-download($context, activity:activitySet($context/corpus,$context/set),true())
           case  "corpus/*/set/*/update" return  ui:set-download($context, activity:activitySet($context/corpus,$context/set), false())
           case  "corpus/*/set/*/delete" return  ui:remove-activities($context, activity:activitySet($context/corpus,$context/set))
           case  "corpus/*/facet/*/update"return   ui:page($context,jobs:start-olap($context))
           default return ui:error-page($context)        
       else  ui:error-page($context)        
};
  

declare function ui:offline($context) as element(div) {
   <div>
     The AidInfo IATI Dataviewer is currently offline for maintenance
   </div>
};

declare function ui:page($context,$body) as element(div) {
   <div>
          {($body/div[@class="nav"],
           <div class="nav">{url:path-menu($context/_root,$context/_path,(),$config:map)} </div>
          )[1]
          }
          <div class="content">
            {($body/div[@class="content"],$body)[1]}
          </div>
   </div>
};

declare function ui:error-page($context) as element(div) {
   ui:page($context,
      <div>
          <h2>URL pattern not recognized</h2>
            {transform:transform(element xml-source {$context}, doc(concat($config:base,"assets/xml2html.xsl")),())}
      </div>
   )
};

(:  the following functions are called from the dispatcher :)


declare function ui:home($context) as element(div) {
 <div>
         <div class="nav">
              <span>Home</span> >
              <a href="{$context/_root}codelist">Codelists</a> |
              <a href="{$context/_root}ruleset">Rulesets</a> |
              <a href="{$context/_root}corpus">Corpuses</a> | 
              <a href="{$context/_root}profile">Profiles</a> |
              <a href="{$context/_root}pipeline">Pipelines</a> |
              <a href="{$context/_root}about">About</a> 
              |  {if ($context/_isadmin)
                 then if ($context/_isrest ) 
                      then <a href="/data/">Public</a>
                      else <a href="data.xq">Public</a> 
                 else if ($context/_isrest)
                      then <a title="requires authentication"  href="/admin/">Admin</a> 
                      else <a title="requires authentication"  href="admin.xq">Admin</a>                      
                 }
              {if ($context/_isadmin) then (" | ",<a href="{$context/_root}jobs">Scheduled Jobs</a> ) else ()}
         </div>
         <div class="content">
               <div>
               <h2>Overview</h2>
               <div>This site provides access to IATI activity documents gathered from their sources around the world via the IATI Registry. It was originaly devloped to provide data for the AidView visualisation but conatins its own faceted browser of activities
               See <a href="{$context/_root}about/sampleURLs">Sample URLs </a> for an overview of the public site functions. The protected admin interface provides furthe access to maintenance and testing functiions.
               </div>
               </div>
              
             <div>
               <h2>Project Links</h2>
               <ul>
                <li><a target="_blank" href="{if ($context/_isrest ) then "/" else "../"}xquery/woapi.xq?result=help">Query API</a></li>
                <li><a href="https://github.com/KitWallace/AIDVIEW-DB">AIDVIEW-DB Github repository and issues</a></li>
                <li><a href="https://github.com/KitWallace/AIDVIEW-DB/issues">Issue list</a></li>
                <li><a target="_blank" href="http://exist-db.org">eXist-db</a></li>
                <li><a target="_blank" href="http://opencirce.org/org">Open Circe </a>  OrganisationIdentifiers</li>   
            
               </ul>
               <h2>IATI Links</h2>
              <ul>
                <li><a target="_blank" class="external" href="http://www.aidview.net/">AidView</a></li>
                <li><a target="_blank" class="external" href="http://wiki.iatistandard.org/">IATI Wiki</a></li>
                <li><a target="_blank" class="external" href="http://www.iatistandard.org">IATI Standard</a></li>
                <li><a target="_blank" class="external" href="http://www.iatiregistry.org/">IATI Registry</a></li>
                <li><a target="_blank" class="external" href="http://www.aidinfo.org/">AidInfo</a></li>
                <li><a target="_blank" class="external" href="http://tools.aidinfolabs.org/">AidInfoLabs</a></li>
                <li><a target="_blank" class="external" href="http://tools.aidinfolabs.org/explorer">IATI Data Explorer</a></li>
                <li><a href="http://bntest.vm.bytemark.co.uk:8080/trac/report/1">Bug Tracker</a></li>
                </ul>
              </div>
               {if ($context/_isadmin)
                then 
                 <div>
                 <h2>Admin tasks</h2>
                 <ul>
                   <li><a href="{$context/_root}initialize">Initialize iati-data</a></li>
                   <li><a href="{$context/_root}test">Run unit tests</a></li>
                   <li><a href="{$context/_root}reindex">Reindex system files</a></li>
                   <li><a href="{$context/_root}resources">View and export application resources</a>  </li>
                   <li><a href="{$context/_root}systemProperties">System Properties</a></li>
                 </ul>
                 
                 </div>
                else ()
               }
               <div>
               <div>
              
               <h2>Test Activity Set</h2>
               
               Load and validate an arbitrary activitySet document:
                <form action='{if ($context/_isrest) then concat($context/_root,"load") else "?"}' >
               {if ($context/_isrest)
                then ()
                else <input type="hidden" name="_path" value="load"/>
               }
               URL <input type="text" name="url" size="60" value=""/> Pin <input type="password" name="pin" size="10"/>
               <input type="submit" value="Load"/>
               </form>
               </div>
           </div>
        </div>
</div>
};


declare function ui:resources($context) as element(div) {
  ui:page($context,
        <ul>
            {for $export in $config:export
             return
                <li><a href="{$context/_root}resources/{$export}/view">View </a> and <a href="{$context/_root}resources/{$export}/export">Export</a> Code and configuration Resources </li>
            }
       </ul>
   )
};

declare function ui:all-corpus($context) {
   <div>
      <div class="nav">
            {url:path-menu($context/_root,$context/_path,(),$config:map)}  
            <span> |<a href="{$context/_root}doc/corpus">About</a> </span> 
      </div>
      <div class="content">
          <ul>
            {
            let $corpii := corpus:meta()
            let $corpii := if ($context/_isadmin) then $corpii else $corpii[empty(temp)]
            for $corpus in $corpii
            return
               <li><a href="{$context/_root}corpus/{$corpus/name}">{$corpus/name/string()}</a> : {$corpus/description/text()} &#160; {if ($corpus/default) then <em>Default</em> else () }</li>
            }  
          </ul>
     </div>
  </div>
};


declare function ui:corpus($context) as element(div) {
  let $corpus := corpus:meta($context/corpus)
  return
       <div>
           <div class="nav">
               {url:path-menu($context/_root,$context/_path,("Publisher","facet","set", "activity","search","report"),$config:map)}  
               <span>|  <a href="{if ($context/_isrest ) then "/" else "../"}xquery/woapi.xq?corpus={$context/corpus}&amp;result=help">Query API</a> </span>
          </div>
          <div class="content">
            <div>
            <h2>Description</h2>
                {$corpus/description/(*,text())}
            </div>
            <h2>Summary</h2>
            <div>
              {let $sets := activity:activitySets($context/corpus)
               let $stale := olap:is-stale($context/corpus)
               let $olap  := if (not($stale)) then olap:facet($context/corpus,"Corpus") else ()
               let $activities := if ($stale) then activity:corpus($context/corpus) else ()
  
               return
                 <table>
                    <tr><th>Number of Sets </th><td>{count($sets)}</td></tr>
                    <tr><th>Number of Valid Sets </th><td>{count($sets[empty(error)])}</td></tr>
                    <tr><th>Number of Sets awaiting download </th><td>{count($sets[activity:download-required(.)])}</td></tr>      
                    <tr><th>Number of Sets downloaded </th><td>{count($sets[download-modified])}</td></tr>
                    <tr><th>Total number of activities</th><td>{if (not($stale)) then $olap/count-all/string() else count($activities)}</td></tr>
                    <tr><th>Number included in AidView </th><td>{if (not($stale)) then $olap/count/string() else count($activities[@iati-ad:include])}</td></tr> 
                    <tr><th>ActivitiesSets updated</th><td>{activity:activitySets-last-ckan-update($context/corpus)}</td></tr>
                    <tr><th>Activities updated</th><td>{corpus:activities-last-updated($context/corpus)}</td></tr>
                    <tr><th>OLAP updated</th><td>{olap:last-updated($context/corpus)} - {if ($stale) then "Stale" else "Current"}</td></tr>
                 </table>
               }
            </div>
            <div>
                {ui:corpus-search-form($context)}         
            </div>
            <div>
                {ui:corpus-select-form($context)}         
            </div>
            {if (empty($context/_isadmin)) then ()
             else 
            <div>            
               <h2>Load Activity Set</h2>           
               Load an activitySet document from source :
               <form action="?">
               <input type="hidden" name="_path" value="corpus/{$context/corpus}/load"/>
               URL <input type="text" name="url" size="60"/> 
               <input type="submit" value="Load"/>
               </form>            
              <h2>Tasks</h2>
               <ul>
                   <li><a href="{$context/_root}corpus/{$context/corpus}/ckanall">Full Refresh from CKAN</a> Runs the full extract as a background task</li>
                   <li><a href="{$context/_root}corpus/{$context/corpus}/update">Update</a> Update all sets as required</li>
                   <li><a href="{$context/_root}corpus/{$context/corpus}/download">Download</a> Force download of all sets - use only for initialization of a corpus</li>
                   <!-- <li><a href="{$context/_root}corpus/{$context/corpus}/cacheorgs">Cache Organisational Codes</a>Mine a full set of organisation Identifiers from this corpus</li> -->
                   <li><a href="{$context/_root}corpus/{$context/corpus}/olap">Create OLAP</a> Create the OLAP summary - required after a download to bring the summaries inline</li>
                   <li><a href="{$context/_root}corpus/{$context/corpus}/reindex">Reindex</a> Reindex the corpus data.</li>
                   <li><a href="{$context/_root}corpus/{$context/corpus}/backup">Backup</a>This zips the data in the corpus into a file in /var/www/backups so that it can be copied externally - approx 2k * no of activities </li>
                   {if ($corpus/@temp)
                   then   <li><a href="{$context/_root}corpus/{$context/corpus}/clear">Clear</a> Clear the corpus data.</li>
                   else ()
                   }
                    <li><a href="{$context/_root}corpus/{$context/corpus}/browseAPILog">Browse request Log</a>  </li>                  
                    <li><a href="{$context/_root}corpus/{$context/corpus}/browseLog">Browse update Log</a> </li>                  
                </ul>
           
            </div>
          }
       </div>
 </div>
};

declare function ui:corpus-facets($context) as element(div) {
  let $corpus := corpus:meta($context/corpus)
  return
       <div>
           <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)}  
             </div>
            <div> 
            <ul>
               {for $facet in (olap:meta-facets($context/corpus)/@name/string(),"Corpus")
                return 
                   <li><a href="{$context/_root}corpus/{$context/corpus}/facet/{$facet}">{$facet}</a> &#160;
                   {if ($context/_isadmin)
                    then <a href="{$context/_root}corpus/{$context/corpus}/facet/{$facet}/update">Update</a>
                    else ()
                   }
                   </li>
               }
              
            </ul>
            </div>
      </div>
};


declare function ui:corpus-stats($context) as element(div) {
    <div>
         <div class="nav">
             {url:path-menu($context/_root,$context/_path,(),$config:map)}  
         </div>
             {olap:update-corpus($context)}   
    </div>  
};



declare function ui:corpus-export($context) as element(div) {
 
    <div>
            <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)} 
               
            </div>

           <div>
            {$context/export}
           </div>
   
    </div>
};

declare function ui:corpus-search-form($context) {
       <form action='{if ($context/_isrest) then concat($context/_root,"corpus/",$context/corpus,"/search") else "?"}' >
               {if ($context/_isrest)
                then ()
                else <input type="hidden" name="_path" value="corpus/{$context/corpus}/search"/>
               }
               Search activity descriptions and titles <input type="text" name="q" value="{$context/q}" size="40"/>
               <input type="submit" value="search"/>
        </form> 
};

declare function ui:corpus-search($context) {
   let $results := 
    if ($context/q)
    then collection(concat($config:data,$context/corpus,"/activities"))/iati-activity[ft:query((title|description), $context/q/string())]
    else ()
   return 
      <div>
            <div class="nav">
            
               {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}doc/activities">About</a>
            </div>
            <div> 
               {ui:corpus-search-form($context)}
               {activity:page($results,$context, concat($context/_root,"corpus/",$context/corpus,"/activity"),concat($context/_root,"corpus/",$context/corpus,"/search",if($context/_isrest) then "?" else "&amp;","q=",$context/q))}
            </div>
     </div>
};    

declare function ui:corpus-select-form($context) {
       <form action='{if ($context/_isrest) then concat($context/_root,"corpus/",$context/corpus,"/select") else "?"}' >
               {if ($context/_isrest)
                then ()
                else <input type="hidden" name="_path" value="corpus/{$context/corpus}/select"/>
               }
               Select Activities by path <input type="text" name="q" value="{$context/q}" size="40"/>
               <input type="submit" value="search"/>
        </form> 
};

declare function ui:corpus-select($context) as element(div) {
let $exp :=  concat('collection(concat($config:data,$context/corpus,"/activities"))/iati-activity[',$context/q,"]")
let $selected-activities := util:eval($exp)
let $count := count ($selected-activities)
return
   <div>
           <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)}               
           </div>
           {ui:corpus-select-form($context)}
           Number of selected activities {$count}

           <div>
           {activity:page($selected-activities,$context,concat($context/_root,"corpus/",$context/corpus,"/activity"),concat($context/_root,"corpus/",$context/corpus,"/select",if($context/_isrest) then "?" else "&amp;","q=",$context/q))} 
           </div>  
   </div>
};

declare function ui:cache-org-codes($context) {
        <div>
             <div class="nav">
                {url:path-menu($context/_root,$context/_path,(),$config:map)} 
            </div>
            <div>
               {codes:cache-organisation-identifier-codes($context/corpus)}
            </div>
        </div>

};

declare function ui:publishers($context) {
 <div>
            <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)}  
            </div>

            <div>

           <h2>Publishers</h2>
           <table class="sortable"> 
             <tr><th>Publisher</th><th>Sets</th><th>Downloaded</th><th>Awaiting <br/>Download</th><th>New</th></tr>
            {for $publisher in  activity:corpus-publishers($context/corpus)
             let $sets := activity:publisher-activitySets($context/corpus,$publisher)
             order by $publisher
             return
                   <tr>
                      <td><a href="{$context/_root}corpus/{$context/corpus}/Publisher/{$publisher}">{$publisher}</a></td>
                      <td>{count($sets)}</td>
                      <td>{count($sets[download-modified])}</td>
                      <td>{count($sets[activity:download-required(.)])}</td>
                      <td>{count($sets[activity:since-last-ckan($context/corpus,.)])}</td>
                   </tr>
            }
         </table>   
         </div>
</div>
};

declare function ui:publisher($context) {
(:  need to link - scrape api/rest/group/{context/Publisher} here   :)
      <div>
            <div class="nav">
               {url:path-menu($context/_root,$context/_path,("set",if ($context/_isadmin) then ("download", "update", "delete") else ()),$config:map)}
            </div>
            <div> 
              <h2>Current Summary</h2>
              {let $sets := activity:publisher-activitySets($context/corpus,$context/Publisher)
              let $activities := activity:set-activities($context/corpus,$sets/package) 
               let $download-required := activity:publisher-activitySets-download-required($context/corpus,$context/Publisher)
               return
                 <table>
                    <tr><th>Number of Sets </th><td>{count($sets)}</td></tr>
                    <tr><th>Number of Sets downloaded </th><td>{count($sets[download-modified])}</td></tr>
                    <tr><th>Number of Sets awaiting download </th><td>{count($download-required)}</td></tr>
                    <tr><th>Total number of activities</th><td>{count($activities)}</td></tr>
                    <tr><th>Number included </th><td>{count($activities[@iati-ad:include])}</td></tr>
         
                    <tr><th>CKAN publisher </th><td><a class="external" href="{$config:ckan-base}publisher/{$context/Publisher}">CKAN</a></td></tr>
                    
                  </table>
              }
              {
              let $cached-summary := olap:publisher-stats($context)
              return 
                if ($cached-summary)
                then
                  <div>
                     <h2>Cached summary</h2>
                     {$cached-summary}
                 </div>
              else ()
              }            
            </div>          
      </div>
};

declare function ui:set-page($context, $activitySets) {
       <div>
            <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)}
             </div>
            {activity:set-page($activitySets,$context,$context/_fullpath)}                 
       </div>
};      

declare function ui:set-activity-page($context, $activities) {
  <div>
            <div class="nav">
                    {url:path-menu($context/_root,$context/_path,(),$config:map)}
    <!--          > 
            <a href="{$context/_root}corpus/{$context/corpus}/profile/{$context/set}">Profile</a>  until set profiling available -->
            </div>
             {activity:page($activities,$context,$context/_fullpath,$context/_fullpath)}        
  </div> 
};

declare function ui:publisher-download($context,$refresh) {
  <div>
            <div class="nav">
                    {url:path-menu($context/_root,$context/_path,(),$config:map)}
            </div>
            {jobs:start-download($context/corpus,$context/Publisher,"",if ($refresh) then "download" else "update") }        
  </div> 
};


declare function ui:set-download($context, $activitySets, $refresh) {
  <div>
            <div class="nav">
                    {url:path-menu($context/_root, concat("corpus/",$context/corpus,"/"),(),$config:map)}
            >  <span>{$context/set}</span>
               <span>{if ($refresh) then "Download" else "Update"}</span> >
            </div>
           {let $download := activity:download-activitySets($activitySets,$context,$refresh)
            return activity:set-page($activitySets,$context,$context/_fullpath)
           }        
  </div> 
};

declare function ui:remove-activities($context, $activitySets) {
  <div>
            <div class="nav">
                    {url:path-menu($context/_root,concat("corpus/",$context/corpus,"/"),(),$config:map)}
            >  
               <span>Delete activities</span> >
            </div>
           {activity:remove-activities($activitySets,$context)}        
  </div> 
};

declare function ui:activities-page($context,$activities) {
<div>
            <div class="nav">
               {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}doc/activities">About</a>
            </div>
             {activity:page($activities,$context,concat($context/_root,"corpus/",$context/corpus,"/activity"))}
</div>
};

declare function ui:activity-page($context,$activity,$main) {
 <div>
           <div class="nav">
              {url:path-menu($context/_root,$context/_path,if ($main) then ("full","profile") else (),$config:map)}             
                   <span>| <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($context/activity)}/profile">Profile</a> </span>
                   <span>| <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($context/activity)}.xml">XML</a> </span>              
                   <span>&lt; <a href="{$context/_root}corpus/{$context/corpus}/set/{$activity/@iati-ad:activitySet}">Activity Set</a> </span>
            </div>
            <div>          
                {activity:as-html($activity,$context)}
           </div>
</div>
};  

declare function ui:load-url($context) {
  if ($context/url)
  then 
     let $set :=  activity:external-activitySet($context)
     return   
        ui:set-page($context,$set)
   else ()
};

declare function ui:activity-full($context) {
        let $activity :=  activity:activity($context/corpus,$context/activity)
        return
           <div>
              <div class="nav">
                {url:path-menu($context/_root,$context/_path,(),$config:map)}
           </div>
              <div>
                 {rules:view-doc($activity,())}
              </div>
           </div>   
};

declare function ui:activity-profile($context) {
           <div>
              <div class="nav">
                 {url:path-menu($context/_root,$context/_path,(),$config:map)}
              </div>
              <div>
                <ul>
                  {for $profile in $rules:profiles[@root="activity"]
                   let $name := $profile/@name/string()
                   order by $name
                   return
                      <li>{$name} :  {$profile/description/node()} >
                        <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($context/activity)}/profile/{$name}/errors">errors</a> |
                        <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($context/activity)}/profile/{$name}/full">full</a> |
                        <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($context/activity)}/profile/{$name}/summary">summary</a> 
                      </li>
                  }
                </ul>
              </div>
           </div>  
};          

declare function ui:activity-profile-errors($context) {
        let $activity :=  activity:activity($context/corpus,$context/activity)
        let $rules := rules:profile-rules($context/profile)
        let $report := rules:validate-doc($activity, $rules,"errors") 
        return
           <div>
              <div class="nav">
                 {url:path-menu($context/_root,$context/_path,(),$config:map)}
                 <a href="{concat($context/_fullpath,'.xml')}">XML</a>
              </div>
              <div>
                  {$report}
              </div>
           </div> 
};

declare function ui:activity-profile-full($context) {
        let $activity :=  activity:activity($context/corpus,$context/activity)
        let $rules := rules:profile-rules($context/profile)
        let $report := rules:validate-doc($activity, $rules,"full") 
        return
           <div>
              <div class="nav">
                 {url:path-menu($context/_root,$context/_path,(),$config:map)}
                 <a href="{concat($context/_fullpath,'.xml')}">XML</a>
               </div>
              <div>
                {$report}
              </div>
           </div>  
};

declare function ui:activity-profile-summary($context) {
        let $activity :=   activity:activity($context/corpus,$context/activity)
        let $rules := rules:profile-rules($context/profile)
        let $errors := rules:validation-errors($activity,  $rules)
        let $summary := rules:error-summary($errors)
        let $report := rules:error-summary-as-html($context, $summary)
        return
           <div>
              <div class="nav">
                  {url:path-menu($context/_root,$context/_path,(),$config:map)}
                  <a href="{concat($context/_fullpath,'.xml')}">XML</a>
              </div>
              <div>
                {$report}
              </div>
           </div>  
};

declare function ui:profiles($context) {
           <div>
             <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <span>Profiles</span> >
              <a href="{$context/_root}doc/profiles"> About</a>
            </div>
            {rules:profiles-as-html($context)}
         </div>
};

declare function ui:profile($context) {
           <div>
             <div class="nav">
              <a href="">Home</a> >
              <a href="{$context/_root}profile">Profiles</a> >
              <span>{$context/profile/string()}</span>              
            </div>
            {rules:profile-as-html($context)}
         </div>
};

declare function ui:codelists($context) {
         <div>
             <div class="nav">
                {url:path-menu($context/_root,$context/_path,(),$config:map)}
                <a href="{$context/_root}codelist.xml">xml</a> |
                <a href="{$context/_root}codelist.csv">csv</a> |
                <a href="{$context/_root}doc/codelist"> About</a> 
                {if ($context/_isadmin) then (" | ", <a href="{$context/_root}codelist-cache" title="Cache the current versions of the code lists">Cache</a> ) else ()}
             </div>
             {codes:code-index-as-html($context)}
        </div>
};


declare function ui:codelist-cache($context) {
         <div>
             <div class="nav">
                {url:path-menu($context/_root,"codelist/cache",(),$config:map)} 
            </div>
            {codes:cache-codes()}
        </div>
};


declare function ui:codelist-metadata($context) {
           <div>
             <div class="nav"> 
              {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}codelist/{$context/codelist}/metadata.xml">xml</a> |
              <a href="{$context/_root}codelist/{$context/codelist}/rules">Rules</a>
           </div>
             {codes:code-list-metadata-as-html($context)}
           </div>
};                  

declare function ui:codelist-rules($context) {
           <div>
             <div class="nav"> 
              {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}codelist/{$context/codelist}/rules.xml">xml</a> 
             </div>
             {rules:codelist-rules-as-html($context)}
           </div>
};

declare function ui:codelist ($context) {
           <div>
             <div class="nav">
              {url:path-menu($context/_root,$context/_path,('metadata'),$config:map)}
             |
              <a href="{$context/_root}codelist/{$context/codelist}.xml">xml</a> |
              <a href="{$context/_root}codelist/{$context/codelist}.csv">csv</a>
             </div>
             {codes:code-list-as-html($context/codelist,(),())}
           </div>
};

declare function ui:codelist-version($context) { 
           <div>
             <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <a href="{$context/_root}codelist">Codelists</a> >
              <span>{$context/codelist/string()}</span> |
              <a href="{$context/_root}codelist/{$context/codelist}/metadata">Metadata</a> |
              <a href="{$context/_root}codelist/{$context/codelist}/version/{$context/version}/lang/{$context/lang}.xml">xml</a>  |
              <a href="{$context/_root}codelist/{$context/codelist}/version/{$context/version}/lang/{$context/lang}.csv">csv</a>
             </div>
             {codes:code-list-as-html($context/codelist,$context/version,$context/lang)}
           </div>
           
};        


declare function ui:codelist-language($context) { 
           <div>
             <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <a href="{$context/_root}codelist">Codelists</a> >
              <span>{$context/codelist/string()}</span> |
              <a href="{$context/_root}codelist/{$context/codelist}/metadata">Metadata</a> |
              <a href="{$context/_root}codelist/{$context/codelist}/lang/{$context/lang}.xml">xml</a>
              <a href="{$context/_root}codelist/{$context/codelist}/lang/{$context/lang}.csv">csv</a>
             </div>
             {codes:code-list-as-html($context/codelist,(),$context/lang)}
           </div>
};    

declare function ui:rulesets($context) { 
       <div>
            <div class="nav">
              {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}doc/rulesets"> About</a>
            </div>
              {rules:rulesets-as-html($context)}
        </div>
};

declare function ui:ruleset($context) {
       <div>
            <div class="nav">
             {url:path-menu($context/_root,$context/_path,(),$config:map)}
              <a href="{$context/_root}ruleset/{$context/ruleset}.xml">xml</a> |
              <a href="{$context/_root}ruleset/{$context/ruleset}.csv">csv</a>
            </div>
              {rules:ruleset-as-html($context)}
       </div>
};

declare function ui:rule($context) {
          let $rule := $rules:rulesets/rule[@id=$context/rule]
          let $ruleset := tokenize($context/rule,":")[1]
          return 
           <div>
            <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <a href="{$context/_root}ruleset">Rulesets</a> >
              <a href="{$context/_root}ruleset/{$ruleset}">{$ruleset}</a> >
              <span>{$context/rule/string()}</span>
            </div>
               {rules:rule-as-html($context)}
          </div>
};         

declare function ui:pipelines($context) {
       <div>
            <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <span>Pipelines</span> |
              <a href="{$context/_root}doc/pipelines"> About</a>
            </div>
              {pipeline:pipelines-as-html($context)}
          </div>
};
 
declare function ui:pipeline($context) {
        <div>
            <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <a href="{$context/_root}pipeline">Pipelines</a> >
              <span>{$context/pipeline}</span> |
              <a href="{$context/_root}pipeline/{$context/pipeline}.xml">xml</a>
            </div>
              {pipeline:pipeline-as-html($context)}
        </div>
};
  
declare function ui:documents($context) { 
          <div>
             <div class="nav">
               <a href="{$context/_root}">Home</a> >
               <span>About</span>

             </div>
             <div>
               {for $doc in collection (concat($config:base,"docs"))/div
                return 
                <li><a href="{$context/_root}about/{$doc/@id}">{$doc/h1/string()}</a> </li>
               }
             </div>
           </div>
};
 
declare function ui:document($context) { 

          let $doc := collection (concat($config:base,"docs"))/div[@id=$context/(about,doc)]
          return
            <div>
             <div class="nav">
               <a href="{$context/_root}">Home</a> >
               <a href="{$context/_root}about">About</a> >
               <span>{$doc/h1/string()}</span>

             </div>
             <div>
               {$doc}
             </div>
           </div>
};
 

declare function ui:xml($context) {
let $sig := $context/_signature
return 

          if ($sig="ruleset/*")  then  rules:ruleset(($context/ruleset)) 
     else if ($sig="pipeline/*") then pipeline:pipeline($context/pipeline)
     else if ($sig="corpus/*/activity/*")  then  activity:activity($context/corpus,$context/activity)
     else if ($sig="codelist") then $codes:metadata
     else if ($sig="codelist/*") then codes:codelist($context/codelist)
     else if ($sig="codelist/*/metadata")  then codes:code-metadata($context/codelist)
     else if ($sig="codelist/*/rules")  then <result codelist="{$context/codelist}">{rules:codelist-rules($context/codelist)}</result>
     else if ($sig="codelist/*/lang/*")  then codes:codelist($context/codelist,(),$context/lang)
     else if ($sig="codelist/*/version/*/lang/*")  then codes:codelist($context/codelist,$context/version,$context/lang)
     else if ($sig="codelist/*")  then codes:codelist($context/codelist,(),())
     else if ($sig="corpus/*/activity/*") then collection(concat("/db/apps/iati{$context/_root}",$context/corpus,"/activities"))/iati-activity[iati-identifier=$context/activity]     
     else if ($sig="corpus/*/activity/*/profile/*/errors")  
     then let $activity :=activity:activity($context/corpus,$context/activity)
          let $rules := rules:profile-rules($context/profile)
          return
             <report activity="{$context/activity}" created="{current-dateTime()}">
                 {rules:validation-errors($activity,  $rules)}
             </report>
     else if ($sig="corpus/*/activity/*/profile/*/summary")
     then let $activity := activity:activity($context/corpus,$context/activity)        
          let $rules := rules:profile-rules($context/profile)
          let $errors := rules:validation-errors($activity,  $rules)
          return rules:error-summary($errors)
     else if ($sig="corpus/*/activity/*")  then activity:activity($context/corpus,$context/activity) 
     else ()
};

declare function ui:csv($context) {
     let $sig := $context/_signature
     let $xml := ui:xml($context)
     return
       if ($sig="ruleset/*") then rules:ruleset-as-csv($context/ruleset)
       else  if ($sig="codelist/*") then  wfn:element-to-csv($xml)
       else  if ($sig="codelist/*/version/*/lang/*") then wfn:element-to-csv($xml)
       else  if ($sig="codelist/*/lang/*")  then wfn:element-to-csv($xml)
       else  if ($sig="codelist") then wfn:element-to-csv($xml)
       else ()
 };
 
 
declare function ui:rss($context) {
let $sig := $context/_signature
return 
            if ($sig="codelist") then codes:rss()
       else if ($sig="corpus/*/Country/*") then rss:country-feed($context)
       else if ($sig="corpus/*/SectorCategory/*") then rss:sectorCategory-feed($context)
       else ()
};


(: this function coerces a path to a query string - part of the unimplemented activity set profiling :)

(:
declare function ui:activitySelector($context) {
  string-join(
    (if ($context/set) then   concat("set=",$context/set) else (),
     if ($context/funder) then   concat("funder=",$context/funder) else (),
     if ($context/publisher) then   concat("publisher=",$context/publisher) else (),
     if ($context/activity) then   concat("activity=",$context/activity) else ()
    )
  ,"&amp;"
  )
};

:)

(:
     
declare function ui:publisher-profile($context) {
           let $selector := ui:activitySelector($context)
           return
           <div>
              <div class="nav">
                 {url:path-menu($context/_root,$context/_path,(),$config:map)}
              </div>
              <div>
               <h2>{$selector}</h2>
                <table>
                  {for $profile in $rules:profiles[@root="activity"]
                   let $name := $profile/@name/string()
                   return
                      <tr><th>{$name}</th>
                         <td>{$profile/description/node()}</td>
                         <td><a href="{$context/_root}corpus/{$context/corpus}/profile/{$name}/summary?{$selector}">Summary</a> </td>
                      </tr>
                  }
                </table>
              </div>
           </div>  
};
:)

(:  these paths for validation of selections of activities but this not yet implemented :)

(:

else if ($sig="corpus/*/profile/*/report") 
      then    
          let $rules := rules:profile-rules($context/profile)
          let $summaries :=
              for $activity in activity:corpus($context/corpus,$context/q)
              let $errors := rules:validation-errors($activity,  $rules)
              return rules:error-summary($errors)
          let $report := rules:profile-summary($summaries, $profile)
          return 
            <div>
             <div class="nav">
              <a href="{$context/_root}">Home</a> >
              <a href="{$context/_root}profile" >Profiles</a> >         
              <span>{$profile/@name/string()}</span>
            </div>
                 {rules:profile-report-to-html($report)}
             </div>
             
 :)   
(:          
      else if ($sig="corpus/*/profile/*/summary")
      then 
   just a test selecting only for a set 
        let $selector := ui:activitySelector($context)
        let $activities:= activity:corpus($context/corpus)[@iati-ad:activitySet = $context/set]
        let $rules := rules:profile-rules($context/profile)
        let $summaries := for $activity in $activities 
                        let $errors := rules:validation-errors($activity,$rules)
                        return rules:error-summary($errors)
        let $report := rules:profile-summary($summaries,rules:profile($context/profile))
         
        return
           <div>
              <div class="nav">
                 {url:path-menu($context/_root, concat("corpus/",$context/corpus,"/profile?",$selector,"Activity"),(),$config:map)}
              </div>
              <div>
              <h2>{$selector}</h2>
                {rules:profile-report-to-html($report)}
              </div>
           </div>  
:)
 