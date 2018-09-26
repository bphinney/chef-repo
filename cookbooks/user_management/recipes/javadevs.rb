#
# Cookbook Name:: users
# Recipe:: javadevs
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Searches data bag "users" for groups attribute "javadev".
# Places returned users in Unix group "javadev" with GID 2301.

#users_manage "javadev" do
#  group_id 2301
#  action [ :remove, :create ]
#end

template "/usr/local/bin/userscan.sh" do
  source "userscan.sh.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end
