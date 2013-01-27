module namespace url = "http://kitwallace.me/url";

import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";

declare function url:parse-path($steps)  {
     (:
     parse a sequence of path steps into an XML fragment in which pairs of steps are interpreted as an element name and its value
     the odd items become element names so must be valid XML names 
     if the last odd element has no value, the element is empty
     :)
     if (count($steps) = 0)
     then ()
     else if (count($steps) = 1)
     then element {$steps[1]} {()}
     else  (element {$steps[1]} {wfn:URL-decode($steps[2])}, url:parse-path(subsequence($steps,3)))   
};

declare function url:path-to-sig($steps) as xs:string* {
     (: takes a sequence of steps and replaces the variable (even) steps by an *
        the steps can then by joined by "/" to create a string to dispatch on
     :)
     if (count($steps) = 0)
     then ()
     else if (count($steps) = 1)
     then $steps[1]
     else  ($steps[1],"*",url:path-to-sig(subsequence($steps,3)))   
};

declare function url:get-context() as element(context) {  
     (:
       create a context object containing all url parameters. 
       url parameters are converted to elments 
       the _path parameter if present will be parsed by splitting the path by "/" and treating successive pairs as
       elements. The steps in the path are also parsed to create a signature for dispatching
       
       format not being parsed correctly yet
     :)
   let $path := request:get-parameter("_path",())
   let $path := if (ends-with($path,"/")) then substring($path, 1, string-length($path) - 1) else $path 
 
   let $format := tokenize($path,"\.")[last()]
   let $format := if ($format = ("xml","csv","rss","html")) then $format else ()
   let $path := if ($format)
                then substring-before($path,concat(".",$format))
                else $path
 
   let $steps := tokenize($path,"/")
   let $signature := string-join(url:path-to-sig($steps),"/")
   return
     element context {
       for $param in request:get-parameter-names()
       let $value := request:get-parameter($param,())
       return element {$param} {attribute qs {"true"} ,string-join($value,",")},
       if ($format) then element _format {$format} else (),
       element _nparam {count(request:get-parameter-names())},
       element _signature {$signature},
       for $step in $steps return element _step {$step},
       url:parse-path($steps)
     }
};

declare function url:path-menu($root, $path, $options, $map) {
   (: build a sequence of menu items.  
       $root is the root of the url
       $path the path to expand
       $options any
       $map is a ...
   :)
let $steps := tokenize($path,"/")
return
  (
   wfn:node-join(
    (element a {attribute href {$root} ,"Home" },
    for $step at $i in $steps
    let $label := if ($i mod 2 = 0) then $step else wfn:URL-decode(($map/term[@name = $step]/string(), $step)[1]) 
    let $step-path := string-join(subsequence($steps,1,$i),"/")
    return
       if ($i eq count($steps) )
       then if ($step ne "") then element span {$label} else ()
       else element a {attribute href {concat($root,$step-path)}, $label }
    )
    ," > ")
    ,
    if (exists($options))
    then 
    (" > ",
    wfn:node-join(
    for $option in $options
    let $label := ($map/term[@name = $option]/string(), $option)[1]
    return 
      element a {attribute href {concat($root,$path,"/",$option)}, $label }
    , " | ")
    )
    else ()
   )
};

(:
declare function url:create-dispatcher ($function-name,$functions) {
concat(
"declare function ",$function-name,"($signature,$context) {&#10;",
 string-join(
 for $function in $functions
 return
  concat("if ($signature eq '",$function/@signature,"') then ",$function/text())
 , " &#10; else "
 )
 ,"&#10; else ()"
 ,"&#10;};"
)
};
:)

(:
declare function url:parse-template($path) as element(query) {
   let $steps := tokenize($path,"/")
   return
     element query {
       for $step at $i in $steps
       let $next := $steps[$i + 1] 
       return
         if (contains($step,"{"))
         then () (: will have been processed in preceding step :)
         else if (exists($next) and contains($next,"{"))
         then 
             element {$step} {wfn:substring-between($next,"{","}")}
         else if (empty($next))
         then element {$step} {"*"}
         else element {$step} {}
     }
};
:)
