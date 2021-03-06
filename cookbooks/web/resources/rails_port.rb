#
# Cookbook Name:: web
# Resource:: rails_port
#
# Copyright 2012, OpenStreetMap Foundation
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

require "yaml"

resource_name :rails_port

default_action :create

property :site, String, :name_attribute => true
property :ruby, String, :default => "2.3"
property :directory, String
property :user, String
property :group, String
property :repository, String, :default => "https://git.openstreetmap.org/public/rails.git"
property :revision, String, :default => "live"
property :run_migrations, [TrueClass, FalseClass], :default => false
property :email_from, String, :default => "OpenStreetMap <support@openstreetmap.org>"
property :status, String, :default => "online"
property :database_host, String
property :database_port, String
property :database_name, String
property :database_username, String
property :database_password, String
property :email_from, String
property :messages_domain, String
property :gpx_dir, String
property :attachments_dir, String
property :log_path, String
property :logstash_path, String
property :memcache_servers, Array
property :potlatch2_key, String
property :id_key, String
property :oauth_key, String
property :nominatim_url, String
property :osrm_url, String
property :google_auth_id, String
property :google_auth_secret, String
property :google_openid_realm, String
property :facebook_auth_id, String
property :facebook_auth_secret, String
property :windowslive_auth_id, String
property :windowslive_auth_secret, String
property :github_auth_id, String
property :github_auth_secret, String
property :wikipedia_auth_id, String
property :wikipedia_auth_secret, String
property :thunderforest_key, String
property :totp_key, String
property :csp_enforce, [TrueClass, FalseClass], :default => false
property :csp_report_url, String
property :piwik_configuration, Hash
property :trace_use_job_queue, [TrueClass, FalseClass], :default => false

action :create do
  package %W[
    ruby#{new_resource.ruby}
    ruby#{new_resource.ruby}-dev
    imagemagick
    nodejs
    geoip-database
  ]

  package %w[
    g++
    pkg-config
    libpq-dev
    libsasl2-dev
    libxml2-dev
    libxslt1-dev
    libmemcached-dev
    libffi-dev
  ]

  package %w[
    pngcrush
    advancecomp
    optipng
    pngquant
    jhead
    jpegoptim
    gifsicle
    libjpeg-turbo-progs
  ]

  gem_package "bundler#{new_resource.ruby}" do
    package_name "bundler"
    version "1.16.2"
    gem_binary "gem#{new_resource.ruby}"
    options "--format-executable"
  end

  gem_package "bundler#{new_resource.ruby}" do
    package_name "pkg-config"
    gem_binary "gem#{new_resource.ruby}"
  end

  declare_resource :directory, rails_directory do
    owner new_resource.user
    group new_resource.group
    mode 0o2775
  end

  git rails_directory do
    action :sync
    repository new_resource.repository
    revision new_resource.revision
    user new_resource.user
    group new_resource.group
    notifies :run, "execute[#{rails_directory}/Gemfile]"
    notifies :run, "execute[#{rails_directory}/app/assets/javascripts/i18n]"
    notifies :run, "execute[#{rails_directory}/public/assets]"
    notifies :delete, "file[#{rails_directory}/public/export/embed.html]"
    notifies :restart, "passenger_application[#{rails_directory}]"
  end

  declare_resource :directory, "#{rails_directory}/tmp" do
    owner new_resource.user
    group new_resource.group
  end

  file "#{rails_directory}/config/environment.rb" do
    owner new_resource.user
    group new_resource.group
  end

  template "#{rails_directory}/config/database.yml" do
    cookbook "web"
    source "database.yml.erb"
    owner new_resource.user
    group new_resource.group
    mode 0o664
    variables :host => new_resource.database_host,
              :port => new_resource.database_port,
              :name => new_resource.database_name,
              :username => new_resource.database_username,
              :password => new_resource.database_password
    notifies :restart, "passenger_application[#{rails_directory}]"
  end

  application_yml = edit_file "#{rails_directory}/config/example.application.yml" do |line|
    line.gsub!(/^( *)server_protocol:.*$/, "\\1server_protocol: \"https\"")
    line.gsub!(/^( *)server_url:.*$/, "\\1server_url: \"#{new_resource.site}\"")

    line.gsub!(/^( *)#publisher_url:.*$/, "\\1publisher_url: \"https://plus.google.com/111953119785824514010\"")

    line.gsub!(/^( *)support_email:.*$/, "\\1support_email: \"support@openstreetmap.org\"")

    if new_resource.email_from
      line.gsub!(/^( *)email_from:.*$/, "\\1email_from: \"#{new_resource.email_from}\"")
    end

    line.gsub!(/^( *)email_return_path:.*$/, "\\1email_return_path: \"bounces@openstreetmap.org\"")

    line.gsub!(/^( *)status:.*$/, "\\1status: :#{new_resource.status}")

    if new_resource.messages_domain
      line.gsub!(/^( *)#messages_domain:.*$/, "\\1messages_domain: \"#{new_resource.messages_domain}\"")
    end

    line.gsub!(/^( *)#geonames_username:.*$/, "\\1geonames_username: \"openstreetmap\"")

    line.gsub!(/^( *)#geoip_database:.*$/, "\\1geoip_database: \"/usr/share/GeoIP/GeoIPv6.dat\"")

    if new_resource.gpx_dir
      line.gsub!(/^( *)gpx_trace_dir:.*$/, "\\1gpx_trace_dir: \"#{new_resource.gpx_dir}/traces\"")
      line.gsub!(/^( *)gpx_image_dir:.*$/, "\\1gpx_image_dir: \"#{new_resource.gpx_dir}/images\"")
    end

    if new_resource.attachments_dir
      line.gsub!(/^( *)attachments_dir:.*$/, "\\1attachments_dir: \"#{new_resource.attachments_dir}\"")
    end

    if new_resource.log_path
      line.gsub!(/^( *)#log_path:.*$/, "\\1log_path: \"#{new_resource.log_path}\"")
    end

    if new_resource.logstash_path
      line.gsub!(/^( *)#logstash_path:.*$/, "\\1logstash_path: \"#{new_resource.logstash_path}\"")
    end

    if new_resource.memcache_servers
      line.gsub!(/^( *)#memcache_servers:.*$/, "\\1memcache_servers: [ \"#{new_resource.memcache_servers.join('", "')}\" ]")
    end

    if new_resource.potlatch2_key
      line.gsub!(/^( *)#potlatch2_key:.*$/, "\\1potlatch2_key: \"#{new_resource.potlatch2_key}\"")
    end

    if new_resource.id_key
      line.gsub!(/^( *)#id_key:.*$/, "\\1id_key: \"#{new_resource.id_key}\"")
    end

    if new_resource.oauth_key
      line.gsub!(/^( *)#oauth_key:.*$/, "\\1oauth_key: \"#{new_resource.oauth_key}\"")
    end

    if new_resource.nominatim_url
      line.gsub!(/^( *)nominatim_url:.*$/, "\\1nominatim_url: \"#{new_resource.nominatim_url}\"")
    end

    if new_resource.osrm_url
      line.gsub!(/^( *)osrm_url:.*$/, "\\1osrm_url: \"#{new_resource.osrm_url}\"")
    end

    if new_resource.google_auth_id
      line.gsub!(/^( *)#google_auth_id:.*$/, "\\1google_auth_id: \"#{new_resource.google_auth_id}\"")
      line.gsub!(/^( *)#google_auth_secret:.*$/, "\\1google_auth_secret: \"#{new_resource.google_auth_secret}\"")
      line.gsub!(/^( *)#google_openid_realm:.*$/, "\\1google_openid_realm: \"#{new_resource.google_openid_realm}\"")
    end

    if new_resource.facebook_auth_id
      line.gsub!(/^( *)#facebook_auth_id:.*$/, "\\1facebook_auth_id: \"#{new_resource.facebook_auth_id}\"")
      line.gsub!(/^( *)#facebook_auth_secret:.*$/, "\\1facebook_auth_secret: \"#{new_resource.facebook_auth_secret}\"")
    end

    if new_resource.windowslive_auth_id
      line.gsub!(/^( *)#windowslive_auth_id:.*$/, "\\1windowslive_auth_id: \"#{new_resource.windowslive_auth_id}\"")
      line.gsub!(/^( *)#windowslive_auth_secret:.*$/, "\\1windowslive_auth_secret: \"#{new_resource.windowslive_auth_secret}\"")
    end

    if new_resource.github_auth_id
      line.gsub!(/^( *)#github_auth_id:.*$/, "\\1github_auth_id: \"#{new_resource.github_auth_id}\"")
      line.gsub!(/^( *)#github_auth_secret:.*$/, "\\1github_auth_secret: \"#{new_resource.github_auth_secret}\"")
    end

    if new_resource.wikipedia_auth_id
      line.gsub!(/^( *)#wikipedia_auth_id:.*$/, "\\1wikipedia_auth_id: \"#{new_resource.wikipedia_auth_id}\"")
      line.gsub!(/^( *)#wikipedia_auth_secret:.*$/, "\\1wikipedia_auth_secret: \"#{new_resource.wikipedia_auth_secret}\"")
    end

    if new_resource.thunderforest_key
      line.gsub!(/^( *)#thunderforest_key:.*$/, "\\1thunderforest_key: \"#{new_resource.thunderforest_key}\"")
    end

    if new_resource.totp_key
      line.gsub!(/^( *)#totp_key:.*$/, "\\1totp_key: \"#{new_resource.totp_key}\"")
    end

    if new_resource.csp_enforce
      line.gsub!(/^( *)csp_enforce:.*$/, "\\1csp_enforce: \"#{new_resource.csp_enforce}\"")
    end

    if new_resource.csp_report_url
      line.gsub!(/^( *)#csp_report_url:.*$/, "\\1csp_report_url: \"#{new_resource.csp_report_url}\"")
    end

    line.gsub!(/^( *)require_terms_seen:.*$/, "\\1require_terms_seen: true")
    line.gsub!(/^( *)require_terms_agreed:.*$/, "\\1require_terms_agreed: true")
    line.gsub!(/^( *)trace_use_job_queue:.*$/, "\\1trace_use_job_queue: false")

    line
  end

  file "create:#{rails_directory}/config/application.yml" do
    path "#{rails_directory}/config/application.yml"
    owner new_resource.user
    group new_resource.group
    mode 0o664
    content application_yml
    notifies :run, "execute[#{rails_directory}/public/assets]"
    only_if { ::File.exist?("#{rails_directory}/config/example.application.yml") }
  end

  file "delete:#{rails_directory}/config/application.yml" do
    path "#{rails_directory}/config/application.yml"
    action :delete
    not_if { ::File.exist?("#{rails_directory}/config/example.application.yml") }
  end

  settings = new_resource.to_hash.transform_keys(&:to_s).slice(
    "email_from",
    "status",
    "messages_domain",
    "attachments_dir",
    "log_path",
    "logstash_path",
    "potlatch2_key",
    "id_key",
    "oauth_key",
    "nominatim_url",
    "osrm_url",
    "google_auth_id",
    "google_auth_secret",
    "google_openid_realm",
    "facebook_auth_id",
    "facebook_auth_secret",
    "windowslive_auth_id",
    "windowslive_auth_secret",
    "github_auth_id",
    "gihub_auth_secret",
    "wikipedia_auth_id",
    "wikipedia_auth_secret",
    "thunderforest_key",
    "totp_key",
    "csp_enforce",
    "csp_report_url",
    "trace_use_job_queue"
  ).reject { |_k, v| v.nil? }.merge(
    "server_protocol" => "https",
    "server_url" => new_resource.site,
    "publisher_url" => "https://plus.google.com/111953119785824514010",
    "support_email" => "support@openstreetmap.org",
    "email_return_path" => "bounces@openstreetmap.org",
    "geonames_username" => "openstreetmap",
    "geoip_database" => "/usr/share/GeoIP/GeoIPv6.dat"
  )

  if new_resource.memcache_servers
    settings["memcache_servers"] = new_resource.memcache_servers.to_a
  end

  if new_resource.gpx_dir
    settings["gpx_trace_dir"] = "#{new_resource.gpx_dir}/traces"
    settings["gpx_image_dir"] = "#{new_resource.gpx_dir}/images"
  end

  file "#{rails_directory}/config/settings.local.yml" do
    owner new_resource.user
    group new_resource.group
    mode 0o664
    content YAML.dump(settings)
    notifies :run, "execute[#{rails_directory}/public/assets]"
    only_if { ::File.exist?("#{rails_directory}/config/settings.yml") }
  end

  if new_resource.piwik_configuration
    file "#{rails_directory}/config/piwik.yml" do
      owner new_resource.user
      group new_resource.group
      mode 0o664
      content YAML.dump(new_resource.piwik_configuration)
      notifies :run, "execute[#{rails_directory}/public/assets]"
    end
  else
    file "#{rails_directory}/config/piwik.yml" do
      action :delete
      notifies :run, "execute[#{rails_directory}/public/assets]"
    end
  end

  execute "#{rails_directory}/Gemfile" do
    action :nothing
    command "bundle#{new_resource.ruby} install"
    cwd rails_directory
    user "root"
    group "root"
    environment "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "yes"
    subscribes :run, "gem_package[bundler#{new_resource.ruby}]"
    notifies :restart, "passenger_application[#{rails_directory}]"
  end

  execute "#{rails_directory}/db/migrate" do
    action :nothing
    command "bundle#{new_resource.ruby} exec rake db:migrate"
    cwd rails_directory
    user new_resource.user
    group new_resource.group
    subscribes :run, "git[#{rails_directory}]"
    notifies :restart, "passenger_application[#{rails_directory}]"
    only_if { new_resource.run_migrations }
  end

  execute "#{rails_directory}/app/assets/javascripts/i18n" do
    action :nothing
    command "bundle#{new_resource.ruby} exec rake i18n:js:export"
    environment "RAILS_ENV" => "production"
    cwd rails_directory
    user new_resource.user
    group new_resource.group
    notifies :run, "execute[#{rails_directory}/public/assets]"
  end

  execute "#{rails_directory}/public/assets" do
    action :nothing
    command "bundle#{new_resource.ruby} exec rake assets:precompile"
    environment "RAILS_ENV" => "production"
    cwd rails_directory
    user new_resource.user
    group new_resource.group
    notifies :restart, "passenger_application[#{rails_directory}]"
  end

  file "#{rails_directory}/public/export/embed.html" do
    action :nothing
  end

  passenger_application rails_directory do
    action :nothing
    only_if { ::File.exist?("/usr/bin/passenger-config") }
  end

  template "/etc/cron.daily/rails-#{new_resource.site.tr('.', '-')}" do
    cookbook "web"
    source "rails.cron.erb"
    owner "root"
    group "root"
    mode 0o755
    variables :directory => rails_directory
  end
end

action :restart do
  passenger_application rails_directory do
    action :restart
  end
end

action_class do
  include Chef::Mixin::EditFile

  def rails_directory
    new_resource.directory || "/srv/#{new_resource.site}"
  end
end
