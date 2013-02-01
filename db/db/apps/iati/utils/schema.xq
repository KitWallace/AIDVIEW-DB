import module namespace sch = "http://tools.aidinfolabs.org/api/schema"  at "../lib/schema.xqm";

declare option exist:serialize  "method=xhtml media-type=text/html";

let $corpus  := request:get-parameter("corpus","unitTests")

let $context := 

<context>
  <_root>../xquery/data.xq?_path=</_root>
  <corpus>{$corpus}</corpus>
</context>

return 
   sch:page($context)