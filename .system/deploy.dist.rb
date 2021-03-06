################################################################################
# Capistrano recipe for deploying to MediaTemple                               #
################################################################################

logger.level = Capistrano::Logger::IMPORTANT  # MAX_LEVEL

# Source control settings ------------------------------------------------------

# the source control ssh nuser
set :git_user, "git"

# the source control host
set :git_host, "github.com"

# the source control user id
set :git_account, "your-github-ccount"

# the source control repository name
set :git_repository, "your-domain.com"

# the git-clone url for your repository
set :repository, "#{git_user}@#{git_host}:#{git_account}/#{git_repository}.git"

# the branch you want to clone (default is master)
set :branch, "master"

# tell capistrano to init and update submodules
set :git_enable_submodules, 1

# ------------------------------------------------------------------------------

# the user id of your (mt) account
set :mt_id, "USERID"

# The name of the application.
set :application, "s#{mt_id}.gridserver.com"

# The name of the user to use when logging into the remote host(s).
set :user, "your-domain.com"

# The root of the directory tree on the remote host(s) that the
# application should be deployed to
set :deploy_to, "/home/#{mt_id}/domains/#{git_repository}"

# The directory under deploy_to that should contain each deployed revision.
set :version_dir, "releases"

# The name to use (relative to deploy_to) for the symlink that points at
# the current release
set :current_dir, "html"

# The name of the directory under deploy_to that will contain directories and
# files to be shared between all releases.
set :shared_dir, "shared"

# The directories which are to be shared and not deployed.
set :shared_children, %w(.cache)

# The files which are to be shared and not deployed.
set :shared_files, [".system/config.php", ".system/sitemap.xml"]

# You shouldn't need to edit below unless you're customizing ###################

# Required to get asked for key import upon connection to new hosts when
# deploying to a new server.
default_run_options[:pty] = true

set :scm, :git
set :ssh_options, { :forward_agent => true }
set :deploy_via, :remote_cache
set :copy_strategy, :checkout
set :copy_compression, :bz2
set :keep_releases, 3

# Whether or not tasks that can use sudo, ought to use sudo. In a shared
# environment, this is typically not desirable (or possible), and
# in that case you should set this variable to false
set :use_sudo, false

# Roles
role :app, "#{application}"
role :web, "#{application}"
role :db,  "#{application}", :primary => true

# Overloaded methods ###########################################################
namespace :deploy do

  desc <<-DESC
    Restart is an empty dummy task for PHP
  DESC
  task :restart, :roles => :app do
    # do nothing but override the default
  end

  desc <<-DESC
    Update latest release source path
  DESC
  task :finalize_update, :roles => :app do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
  end

  desc <<-DESC
    Symlink static directories and static files that need to remain between deployments
  DESC
  task :create_symlinks, :roles => :app do
    if shared_files
      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "mkdir -p #{link_dir}"
        run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end
    end
  end
end

# Deployment process ###########################################################
after "deploy", "deploy:create_symlinks"

after ('deploy:setup'), :roles => :app do
  if Capistrano::CLI.ui.agree("Upload configuration? (y/N)")
    run "mkdir -p #{deploy_to}/#{shared_dir}/.system/"
    top.upload(".system/config.php", "#{deploy_to}/#{shared_dir}/.system/config.php", :via => :scp)
  end
end
