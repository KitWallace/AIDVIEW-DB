import module namespace hc= "http://expath.org/ns/http-client";

let $url := request:get-parameter("url",())

let $request :=
          element hc:request {attribute method {"GET"}, attribute href {$url}, attribute timeout {"100"} } 
let $response :=  util:catch("*",  hc:send-request($request) , ())
return 
   $response
