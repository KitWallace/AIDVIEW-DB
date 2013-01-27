
import module namespace api = "http://tools.aidinfolabs.org/api/api" at "../lib/api.xqm";
let $str := request:get-query-string()
return api:api($str)  
