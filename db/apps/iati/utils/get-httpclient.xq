
let $url := request:get-parameter("url",())

let $response := util:catch("*", httpclient:get(xs:anyURI($url),false(),()),())
return 
   $response
