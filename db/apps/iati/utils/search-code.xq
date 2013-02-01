declare option exist:serialize "method=xhtml media-type=text/html";

let $q := normalize-space(request:get-parameter("q",()))
let $tdir:= normalize-space(request:get-parameter("dir",()))
let $dirs := ("lib","xquery","utils")
let $base := "/db/apps/iati/"
return 

<html>

   <form action="?">
        Search <select name="dir">
           {for $dir in $dirs 
           return 
              element option {
                   if ($dir = $tdir) then attribute selected {"selected"} else (),
                   $dir
                }
           }
           </select> for <input type="text" name="q" size="30" value="{$q}" />
   </form>
   <div>
   {
   if (exists($q) and $q ne "") 
   then 
     let $directory := concat($base,$tdir)
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
           <doc name="{$file}"  count="{count($lines)}">{$matches}</doc>

     return
        <div>
           <h2> {$q} matched {count($docs//match)} in {sum($docs/@count)}</h2>
           {for $doc in $docs[match]
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