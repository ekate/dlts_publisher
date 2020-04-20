This codebase can be used for 2 initial steps in book publication workflow
1. Generates json documents which are then used to create book or map objects in Drupal (CMS which hosts publishing repository).
2. Add information about book images to mongodb
3. Update handles 

After those 2 steps are completed you need to add book json objects to github.  

* [Installation](#script-setup)
* [Usage ](#calling-the-script-directly)

## Requirements
Ruby version 2.1.0

## Installation
* [Install rvm, if is is not present](https://rvm.io/rvm/install)
*  Clone the [repository](https://github.com/ekate/dlts_publisher) and change to it's root directory `cd dlts_publisher`
* Install ruby v.2.4.0:
   `$ rvm install ruby-2.4.0`
* Install bundler: `gem install bundle`
* Install required gems by running the command: `$ bundle install`
* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)* Create credentials file in ~/.rhs/credentials.yml (ask admin about passwords)
## Usage
##### Mongodb update

The script requires the following parameters which are provided in a JIRA ticket related to the published batch: 

* **se_list** list of books to be published which is provided in JIRA ticket
* **wip_path** path to collection in Rstar 
* **<book | map>** type of object
* **<database name>** mongodb database name.    


ruby lib/json_generator_from_mets.rb  /content/prod/rstar/content/uaena/aco/wip/se book devdb2 ~/auena_se.txt 
##### JSON generation

The script requires the following parameters which are provided in a JIRA ticket related to the published batch: 

* **ie_list** list of books to be published
* **wip_path** path to collection in Rstar 
* **character set** For Arabic book collection the script runs twice first with Latn parameter then with Arab parameter. 
For all other books we run it only once with Latn parameter.
* **Rstar username** 
* **Rstar password** 
* **git_path** path to local copy of github repository which hosts json files.

You can also provide additional options to the script

* **-f <ie_list>** If we want to publish only specific books or maps from the collection directory, we can provide list of books to 
be published. This list is provided in JIRA ticket' 
* **-t <book | map>** Define if object is a book or a map (book|map)
* **-k <true | false>** Defines if we want to generate field "category" from the book CALL NUMBER field. Usually set to true
* **-m <file which maps MARC files to book_id>,<path to MARC files directory>** In some cases book CALL NUMBER field. Usually set to true
* **-c <collection UID>** If book is a part of additional collection we can provide additional collection code. It will be reflected
in the JIRA ticket
* **-p <provider UID>** If book's provider is different then the partner institute we can add it here. It will be reflected in the JIRA ticket
* **-d <start date>** If we want to publish books or maps only created after certain date we can provide start date here.

     
The script will generate a set of json objects and save them in the local copy of content repository. We then commit and push new content 
to https://github.com/NYULibraries/dlts_viewer_content

###### Usage examples

 Publish books for ISAW
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/isaw/awdl Latn  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -t book -f ~/isaw_batch1.txt `

 Publish books for ACO, generate categories
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/uaena/aco Latn  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/uenm_last.txt -t book -k true`
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/uaena/aco Arab  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/uenm_last.txt -t book -k true`

 Publish books for ACO, generate categories using MARC files to get CALL NUMBERS
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/princeton/aco Latn  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/prin_10.txt -k true  -m ~/prin_11_bsn.txt,/content/prod/rstar/tmp/rstar/aco-karms/work/NjP/NjP_20190531/marcxml_in`
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/princeton/aco Arab  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/prin_10.txt -k true  -m ~/prin_11_bsn.txt,/content/prod/rstar/tmp/rstar/aco-karms/work/NjP/NjP_20190531/marcxml_in`

 Publish maps
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/fales/io/ Latn  /content/prod/rstar/tmp/repos/dlts_viewer_content/maps/ -f ~/fales_ie_21_patch -t maps`
 
 Publish books for ISAW which have additional collection 
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/ifa/egypt/ Latn /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/egypt_4.txt -t book -c 126bb8e7-11e0-hgrt-b0b0-6e2c90d2f816` 
 
 Publish books for ISAW which have provider different from collection partner
 
 `bundle exec ruby lib/dlts_publisher.rb /content/prod/rstar/content/isaw/awdl/ Latn  /content/prod/rstar/tmp/repos/dlts_viewer_content/books/ -f ~/cin.txt -p d6d2a72a-cfx4-4ab6-9817-950f1a659935`
 
