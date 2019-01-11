#!/usr/bin/env bash

yum install -y git wget python-pip
pip install -U pip
pip install ansible

cat << EOF >> /etc/environment
HMPPS_ROLE=${app_name}
HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
HMPPS_STACKNAME=${env_identifier}
HMPPS_STACK="${short_env_identifier}"
HMPPS_ENVIRONMENT=${route53_sub_domain}
HMPPS_ACCOUNT_ID="${account_id}"
HMPPS_DOMAIN="${private_domain}"
JAVA_HOME=/usr/java/jdk1.8.0_181-amd64/jre
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="${app_name}"
export HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
export HMPPS_STACKNAME="${env_identifier}"
export HMPPS_STACK="${short_env_identifier}"
export HMPPS_ENVIRONMENT=${route53_sub_domain}
export HMPPS_ACCOUNT_ID="${account_id}"
export HMPPS_DOMAIN="${private_domain}"
export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64/jre

cat << EOF > ~/requirements.yml
---

- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: centos
- name: rsyslog
  src: https://github.com/ministryofjustice/hmpps-rsyslog-role
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
- name: logstash
  src: https://github.com/ministryofjustice/hmpps-logstash
- name: alfresco
  src: https://github.com/ministryofjustice/hmpps-alfresco-bootstrap
- name: users
  src: singleplatform-eng.users

EOF

cat << EOF > ~/bootstrap_vars.yml
- mount_point: "${cache_home}"
- device_name: "${ebs_device}"
- monitoring_host: "${monitoring_server_url}"
- bucket_name: "${bucket_name}" 
- bucket_encrypt_type: "${bucket_encrypt_type}"
- bucket_key_id: "${bucket_key_id}"
- db_user: "${db_user}"
- db_password: "${db_password}"
- db_name: "${db_name}"
- db_host: "${db_host}"
- server_mode: "${server_mode}"
- cluster_name: "${cluster_name}"
- cluster_subnet: "${cluster_subnet}"
- monitoring_server_url: "${monitoring_server_url}"
- monitoring_cluster_name: "${monitoring_cluster_name}"
- cldwatch_log_group: "${cldwatch_log_group}"
- region: "${region}"
- external_fqdn: "${external_fqdn}"
- alfresco_protocol: "https"
- alfresco_port: "443"
- cluster_enabled: "true"
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/${bastion_inventory}.yml -O ~/users.yml

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  vars_files:
    - "{{ playbook_dir }}/bootstrap_vars.yml"
    - "{{ playbook_dir }}/users.yml"
  roles:
    - bootstrap
    - rsyslog
    - elasticbeats
    - logstash
    - users
    - alfresco
EOF

ansible-galaxy install -f -r ~/requirements.yml
SELF_REGISTER=true ansible-playbook ~/bootstrap.yml

# Currently there is a bit of oddness with the service startup, it seems we have to restart it for Alfresco to be available
export DATE=$(date +"%F-%H-%M")
cp /etc/sysconfig/tomcat /etc/sysconfig/tomcat-$DATE
echo 'JAVA_OPTS="-XmsMEMORY_REPLACE -XmxMEMORY_REPLACE -XX:PermSize=192m -XX:NewSize=512m -XX:MaxPermSize=1G \
  -XX:NewRatio=4 -XX:+UseParNewGC -XX:+UseCodeCacheFlushing -XX:+DisableExplicitGC \
  -XX:InitialCodeCacheSize=256m -XX:ReservedCodeCacheSize=256m -XX:+UseConcMarkSweepGC \
  -XX:+CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -Dsun.rmi.dgc.client.gcInterval=3600000 \
  -Dsun.rmi.dgc.server.gcInterval=3600000 -server -Dsun.security.ssl.allowUnsafeRenegotiation=true -Duser.timezone=UTC \
  -Dsun.security.krb5.msinterop.kstring=true"' > /etc/sysconfig/tomcat

sed -i 's/MEMORY_REPLACE/${jvm_memory}/g' /etc/sysconfig/tomcat

# stop tomcat-alfresco service
sudo systemctl stop tomcat-alfresco
sleep 10
sudo systemctl disable tomcat-alfresco

### Create our log4j.properties file, this needs to go into the bootstrap

sudo mkdir -p /usr/share/tomcat/shared/classes/extension
sudo chown -R tomcat:tomcat /usr/share/tomcat/shared/classes/extension
sudo chmod -R 775 /usr/share/tomcat/shared/classes/extension

cat << EOF > /usr/share/tomcat/shared/classes/extension/log4j.properties
# Set root logger level to error
log4j.rootLogger=debug, Console, File

###### Console appender definition #######

# All outputs currently set to be a ConsoleAppender.
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout

# use log4j NDC to replace %x with tenant domain / username
log4j.appender.Console.layout.ConversionPattern=%d{ISO8601} %x %-5p [%c{3}] [%t] %m%n
#log4j.appender.Console.layout.ConversionPattern=%d{ABSOLUTE} %-5p [%c] %m%n

###### File appender definition #######
log4j.appender.File=org.apache.log4j.DailyRollingFileAppender
log4j.appender.File.File= /usr/share/tomcat/alfresco.log
log4j.appender.File.Append=true
log4j.appender.File.DatePattern='.'yyyy-MM-dd
log4j.appender.File.layout=org.apache.log4j.PatternLayout
log4j.appender.File.layout.ConversionPattern=%d{yyyy-MM-dd} %d{ABSOLUTE} %-5p [%c] [%t] %m%n

###### Hibernate specific appender definition #######
#log4j.appender.file=org.apache.log4j.FileAppender
#log4j.appender.file.File=hibernate.log
#log4j.appender.file.layout=org.apache.log4j.PatternLayout
#log4j.appender.file.layout.ConversionPattern=%d{ABSOLUTE} %5p %c{1}:%L - %m%n

###### Log level overrides #######

# Commented-in loggers will be exposed as JMX MBeans (refer to org.alfresco.repo.admin.Log4JHierarchyInit)
# Hence, generally useful loggers should be listed with at least ERROR level to allow simple runtime
# control of the level via a suitable JMX Console. Also, any other loggers can be added transiently via
# Log4j addLoggerMBean as long as the logger exists and has been loaded.

# Hibernate
log4j.logger.org.hibernate=error
log4j.logger.org.hibernate.util.JDBCExceptionReporter=fatal
log4j.logger.org.hibernate.event.def.AbstractFlushingEventListener=fatal
log4j.logger.org.hibernate.type=warn
log4j.logger.org.hibernate.cfg.SettingsFactory=warn

# Spring
log4j.logger.org.springframework=warn
# Turn off Spring remoting warnings that should really be info or debug.
log4j.logger.org.springframework.remoting.support=error
log4j.logger.org.springframework.util=error

# Axis/WSS4J
log4j.logger.org.apache.axis=info
log4j.logger.org.apache.ws=info

# CXF
log4j.logger.org.apache.cxf=error

# MyFaces
log4j.logger.org.apache.myfaces.util.DebugUtils=info
log4j.logger.org.apache.myfaces.el.VariableResolverImpl=error
log4j.logger.org.apache.myfaces.application.jsp.JspViewHandlerImpl=error
log4j.logger.org.apache.myfaces.taglib=error

# OpenOfficeConnection
log4j.logger.net.sf.jooreports.openoffice.connection=fatal

# log prepared statement cache activity ###
log4j.logger.org.hibernate.ps.PreparedStatementCache=info

# Alfresco
log4j.logger.org.alfresco=error
log4j.logger.org.alfresco.repo.admin=info
log4j.logger.org.alfresco.repo.transaction=warn
log4j.logger.org.alfresco.repo.cache.TransactionalCache=warn
log4j.logger.org.alfresco.repo.model.filefolder=warn
log4j.logger.org.alfresco.repo.tenant=info
log4j.logger.org.alfresco.config=warn
log4j.logger.org.alfresco.config.JndiObjectFactoryBean=warn
log4j.logger.org.alfresco.config.JBossEnabledWebApplicationContext=warn
log4j.logger.org.alfresco.repo.management.subsystems=warn
log4j.logger.org.alfresco.repo.management.subsystems.ChildApplicationContextFactory=info
log4j.logger.org.alfresco.repo.management.subsystems.ChildApplicationContextFactory$ChildApplicationContext=warn
log4j.logger.org.alfresco.repo.security.sync=info
log4j.logger.org.alfresco.repo.security.person=info

log4j.logger.org.alfresco.sample=info
log4j.logger.org.alfresco.web=info
#log4j.logger.org.alfresco.web.app.AlfrescoNavigationHandler=debug
#log4j.logger.org.alfresco.web.ui.repo.component.UIActions=debug
#log4j.logger.org.alfresco.web.ui.repo.tag.PageTag=debug
#log4j.logger.org.alfresco.web.bean.clipboard=debug
log4j.logger.org.alfresco.service.descriptor.DescriptorService=info
#log4j.logger.org.alfresco.web.page=debug

log4j.logger.org.alfresco.repo.importer.ImporterBootstrap=error
#log4j.logger.org.alfresco.repo.importer.ImporterBootstrap=info

log4j.logger.org.alfresco.repo.admin.patch.PatchExecuter=info
log4j.logger.org.alfresco.repo.domain.patch.ibatis.PatchDAOImpl=info

# Specific patches
log4j.logger.org.alfresco.repo.admin.patch.impl.DeploymentMigrationPatch=info
log4j.logger.org.alfresco.repo.version.VersionMigrator=info

log4j.logger.org.alfresco.repo.module.ModuleServiceImpl=info
log4j.logger.org.alfresco.repo.domain.schema.SchemaBootstrap=info
log4j.logger.org.alfresco.repo.admin.ConfigurationChecker=info
log4j.logger.org.alfresco.repo.node.index.AbstractReindexComponent=warn
log4j.logger.org.alfresco.repo.node.index.IndexTransactionTracker=warn
log4j.logger.org.alfresco.repo.node.index.FullIndexRecoveryComponent=info
log4j.logger.org.alfresco.util.OpenOfficeConnectionTester=info
log4j.logger.org.alfresco.repo.node.db.hibernate.HibernateNodeDaoServiceImpl=warn
log4j.logger.org.alfresco.repo.domain.hibernate.DirtySessionMethodInterceptor=warn
log4j.logger.org.alfresco.repo.transaction.RetryingTransactionHelper=warn
log4j.logger.org.alfresco.util.transaction.SpringAwareUserTransaction.trace=warn
log4j.logger.org.alfresco.util.AbstractTriggerBean=warn
log4j.logger.org.alfresco.enterprise.repo.cluster=debug
org.alfresco.enterprise.repo.cluster.core.ClusteringBootstrap=DEBUG
log4j.logger.org.alfresco.repo.version.Version2ServiceImpl=warn

#log4j.logger.org.alfresco.web.app.DebugPhaseListener=debug
log4j.logger.org.alfresco.repo.node.db.NodeStringLengthWorker=info

log4j.logger.org.alfresco.repo.workflow=info

# CIFS server debugging
log4j.logger.org.alfresco.smb.protocol=error
#log4j.logger.org.alfresco.smb.protocol.auth=debug
#log4j.logger.org.alfresco.acegi=debug

# FTP server debugging
log4j.logger.org.alfresco.ftp.protocol=error
#log4j.logger.org.alfresco.ftp.server=debug

# WebDAV debugging
#log4j.logger.org.alfresco.webdav.protocol=debug
log4j.logger.org.alfresco.webdav.protocol=info

# NTLM servlet filters
#log4j.logger.org.alfresco.web.app.servlet.NTLMAuthenticationFilter=debug
#log4j.logger.org.alfresco.repo.webdav.auth.NTLMAuthenticationFilter=debug

# Kerberos servlet filters
#log4j.logger.org.alfresco.web.app.servlet.KerberosAuthenticationFilter=debug
#log4j.logger.org.alfresco.repo.webdav.auth.KerberosAuthenticationFilter=debug

# File servers
log4j.logger.org.alfresco.fileserver=warn

# Repo filesystem debug logging
#log4j.logger.org.alfresco.filesys.repo.ContentDiskDriver=debug

# Integrity message threshold - if 'failOnViolation' is off, then WARNINGS are generated
log4j.logger.org.alfresco.repo.node.integrity=ERROR

# Authentication
# Specifically brute force attack detection
log4j.logger.org.alfresco.repo.security.authentication=warn

# Indexer debugging
log4j.logger.org.alfresco.repo.search.Indexer=error
#log4j.logger.org.alfresco.repo.search.Indexer=debug

log4j.logger.org.alfresco.repo.search.impl.lucene.index=error
log4j.logger.org.alfresco.repo.search.impl.lucene.fts.FullTextSearchIndexerImpl=warn
#log4j.logger.org.alfresco.repo.search.impl.lucene.index=DEBUG

# Audit debugging
# log4j.logger.org.alfresco.repo.audit=DEBUG
# log4j.logger.org.alfresco.repo.audit.model=DEBUG

# Property sheet and modelling debugging
# change to error to hide the warnings about missing properties and associations
log4j.logger.alfresco.missingProperties=warn

# Dictionary/Model debugging
log4j.logger.org.alfresco.repo.dictionary=warn
log4j.logger.org.alfresco.repo.dictionary.types.period=warn

# Virtualization Server Registry
log4j.logger.org.alfresco.mbeans.VirtServerRegistry=error

# Spring context runtime property setter
log4j.logger.org.alfresco.util.RuntimeSystemPropertiesSetter=info

# Debugging options for clustering
log4j.logger.org.alfresco.repo.content.ReplicatingContentStore=debug
log4j.logger.org.alfresco.repo.content.replication=debug

#log4j.logger.org.alfresco.repo.deploy.DeploymentServiceImpl=debug

# Activity service
log4j.logger.org.alfresco.repo.activities=warn

# User usage tracking
log4j.logger.org.alfresco.repo.usage=info

# Sharepoint
log4j.logger.org.alfresco.module.vti=info

# Forms Engine
log4j.logger.org.alfresco.web.config.forms=info
log4j.logger.org.alfresco.web.scripts.forms=info

# CMIS
log4j.logger.org.alfresco.opencmis=error
log4j.logger.org.alfresco.opencmis.AlfrescoCmisServiceInterceptor=error
log4j.logger.org.alfresco.cmis=error
log4j.logger.org.alfresco.cmis.dictionary=warn
log4j.logger.org.apache.chemistry.opencmis=info
log4j.logger.org.apache.chemistry.opencmis.server.impl.browser.CmisBrowserBindingServlet=OFF
log4j.logger.org.apache.chemistry.opencmis.server.impl.atompub.CmisAtomPubServlet=OFF

# IMAP
log4j.logger.org.alfresco.repo.imap=info

# JBPM
# Note: non-fatal errors (eg. logged during job execution) should be handled by Alfresco's retrying transaction handler
log4j.logger.org.jbpm.graph.def.GraphElement=fatal

#log4j.logger.org.alfresco.repo.googledocs=debug

###### Scripting #######

# Web Framework
log4j.logger.org.springframework.extensions.webscripts=info
log4j.logger.org.springframework.extensions.webscripts.ScriptLogger=warn
log4j.logger.org.springframework.extensions.webscripts.ScriptDebugger=off

# Repository
log4j.logger.org.alfresco.repo.web.scripts=warn
log4j.logger.org.alfresco.repo.web.scripts.BaseWebScriptTest=info
log4j.logger.org.alfresco.repo.web.scripts.AlfrescoRhinoScriptDebugger=off
log4j.logger.org.alfresco.repo.jscript=error
log4j.logger.org.alfresco.repo.jscript.ScriptLogger=warn
log4j.logger.org.alfresco.repo.cmis.rest.CMISTest=info

log4j.logger.org.alfresco.repo.domain.schema.script.ScriptBundleExecutorImpl=off
log4j.logger.org.alfresco.repo.domain.schema.script.ScriptExecutorImpl=info

log4j.logger.org.alfresco.repo.search.impl.solr.facet.SolrFacetServiceImpl=info

# Bulk Filesystem Import Tool
log4j.logger.org.alfresco.repo.bulkimport=warn

# Freemarker
# Note the freemarker.runtime logger is used to log non-fatal errors that are handled by Alfresco's retrying transaction handler
log4j.logger.freemarker.runtime=

# Metadata extraction
log4j.logger.org.alfresco.repo.content.metadata.AbstractMappingMetadataExtracter=warn

# Reduces PDFont error level due to ALF-7105
log4j.logger.org.apache.pdfbox.pdmodel.font.PDSimpleFont=fatal
log4j.logger.org.apache.pdfbox.pdmodel.font.PDFont=fatal
log4j.logger.org.apache.pdfbox.pdmodel.font.PDCIDFont=fatal

# no index support
log4j.logger.org.alfresco.repo.search.impl.noindex.NoIndexIndexer=fatal
log4j.logger.org.alfresco.repo.search.impl.noindex.NoIndexSearchService=fatal

# lucene index warnings
log4j.logger.org.alfresco.repo.search.impl.lucene.index.IndexInfo=warn

# Warn about RMI socket bind retries.
log4j.logger.org.alfresco.util.remote.server.socket.HostConfigurableSocketFactory=warn

log4j.logger.org.alfresco.repo.usage.RepoUsageMonitor=info

# Authorization
log4j.logger.org.alfresco.enterprise.repo.authorization.AuthorizationService=info
log4j.logger.org.alfresco.enterprise.repo.authorization.AuthorizationsConsistencyMonitor=warn


EOF
# start tomcat service
sudo systemctl enable tomcat
sudo systemctl start tomcat