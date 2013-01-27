module namespace corpus ="http://tools.aidinfolabs.org/api/corpus";

import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm" ;
import module namespace activity = "http://tools.aidinfolabs.org/api/activity" at "../lib/activity.xqm" ;

declare function corpus:meta() as element(corpus)* {
  for $corpus in xmldb:get-child-collections($config:data)
  return corpus:meta($corpus)
};

declare function corpus:meta($name as xs:string ) as element(corpus)?  {
  doc(concat($config:data,$name,"/corpus/config.xml"))/config
};


declare function corpus:activities-updated($name as xs:string) as element(corpus) {
   let $meta := corpus:meta($name)
   let $update := update replace $meta/activities-updated with element activities-updated {current-dateTime()}
   return corpus:meta($name)
};

declare function corpus:activities-last-updated($name as xs:string) as xs:string? {
   corpus:meta($name)/activities-updated/string()
};

declare function corpus:create-default-corpii() {
   let $vstore := 
       <config><name>vstore</name><temp>true</temp><description>temporary collection for validation</description><activities-updated/></config>
   let $dummy := corpus:create($vstore)
   let $main := 
       <config><name>main</name><default>true</default><activities-updated/><pipeline>pipeline1</pipeline><description>full collection : 2010 Base values</description></config>
   let $dummy := corpus:create($main)
   let $unitTests := 
       <config><name>unitTests</name><activities-updated/><pipeline>pipeline1</pipeline><description>unit Test collection</description></config>
   let $dummy := corpus:create($unitTests)
   return true()
};

declare function corpus:create($corpus as element(config)) {
   if (exists(activity:corpus($corpus/name))) then ()
   else
       let $name := $corpus/name
       let $dir := xmldb:create-collection($config:data,$name)
       let $main := xmldb:create-collection($dir,"corpus")
       let $log :=  xmldb:store($main,"log.xml",element log{})
       let $apilog :=  xmldb:store($main,"api-log.xml",element log{})
       let $config := xmldb:store($main,"config.xml",$corpus)
       let $activities :=  xmldb:create-collection($dir,"activities")
       let $sets :=  xmldb:create-collection($dir,"sets")
       let $createActivitySets := xmldb:store($sets,"activitySets.xml",element activitySets{})   
       let $olap :=  xmldb:create-collection($dir,"olap")
       (:default olap configuration :)
       let $confstore := xmldb:store($olap,"config.xml",doc(concat($config:system,"olap-config.xml")))
        
       let $set-access :=
           if ($corpus/temp)
           then (: set world writeable on the data collection  :)
                ( 
                  xmldb:chmod-collection($dir,util:base-to-integer(0777,8)),
                  xmldb:chmod-resource(concat($dir,"/sets"),"activitySets.xml",util:base-to-integer(0766,8)),
                  xmldb:chmod-resource(concat($dir,"/corpus"),"config.xml",util:base-to-integer(0766,8)),
                  xmldb:chmod-resource(concat($dir,"/corpus"),"log.xml",util:base-to-integer(0766,8)),
                  xmldb:chmod-collection(concat($dir,"/activities"),util:base-to-integer(0777,8)),           
                  xmldb:chmod-collection(concat($dir,"/olap"),util:base-to-integer(0777,8))             
                )
           else ()
       
   (: indexes :)
 
       let $index := concat("/db/system/config",$config:data)
       let $dir := xmldb:create-collection($index,$name)
       let $sets := xmldb:create-collection($dir,"sets")
       let $activitySetconfig := xmldb:store($sets,"collection.xconf",doc(concat($config:system,"activitySet-collection.xconf")))
       let $activities :=  xmldb:create-collection($dir,"activities")
       let $activityconfig := xmldb:store($activities,"collection.xconf",doc(concat($config:system,"activity-collection-lucene.xconf")))
       let $olap :=  xmldb:create-collection($dir,"olap")
       let $olapconfig := xmldb:store($olap,"collection.xconf",doc(concat($config:system,"olap-collection.xconf")))
    return 
          $corpus
};

declare function corpus:clear($corpus) {
     let $dir := concat($config:data,$corpus)
     let $remove_activities := xmldb:remove(concat($dir,"/activities"))
     let $create-activities := xmldb:create-collection($dir,"/activities")
     let $clear-log :=  xmldb:store($dir,"/log.xml",<log/>)
     let $clear-api-log :=  xmldb:store($dir,"/api-log.xml",<log/>)
     let $clear-activity-sets := xmldb:store($dir,"/sets/activitySets.xml",<activitySets/>)
     return concat($corpus," cleared")
};

declare function corpus:clear-log($corpus) {
     let $dir := concat($config:data,$corpus)
     return xmldb:store($dir,"/log.xml",<log/>)
};
