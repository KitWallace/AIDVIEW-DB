declare namespace activity = "http://tools.aidinfolabs.org/api/activity";
import module namespace jxml = "http://kitwallace.me/jxml" at "/db/lib/jxml.xqm";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  

declare function activity:ckan-packages($context as element(context)) {
      let $url := concat($config:ckan-base,"/api/search/package?filetype=activity")
      let $list :=jxml:convert-url($url,<params><rough/></params>)
      let $max := $list/div/count
      return
          for $i in (1 to  ($max idiv 1000 ) + 1)
          let $start := ($i - 1)* 1000 + 1
          let $url := concat($config:ckan-base,"/api/search/package?filetype=activity&amp;start=",xs:string($start),"&amp;limit=1000")
          let $list :=jxml:convert-url($url,<params><rough/></params>)
          return $list//results/item
};

let $packages := activity:ckan-packages(element context{ element corpus {"test"}})

return 
  element packages {
       attribute count {count($packages)}, 
       $packages
  }
  