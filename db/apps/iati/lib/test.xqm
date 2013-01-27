module namespace test = "http://tools.aidinfolabs.org/api/test";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";  
import module namespace wfn = "http://kitwallace.me/wfn" at "/db/lib/wfn.xqm";  

(:  Run a suite of tests defined in a test script.

   Chris Wallace Dec 2006
    
   Feb 2007 
           -  format changed to introduce batches of tests
           -  XQuery formated with <pre> ..</pre>
           -  XML formated with the stylesheet based on one from Oliver Becker,  obecker@informatik.hu-berlin.de
           
   March 2007 
           - remove batch level - no value
           - test with basic value results must have output = 'text'
           - pre renamed to prolog
           - test for sequence handled with string-join
           
   June 2007 
          - add execution of url relative to a base 
          - add contains type test in adddition to default of deep-equals
          - run tests in full, then format results
          
    Feb 2009 
          - added to wiki 
          - still issue about exposing files with bare XQuery to execute  
          - restructured
          - added modules to preload -makes test time more comparable
          - use util:catch to run eval so compilation errors are caught
          - string compare under normalize-space - may need to be an option
          - failonly parameter to show only failing tests
          - author element added
          -output format settable at uri or  testset level
            
     April 2009 
          - added epilog 
          - caching busting on url - need to switch to httpclient 
          - added compare =no  for tests to be run only 
          
     February 2011
          - changed to load a file by name - should make sure that only local files can be loaded
          - problem with XML comparison - ok forgot about namespaces 
          - config structure added to simplify parameters
          
     Todo - 
          test options need tidying
          namespace and schema required for test script
          check for multiple contains phrases
          check for not contains
          define tolerance in numerical results
          xqdoc comment standard headings for the documentation on a method
          style the output from util:describe-function
          XML schema for the test script
      
      could be replaced by the eXist test module
                 
:)


(:     ------------------------------------------------run-test -------------------------------------------:)
declare function test:run-test($test as element(test), $tn as xs:integer, $config as element(config)) as element(testResult) {
let $url := 
       if (exists($test/url))
       then 
            if (starts-with($test/url,'http://'))
            then $test/url
            else if (starts-with($config/base,"http"))
            then concat($config/base,$test/url)
            else concat($config/base,$test/../collection,'/',$test/url)
      else ()
let $moduleLoad := 
     for $module in  $test/../module
     return  util:import-module($module/@uri,$module/@prefix,$module/@location)
let $start := util:system-time()
let $output := 
    if ( not($test/@run='no'))
    then
        if (exists($test/code))
        then util:catch("*",util:eval(concat($test/../prolog,$test/code,$test/../epilog)),<error>Compile error</error>)
        else 
            if (exists($url))
            then doc($url)/*
           else ()
      else ()
let $end := util:system-time()
let $runtimems := (($end - $start) div xs:dayTimeDuration('PT1S')) * 1000
let $expected := 
    if ($test/@output='text') 
    then data($test/expected)
    else $test/expected/node()
 let $OK := 
 if ($test/@compare='no' or $config/compare="no")
 then ()
 else if ($test/@type='contains')
    then contains(string-join($output,' '),$expected) 
    else
       if ($test/@output='text')  
       then normalize-space(string-join(for $x in $output return string($x),' ')) eq normalize-space($expected)       
       else deep-equal($output,$expected) 

return
  <testResult  tn='{$tn}'  pass='{$OK}'>
    <url>{$url}</url>
    <elapsed>{$runtimems}</elapsed>
    <output>{$output}</output>
  </testResult>
};

(: ----------------------------------------------run-test ----------------------------------------:)
declare function test:run-testSet( $testSet as element(TestSet), $config as element(config) ) as element(results){
<results>
  {
  for $test at $tn in $testSet/test
  return test:run-test($test, $tn, $config)
  }
</results>
};

(: ----------------------------------------------show-testSet ---------------------------------:)
declare function test:show-testSet($testSet as element(TestSet) , $results as element(results) , $config as element(config) ) as element(div)  {
let $n := count($testSet/test)
let $npassed := count($results/testResult[@pass='true']) 
let $nfail := count($results/testResult[@pass='false']) 
let $nother := count($results/testResult[@pass='']) 
return 
<div>
  <h1>Test Results for {$testSet/testName} </h1>
  <h2>eXist Version {system:get-version()} :  Revision {system:get-revision()} </h2>

   {if ($n = $npassed)
    then <h2 class='good'> {$n} Test{if($n > 1) then 's' else ()} passed </h2>
    else if ($nfail > 0)
    then <h2 class='bad'>{$npassed} Test{if($npassed > 1) then 's' else ()} passed, {$nfail} Failed,  {$nother} not checked</h2>
    else <h2 class='warn'>{$npassed} Test{if($npassed > 1) then 's' else ()} passed,  {$nother} not checked</h2>
   }
   <h3>Total elapsed time {sum($results/testResult/elapsed)} (ms)</h3>
   {$testSet/description/*}
   {if ($testSet/imports)
   then 
   <div>
      <h3>Imported Modules</h3>
      <ul>
      {for $module in $testSet/modules
      return <li>module {$module/@prefix/string()} ="{$module/@uri/string()}" at  "{$module/@location/string()}"</li>
      }
      </ul>
   </div>
   else ()
   }
    {if (exists($testSet/prolog)) 
    then 
     <div id='prolog'>
        <h3>Prolog</h3>
        <pre>{$testSet/prolog/string()}</pre>
     </div>
    else ()
   }
   {if (exists($testSet/epilog)) 
    then 
     <div id='epilog'>
        <h3>Epilog</h3>
        <pre>{$testSet/epilog/string()}</pre>
     </div>
    else ()
   }
   { for $result at $tn in $results/testResult
     let $test := $testSet/test[$tn]
     return test:show-test($test,$result,$config)
    }
</div>
};

(: ----------------------------------show-test ----------------------------------:)
declare function test:show-test($test as element(test), $result as element(testResult) , $config as element(config)) as element(div)? {
   let $tn := $result/@tn/string()
   let $id := $test/@id/string()
   let $output :=  
       if ($test/@output='text') 
       then string($result/output)
       else $result/output/node()
       
   let $expected :=  if ($test/@output='text') 
                     then data($test/expected)
                     else $test/expected/node() 
   return 
      if ($config/failonly="yes" and $result/@pass='true')
      then ()
      else
     <div>
      {if ($test/@run='no')
       then <h3 class="warn">Test {$tn}  &#160; {$id} Not run</h3>
       else 
          if ($result/@pass ='')
          then  <h3 class="warn">Test {$tn} &#160; {$id} Not checked</h3>
          else if ($result/@pass='true') 
          then <h3 class="good">Test {$tn} &#160; {$id} Passed</h3>
          else <h3 class="bad">Test {$tn}  &#160; {$id} Failed</h3>
      } 
       <table border="1">
         { if (exists($test/task)) 
           then <tr><th>Task</th><td>{$test/task/node()}</td></tr>
           else ()
         }
         <tr><th>XQuery</th>
             <td>{if ($test/code) 
                  then <pre>{$test/code/string()}</pre> 
                  else 
                  if ($result/url) 

                  then <div><a href="{$result/url}">{$result/url/string()}</a></div>
                  else () 
                 }</td>
         </tr>

{  if ($test/@type='contains')
   then
      ( <tr>
         <th>Page Contains </th>
         <td>{ $expected}  </td>
      </tr>,
      if (not($result/@pass='true'))
      then 
         <tr>
           <th>Actual</th>
           <td>{$output}</td>
        </tr>
      else ()
      )
   else (
        if ($config/out="yes")
        then <tr><th>Output</th>
             <td>{
             if ($test/@output="html")
             then  $output
             else if ($test/@output ="txt")
             then <pre>{$output}</pre>
             else if ($test/@output = "xml" and $config/pp = "yes")
             then wfn:element-to-nested-table($output)
             else <pre>{$output}</pre>
              }
             </td> 
         </tr>
         else (),
         if (not($result/@pass='true') and $expected) 
          then <tr><th>Expected</th>
               <td>
                  <pre>{$expected}</pre>
               </td>
               </tr>
          else ()  
         
        )
}
         {if (exists($test/comment)) then <tr><th>Comment</th><td>{$test/comment/node()}</td></tr> else ()}
         <tr><th>Elapsed Time (ms)</th><td>{string($result/elapsed)}</td></tr>
       </table>
 </div>
 };
 
declare function test:do-testSet($testname) {
let $testSet := doc(concat($config:base,"tests/",$testname,".xml"))/TestSet
let $config := 
  <config>
     <pp>yes</pp>
     <out>yes</out>
     <failonly>no</failonly>
     <compare>yes</compare>
  </config>

let $results := test:run-testSet($testSet,$config)
return
   test:show-testSet($testSet,$results,$config) 
};


declare function test:list-tests($context) {
   if (empty($context/corpus))
   then 
       <ul>            
            {for $test in collection (concat($config:base,"tests"))/TestSet
             let $name := substring-before(util:document-name($test),".xml")
             return 
                  <li><a href="{$context/_root}test/{$name}">{$name}</a></li>
            }               
      </ul>    
   else ()
};