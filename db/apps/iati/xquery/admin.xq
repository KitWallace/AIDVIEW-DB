import module namespace ui = "http://tools.aidinfolabs.org/api/ui" at "../lib/ui.xqm";  
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace log = "http://tools.aidinfolabs.org/api/log" at "../lib/log.xqm";  
import module namespace url= "http://kitwallace.me/url" at "/db/lib/url.xqm";

let $context := url:get-context()  
let $root := element _root {if ($context/_isrest) then "/admin/" else "?_path="}
let $context := 
  element context {
     $context/(* except _root), 
     $root, 
     if (empty($context/start)) then element start {"1"} else (),
     if (empty($context/pagesize)) then element pagesize {"25"} else (),
     if (empty($context/_format)) then element _format {"html"} else (),
     if (empty($context/lang)) then element lang {"en"} else (),
     if (empty($context/version)) then element version {"1.0"} else (),
     
     element _fullpath {concat($root,$context/_path)},
     element _isadmin {"true"}   (: need to set this from the login characteristics :)
  } 
return
if ($context/_format="html") 
then
 let $content := ui:content($context)
 let $option := util:declare-option("exist:serialize", "method=xhtml media-type=text/html")
 let $base := if ($context/_isrest) then "/" else "../"
 return
 <html>
   <head>
     <script src="{$base}jscript/sorttable.js" type="text/javascript" charset="utf-8"></script>
     <link rel="stylesheet" type="text/css" href="{$base}assets/screen.css"/>
     <title>AIDVIEW-DB - V3 - admin</title>
 
  </head> 
  <body class="admin">
     {$content}
  </body>  
</html>
else if($context/_format="xml")
then   
     ui:xml($context)
else if($context/_format="json")
then  
     let $xml := ui:xml($context)
     let $serialize := util:declare-option("exist:serialize","method=json media-type=text/json")
     return element result {$xml}
else if($context/_format="csv")
then  
     let $serialize := util:declare-option("exist:serialize","method=text media-type=text/txt")
     return ui:csv($context)
else () 