module namespace admin = "http://tools.aidinfolabs.org/api/admin";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace corpus= "http://tools.aidinfolabs.org/api/corpus" at "../lib/corpus.xqm";  


declare function admin:initialize() as element(div) {

(: use the corpus index to create the data files :)

<div>
     {admin:reindex()}
     
     {xmldb:create-collection($config:dir,"iati-data")}
     {xmldb:create-collection(concat("/db/system/config/",$config:dir),"iati-data")}
     {corpus:create-default-corpii()}   


(: set world excecution on public scripts :)
 
     {xmldb:chmod-resource(concat($config:base,"xquery"),"data.xq",util:base-to-integer(0755,8))}   
     {xmldb:chmod-resource(concat($config:base,"xquery"),"woapi.xq",util:base-to-integer(0755,8))}
     {xmldb:chmod-resource(concat($config:base,"xquery"),"ckan-job.xq",util:base-to-integer(0755,8))}
     {xmldb:chmod-resource(concat($config:base,"xquery"),"olap-job.xq",util:base-to-integer(0755,8))}
     {xmldb:chmod-resource(concat($config:base,"xquery"),"download-job.xq",util:base-to-integer(0755,8))}


</div>
};


declare function admin:reindex() as element(div) {
    let $reindex-config := xmldb:reindex($config:base)   
    return <div>config, codes and other system resources reindexed</div>
};
