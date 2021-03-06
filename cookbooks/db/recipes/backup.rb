#
# Cookbook Name:: db
# Recipe:: backup
#
# Copyright 2013, OpenStreetMap Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

template "/usr/local/bin/backup-db" do
  source "backup-db.erb"
  owner "root"
  group "root"
  mode 0o755
end

template "/etc/cron.d/backup-db" do
  source "backup.cron.erb"
  owner "root"
  group "root"
  mode 0o644
end
