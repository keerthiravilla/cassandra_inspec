
# encoding: utf-8
#
# Copyright 2018, R S Keerthi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use or modify this file except in compliance with the licence
#
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
#
#author : R S Keerthi
#
#Testing cassandra for ubuntu 16.04
if( os[:name]== 'ubuntu' && os[:family]=='debian' && os[:release]=='16.04' )
#cassandra nosql database
#checking the status of the cassandra database
      control 'os-ubuntu' do
	impact 0.5
	title 'Cassandra installed'
	desc 'Cassandra service should be installed,enabled and running'
        describe service("cassandra")do
             it {should be_installed}
             it {should be_enabled}
             it {should be_running}
        end
      end
      

#To check cassandra files
#
#
# cassandra.conf file checking
     control 'cassandra-file-check'do
       desc 'cassandra.conf file should exit and should be executable file'
       describe file('/etc/sysctl.d/cassandra.conf')do
            it {should exist}
            it {should be_file}
            its('mode') {should cmp '0644'}
       end
     
# cassandra.service file checking
        describe file('/run/systemd/generator.late/cassandra.service') do
             it { should exist }
             it { should be_file }
      end
     end
#
#
# using ufw enable the firewall
#   
#To check cassandra services and permissions
     control 'cassandra-services'do
       desc 'The cassandra service file should contain the path to cassandra.conf file and it should be owned by root, writable by others and   readable by others'
       describe file('/run/systemd/generator.late/cassandra.service') do
            it { should be_owned_by 'root' }
            it { should be_grouped_into 'root' }
            it { should be_readable.by('others') }
            it { should_not be_writable.by('others') }
            it { should_not be_executable.by('others') }
        end
      end
#To check cassandra.yaml services and permissions
     control 'cassandra-yaml-file'do
       desc 'The cassandra yaml file should be owned by root,writable by others and readable by others' 
       describe file('/etc/cassandra/cassandra.yaml') do 
            it { should be_owned_by 'root' }
            it { should be_grouped_into 'root' }
            it { should be_readable.by('others') }
            it { should_not be_writable.by('others') }
            it { should_not be_executable.by('others') }
       end
     end
#
#
#To check the cassandra service file contents
        describe file('/run/systemd/generator.late/cassandra.service') do
            its('content') { should match 'Type=forking' }
            its('content') { should match 'Restart=no' }
            its('content') { should match 'IgnoreSIGPIPE=no'}
            its('content') { should match 'KillMode=process'}
            its('content') { should match 'GuessMainPID=no'}
            its('content') { should match 'RemainAfterExit=yes'}
            its('content') { should match 'ExecStart=/etc/init.d/cassandra       start' }
            its('content') { should match 'TimeoutSec=5min'}
        end
#
#
#To check cassandra.conf services and permissions
     control 'cassandra-conf-file'do
       desc 'The cassandra conf file should be owned by root,writable by others and readable by others'
       describe file('/etc/sysctl.d/cassandra.conf') do
            it { should be_owned_by 'root' }
            it { should be_grouped_into 'root' }
            it { should be_readable.by('others') }
            it { should_not be_writable.by('others') }
            it { should_not be_executable.by('others') }
        end
     end
#
#  
#security process
     control 'cassandra-process' do
       impact 0.8
       title 'Process-security'
       desc 'cassandra process should not run as the root user'
       describe processes('cassandra') do
            its('users') { should_not include 'root' } 
       end
     end
#
#
#To check the cassandra-env.sh
#       
#The cassandra-env files max heap size should be 4G and newsize should be 800M for better performance of cassandra
       describe file('/etc/cassandra/cassandra-env.sh')do
            its('MAX_HEAP_SIZE') {should eq '4G'}
            its('HEAP_NEWSIZE') {should eq '800M'}
            its('JMX_PORT') {should match 7199}
       end
#
#checking cassandra.yaml file
    control 'cassandra.yaml-file'do
      desc 'checking the cassandra.yaml methods for optimizing and configuring cassandra' 
      describe yaml('/etc/cassandra/cassandra.yaml')do
           its('disk_failure_policy') {should eq 'stop'}
           its('commit_failure_policy') {should eq 'stop'}
           its('prepared_statements_cache_size_mb') {should_not match /<0/}
           its('disk_optimization_strategy') {should eq 'ssd'}
           its('memtable_allocation_type') {should eq 'heap_buffers'}
           its('ssl_storage_port') {should cmp 7001}
           its('listen_interface') {should eq 'eth0'}
           its('sstable_preemptive_open_interval_in_mb') {should eq 50}
           its('dynamic_snitch_badness_threshold') {should eq 0.1} 
           its('batch_size_fail_threshold_in_kb') {should eq 50}
           its('listen_address') {should cmp 'localhost'}
           its('tracetype_query_ttl') {should cmp 86400}
#optimizing disk read Possible values
           its('disk_optimization_strategy') {should cmp 'ssd'}
#
#its('client_encryption_enabled') {should eq 'true'}
#to increase the performance of cassandra
           its('dynamic_snitch_update_interval_in_ms') {should cmp 100}
           its('dynamic_snitch_reset_interval_in_ms') {should cmp 600000}
           its('dynamic_snitch_badness_threshold') {should cmp 0.1}
#
#for best cassandra test environment rpc_server_type=hsha thrift clients are handled asynchronously using a small number of threads that do not vary with the amount of thrift clients
#change rpc_server_type value to hsha
#changes to yaml file to increase the performance
#reference http://opensourceconnections.com/blog/2013/08/31/building-the-perfect-cassandra-test-environment/

            its('rpc_server_type') {should match 'hsha'}   
            its('concurrent_compactors') {should cmp 1}
            its('key_cache_size_in_mb') {should cmp 0}
            its('compaction_throughput_mb_per_sec') {should cmp 0}
       end
     end
#
#To check the info of the cassandra service
#fetching uid and gid of a system
   File.open('/etc/passwd').each do |line|
        if line.include? "cassandra"
           user=line
           userdata=user.split(":")
           user_uid=userdata[2]
           user_gid=userdata[3]
        control 'passwd' do
          title 'cassandra-info'
          desc 'It contains the cassandra information that may log into the system'
          if(describe passwd()do
             its('users') { should include 'cassandra' }
          end)
          describe passwd.users('cassandra') do
               its('uids') { should include user_uid }
	       its('gids') { should include user_gid }
          end
         end
       end
     end
   end      
#
#
#cassandra port and ip address
    describe port('7199') do
         it { should be_listening } 
         its('processes') { should include 'cassandra'}
         its ('protocols') { should include 'tcp' }
    end
    describe ssl(port:22) do
         it { should_not be_enabled }
    end
#
#			
#checking user details
    control 'user' do
      desc 'To check cassandra profiles for a single, known/expected local user, including the groups to which that user belongs, the frequency of required password changes, and the directory paths to home and shell'
      describe user('cassandra') do
           it { should exist }
           its('group') {should_not eq 'root' }
      end
    end
#
#
#To check the cassandra.rackdc.properties
#To configuring cassandra.rackdc properties to optimize the cassandra'
      describe file('/etc/cassandra/cassandra-rackdc.properties')do
           its('dc') {should cmp 'dc1'}
           its('rack') {should cmp 'rack1'}
       end
#
#
#To optimize and improve performance of the cassandra
#<keyspace> is the one from which algorithm can find the load
#information to optimize token assignment 
    describe yaml('/etc/cassandra/cassandra.yaml')do
         its('Dcassandra.allocate_tokens_for_keyspace') {should eq '<keyspace>'}
 
         #To override the bootstrap process failure 
         its('Dcassandra.consistent.rangemovement') {should cmp 'false'}

         #To resume failed and hanged bootstrap
         its('Dcassandra.reset_bootstrap_progress') {should cmp 'true'}
         #Replacing a dead node
         its('Dcassandra.replace_address_first_boot') {should eq '<dead_node_ip>'}
      end
#
#
#configuring gossip settings
    describe yaml('/etc/cassandra/cassandra.yaml')do
         its('storage_port') {should eq 7000}
    end

#user resoucre limits
#by limiting the resources for the users the disk will be optimized in cassandra
    describe file('/etc/security/limits.d/cassandra.conf')do
         its('content') {should include 'cassandra  -  memlock  unlimited'}
         its('content') {should include 'cassandra  -  as       unlimited'}
         its('content') {should include 'cassandra  -  nproc    8096'}
     end
#
#
#checking wheather the file contains user encryption properties
describe file('/etc/cassandra/cassandra.yaml')do
     its('content') {should match 'internode_encryption: none' }
     its('content') {should match 'keystore: conf/.keystore'}
     its('content') {should match 'truststore: conf/.truststore'}
     its('content') {should match 'truststore_password: cassandra'}
     its('content') {should match 'chunk_length_kb: 64'}
     its('content') {should match 'cipher: AES/CBC/PKCS5Padding'}   
end
end
