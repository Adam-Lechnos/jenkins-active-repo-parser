# jenkins-active-repo-parser
Pull latest list of GitHub repos from a list of topics for Jenkins Active Choice Parameter

#### Overview

* The script will output a list of repos associated with topics into parsable text files for Jenkins, based on a specified GitHub org.

#### Install
* Place the .sh file on the main jenkins host as the `jenkins` user within the '/var/lib/jenkins/scripts' folder.
* Inside the `scripts` folder, create a new folder labeled `logs`.
* Test the script and observe its output to screen in addition to the logs created within the `logs` folder. The end of each execution will create a new `complete_` log file.
* The script will also create one `output_` prepended log file for each member topic. A `git_org_list.txt` should also be created, parsable for a dropdown.
* Enable the script to run every 2 minutes via cron

#### Outputs
* Each repo list will be located within its own text file.
* For users with no repos labeled, the text file will contain the work 'empty' respectively.
* The Active Choice Parameter in Jenkins will parse the text file names into a dropdown list, with *example_org as the default option.
* A second Active Choice Parameter will then display the list of git repos inside the respective text file, per the previous selection.

#### Active Choices Reactive Parameter script
```
def proc = "cat /var/lib/jenkins/activechoice_repo_parser/output_${git_org}_content.qt-${account_group}.txt".execute()
proc.waitFor()
def output = proc.in.text
def exitcode = proc.exitValue()
def error = proc.err.text
return output.tokenize()
```
