import module namespace codes = "http://tools.aidinfolabs.org/api/codes" at "../lib/codes.xqm";

let $orgs := codes:codelist("OrganisationIdentifier")
return
element codelist {
   attribute name {"OrganisationIdentifier"},
   attribute version {"1.2"},
   attribute date-last-modified {current-dateTime()},
   attribute xml:lang {"en"},
   for $org in $orgs/*
   let $code := substring-before($org/code,"-")
   return
     if ( string-length($code) = 2)
     then 
         let $country := codes:code-value("Country",$code)
         let $countryname := ($country/name,$code)[1]
         let $orgname :=  concat($org/name," (",$countryname,")")
         return
           element OrganisationalIdentifier {
              $org/code, $org/abbreviation,
              element name {$orgname}
           }
      else 
         $org
}
