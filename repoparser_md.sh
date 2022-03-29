#!/bin/bash

#repoparser

logLocation=/var/lib/jenkins/jenkins-active-repo-parser/logs/
timestamp="$(date +"%FT%H%M%S")"
logretention=20
loglist=$(ls -l $logLocation | grep .log | awk '{print $9}' | wc -l)

#add token here
token=

ratelimit=$(
curl -s -H "Authorization: bearer $token" -d '
  {
      "query": "query {viewer { login } rateLimit {limit cost remaining resetAt}}"

  }
  ' https://api.github.factset.com/graphql | jq -r '.data.rateLimit.remaining'
)

if [ ! -d $logLocation ]; then
  mkdir $logLocation
fi

echo "-----------------------"
echo "enforcing log retention"
echo "-----------------------"

if [ $loglist -gt $logretention ]
then

 delcount=`expr $loglist - $logretention`
 echo "log rentention hit, deleting oldest log file" | tee -a $logLocation/completed_$timestamp.log
 find $logLocation -type f -printf '%T+ %p\n' | sort | head -n $delcount | awk '{print $2}' | sed 's/[^\]*logs[^\]//' | xargs -I {} rm $logLocation{}

else

 continue

fi

echo "completed"

echo "--------------------"
echo "API rate limit check"
echo "--------------------"

if [ $ratelimit -gt "300" ]
then
    echo "passed"
    echo "remaining rate limit is $ratelimit, reseting within 1 hour"
else
    echo "API rate limit reached or failure, exiting. Current API limit is $ratelimit" | tee -a $logLocation"not_completed_rate_lmit_$timestamp.log"
    exit 1
fi

echo "completed"

echo "--------------------------------------"
echo "parsing GraphQL repolist to output txt"
echo "--------------------------------------"

count=$(cat /var/lib/jenkins/git/jenkins-active-repo-parser/topics.txt | wc -l)

while [ $count -gt 0 ]
do
 
    topic=$(cat /var/lib/jenkins/git/jenkins-active-repo-parser/topics.txt | awk NR==$count)
    
    echo "creating market-data list for topic $topic"    

    curl -s -H "Authorization: bearer $token" -d '
    {
        "query": "query { search(query: \"topic:'$topic' org:GIT-ORG:updated\", type: REPOSITORY, first: 100) { repositoryCount nodes { ... on Repository { sshUrl }}}}"

    } 
    ' https://api.github.com/graphql | jq -r '.data.search.nodes[].sshUrl' > "/var/lib/jenkins/git/jenkins-active-repo-parser/output."$topic".txt"

     
    
    echo "---devops---" >> "/var/lib/jenkins/git/jenkins-active-repo-parser/output."$topic".txt"


    echo "creating market-data list for topic $topic, qt-admin repos"    

    curl -s -H "Authorization: bearer $token" -d '
    {
        "query": "query { search(query: \"topic:'qt-admin' org:market-data-cloud sort:updated\", type: REPOSITORY, first: 100) { repositoryCount nodes { ... on Repository { sshUrl }}}}"

    } 
    ' https://api.github.factset.com/graphql | jq -r '.data.search.nodes[].sshUrl' >> "/var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/output_*market-data_content."$topic".txt"


   
      if [ `ls -l /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/output_*market-data_content."$topic".txt | awk '{print $5}'` -eq "0" ]
      then
        echo "empty" > /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/output_*market-data_content."$topic".txt
      else
        sed -i '1 i\Select..' /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/output_*market-data_content."$topic".txt
      fi


    count=$((count-1))

done

wait
 
echo "-------------------------"
echo "creating market data list"
echo "-------------------------"

echo "completed"

echo "---------------------------"
echo "creating GitHub Topics list"
echo "---------------------------"

ls -l /var/lib/jenkins/git/cloud-market-data/jenkins_tools/reference_groups | grep content | cut -d. -f2 | sort | uniq > /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/topics.txt


echo "completed"

echo "----------------------------------"
echo "creating git_repo list for jenkins"
echo "----------------------------------"

ls -l /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/ | grep output_ | cut -d_ -f2 | cut -d. -f1 | uniq | sort --version-sort -r > /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/git_org_list.txt

echo "completed"

echo "------------------------------------------"
echo "COMPLETED at $(date)" | tee -a /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/logs/completed_$timestamp.log
echo "------------------------------------------"

echo "remaining api rate limit is $ratelimit, reseting within 1 hour" >> /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/logs/completed_$timestamp.log
echo "log timestamp code: $timestamp" >> /var/lib/jenkins/git/cloud-market-data/jenkins_tools/activechoice_repo_parser/logs/completed_$timestamp.log
