# ==============================================================
# Packages
# ==============================================================

execute "update repositories" do
	command "apt-get update -y"
	action :run
end

apt_packages = [
  "apache2",
	"build-essential",
  "libapache2-mod-python",
  "python-cairo",
  "python-dev",
  "python-django",
  "python-django-tagging",
  "python-ldap",
  "python-memcache",
  "python-pip",
  "python-pysqlite2",
  "python-simplejson",
]
apt_packages.each do |pkg|
  apt_package pkg do
    action :upgrade # install or upgrade
  end
end


# ==============================================================
# install & configure graphite
# ==============================================================

# Apparently graphite needs an older version of Twisted
execute "pip install twisted" do
  command 'pip install "Twisted<12.0"'
  action :run
end

execute "pip install ceres" do
  command 'pip install https://github.com/graphite-project/ceres/tarball/master'
  action :run
end

execute "pip install carbon" do
  command 'pip install carbon'
  action :run
end

execute "pip install whisper" do
  command 'pip install whisper'
  action :run
end

execute "pip install graphite-web" do
  command 'pip install graphite-web'
  action :run
end

# Copy config files into place
cookbook_file "carbon.conf" do
  path "/opt/graphite/conf/carbon.conf"
  mode 0644 # -rw-r--r--
  action :create
end
cookbook_file "storage-schemas.conf" do
  path "/opt/graphite/conf/storage-schemas.conf"
  mode 0644 # -rw-r--r--
  action :create
end
cookbook_file "aggregation-rules.conf" do
  path "/opt/graphite/conf/aggregation-rules.conf"
  mode 0644 # -rw-r--r--
  action :create
end

# Directory permissions
www_data_dirs = [
  "/opt/graphite/storage",
  "/opt/graphite/storage/log/webapp",
  "/opt/graphite/storage/whisper",
]
www_data_dirs.each do |www_data_dir|
  directory www_data_dir do
    owner "www-data"
    mode 0775 # -rwxrwxr-x
    action :create
  end
end

# Setup graphite-webapp database (sqlite, no initial admin user)
execute "create tables for graphite webapp" do
  cwd '/opt/graphite/webapp/graphite'
  command 'python manage.py syncdb --noinput' # runs as sudo
  action :run
end

# Change ownership of the graphite.db sqlite database
file "/opt/graphite/storage/graphite.db" do
  owner "www-data"
  mode 0644 # -rw-r--r--
  action :create
end



# ==============================================================
# configure apache for graphite-webapp
# ==============================================================

# Copy config files into place
cookbook_file "graphite-vhost" do
  path "/etc/apache2/sites-available/graphite-vhost"
  action :create
end

service "apache2" do
  supports :start => true, :stop => true, :restart => true, :reload => true
  action :nothing
end

execute "disable default site" do
  command 'a2dissite default' # runs as sudo
  action :run
  notifies :reload, "service[apache2]"
end

execute "enable graphite site" do
  command 'a2ensite graphite-vhost' # runs as sudo
  action :run
  notifies :reload, "service[apache2]"
end
