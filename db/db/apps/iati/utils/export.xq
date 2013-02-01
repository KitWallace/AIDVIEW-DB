module namespace export = "http://tools.aidinfolabs.org/api/config";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  

(:
  save the zip resources file to a directory on the web so that the file can be download eg using wget
  files are not timestamped so only one backup per resourcefile name is stored
:)

declare function export:zip($resources as xs:string*) {
let $uris := 
    for $resource in $resources
    return xs:anyURI($resource)

return compression:zip($uris,true())
};

declare function export:cache-fs($resources,$config) {
 for $resource in $resources[@fspath]
 let $path := 
               if (starts-with($resource/@path,"/")) 
               then $resource/@path/string()
               else concat($config:base,"/",$resource/@path)
 let $filename := tokenize($path,"/")[last()]
 let $suffix := substring-after($filename,".")
 
 let $file:=
    if ($suffix = ("xml","xslt"))
    then 
        file:read($resource/@fspath)
    else 
        file:read-binary($resource/@fspath)
 return xmldb:store($config:system,$filename,$file)
};

declare function export:list-resources($resources) {
      <table border ="1" class="sortable">
            <tr><th width="30%">Resource</th><th>Export?</th><th>Filestore?</th><th>Description</th><th>Links</th></tr>
            {for $resource in $resources
             let $path := 
               if (starts-with($resource/@path,"/")) 
               then $resource/@path/string()
               else concat($config:base,"/",$resource/@path)
             let $suffix := substring-after(tokenize($path,"/")[last()],".")
             return 
               <tr>
                   <td>
                      {if ($suffix = ("xml","xsl","css","xconf","js"))
                       then <a href="/exist/rest/{$path}">{$path}</a>                     
                       else $path
                      }
                   </td>
                   <td>{if (empty($resource/@ignore)) then "yes" else () }</td>
                   <td>{if ($resource/@fspath) then "yes" else () } </td>
                   <td>{$resource/description/string()} {if ($resource/@fspath) then concat (" [ ", $resource/@fspath, "]") else () } </td>
                   <td>{for $link in $resource/link
                        return <a href="{$link}">{$link/string()}</a>
                        }
                    </td>
               </tr>
            }
         </table>
};

declare function export:view-resources($resourcefile) {
let $resources := doc(concat($config:system,$resourceFile))/resources
let $base := $config:base
return
 <div>
     {local:cache-fs($resources,$config)}
     {local:list-resources($resources/resource)}
 </div>
};

declare function export:zip-resources($resourcefile) {
let $resources := doc(concat($config:system,$resourceFile))/resources
let $base := $config:base
return

    let $zipfilename := concat($resources/@name,"-backup.zip")
    let $paths := 
      for $path in $resources/resource[empty(@ignore)]/@path
      return 
        if (starts-with($path,"/")) 
        then $path
        else concat($base,"/",$path)

    let $zip := export:zip($paths)
    let $store := file:serialize-binary($zip,<name>{concat($config:backupdir,$zipfilename)}</name>)
    return
      if ($store)
      then 
       <div> 
         <h2>{$resources/@name/string()} - {$resourceFile}</h2>
       </div>
    else 
    <div>
        <h2>{$resources/@name/string()} - {$resourceFile}</h2>
        <div> zip or store failed</div>
    </div>
  else ()
};