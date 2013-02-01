import module namespace hc= "http://expath.org/ns/http-client";

let $url := request:get-parameter("url",())

let $request :=
          element hc:request {attribute method {"GET"}, attribute href {$url}, attribute timeout {"100"} } 
let $result :=  util:catch("*",  hc:send-request($request) , ())
let $meta := $result[1]
let $status := $meta/@status/string()
let $message := 

    if (empty($meta))
    then let $message := <error>http {$url/string()} request failed</error>
        
         return $message
    else if  ($status ne "200")
    then 
        let $message := <error>http {$url/string()} Status {$status}</error>
        
        return $message
     else 
     let $activities := $result[2]/descendant-or-self::iati-activities
     return 
      if (empty($activities/iati-activity))
      then  
         let $message := <warning>http {$url} no activities found</warning>
         return $message
      else 
         let $message := <ok>{count($activities/iati-activity)} activities found </ok>
         return $message
return
  <result>
     {$message}
     {$result}
  </result>
