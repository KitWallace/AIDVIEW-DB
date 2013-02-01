import module namespace admin = "http://tools.aidinfolabs.org/api/admin" at "../lib/admin.xqm";
import module namespace config = "http://tools.aidinfolabs.org/api/config" at "../lib/config.xqm";

      for $corpus in doc(concat($config:config,"corpusindex.xml"))/corpusindex/corpus[@temp]
      return  admin:clear-corpus($corpus/@name)
