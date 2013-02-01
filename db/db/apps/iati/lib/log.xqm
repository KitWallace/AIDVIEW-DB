module namespace log = "http://tools.aidinfolabs.org/api/log";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";  

declare function log:write_xml($record) {
 let $xml-log-update :=
    if($record/severity=("warn","error")) then 

    let $dt := util:system-dateTime()
    let $log := doc(concat($config:data,$record/corpus,"/log.xml"))/log
    let $record := element record {attribute time {$dt}, $record/*}
    let $log-update := update insert  $record into $log
    return $record
  else ()
 return
    util:log-app('debug',"IATI",string-join($record/*,"-"))
};

declare function log:write($corpus,$severity,$action,$unit,$id,$data,$message) {
  let $xml-log-update :=
    if($severity=("warn","error")) then 
       let $dt := util:system-dateTime()
       let $log := doc(concat($config:data,$corpus,"/log.xml"))/log
       let $record := element record {attribute time {$dt},element level {$severity},element task{$action},element {$unit} {$id}, element data {$data}, element message {$message} }
       let $log-update := update insert  $record into $log
       return $record
    else ()
 return
   util:log-app("debug","IATI",string-join(($corpus,$action,$unit,$id,$data,$message),"-"))
};

declare function log:write($corpus,$severity,$action,$unit,$id,$message) {
 log:write($corpus,$severity,$action,$unit,$id,(),$message) 
};

declare function log:write($corpus,$severity,$action,$unit,$message) {
 log:write($corpus,$severity,$action,$unit,(),(),$message) 
};

declare function log:write($corpus,$severity,$action,$message) {
 log:write($corpus,$severity,$action,"none",(),(),$message) 
};

declare function log:html($context) {
  let $log := doc(concat($config:data,$context/corpus,"/log.xml"))
  return 
     <table class="sortable">
      <tr><th>time</th><th>Severity</th><th>Task</th><th>Object</th><th>Message</th></tr>
      {for $record in $log//record
       return
         <tr><td>{$record/@time/string()}</td>
             <td>{$record/level/string()}</td>
             <td>{$record/task/string()}</td>
              <td>
              {if ($record/host) 
              then <a href="{$context/_root}corpus/{$context/corpus}/Host/{$record/host}">{$record/host/string()}&#160;</a>
              else ()
             }
             {if ($record/package) 
              then <a href="{$context/_root}corpus/{$context/corpus}/set/{$record/package}">{$record/package/string()}&#160;</a>
              else ()
             }
             {if ($record/facet) 
              then concat("facet:",$record/facet)
              else ()
             }
             {if ($record/iati-identifier) 
              then <a href="{$context/_root}corpus/{$context/corpus}/activity/{wfn:URL-encode($record/iati-identifier)}">{$record/iati-identifier/string()}&#160;</a>
              else ()
             }
             {if ($record/download_url) 
              then <a href="{$record/download_url}">Download_url</a>
              else ()
             }
             </td> 
             <td>{$record/data/string()}</td>
             <td>{$record/message/string()}</td>
 
         </tr>
      }
    </table>
};