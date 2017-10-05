srcdir="/usr/share/jenkins"
jenkinsdir="/var/lib/jenkins"
user="admin"
passwd=`cat /var/lib/jenkins/secrets/initialAdminPassword`
url="localhost:8080"
apt-get install html-xml-utils
wget -P $srcdir http://$url/jnlpJars/jenkins-cli.jar
java -jar $srcdir/jenkins-cli.jar -s http://$url who-am-i --username $user --password $passwd
api=`curl --silent --basic http://$user:$passwd@$url/user/admin/configure | hxselect '#apiToken' | sed 's/.*value="\([^"]*\)".*/\1\n/g'`
CRUMB=`curl 'http://'$user':'$api'@'$url'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'`
echo $api
echo $CRUMB
curl -X POST -d '<jenkins><install plugin="packer@current" /></jenkins>' --header 'Content-Type: text/xml' -H "$CRUMB" http://$user:$api@$url/pluginManager/installNecessaryPlugins
curl -X POST -d '<jenkins><install plugin="terraform@current" /></jenkins>' --header 'Content-Type: text/xml' -H "$CRUMB" http://$user:$api@$url/pluginManager/installNecessaryPlugins
#systemctl restart jenkins && sleep 30
sleep 30 && java -jar $srcdir/jenkins-cli.jar -s  http://$url restart --username $user --password $passwd
wget -P $srcdir https://raw.githubusercontent.com/sysgain/MSOSS/staging/scripts/elk-config.xml
wget -P $srcdir https://raw.githubusercontent.com/sysgain/MSOSS/staging/scripts/packer-config.xml
apt-get install xmlstarlet
if [ ! -f "elk-config.xml" ]
then
	xmlstarlet ed -u '//buildWrappers/org.jenkinsci.plugins.terraform.TerraformBuildWrapper/variables' -v "subscription_id = &quot;$1&quot;
client_id = &quot;$2&quot;
client_secret = &quot;$3&quot;
tenant_id = &quot;$4&quot;
ResourceGroup = &quot;$5&quot;
Location = &quot;$6&quot;
vnetName = &quot;$7&quot;
DynamicIP = &quot;$8&quot;
subnetName = &quot;$9&quot;
storageAccType = &quot;${10}&quot;
vmSize = &quot;${11}&quot;
vmName = &quot;${12}&quot;
userName = &quot;${13}&quot;
password = &quot;${14}&quot;" $srcdir/elk-config.xml | sed "s/&amp;quot;/\"/g" > $srcdir/elk-newconfig.xml
fi

if [ ! -f "packer-config.xml" ]
then
	xmlstarlet ed -u '//publishers/biz.neustar.jenkins.plugins.packer.PackerPublisher/params' -v "-var &apos;client_id=$2&apos; -var &apos;client_secret=$3&apos; -var &apos;resource_group=$5&apos; -var &apos;storage_account=${15}&apos; -var &apos;subscription_id=$1&apos; -var &apos;tenant_id=$4&apos;" $srcdir/packer-config.xml | sed "s/amp;//g" > $srcdir/packer-newconfig.xml

fi
	
wget -P $jenkinsdir https://raw.githubusercontent.com/sysgain/MSOSS/staging/scripts/biz.neustar.jenkins.plugins.packer.PackerPublisher.xml
wget -P $jenkinsdir https://raw.githubusercontent.com/sysgain/MSOSS/staging/scripts/org.jenkinsci.plugins.terraform.TerraformBuildWrapper.xml
sleep 30 && java -jar $srcdir/jenkins-cli.jar -s  http://$url restart --username $user --password $passwd && sleep 30
curl -X POST "http://$user:$api@$url/createItem?name=ELKJob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
curl -X POST "http://$user:$api@$url/createItem?name=AppPackerjob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
curl -X POST "http://$user:$api@$url/createItem?name=MangoDBPackerjob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
curl -X POST "http://$user:$api@$url/createItem?name=AppTerraformjob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
curl -X POST "http://$user:$api@$url/createItem?name=MangoDBTerraformjob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
curl -X POST "http://$user:$api@$url/createItem?name=VMSSJob" --data-binary "@$srcdir/elk-newconfig.xml" -H "$CRUMB" -H "Content-Type: text/xml"
