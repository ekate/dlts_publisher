This codebase reads a wip and imports a photo document into the dlts_book collection for the viewer workflow. It is part of the book publishing workflow.


Links within the README:
* [Script Setup](#script-setup)
* [Call script ](#calling-the-script-directly)

## Requirements
#### Ruby version 2.1.0

## Script Setup
* Install rvm, if not present, from [here](https://rvm.io/rvm/install)
* Install ruby v.2.1.0:
   `$ rvm install ruby-2.1.0`
* The .ruby-gemset file in the directory will automatically create a gemset
* Install bundle: `gem install bundle`
* Install required gems by running the command: `$ bundle`

#### calling-the-script-directly 
The script requirese the following parameters: 
se_list
wip_path
git_path
R* username 
R* password 
characterset(Latn|Arab)
```
* **se_list**: list of books to be published
* **wip_path**: /path to collection in R*/
* **git_path**: /path to local copy of github repository/
* **characterset**: /For Arabic book collection the script runs twice first with Latn parameter then with Arab parameter. For all other books it runs only with Latn parameter/
* **R* username** 
* **R* password** 
* The script then should be called the following way:
```
    * `bundle exec ruby lib/dlts_publisher.rb wip_path Latn|Arab R*username R*password git_path -f path_to_se_list`

The script will generate a set of json objects and save them in the local copy of content repository. 
