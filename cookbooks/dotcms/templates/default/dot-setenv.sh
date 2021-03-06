#! /bin/sh
<% if File.exists?("/opt/newrelic/newrelic.jar") -%>
export JAVA_OPTS="$JAVA_OPTS -javaagent:/opt/newrelic/newrelic.jar"
<% end -%>
# Other tunables
#export CATALINA_OPTS="$CATALINA_OPTS -Xms3072M"
#export CATALINA_OPTS="$CATALINA_OPTS -Xmx4096M"
#export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxPermSize=1024m"
#export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseParallelGC"
#export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxGCPauseMillis=1500"
 
echo "Using CATALINA_OPTS:"
for arg in $CATALINA_OPTS
do
echo ">> " $arg
done
echo ""
 
echo "Using JAVA_OPTS:"
for arg in $JAVA_OPTS
do
echo ">> " $arg
done
echo "_______________________________________________"
echo ""

