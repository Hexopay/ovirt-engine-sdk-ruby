#!/usr/bin/ruby

#
# Copyright (c) 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'logger'
require 'ovirtsdk4'

# This example will connect to the server and attach an existing NFS
# data storage domain to a data center.

# Create the connection to the server:
connection = OvirtSDK4::Connection.new(
  url: 'https://engine40.example.com/ovirt-engine/api',
  username: 'admin@internal',
  password: 'redhat123',
  ca_file: 'ca.pem',
  debug: true,
  log: Logger.new('example.log')
)

# Locate the service that manages the storage domains and use it to
# search for the storage domain:
sds_service = connection.system_service.storage_domains_service
sd = sds_service.list(search: 'name=mydata')[0]

# Locate the service that manages the data centers and use it to
# search for the data center:
dcs_service = connection.system_service.data_centers_service
dc = dcs_service.list(search: 'name=mydc')[0]

# Locate the service that manages the data center where we want to
# attach the storage domain:
dc_service = dcs_service.data_center_service(dc.id)

# Locate the service that manages the storage domains that are attached
# to the data centers:
attached_sds_service = dc_service.storage_domains_service

# Use the "add" method of service that manages the attached storage
# domains to attach it:
attached_sds_service.add(
  OvirtSDK4::StorageDomain.new(
    id: sd.id
  )
)

# Wait till the storage domain is active:
attached_sd_service = attached_sds_service.storage_domain_service(sd.id)
loop do
  sleep(5)
  sd = attached_sd_service.get
  break if sd.status == OvirtSDK4::StorageDomainStatus::ACTIVE
end

# Close the connection to the server:
connection.close
