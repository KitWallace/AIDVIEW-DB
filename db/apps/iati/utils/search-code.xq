declare option exist:serialize "method=xhtml media-type=text/html";

let $q := normalize-space(request:get-parameter("q",()))
let $dir:= normalize-space(request:get-parameter("dir",()))
let $dirs := ("lib","xquery","utils")
let $base := "/db/apps/iati/"
return 

<html>

   <form action="?">
        Search <select name="dir">
           {for $dir in $dirs 
           return 
             <option>{$dir}</option>
           }
           </select> for <input type="text" name="q" size="30" value="{$q}" />
   </form>
   <div>
   {
   if (exists($q) and $q ne "") 
   then 
     let $directory := concat($base,$dir)
     let $files := xmldb:get-child-resources($directory)
     
     let $docs := 
        for $file in $files
        let $text := util:binary-to-string(util:binary-doc(concat($directory,"/",$file)))
        let $lines := tokenize($text,"&#10;")
        let $matches :=  
             for $line at $ln in $lines
             where $line[contains(.,$q)]
             return <match ln="{$ln}">{$line}</match>
        return
           if ($matches) then <doc name="{$file}" >{$matches}</doc> else ()

     return
        <div>
           <h2> {$q} matched {count($docs//match)}</h2>
           {for $doc in $docs
            return 
             <div>
               <h3>{$doc/@name/string()}</h3>
                   {for $match in $doc/match
                   return <div>{$match/@ln/string()} : {$match/text()}</div>
                   }
             </div>
           }
       </div>
   else 
      <div>
         no search term provided
      </div>
    }
  </div>
</html>