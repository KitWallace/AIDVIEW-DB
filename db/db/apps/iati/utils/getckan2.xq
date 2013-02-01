declare namespace activity = "http://tools.aidinfolabs.org/api/activity";
import module namespace jxml = "http://kitwallace.me/jxml" at "/db/lib/jxml.xqm";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  

declare function activity:ckan-activitySet($package as xs:string) as element(activitySet) {
       let $meta-url := concat($config:ckan-base,"/api/rest/package/",$package)
       let $metadata := util:catch("*",jxml:convert-url($meta-url)/div,<error>extract failed</error>)
       let $url := $metadata/download_url
       return

         element metadata {
            element metaurl {$meta-url},
            element package {$package},
            element publisher {$metadata/groups/item[1]/string()},
            element host {substring-before(substring-after($url,"//"),"/")},
            $metadata,
            $url,
            $metadata/metadata_modified
         }

          
};

activity:ckan-activitySet("ausaid-nu")