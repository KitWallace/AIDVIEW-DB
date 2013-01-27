module namespace config = "http://tools.aidinfolabs.org/api/config" ;

declare variable $config:host :=  "http://localhost";
declare variable $config:ip := "localhost";
declare variable $config:dir := "/db/apps/";
declare variable $config:base := concat($config:dir,"iati/");
declare variable $config:data := concat($config:dir,"iati-data/");
declare variable $config:version := "3";
declare variable $config:last-modified:= "2013/01/21";
declare variable $config:codes :=  concat($config:base,"codes/");
declare variable $config:system :=  concat($config:base,"system/");
declare variable $config:logs :=  concat($config:base,"logs/");
declare variable $config:config := concat($config:base,"config/");
declare variable $config:rss-age :="200";
declare variable $config:logging := false();
declare variable $config:ckan-base := "http://www.iatiregistry.org/";
declare variable $config:pin := "1616";
declare variable $config:backupdir := "/var/www/backups/";
declare variable $config:export := ("application");
declare variable $config:map :=    (: used to generate friendly menus from URLs :)
<terms>
   <term name="set">Activity Sets</term>    
   <term name="corpus">Corpuses</term>
   <term name="Host">Hosts</term>
   <term name="activity">Activities</term>
   <term name="facet">Facets</term>
   <term name="Publisher">Publishers</term>
</terms>;
declare variable $config:islive := true();   (: set this to false() to put the database off line :)

declare function config:login() {
  xmldb:login($config:base,"admin","perdika")
};
