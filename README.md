AIDVIEW-DB
==========

A repository, browser and API for IATI activities

#Version 2 to Version 3 changes

- This version has a redesigned OLAP which is performing better
- the update process is been changed to make better use of the CKAN last-modified date and hash on individual activities
- management and uploading of actititySets is structured  by the CKAN publisher code rather than by the download host so that reports should be inline with the registry
- activity-status and Reporting organisation are now facets in the OLPA and available in browser and API
- XQuery code has been upgraded to use the latest release fomr eXist and takes advantages of XQuery 3.0 features for performance
- a number of minor issues have been cleared of the jobs list which has been transfered to the issue list on Github

#Impacts

- The default corpus name is now 'main' not 'test' The change of name of the default corpus may impact WO since their calls seem to be setting the corpus name - really it should not be set so that the API can default.
- Although the new API includes additional facets, this should not be apparent to AIdView
- There has been quite substantial code changes and these have not been able to be fully tested
- The new version uses a later version of exist which is nearing full release and will at some time need to be upgraded agian
- A number of technical issues remain as doucmente din the issue list. 

## License 

Code by Chris Wallace (@kitwallace / kit.wallace -at- gmail.com) for [AidInfo](http://www.aidinfo.org).

AidView API and associated components
Copyright (C) Chris Wallace & Development Initiatives Poverty Research Ltd

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. ## License 

