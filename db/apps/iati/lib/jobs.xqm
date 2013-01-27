module namespace jobs = "http://tools.aidinfolabs.org/api/jobs";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  

declare function jobs:scheduled-jobs() {
let $all-jobs := scheduler:get-scheduled-jobs()
return $all-jobs//scheduler:job[starts-with(@name,"iati-")]
};

declare function jobs:scheduled-jobs($corpus) {
let $all-jobs := scheduler:get-scheduled-jobs()
return $all-jobs//scheduler:job[starts-with(@name,("iati-",$corpus))]
};


declare function jobs:scheduled-job($jobname) {
let $all-jobs := scheduler:get-scheduled-jobs()
return $all-jobs//scheduler:job[@name=$jobname]
};


declare function jobs:start-olap($context) {
let $login := config:login()
let $jobname := concat("iati-",$context/corpus,"-",$context/facet,"-olap")
let $running :=jobs:scheduled-job($jobname)
let $params := 
<parameters>
   <param name="corpus" value="{$context/corpus}"/>
   <param name="facet" value="{$context/facet}"/>
</parameters>
let $stop-job := 
  if ($running and $running//state="4")  (:finished :)
  then scheduler:delete-scheduled-job($jobname)
  else ()
let $running :=jobs:scheduled-job($jobname)
let $start-job :=
  if (not($running))
  then scheduler:schedule-xquery-periodic-job(concat($config:base,"xquery/olap-job.xq"),1,$jobname,$params,0,0)
  else ()
return 
  <div>
    Jobname {$jobname} : started : {$start-job}
    {$params}
    {$running}
  </div>
};

declare function jobs:start-ckan($corpus) {
let $login := config:login()
let $jobname := concat("iati-",$corpus,"-ckan")
let $running :=jobs:scheduled-job($jobname)
let $params := 
<parameters>
   <param name="corpus" value="{$corpus}"/>
</parameters>
let $stop-job := 
  if ($running and $running//state="4")  (:finished :)
  then scheduler:delete-scheduled-job($jobname)
  else ()
let $running :=jobs:scheduled-job($jobname)
let $start-job :=
  if (not($running))
  then scheduler:schedule-xquery-periodic-job(concat($config:base,"xquery/ckan-job.xq"),1,$jobname,$params,0,0)
  else ()
return 
  <div>
    Jobname {$jobname} : started : {$start-job}
    {$running}
  </div>
};

declare function jobs:start-download($corpus,$publisher,$set,$mode) {
let $login := config:login()
let $jobname := concat("iati-",string-join(($corpus,$publisher,$set),"-"),"-download")
let $running :=jobs:scheduled-job($jobname)
let $params := 
<parameters>
   <param name="corpus" value="{$corpus}"/>
   <param name="publisher" value="{$publisher}"/>
   <param name="set" value="{$set}"/>
   <param name="mode" value="{$mode}"/>
</parameters>
let $stop-job := 
  if ($running and $running//state="4")  (:finished :)
  then scheduler:delete-scheduled-job($jobname)
  else ()
let $running :=jobs:scheduled-job($jobname)
let $start-job :=
  if (not($running))
  then scheduler:schedule-xquery-periodic-job(concat($config:base,"xquery/download-job.xq"),1,$jobname,$params,0,0)
  else ()
return 
  <div>
    Jobname {$jobname} : started : {$start-job}
    {$running}
  </div>
};

declare function jobs:start-reindex($corpus) {
let $login := config:login()
let $jobname := concat("iati-",$corpus,"-reindex")
let $running :=jobs:scheduled-job($jobname)
let $params := 
<parameters>
   <param name="corpus" value="{$corpus}"/>
</parameters>
let $stop-job := 
  if ($running and $running//state="4")  (:finished :)
  then scheduler:delete-scheduled-job($jobname)
  else ()
let $running :=jobs:scheduled-job($jobname)
let $start-job :=
  if (not($running))
  then scheduler:schedule-xquery-periodic-job(concat($config:base,"xquery/reindex-job.xq"),1,$jobname,$params,0,0)
  else ()
return 
  <div>
    Jobname {$jobname} : started : {$start-job}
    {$running}
  </div>
};
