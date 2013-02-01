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

element div
{
let $context := element context {element corpus {"main"}}
let $sets := activity:activitySets($context/corpus)
for $activitySet in $sets
return
if (exists($activitySet/activity-count))
then element div {concat($activitySet/package," = ",$activitySet/activity-count)}
else 
let $activity-count := count(collection(concat($config:data,$context/corpus,"/activities"))/iati-activity[@iati-ad:activitySet= $activitySet/package])
let $update-count := update insert element activity-count {$activity-count} into  $activitySet
return element div {concat($activitySet/package," + ",$activity-count)}
}
